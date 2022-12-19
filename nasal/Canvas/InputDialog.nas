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
    # hash settings - Settings object
    # return me
    #
    new: func(settings) {
        var me = { parents: [
            InputDialog,
            Dialog.new(settings, Dialog.ID_INPUT, InputDialog.WINDOW_WIDTH, InputDialog.WINDOW_HEIGHT, "Change value")
        ] };

        # Override window del method for close FilterSelector
        var self = me;
        me.window.del = func() {
            call(InputDialog.hide, [], self);
        };

        me.bgImage.hide();

        me.addonNodePath = me.addon.node.getPath();

        me.allDataIndex    = nil; # index of log entry in whole CSV file
        me.parentDataIndex = nil; # index of column in single row
        me.header          = nil; # header name

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
    # return void
    #
    del: func() {
        me.filterSelector.del();
        call(Dialog.del, [], me);
    },

    #
    # Set label text
    #
    # string label
    # return void
    #
    setLabel: func(label) {
        me.btnTypeSelector.setVisible(label == "Type");

        me.label.setText(label);
    },

    #
    # Set input text
    #
    # string text
    # return void
    #
    setLineEdit: func(text) {
        me.lineEdit.setText(text);
    },

    #
    # vector data
    #   data[0] - index of header
    #   data[1] - index of row in CSV file
    #   data[2] - label text (header)
    #   data[3] - text to edit
    # return void
    #
    show: func(data) {
        me.parentDataIndex = data[0];
        me.allDataIndex    = data[1];
        me.header          = data[2];

        me.setLabel(data[2]);
        me.setLineEdit(sprintf("%s", data[3]));
        me.lineEdit.setFocus();
        call(Dialog.show, [], me);
    },

    #
    # return void
    #
    hide: func() {
        me.filterSelector.hide();
        call(Dialog.hide, [], me);
    },

    #
    # return void
    #
    actionTypeSelect: func() {
        me.filterSelector.setItems(AircraftType.getVector(), false);
        me.filterSelector.setColumnIndex(File.INDEX_TYPE);
        me.filterSelector.setPosition(
            getprop("/devices/status/mice/mouse/x") or 0,
            getprop("/devices/status/mice/mouse/y") or 0
        );
        me.filterSelector.setTitle("Aircraft type filter");
        me.filterSelector.setCallback(me, me.filterSelectorCallback);
        me.filterSelector.show();
    },

    #
    # int filterId
    # string value
    # return void
    #
    filterSelectorCallback: func(filterId, value) {
        me.lineEdit.setText(value);
    },

    #
    # Save action
    #
    # return void
    #
    actionSave: func() {
        var value = me.lineEdit.text();
        if (value == nil) {
            value = "";
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
    # return void
    #
    actionCancel: func() {
        me.hide();

        # Set property redraw-details for remove selected bar
        setprop(me.addonNodePath ~ "/addon-devel/redraw-details", true);
    },

    #
    # Validate the value according to header
    #
    # return bool - Return true if value is correct
    #
    validate: func(value) {
        for (var i = 0; i < size(value); i += 1) {
            if (value[i] == `,` or value[i] == `"`) {
                gui.popupTip("Please do not use `,` and `\"` as these are special characters for the CSV file.");
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
        else if (me.header == "Aircraft") {
            if (!me.validateAircraft(value)) {
                gui.popupTip("Incorrect Aircraft ID");
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
    # string value
    # return bool
    #
    validateDate: func(value) {
        return string.match(value, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]");
    },

    #
    # string value
    # return bool
    #
    validateTime: func(value) {
        return string.match(value, "[0-9][0-9]:[0-9][0-9]");
    },

    #
    # string value
    # return bool
    #
    validateAircraft: func(value) {
        for (var i = 0; i < size(value); i += 1) {
            if (value[i] == `.` or value[i] == ` `) {
                return false;
            }
        }

        return true;
    },

    #
    # string value
    # return bool
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
    # string value
    # return bool
    #
    validateDigit: func(value) {
        return string.match(value, "[0-9]");
    },

    #
    # string value
    # return bool
    #
    validateCrash: func(value) {
        return value == "1" or value == "0" or value == "";
    },

    #
    # string value
    # return bool
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
    # string value
    # return bool
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
