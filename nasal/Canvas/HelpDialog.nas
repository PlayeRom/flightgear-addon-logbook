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
    WINDOW_WIDTH  : 700,
    WINDOW_HEIGHT : 420,
    PADDING       : 10,
    TITLE         : "Logbook Help",

    #
    # Constructor
    #
    # @param hash settings - Settings object
    # @return me
    #
    new: func(settings) {
        var me = { parents: [
            HelpDialog,
            Dialog.new(
                settings,
                HelpDialog.WINDOW_WIDTH,
                HelpDialog.WINDOW_HEIGHT,
                HelpDialog.TITLE,
                true,
                func(width) { me.onResizeWidth(width); }
            ),
        ] };

        me.bgImage.hide();

        me.setPositionOnCenter();

        me.canvas.set("background", me.style.CANVAS_BG);

        var margins = {
            left   : HelpDialog.PADDING,
            top    : HelpDialog.PADDING,
            right  : 0,
            bottom : 0,
        };
        me.scrollData = me.createScrollArea(me.style.CANVAS_BG, margins);

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent(
            me.scrollData,
            "LiberationFonts/LiberationSans-Regular.ttf",
            16,
            "left-baseline"
        );

        me.helpTexts = std.Vector.new();
        me.propHelpText = props.globals.getNode(me.addon.node.getPath() ~ "/addon-devel/help-text");

        me.reDrawTexts(0, 0, HelpDialog.WINDOW_WIDTH - (HelpDialog.PADDING * 2));
        me.drawBottomBar();

        return me;
    },

    #
    # Reszie collback from parent Dialog
    #
    # @param int width
    # @return void
    #
    onResizeWidth: func(width) {
        me.reDrawTexts(0, 0, width - (HelpDialog.PADDING * 2));
    },

    #
    # @param int x
    # @param int y
    # @param int|nil maxWidth
    # @return void
    #
    reDrawTexts: func(x, y, maxWidth = nil) {
        me.scrollDataContent.removeAllChildren();
        me.helpTexts.clear();

        foreach (var node; me.propHelpText.getChildren("paragraph")) {
            var isHeader = math.mod(node.getIndex(), 2) == 0;
            var text = me.scrollDataContent.createChild("text")
                .setText(node.getIndex() == 1
                    ? sprintf(node.getValue(), File.FILE_VERSION)
                    : node.getValue()
                )
                .setTranslation(x, y)
                .setColor(me.style.TEXT_COLOR)
                .setFontSize(isHeader ? 18 : 16)
                .setFont(isHeader
                    ? "LiberationFonts/LiberationSans-Bold.ttf"
                    : "LiberationFonts/LiberationSans-Regular.ttf"
                )
                .setAlignment("left-baseline");

            if (maxWidth != nil) {
                text.setMaxWidth(maxWidth);
            }

            y += text.getSize()[1] + 10;

            me.helpTexts.append(text);
        }
    },

    #
    # @return hash - HBoxLayout object with button
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

        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return buttonBox;
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
    # @param hash style
    # @return void
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.scrollData.setColorBackground(me.style.CANVAS_BG);

        foreach (var text; me.helpTexts.vector) {
            text.setColor(me.style.TEXT_COLOR);
        }
    },
};
