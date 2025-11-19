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
# ConfirmationDialog class.
#
var ConfirmationDialog = {
    CLASS: "ConfirmationDialog",

    #
    # Constructor.
    #
    # @param  string  title
    # @return hash
    #
    new: func(title) {
        var obj = {
            parents: [
                ConfirmationDialog,
                PersistentDialog.new(
                    width: 300,
                    height: 80,
                    title: title,
                ),
            ],
        };

        call(PersistentDialog.setChild, [obj, ConfirmationDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._widget = WidgetHelper.new(obj._group);

        obj._logIndex      = nil;
        obj._parentObj     = nil;
        obj._addonNodePath = g_Addon.node.getPath();

        var MARGIN = 12;
        obj._vbox.setContentsMargin(MARGIN);

        obj._label = obj._widget.getLabel("", true);

        var btnOK     = obj._widget.getButton("Delete", func obj._actionPositive());
        var btnCancel = obj._widget.getButton("Cancel", func obj._actionNegative());

        var buttonBox = canvas.HBoxLayout.new();
        buttonBox.addStretch(1);
        buttonBox.addItem(btnOK);
        buttonBox.addItem(btnCancel);

        obj._vbox.addItem(obj._label);
        obj._vbox.addItem(buttonBox);

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func {
        call(PersistentDialog.del, [], me);
    },

    #
    # Set label text.
    #
    # @param  string  label
    # @return void
    #
    setLabel: func(label) {
        me._label.setText(label);
    },

    #
    # @param  int logIndex
    # @param  hash|nil  parentObj  Dialog parent class.
    # @return void
    # @override PersistentDialog
    #
    show: func(logIndex, parentObj = nil) {
        me._logIndex = logIndex;
        me._parentObj = parentObj;

        call(PersistentDialog.show, [], me);
    },

    #
    # Positive button action.
    #
    # @return void
    #
    _actionPositive: func {
        g_Sound.play('delete');

        if (me._parentObj == nil) {
            call(PersistentDialog.hide, [], me);
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
    # Negative button action.
    #
    # @return void
    #
    _actionNegative: func {
        call(PersistentDialog.hide, [], me);
    },
};
