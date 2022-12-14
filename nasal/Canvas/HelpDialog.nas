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
    WINDOW_WIDTH  : 600,
    WINDOW_HEIGHT : 360,
    PADDING       : 10,

    #
    # Constructor
    #
    # return me
    #
    new: func() {
        var me = { parents: [
            HelpDialog,
            Dialog.new(Dialog.ID_HELP, HelpDialog.WINDOW_WIDTH, HelpDialog.WINDOW_HEIGHT, "Logbook Help", true),
        ] };

        me.setPositionOnCenter(HelpDialog.WINDOW_WIDTH, HelpDialog.WINDOW_HEIGHT);

        me.canvas.set("background", me.style.CANVAS_BG);

        var margins = {"left": HelpDialog.PADDING, "top": HelpDialog.PADDING, "right": 0, "bottom": 0};
        me.scrollData = me.createScrollArea(me.style.CANVAS_BG, margins);

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent(
            me.scrollData,
            "LiberationFonts/LiberationSans-Regular.ttf",
            14,
            "left-baseline"
        );

        me.textHelp = me.drawText(0, 0, HelpDialog.WINDOW_WIDTH - (HelpDialog.PADDING * 2));

        var buttonBox = me.drawBottomBar();

        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return me;
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
    # return void
    #
    del: func() {
        me.parents[1].del();
    },

    #
    # hash style
    # return void
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.scrollData.setColorBackground(me.style.CANVAS_BG);
        me.textHelp.setColor(me.style.TEXT_COLOR);
    },

    #
    # return string
    #
    getHelpText: func() {
        return sprintf(getprop(me.addon.node.getPath() ~ "/addon-devel/help-text"), File.FILE_VERSION);
    },
};
