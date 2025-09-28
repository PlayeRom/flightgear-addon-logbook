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
    CLASS: "HelpDialog",

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
    # @return hash
    #
    new: func() {
        var me = { parents: [
            HelpDialog,
            PersistentDialog.new(
                width   : HelpDialog.WINDOW_WIDTH,
                height  : HelpDialog.WINDOW_HEIGHT,
                title   : HelpDialog.TITLE,
                resize  : true,
                onResize: func(w, h) { me._onResize(w, h); }
            ),
        ] };

        var dialogParent = me.parents[1];
        dialogParent.setChild(me, HelpDialog);  # Let the parent know who their child is.
        dialogParent.setPositionOnCenter();

        var margins = {
            left   : HelpDialog.PADDING,
            top    : HelpDialog.PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollData = ScrollAreaHelper.create(context: me._group, margins: margins);

        me._vbox.addItem(me._scrollData, 1); # 2nd param = stretch

        me._scrollDataContent = ScrollAreaHelper.getContent(
            context  : me._scrollData,
            font     : "LiberationFonts/LiberationSans-Regular.ttf",
            fontSize : 16,
            alignment: "left-baseline"
        );

        me._helpTexts = std.Vector.new();
        me._propHelpText = props.globals.getNode(g_Addon.node.getPath() ~ "/addon-devel/help-text");

        me._reDrawTexts(x: 0, y: 0, maxWidth: HelpDialog.WINDOW_WIDTH - (HelpDialog.PADDING * 2));
        me._drawBottomBar();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me.parents[1].del();
    },

    #
    # Resize callback from parent Dialog
    #
    # @param  int  width
    # @param  int  height
    # @return void
    #
    _onResize: func(width, height) {
        me._reDrawTexts(x: 0, y: 0, maxWidth: width - (HelpDialog.PADDING * 2));
    },

    #
    # @param  int  x
    # @param  int  y
    # @param  int|nil  maxWidth
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
                .setColor(canvas.style.getColor("text_color"))
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
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnAddonDir = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("Open Storage Folder")
            .setFixedSize(200, 26)
            .listen("clicked", func {
                Utils.openBrowser({ "path": g_Addon.storagePath });
            });

        var btnClose = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("Close")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                me.hide();
            });

        buttonBox.addItem(btnAddonDir);
        buttonBox.addItem(btnClose);

        me._vbox.addSpacing(10);
        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(10);

        return buttonBox;
    },
};
