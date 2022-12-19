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
    # hash settings - Settings object
    # string title
    # return me
    #
    new: func(settings, title) {
        var me = { parents: [
            ConfirmationDialog,
            Dialog.new(
                settings,
                Dialog.ID_DELETE,
                ConfirmationDialog.WINDOW_WIDTH,
                ConfirmationDialog.WINDOW_HEIGHT,
                title
            )
        ] };

        me.bgImage.hide();

        me.logIndex      = nil;
        me.parentObj     = nil;
        me.addonNodePath = me.addon.node.getPath();

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
    # hash|nill parentObj - Dialog parent class
    # return void
    #
    show: func(logIndex, parentObj = nil) {
        me.logIndex = logIndex;
        me.parentObj = parentObj;

        call(Dialog.show, [], me);
    },

    #
    # Positive button action
    #
    # return void
    #
    actionPositive: func() {
        if (me.parentObj == nil) {
            call(Dialog.hide, [], me);
        }
        else {
            # Also hide immediately the parent window that called ConfirmationDialog.
            # In our case, it will be DetailsDialog.
            call(me.parentObj.hide, [], me.parentObj);
        }

        # Set index to properties and trigger action listener
        setprop(me.addonNodePath ~ "/addon-devel/action-delete-entry-index", me.logIndex);
        setprop(me.addonNodePath ~ "/addon-devel/action-delete-entry", true);
    },

    #
    # Negative button action
    #
    # return void
    #
    actionNegative: func() {
        call(Dialog.hide, [], me);
    },
};
