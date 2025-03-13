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
    #
    # Constants
    #
    WINDOW_WIDTH  : 280,
    WINDOW_HEIGHT : 350,
    PADDING       : 10,

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [
            AboutDialog,
            Dialog.new(AboutDialog.WINDOW_WIDTH, AboutDialog.WINDOW_HEIGHT, "Logbook About"),
        ] };

        me.bgImage.hide();

        me.setPositionOnCenter();

        var margins = {
            left   : AboutDialog.PADDING,
            top    : AboutDialog.PADDING,
            right  : AboutDialog.PADDING,
            bottom : 0,
        };
        me._scrollData = me.createScrollArea(margins: margins);

        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch

        me._scrollDataContent = me.getScrollAreaContent(me._scrollData);

        me._drawScrollable();

        var buttonBoxClose = me._drawBottomBar("Close", func() { me.window.hide(); });
        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBoxClose);
        me.vbox.addSpacing(10);

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
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        vBoxLayout.addItem(me._getLabel(g_Addon.name));
        vBoxLayout.addItem(me._getLabel(sprintf("version %s", g_Addon.version.str())));
        vBoxLayout.addItem(me._getLabel("March 13, 2025"));
        vBoxLayout.addStretch(1);
        vBoxLayout.addItem(me._getLabel("Written by:"));

        foreach (var author; g_Addon.authors) {
            vBoxLayout.addItem(me._getLabel(Utils.toString(author.name)));
        }

        vBoxLayout.addStretch(1);
        vBoxLayout.addItem(me._getLabel("This add-on uses © OpenStreetMap and OpenTopoMap to draw the map."));

        var btnWiki = canvas.gui.widgets.Button.new(me._scrollDataContent, canvas.style, {})
            .setText("FlightGear wiki...")
            .setFixedSize(200, 26)
            .listen("clicked", func {
                fgcommand("open-browser", props.Node.new({ "url": g_Addon.homePage }));
            });

        var btnRepo = canvas.gui.widgets.Button.new(me._scrollDataContent, canvas.style, {})
            .setText("GitHub website...")
            .setFixedSize(200, 26)
            .listen("clicked", func {
                fgcommand("open-browser", props.Node.new({ "url": g_Addon.codeRepositoryUrl }));
            });

        var btnAddonDir = canvas.gui.widgets.Button.new(me._scrollDataContent, canvas.style, {})
            .setText("Local storage directory...")
            .setFixedSize(200, 26)
            .listen("clicked", func {
                fgcommand("open-browser", props.Node.new({ "path": g_Addon.storagePath }));
            });

        vBoxLayout.addStretch(1);
        vBoxLayout.addItem(btnWiki);
        vBoxLayout.addItem(btnRepo);
        vBoxLayout.addItem(btnAddonDir);

        me._scrollData.setLayout(vBoxLayout);
    },

    #
    # @param  string  text  Label text
    # @return ghost  Label widget
    #
    _getLabel: func(text) {
        var label = canvas.gui.widgets.Label.new(me._scrollDataContent, canvas.style, {wordWrap: true})
            .setText(text);

        if (Utils.isFG2024Version()) {
            label.setTextAlign("center");
        }

        return label;
    },

    #
    # @param  string  label  Label of button
    # @param  func  callback  function which will be executed after click the button
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func(label, callback) {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(label)
            .setFixedSize(75, 26)
            .listen("clicked", callback);

        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        return buttonBox;
    },
};
