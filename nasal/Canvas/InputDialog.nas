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
    # @param hash settings - Settings object
    # @return me
    #
    new: func(settings) {
        var me = { parents: [
            InputDialog,
            Dialog.new(settings, InputDialog.WINDOW_WIDTH, InputDialog.WINDOW_HEIGHT, "Change value")
        ] };

        # Override window del method for close FilterSelector
        var self = me;
        me.window.del = func() {
            call(InputDialog.hide, [], self);
        };

        me.bgImage.hide();

        me.addonNodePath = me.addon.node.getPath();

        me.allDataIndex    = nil; # index of log entry in whole CSV file
        me.header          = nil; # header name
        me.parent          = nil;
        me.value           = nil;

        me.filterSelector = FilterSelector.new(settings);

        var MARGIN = 12;
        me.vbox.setContentsMargin(MARGIN);

        me.label = canvas.gui.widgets.Label.new(me.group, canvas.style, {wordWrap: 1});
        me.vbox.addItem(me.label);

        me.lineEdit = canvas.gui.widgets.LineEdit.new(me.group, canvas.style, {});
        me.vbox.addItem(me.lineEdit);
        me.lineEdit.setFocus();

        var buttonBox = canvas.HBoxLayout.new();
        me.vbox.addItem(buttonBox);

        me.btnTypeSelector = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Select")
            .listen("clicked", func { me.actionTypeSelect(); }
        );
        me.btnTypeSelector.setVisible(false);

        var btnOK = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Save")
            .listen("clicked", func { me.actionSave(); }
        );

        var btnCancel = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Cancel")
            .listen("clicked", func { me.actionCancel(); }
        );

        buttonBox.addItem(me.btnTypeSelector);
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
        me.filterSelector.del();
        call(Dialog.del, [], me);
    },

    #
    # Set label text
    #
    # @param string label
    # @return void
    #
    setLabel: func(label) {
        me.btnTypeSelector.setVisible(label == "Type");

        me.label.setText(label);
    },

    #
    # Set input text
    #
    # @param string text
    # @return void
    #
    setLineEdit: func(text) {
        me.lineEdit.setText(text);
    },

    #
    # @param hash parent
    # @param int allDataIndex
    # @param string label as a Header text
    # @param string value to edit
    # @return void
    #
    show: func(parent, allDataIndex, label, value) {
        me.parent       = parent;
        me.allDataIndex = allDataIndex;
        me.header       = label;
        me.value        = value;

        me.setLabel(me.header);
        me.setLineEdit(sprintf("%s", value));
        me.lineEdit.setFocus();
        call(Dialog.show, [], me);
    },

    #
    # @return void
    #
    hide: func() {
        if (me.parent != nil) {
            # Remove highlighted row in LogbookDialog
            me.parent.listView.removeHighlightingRow();
        }

        me.filterSelector.hide();
        call(Dialog.hide, [], me);
    },

    #
    # @param hash style
    # @return me
    #
    setStyle: func(style) {
        me.filterSelector.setStyle(style);
        return me;
    },

    #
    # @return void
    #
    actionTypeSelect: func() {
        me.filterSelector
            .setItems(AircraftType.getVector(), false)
            .setColumnIndex(File.INDEX_TYPE)
            .setPosition(
                getprop("/devices/status/mice/mouse/x") or 0,
                getprop("/devices/status/mice/mouse/y") or 0
            )
            .setTitle("Select aircraft type")
            .setCallback(me, me.filterSelectorCallback)
            .show();
    },

    #
    # @param int filterId
    # @param string value
    # @return void
    #
    filterSelectorCallback: func(filterId, value) {
        me.lineEdit.setText(value);
    },

    #
    # Save action
    #
    # @return void
    #
    actionSave: func() {
        var value = me.lineEdit.text();
        if (value == nil) {
            value = "";
        }

        if (cmp(value, me.value) == 0) {
            # Nothing changed, nothing to save
            me.hide();
            gui.popupTip("Nothing has changed");
            return;
        }

        if (!me.validate(value)) {
            return;
        }

        me.hide();

        # Set values to properties and trigger action listener
        setprop(me.addonNodePath ~ "/addon-devel/action-edit-entry-index", me.allDataIndex);
        setprop(me.addonNodePath ~ "/addon-devel/action-edit-entry-header", me.header);
        setprop(me.addonNodePath ~ "/addon-devel/action-edit-entry-value", value);
        setprop(me.addonNodePath ~ "/addon-devel/action-edit-entry", true);
    },

    #
    # Cancel action
    #
    # @return void
    #
    actionCancel: func() {
        me.hide();

        # Set property redraw-details for remove selected bar
        setprop(me.addonNodePath ~ "/addon-devel/redraw-details", true);
    },

    #
    # Validate the value according to header
    #
    # @param string value
    # @return bool - Return true if value is correct
    #
    validate: func(value) {
        for (var i = 0; i < size(value); i += 1) {
            if (value[i] == `,` or value[i] == `"`) { #"# <- Fix syntax coloring in Visual Code
                gui.popupTip("Please don't use `,` and `\"` as these are special characters for the CSV file.");
                return false;
            }
        }

        if (me.header == "Date") {
            if (!me.validateDate(value)) {
                gui.popupTip("Incorrect date");
                return false;
            }
        }
        else if (me.header == "Time") {
            if (!me.validateTime(value)) {
                gui.popupTip("Incorrect time");
                return false;
            }
        }
        else if (me.header == "Variant") {
            if (!me.validateVariant(value)) {
                gui.popupTip("Please don't use space or dot characters");
                return false;
            }
        }
        else if (me.header == "Type") {
            if (!me.validateAircraftType(value)) {
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
        else if (me.header == "Landings") {
            if (!me.validateDigit(value)) {
                gui.popupTip("The allowed value is a digit.");
                return false;
            }
        }
        else if (me.header == "Crash") {
            if (!me.validateCrash(value)) {
                gui.popupTip("The allowed value are 1 or 0 (or empty).");
                return false;
            }
        }
        else if (me.header == "Day" or
                 me.header == "Night" or
                 me.header == "Instrument" or
                 me.header == "Duration" or
                 me.header == "Distance" or
                 me.header == "Fuel"
        ) {
            if (!me.validateDecimal(value)) {
                gui.popupTip("The allowed value is decimal number.");
                return false;
            }
        }
        else if (me.header == "Max Alt") {
            if (!me.validateNumber(value)) {
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
    validateDate: func(value) {
        return string.match(value, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]");
    },

    #
    # @param string value
    # @return bool
    #
    validateTime: func(value) {
        return string.match(value, "[0-9][0-9]:[0-9][0-9]");
    },

    #
    # @param string value
    # @return bool
    #
    validateVariant: func(value) {
        for (var i = 0; i < size(value); i += 1) {
            if (value[i] == `.` or value[i] == ` `) {
                return false;
            }
        }

        return true;
    },

    #
    # @param string value
    # @return bool
    #
    validateAircraftType: func(value) {
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
    validateDigit: func(value) {
        return string.match(value, "[0-9]");
    },

    #
    # @param string value
    # @return bool
    #
    validateCrash: func(value) {
        return value == "1" or value == "0" or value == "";
    },

    #
    # @param string value
    # @return bool
    #
    validateDecimal: func(value) {
        for (var i = 0; i < size(value); i += 1) {
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
    validateNumber: func(value) {
        for (var i = 0; i < size(value); i += 1) {
            if (!string.isdigit(value[i])) {
                return false;
            }
        }

        return true;
    },
};
