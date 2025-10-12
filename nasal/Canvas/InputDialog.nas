#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# InputDialog class.
#
var InputDialog = {
    CLASS: "InputDialog",

    #
    # Constants:
    #
    WINDOW_WIDTH  : 400,
    WINDOW_HEIGHT : 120,

    #
    # Constructor.
    #
    # @param  hash  columns  Columns object.
    # @return hash
    #
    new: func(columns) {
        var me = {
            parents: [
                InputDialog,
                PersistentDialog.new(InputDialog.WINDOW_WIDTH, InputDialog.WINDOW_HEIGHT, "Change value"),
            ],
        };

        call(PersistentDialog.setChild, [me, InputDialog], me.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], me.parents[1]);

        me._addonNodePath = g_Addon.node.getPath();

        me._recordId        = nil; # Record ID in SQLLite or index of log entry in whole CSV file
        me._parent          = nil; # DetailsDialog
        me._value           = nil;
        me._columnItem      = nil; # columnItem from Columns class

        me._filterSelector = FilterSelector.new(columns);

        var MARGIN = 12;
        me._vbox.setContentsMargin(MARGIN);

        me._label = canvas.gui.widgets.Label.new(me._group, canvas.style, {wordWrap: true});
        me._vbox.addItem(me._label);

        me._lineEdit = canvas.gui.widgets.LineEdit.new(me._group, canvas.style, {});
        me._vbox.addItem(me._lineEdit);
        me._lineEdit.setFocus();

        var buttonBox = canvas.HBoxLayout.new();
        me._vbox.addItem(buttonBox);

        me._btnTypeSelector = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("Select")
            .listen("clicked", func { me._actionTypeSelect(); }
        );
        me._btnTypeSelector.setVisible(false);

        var btnOK = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("Save")
            .listen("clicked", func { me._actionSave(); }
        );

        var btnCancel = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("Cancel")
            .listen("clicked", func { me._actionCancel(); }
        );

        buttonBox.addItem(me._btnTypeSelector);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnOK);
        buttonBox.addItem(btnCancel);

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._filterSelector.del();

        call(PersistentDialog.del, [], me);
    },

    #
    # Set label text.
    #
    # @param  string  label
    # @return void
    #
    _setLabel: func(label) {
        me._btnTypeSelector.setVisible(label == "Type");

        me._label.setText(label);
    },

    #
    # Set input text.
    #
    # @param  string  text
    # @return void
    #
    _setLineEdit: func(text) {
        me._lineEdit.setText(text);
    },

    #
    # @param  hash  parent  DetailsDialog object.
    # @param  int  id  Record ID in SQLite or index of whole CSV file.
    # @param  string  value  Value to edit.
    # @param  hash  columnItem  Column item from Columns class.
    # @return void
    # @override PersistentDialog
    #
    show: func(parent, id, value, columnItem) {
        me._parent     = parent;
        me._recordId   = id;
        me._value      = value;
        me._columnItem = columnItem;

        me._setLabel(me._columnItem.header);
        me._setLineEdit(me._value);
        me._lineEdit.setFocus();

        call(PersistentDialog.show, [], me);
    },

    #
    # @return void
    # @Override PersistentDialog
    #
    hide: func() {
        if (me._parent != nil) {
            # Remove highlighted row in LogbookDialog
            me._parent.getListView().removeHighlightingRow();
        }

        me._filterSelector.hide();

        call(PersistentDialog.hide, [], me);
    },

    #
    # @param  hash  style
    # @return hash
    #
    setStyle: func(style) {
        me._filterSelector.setStyle(style);
        return me;
    },

    #
    # Get FilterSelector dialog.
    #
    # @return hash  FilterSelector object.
    #
    getFilterSelector: func() {
        return me._filterSelector;
    },

    #
    # @return void
    #
    _actionTypeSelect: func() {
        me._filterSelector
            .setItems(items: AircraftType.getVector(), withDefaultAll: false)
            .setColumnName(Columns.AC_TYPE)
            .setPosition(
                getprop("/devices/status/mice/mouse/x") or 0,
                getprop("/devices/status/mice/mouse/y") or 0
            )
            .setTitle("Select aircraft type")
            .setCallback(Callback.new(me._filterSelectorCallback, me))
            .show();
    },

    #
    # @param  string  columnName
    # @param  string  value
    # @return void
    #
    _filterSelectorCallback: func(columnName, value) {
        me._lineEdit.setText(value);
    },

    #
    # Save action.
    #
    # @return void
    #
    _actionSave: func() {
        var value = me._lineEdit.text();
        if (value == nil) {
            value = "";
        }

        if (cmp(value, me._value) == 0) {
            # Nothing changed, nothing to save
            me.hide();
            gui.popupTip("Nothing has changed");
            return;
        }

        if (!me._validate(value)) {
            return;
        }

        g_Sound.play('paper');

        me.hide();

        # Set values to properties and trigger action listener
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-index", me._recordId);
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-column-name", me._columnItem.name);
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-value", value);
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry", true);
    },

    #
    # Cancel action.
    #
    # @return void
    #
    _actionCancel: func() {
        me.hide();

        # Set property redraw-details for remove selected bar
        setprop(me._addonNodePath ~ "/addon-devel/redraw-details", true);
    },

    #
    # Validate the value according to header.
    #
    # @param  string  value
    # @return bool  Return true if value is correct.
    #
    _validate: func(value) {
        if (!Utils.isUsingSQLite()) {
            for (var i = 0; i < size(value); i += 1) {
                if (   value[i] == `,`
                    or value[i] == `"` #"# <- Fix syntax coloring in Visual Code
                ) {
                    gui.popupTip("Please don't use `,` and `\"` as these are special characters for the CSV file.");
                    return false;
                }
            }
        }

        if (   me._columnItem.name == Columns.DATE
            or me._columnItem.name == Columns.SIM_UTC_DATE
            or me._columnItem.name == Columns.SIM_LOC_DATE
        ) {
            if (!me._validateDate(value)) {
                gui.popupTip("Incorrect date");
                return false;
            }
        }
        elsif (me._columnItem.name == Columns.TIME
            or me._columnItem.name == Columns.SIM_UTC_TIME
            or me._columnItem.name == Columns.SIM_LOC_TIME
        ) {
            if (!me._validateTime(value)) {
                gui.popupTip("Incorrect time");
                return false;
            }
        }
        elsif (me._columnItem.name == Columns.VARIANT) {
            if (!me._validateVariant(value)) {
                gui.popupTip("Please don't use space or dot characters");
                return false;
            }
        }
        elsif (me._columnItem.name == Columns.AC_TYPE) {
            if (!me._validateAircraftType(value)) {
                var msg = "Incorrect Aircraft Type. Allowed values are: ";
                var types = "";
                foreach (var type; AircraftType.getVector()) {
                    if (types != "") {
                        types ~= ", ";
                    }
                    types ~= type;
                }
                gui.popupTip(msg ~ types ~ ".");
                return false;
            }
        }
        elsif (me._columnItem.name == Columns.LANDING
            or me._columnItem.name == Columns.CRASH
        ) {
            if (!me._validateBoolean(value)) {
                gui.popupTip("The allowed value are 1 or 0 (or empty).");
                return false;
            }
        }
        elsif (me._columnItem.name == Columns.DAY
            or me._columnItem.name == Columns.NIGHT
            or me._columnItem.name == Columns.INSTRUMENT
            or me._columnItem.name == Columns.MULTIPLAYER
            or me._columnItem.name == Columns.SWIFT
            or me._columnItem.name == Columns.DURATION
            or me._columnItem.name == Columns.DISTANCE
            or me._columnItem.name == Columns.FUEL
            or me._columnItem.name == Columns.MAX_MACH
        ) {
            if (!me._validateDecimal(value)) {
                gui.popupTip("The allowed value is decimal number.");
                return false;
            }
        }
        elsif (me._columnItem.name == Columns.MAX_ALT
            or me._columnItem.name == Columns.MAX_GS_KT
        ) {
            if (!me._validateNumber(value)) {
                gui.popupTip("The allowed value is a number.");
                return false;
            }
        }

        return true;
    },

    #
    # @param  string  value
    # @return bool
    #
    _validateDate: func(value) {
        return string.match(value, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]");
    },

    #
    # @param  string  value
    # @return bool
    #
    _validateTime: func(value) {
        return string.match(value, "[0-9][0-9]:[0-9][0-9]");
    },

    #
    # @param  string  value
    # @return bool
    #
    _validateVariant: func(value) {
        for (var i = 0; i < size(value); i += 1) {
            if (   value[i] == `.`
                or value[i] == ` `
            ) {
                return false;
            }
        }

        return true;
    },

    #
    # @param  string  value
    # @return bool
    #
    _validateAircraftType: func(value) {
        foreach (var type; AircraftType.getVector()) {
            if (type == value) {
                return true;
            }
        }

        return false;
    },

    #
    # @param  string  value
    # @return bool
    #
    _validateBoolean: func(value) {
        return value == "1"
            or value == "0"
            or value == "";
    },

    #
    # @param  string  value
    # @return bool
    #
    _validateDecimal: func(value) {
        var length = size(value);
        if (length == 0) {
            return false;
        }

        for (var i = 0; i < length; i += 1) {
            if (!string.isdigit(value[i]) and value[i] != `.`) {
                return false;
            }
        }

        return true;
    },

    #
    # @param  string  value
    # @return bool
    #
    _validateNumber: func(value) {
        var length = size(value);
        if (length == 0) {
            return false;
        }

        for (var i = 0; i < length; i += 1) {
            if (!string.isdigit(value[i])) {
                return false;
            }
        }

        return true;
    },
};
