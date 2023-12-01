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
    WINDOW_WIDTH  : 320,
    WINDOW_HEIGHT : 180,
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
            right  : 0,
            bottom : 0,
        };
        me.scrollData = me.createScrollArea(nil, margins);

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent(me.scrollData);

        me.drawScrollable();

        var buttonBoxClose = me.drawBottomBar("Close", func() { me.window.hide(); });
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
    drawScrollable: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        vBoxLayout.addItem(me.getLabel(
            sprintf(
                "%s version %s - December 1, 2023",
                me.addon.name,
                me.addon.version.str()
            )
        ));

        vBoxLayout.addItem(me.getLabel("Written by:"));

        foreach (var author; me.addon.authors) {
            vBoxLayout.addItem(me.getLabel(sprintf("%s", author.name)));
        }

        var btnRepo = canvas.gui.widgets.Button.new(me.scrollDataContent, canvas.style, {})
            .setText("Open the repository website...")
            .setFixedSize(200, 26)
            .listen("clicked", func {
                fgcommand("open-browser", props.Node.new({"url" : me.addon.codeRepositoryUrl}));
            });

        vBoxLayout.addItem(btnRepo);

        me.scrollData.setLayout(vBoxLayout);
    },

    #
    # @param string text - Label text
    # @return hash - Label widget
    #
    getLabel: func(text) {
        return canvas.gui.widgets.Label.new(me.scrollDataContent, canvas.style, {})
            .setText(text);
    },

    #
    # @param string label - Label of button
    # @param func callback - function which will be executed after click the button
    # @return hash - HBoxLayout object with button
    #
    drawBottomBar: func(label, callback) {
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
