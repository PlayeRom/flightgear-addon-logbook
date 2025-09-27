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
# AboutDialog class to display about info
#
var AboutDialog = {
    CLASS: "AboutDialog",

    #
    # Constants
    #
    WINDOW_WIDTH  : 280,
    WINDOW_HEIGHT : 400,
    PADDING       : 10,

    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [
            AboutDialog,
            Dialog.new(AboutDialog.WINDOW_WIDTH, AboutDialog.WINDOW_HEIGHT, "Logbook About"),
        ] };

        var dialogParent = me.parents[1];
        dialogParent.setChild(me, AboutDialog); # Let the parent know who their child is.
        dialogParent.setPositionOnCenter();

        me.bgImage.hide();

        me._vbox.addSpacing(AboutDialog.PADDING);
        me._drawContent();

        var buttonBoxClose = me._drawBottomBar("Close", func { me.hide(); });
        me._vbox.addSpacing(AboutDialog.PADDING);
        me._vbox.addItem(buttonBoxClose);
        me._vbox.addSpacing(AboutDialog.PADDING);

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
    # Draw content.
    #
    # @return void
    #
    _drawContent: func() {
        me._vbox.addItem(me._getLabel(g_Addon.name));
        me._vbox.addItem(me._getLabel(sprintf("version %s", g_Addon.version.str())));
        me._vbox.addItem(me._getLabel("July 27, 2025"));

        me._vbox.addStretch(1);
        me._vbox.addItem(me._getLabel("Written by:"));

        foreach (var author; g_Addon.authors) {
            me._vbox.addItem(me._getLabel(Utils.toString(author.name)));
        }

        me._vbox.addStretch(1);
        # TODO: Unfortunately, it seems that FG incorrectly handles wordWrap for widgets.Label, artificially narrowing
        # the Label's width so it doesn't adhere to the available window width. Therefore, I don't use wordWrap and
        # manually break the text using the \n character.
        me._vbox.addItem(me._getLabel("This add-on uses © OpenStreetMap and OpenTopoMap to draw the map.", true));

        me._vbox.addStretch(1);

        me._vbox.addItem(me._getButton("FlightGear Wiki", func {
            Utils.openBrowser({ "url": g_Addon.homePage });
        }));

        me._vbox.addItem(me._getButton("GitHub Website", func {
            Utils.openBrowser({ "url": g_Addon.codeRepositoryUrl });
        }));

        me._vbox.addItem(me._getButton("Open Storage Folder", func {
            Utils.openBrowser({ "path": g_Addon.storagePath });
        }));

        me._vbox.addStretch(1);
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = 0) {
        var label = canvas.gui.widgets.Label.new(me._group, canvas.style, { wordWrap: wordWrap })
            .setText(text);

        if (Utils.isFG2024Version()) {
            label.setTextAlign("center");
        }

        return label;
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText(text)
            .setFixedSize(200, 26)
            .listen("clicked", callback);
    },

    #
    # @param  string  label  Label of button
    # @param  func  callback  function which will be executed after click the button
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func(label, callback) {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText(label)
            .setFixedSize(75, 26)
            .listen("clicked", callback);

        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        return buttonBox;
    },
};
