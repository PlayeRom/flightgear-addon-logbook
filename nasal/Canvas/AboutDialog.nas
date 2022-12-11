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
    WINDOW_WIDTH         : 320,
    WINDOW_HEIGHT        : 180,
    PADDING              : 10,

    #
    # Constructor
    #
    # hash addon - addons.Addon object
    #
    new: func(addon) {
        var me = { parents: [AboutDialog] };

        me.addon = addon;

        me.window = me.createCanvasWindow();
        me.canvas = me.window.createCanvas().set("background", canvas.style.getColor("bg_color"));
        me.group  = me.canvas.createGroup();

        me.vbox   = canvas.VBoxLayout.new();
        me.canvas.setLayout(me.vbox);

        me.scrollData = me.createScrollArea();

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent();

        var aboutText = me.drawScrollable();

        # var buttonBoxRepo = me.drawBottomBar("Open the repository website...", func() {
        #     fgcommand("open-browser", props.Node.new({"url" : addon.codeRepositoryUrl}));
        # });
        # me.vbox.addItem(buttonBoxRepo);
        # me.vbox.addSpacing(10);

        var buttonBoxClose = me.drawBottomBar("Close", func() { me.window.hide(); });
        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBoxClose);
        me.vbox.addSpacing(10);

        return me;
    },

    #
    # return hash
    #
    createCanvasWindow: func() {
        var window = canvas.Window.new([AboutDialog.WINDOW_WIDTH, AboutDialog.WINDOW_HEIGHT], "dialog")
            .set("title", "Logbook Help");
            # .setBool("resize", true);

        window.hide();

        window.del = func() {
            # This method will be call after click on (X) button in canvas top
            # bar and here we want hide the window only.
            # FG next version provide destroy_on_close, but for 2020.3.x it's
            # unavailable, so we are handling it manually by this trick.
            call(me.hide, [], me);
        };

        # Because window.del only hide the window, we have to add extra method
        # to really delete the window.
        window.destroy = func() {
            call(canvas.Window.del, [], me);
        };

        # Set position on center of screen
        var screenW = getprop("/sim/gui/canvas/size[0]");
        var screenH = getprop("/sim/gui/canvas/size[1]");

        window.setPosition(
            screenW / 2 - AboutDialog.WINDOW_WIDTH / 2,
            screenH / 2 - AboutDialog.WINDOW_HEIGHT / 2
        );

        return window;
    },

    #
    # return hash - gui.widgets.ScrollArea object
    #
    createScrollArea: func() {
        var scrollData = canvas.gui.widgets.ScrollArea.new(me.group, canvas.style, {});
        scrollData.setColorBackground(canvas.style.getColor("bg_color"));
        scrollData.setContentsMargins(AboutDialog.PADDING, AboutDialog.PADDING, 0, 0); # left, top, right, bottom

        return scrollData;
    },

    #
    # return hash - content group of ScrollArea
    #
    getScrollAreaContent: func() {
        var scrollDataContent = me.scrollData.getContent();
        # scrollDataContent
        #     .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
        #     .set("character-size", 14)
        #     .set("alignment", "center-top");

        return scrollDataContent;
    },

    drawScrollable: func() {
        var radioList = canvas.VBoxLayout.new();

        radioList.addItem(me.getLabel(
            sprintf(
                "%s version %s - 6th December 2022",
                me.addon.name,
                me.addon.version.str()
            )
        ));

        radioList.addItem(me.getLabel("Written by:"));

        foreach (var author; me.addon.authors) {
            radioList.addItem(me.getLabel(sprintf("%s", author.name)));
        }

        var btnRepo = canvas.gui.widgets.Button.new(me.scrollDataContent, canvas.style, {})
            .setText("Open the repository website...")
            .setFixedSize(200, 26)
            .listen("clicked", func {
                fgcommand("open-browser", props.Node.new({"url" : me.addon.codeRepositoryUrl}));
            });

        radioList.addItem(btnRepo);

        me.scrollData.setLayout(radioList);
    },

    #
    # string text
    # return hash - Label widget
    #
    getLabel: func(text) {
        return canvas.gui.widgets.Label.new(me.scrollDataContent, canvas.style, {})
            .setText(text);
    },

    #
    # return hash - HBoxLayout object with button
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

    #
    # Destructor
    #
    del: func() {
        me.window.destroy();
    },

    #
    # Show canvas dialog
    #
    show: func() {
        me.window.raise();
        me.window.show();
    },

    #
    # Hide canvas dialog
    #
    hide: func() {
        me.window.hide();
    },
};
