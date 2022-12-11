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
# HelpDialog class to display help text
#
var HelpDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH         : 600,
    WINDOW_HEIGHT        : 360,
    PADDING              : 10,

    #
    # Constructor
    #
    # hash addon - addons.Addon object
    # hash style
    #
    new: func(addon, style) {
        var me = { parents: [HelpDialog] };

        me.addon = addon;
        me.style = style;

        me.window = me.createCanvasWindow();
        me.canvas = me.window.createCanvas().set("background", me.style.CANVAS_BG);
        me.group  = me.canvas.createGroup();

        me.vbox   = canvas.VBoxLayout.new();
        me.canvas.setLayout(me.vbox);

        me.scrollData = me.createScrollArea();

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent();

        me.textHelp = me.drawText(0, 0, HelpDialog.WINDOW_WIDTH - (HelpDialog.PADDING * 2));

        var buttonBox = me.drawBottomBar();

        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return me;
    },

    #
    # return hash
    #
    createCanvasWindow: func() {
        var window = canvas.Window.new([HelpDialog.WINDOW_WIDTH, HelpDialog.WINDOW_HEIGHT], "dialog")
            .set("title", "Logbook Help")
            .setBool("resize", true);

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
            screenW / 2 - HelpDialog.WINDOW_WIDTH / 2,
            screenH / 2 - HelpDialog.WINDOW_HEIGHT / 2
        );

        return window;
    },

    #
    # return hash - gui.widgets.ScrollArea object
    #
    createScrollArea: func() {
        var scrollData = canvas.gui.widgets.ScrollArea.new(me.group, canvas.style, {});
        scrollData.setColorBackground(me.style.CANVAS_BG);
        scrollData.setContentsMargins(HelpDialog.PADDING, HelpDialog.PADDING, 0, 0); # left, top, right, bottom

        return scrollData;
    },

    #
    # return hash - content group of ScrollArea
    #
    getScrollAreaContent: func() {
        var scrollDataContent = me.scrollData.getContent();
        scrollDataContent
            .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
            .set("character-size", 14)
            .set("alignment", "left-baseline");

        return scrollDataContent;
    },

    #
    # int x
    # int y
    # int|nil maxWidth
    # return hash - canvas text object
    #
    drawText: func(x, y, maxWidth = nil) {
        var text = me.scrollDataContent.createChild("text")
            .setText(me.getHelpText())
            .setTranslation(x, y)
            .setColor(me.style.TEXT_COLOR)
            .setAlignment("left-top");

        if (maxWidth != nil) {
            text.setMaxWidth(maxWidth);
        }

        return text;
    },

    #
    # return hash - HBoxLayout object with button
    #
    drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Close")
            .setFixedSize(75, 26);

        btnClose.listen("clicked", func {
            me.window.hide();
        });

        buttonBox.addItem(btnClose);

        return buttonBox;
    },

    #
    # Destructor
    #
    del: func() {
        me.window.destroy();
    },

    #
    # hash style
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.scrollData.setColorBackground(me.style.CANVAS_BG);
        me.textHelp.setColor(me.style.TEXT_COLOR);
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

    #
    # return string
    #
    getHelpText: func() {
        return getprop(me.addon.node.getPath() ~ "/addon-devel/help-text");
    },
};
