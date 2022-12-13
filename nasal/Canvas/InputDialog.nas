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
            gui.popupTip("Please do not use `,` and `\"` as these are special characters for the CSV file.");
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

    validate: func(value) {
        for (var i = 0; i < size(value); i += 1) {
            if (value[i] == `,` or value[i] == `"`) {
                return false;
            }
        }

        return true;
    },
};
