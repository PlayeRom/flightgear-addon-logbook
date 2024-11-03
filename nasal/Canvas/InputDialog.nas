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
# InputDialog class
#
var InputDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 400,
    WINDOW_HEIGHT : 120,

    #
    # Constructor
    #
    # @param  hash  columns  Columns object
    # @return me
    #
    new: func(columns) {
        var me = { parents: [
            InputDialog,
            Dialog.new(InputDialog.WINDOW_WIDTH, InputDialog.WINDOW_HEIGHT, "Change value")
        ] };

        # Override window del method for close FilterSelector
        var self = me;
        me.window.del = func() {
            call(InputDialog.hide, [], self);
        };

        me.bgImage.hide();

        me._addonNodePath = g_Addon.node.getPath();

        me._allDataIndex    = nil; # index of log entry in whole CSV file
        me._header          = nil; # header name
        me._parent          = nil; # DetailsDialog
        me._value           = nil;

        me._filterSelector = FilterSelector.new(columns);

        var MARGIN = 12;
        me.vbox.setContentsMargin(MARGIN);

        me._label = canvas.gui.widgets.Label.new(me.group, canvas.style, {wordWrap: 1});
        me.vbox.addItem(me._label);

        me._lineEdit = canvas.gui.widgets.LineEdit.new(me.group, canvas.style, {});
        me.vbox.addItem(me._lineEdit);
        me._lineEdit.setFocus();

        var buttonBox = canvas.HBoxLayout.new();
        me.vbox.addItem(buttonBox);

        me._btnTypeSelector = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Select")
            .listen("clicked", func { me._actionTypeSelect(); }
        );
        me._btnTypeSelector.setVisible(false);

        var btnOK = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Save")
            .listen("clicked", func { me._actionSave(); }
        );

        var btnCancel = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Cancel")
            .listen("clicked", func { me._actionCancel(); }
        );

        buttonBox.addItem(me._btnTypeSelector);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnOK);
        buttonBox.addItem(btnCancel);

        me.setPositionOnCenter();
        me.window.hide();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._filterSelector.del();
        call(Dialog.del, [], me);
    },

    #
    # Set label text
    #
    # @param string label
    # @return void
    #
    _setLabel: func(label) {
        me._btnTypeSelector.setVisible(label == "Type");

        me._label.setText(label);
    },

    #
    # Set input text
    #
    # @param string text
    # @return void
    #
    _setLineEdit: func(text) {
        me._lineEdit.setText(text);
    },

    #
    # @param  hash  parent  DetailsDialog object
    # @param  int  allDataIndex
    # @param  string  label  Header text
    # @param  string  value  Value to edit
    # @return void
    #
    show: func(parent, allDataIndex, label, value) {
        me._parent       = parent;
        me._allDataIndex = allDataIndex;
        me._header       = label;
        me._value        = value;

        me._setLabel(me._header);
        me._setLineEdit(sprintf("%s", value));
        me._lineEdit.setFocus();

        call(Dialog.show, [], me);
    },

    #
    # @return void
    #
    hide: func() {
        if (me._parent != nil) {
            # Remove highlighted row in LogbookDialog
            me._parent.getListView().removeHighlightingRow();
        }

        me._filterSelector.hide();
        call(Dialog.hide, [], me);
    },

    #
    # @param hash style
    # @return me
    #
    setStyle: func(style) {
        me._filterSelector.setStyle(style);
        return me;
    },

    #
    # Get FilterSelector dialog
    #
    # @return hash  FilterSelector object
    #
    getFilterSelector: func() {
        return me._filterSelector;
    },

    #
    # @return void
    #
    _actionTypeSelect: func() {
        me._filterSelector
            .setItems(AircraftType.getVector(), false)
            .setColumnIndex(StorageCsv.INDEX_TYPE)
            .setPosition(
                getprop("/devices/status/mice/mouse/x") or 0,
                getprop("/devices/status/mice/mouse/y") or 0
            )
            .setTitle("Select aircraft type")
            .setCallback(me, me._filterSelectorCallback)
            .show();
    },

    #
    # @param  int  filterId
    # @param  string  dbColumnName
    # @param  string  value
    # @return void
    #
    _filterSelectorCallback: func(filterId, dbColumnName, value) {
        me._lineEdit.setText(value);
    },

    #
    # Save action
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
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-index", me._allDataIndex);
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-header", me._header);
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-value", value);
        setprop(me._addonNodePath ~ "/addon-devel/action-edit-entry", true);
    },

    #
    # Cancel action
    #
    # @return void
    #
    _actionCancel: func() {
        me.hide();

        # Set property redraw-details for remove selected bar
        setprop(me._addonNodePath ~ "/addon-devel/redraw-details", true);
    },

    #
    # Validate the value according to header
    #
    # @param string value
    # @return bool - Return true if value is correct
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

        if (me._header == "Date") {
            if (!me._validateDate(value)) {
                gui.popupTip("Incorrect date");
                return false;
            }
        }
        else if (me._header == "Time") {
            if (!me._validateTime(value)) {
                gui.popupTip("Incorrect time");
                return false;
            }
        }
        else if (me._header == "Variant") {
            if (!me._validateVariant(value)) {
                gui.popupTip("Please don't use space or dot characters");
                return false;
            }
        }
        else if (me._header == "Type") {
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
        else if (  me._header == "Landing"
                or me._header == "Crash"
        ) {
            if (!me._validateBoolean(value)) {
                gui.popupTip("The allowed value are 1 or 0 (or empty).");
                return false;
            }
        }
        else if (   me._header == "Day"
                 or me._header == "Night"
                 or me._header == "Instrument"
                 or me._header == "Multiplayer"
                 or me._header == "Swift"
                 or me._header == "Duration"
                 or me._header == "Distance"
                 or me._header == "Fuel"
        ) {
            if (!me._validateDecimal(value)) {
                gui.popupTip("The allowed value is decimal number.");
                return false;
            }
        }
        else if (me._header == "Max Alt") {
            if (!me._validateNumber(value)) {
                gui.popupTip("The allowed value is a number.");
                return false;
            }
        }

        return true;
    },

    #
    # @param string value
    # @return bool
    #
    _validateDate: func(value) {
        return string.match(value, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]");
    },

    #
    # @param string value
    # @return bool
    #
    _validateTime: func(value) {
        return string.match(value, "[0-9][0-9]:[0-9][0-9]");
    },

    #
    # @param string value
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
    # @param string value
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
    # @param string value
    # @return bool
    #
    _validateBoolean: func(value) {
        return value == "1"
            or value == "0"
            or value == "";
    },

    #
    # @param string value
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
    # @param string value
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
