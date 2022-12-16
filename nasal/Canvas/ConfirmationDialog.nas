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
# ConfirmationDialog class
#
var ConfirmationDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 300,
    WINDOW_HEIGHT : 80,

    #
    # Constructor
    #
    # hash file - File object
    # string title
    # return me
    #
    new: func(file, title) {
        var me = { parents: [
            ConfirmationDialog,
            Dialog.new(Dialog.ID_DELETE, ConfirmationDialog.WINDOW_WIDTH, ConfirmationDialog.WINDOW_HEIGHT, title)
        ] };

        me.bgImage.hide();

        me.file     = file;
        me.logIndex = nil;

        var MARGIN = 12;
        me.vbox.setContentsMargin(MARGIN);

        me.label = canvas.gui.widgets.Label.new(me.group, canvas.style, {wordWrap: 1});
        me.vbox.addItem(me.label);

        var buttonBox = canvas.HBoxLayout.new();
        me.vbox.addItem(buttonBox);

        buttonBox.addStretch(1);
        var btnOK = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Delete")
            .listen("clicked", func { me.actionPositive(); }
        );

        var btnCancel = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Cancel")
            .listen("clicked", func { me.actionNegative(); }
        );

        buttonBox.addItem(btnOK);
        buttonBox.addItem(btnCancel);

        me.setPositionOnCenter(ConfirmationDialog.WINDOW_WIDTH, ConfirmationDialog.WINDOW_HEIGHT);
        me.window.hide();

        return me;
    },

    #
    # Destructor
    #
    # return void
    #
    del: func() {
        call(Dialog.del, [], me);
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
    # int logIndex
    # return void
    #
    show: func(logIndex) {
        me.logIndex = logIndex;

        call(Dialog.show, [], me);
    },

    #
    # Positive button action
    #
    # return void
    #
    actionPositive: func() {
        me.window.hide();

        if (me.file.deleteLog(me.logIndex)) {
            gui.popupTip("The log has been deleted!");

            setprop(me.addon.node.getPath() ~ "/addon-devel/logbook-entry-deleted", true);
            setprop(me.addon.node.getPath() ~ "/addon-devel/reload-logbook", true);
        }
    },

    #
    # Negative button action
    #
    # return void
    #
    actionNegative: func() {
        me.window.hide();
    },
};
