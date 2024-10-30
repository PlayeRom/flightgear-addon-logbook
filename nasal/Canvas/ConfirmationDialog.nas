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
    # @param string title
    # @return me
    #
    new: func(title) {
        var me = { parents: [
            ConfirmationDialog,
            Dialog.new(
                ConfirmationDialog.WINDOW_WIDTH,
                ConfirmationDialog.WINDOW_HEIGHT,
                title
            )
        ] };

        me.bgImage.hide();

        me._logIndex      = nil;
        me._parentObj     = nil;
        me._addonNodePath = g_Addon.node.getPath();

        var MARGIN = 12;
        me.vbox.setContentsMargin(MARGIN);

        me._label = canvas.gui.widgets.Label.new(me.group, canvas.style, {wordWrap: 1});
        me.vbox.addItem(me._label);

        var buttonBox = canvas.HBoxLayout.new();
        me.vbox.addItem(buttonBox);

        buttonBox.addStretch(1);
        var btnOK = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Delete")
            .listen("clicked", func { me._actionPositive(); }
        );

        var btnCancel = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Cancel")
            .listen("clicked", func { me._actionNegative(); }
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
    # @return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Set label text
    #
    # @param string label
    # @return void
    #
    setLabel: func(label) {
        me._label.setText(label);
    },

    #
    # @param int logIndex
    # @param hash|nil parentObj - Dialog parent class
    # @return void
    #
    show: func(logIndex, parentObj = nil) {
        me._logIndex = logIndex;
        me._parentObj = parentObj;

        call(Dialog.show, [], me);
    },

    #
    # Positive button action
    #
    # @return void
    #
    _actionPositive: func() {
        g_Sound.play('delete');

        if (me._parentObj == nil) {
            call(Dialog.hide, [], me);
        }
        else {
            # Also hide immediately the parent window that called ConfirmationDialog.
            # In our case, it will be DetailsDialog.
            call(me._parentObj.hide, [], me._parentObj);
        }

        # Set index to properties and trigger action listener
        setprop(me._addonNodePath ~ "/addon-devel/action-delete-entry-index", me._logIndex);
        setprop(me._addonNodePath ~ "/addon-devel/action-delete-entry", true);
    },

    #
    # Negative button action
    #
    # @return void
    #
    _actionNegative: func() {
        call(Dialog.hide, [], me);
    },
};
