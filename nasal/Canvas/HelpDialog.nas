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
    # @return me
    #
    new: func() {
        var me = { parents: [
            HelpDialog,
            Dialog.new(
                HelpDialog.WINDOW_WIDTH,
                HelpDialog.WINDOW_HEIGHT,
                HelpDialog.TITLE,
                true,
                func(w, h) { me._onResize(w, h); }
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
        me._scrollData = me.createScrollArea(me.style.CANVAS_BG, margins);

        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch

        me._scrollDataContent = me.getScrollAreaContent(
            me._scrollData,
            "LiberationFonts/LiberationSans-Regular.ttf",
            16,
            "left-baseline"
        );

        me._helpTexts = std.Vector.new();
        me._propHelpText = props.globals.getNode(g_Addon.node.getPath() ~ "/addon-devel/help-text");

        me._reDrawTexts(0, 0, HelpDialog.WINDOW_WIDTH - (HelpDialog.PADDING * 2));
        me._drawBottomBar();

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
    # Resize callback from parent Dialog
    #
    # @param  int  width
    # @param  int  height
    # @return void
    #
    _onResize: func(width, height) {
        me._reDrawTexts(0, 0, width - (HelpDialog.PADDING * 2));
    },

    #
    # @param int x
    # @param int y
    # @param int|nil maxWidth
    # @return void
    #
    _reDrawTexts: func(x, y, maxWidth = nil) {
        me._scrollDataContent.removeAllChildren();
        me._helpTexts.clear();

        foreach (var node; me._propHelpText.getChildren("paragraph")) {
            var isHeader = math.mod(node.getIndex(), 2) == 0;
            var text = me._scrollDataContent.createChild("text")
                .setText(node.getIndex() == 1
                    ? sprintf(node.getValue(), Storage.CSV_FILE_VERSION)
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

            me._helpTexts.append(text);
        }
    },

    #
    # @return hash - HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnAddonDir = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Local storage directory...")
            .setFixedSize(200, 26)
            .listen("clicked", func {
                fgcommand("open-browser", props.Node.new({ "path": g_Addon.storagePath }));
            });

        var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Close")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                me.window.hide();
            });

        buttonBox.addItem(btnAddonDir);
        buttonBox.addItem(btnClose);

        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return buttonBox;
    },

    #
    # @param hash style
    # @return void
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me._scrollData.setColorBackground(me.style.CANVAS_BG);

        foreach (var text; me._helpTexts.vector) {
            text.setColor(me.style.TEXT_COLOR);
        }
    },
};
