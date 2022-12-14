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
    # hash file - File object
    # return me
    #
    new: func(file) {
        var me = { parents: [
            InputDialog,
            Dialog.new(InputDialog.WINDOW_WIDTH, InputDialog.WINDOW_HEIGHT, "Change value")
        ] };

        me.file           = file;
        me.rowIndexToEdit = nil;
        me.header         = nil;

        var MARGIN = 12;
        me.vbox.setContentsMargin(MARGIN);

        me.label = canvas.gui.widgets.Label.new(me.group, canvas.style, {wordWrap: 1});
        me.vbox.addItem(me.label);

        me.lineEdit = canvas.gui.widgets.LineEdit.new(me.group, canvas.style, {});
        me.vbox.addItem(me.lineEdit);
        me.lineEdit.setFocus();

        var buttonBox = canvas.HBoxLayout.new();
        me.vbox.addItem(buttonBox);

        buttonBox.addStretch(1);
        var btnOK = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Save")
            .listen("clicked", func { me.actionSave(); }
        );

        var btnCancel = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Cancel")
            .listen("clicked", func { me.actionCancel(); }
        );

        buttonBox.addItem(btnOK);
        buttonBox.addItem(btnCancel);

        me.setPositionOnCenter(InputDialog.WINDOW_WIDTH, InputDialog.WINDOW_HEIGHT);
        me.window.hide();

        return me;
    },

    #
    # Destructor
    #
    del: func() {
        me.parents[1].del();
    },

    #
    # Set label text
    #
    # string label
    # return void
    #
    setLabel: func(label) {
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
    #   data[0] - index of row in CSV file
    #   data[1] - label text (header)
    #   data[2] - text to edit
    # return void
    #
    show: func(data) {
        me.rowIndexToEdit = data[0];
        me.header = data[1];

        me.label.setText(data[1]);
        me.lineEdit.setText(data[2]);
        me.lineEdit.setFocus();
        me.parents[1].show();
    },

    #
    # Save action
    #
    actionSave: func() {
        var value = me.lineEdit.text();
        if (value == nil) {
            value = "";
        }

        if (!me.validate(value)) {
            return;
        }

        me.window.hide();

        if (me.file.editData(me.rowIndexToEdit, me.header, value)) {
            gui.popupTip("The change has been saved!");
        }
    },

    #
    # Cancel action
    #
    actionCancel: func() {
        me.window.hide();
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
    validateDigit: func(value) {
        return string.match(value, "[0-9]");
    },

    #
    # string value
    # return bool
    #
    validateCrash: func(value) {
        if (value == "1" or value == "0" or value == "") {
            return true;
        }

        return false;
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
