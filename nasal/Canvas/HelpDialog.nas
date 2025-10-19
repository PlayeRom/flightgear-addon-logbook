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
# HelpDialog class to display help text.
#
var HelpDialog = {
    CLASS: "HelpDialog",

    #
    # Constants:
    #
    WINDOW_WIDTH  : 700,
    WINDOW_HEIGHT : 420,
    PADDING       : 10,

    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = { parents: [
            HelpDialog,
            PersistentDialog.new(
                width   : HelpDialog.WINDOW_WIDTH,
                height  : HelpDialog.WINDOW_HEIGHT,
                title   : "Logbook Help",
                resize  : true,
                onResize: func(w, h) { obj._onResize(w, h); }
            ),
        ] };

        call(PersistentDialog.setChild, [obj, HelpDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._widget = WidgetHelper.new(obj._group);

        var margins = {
            left   : me.PADDING,
            top    : me.PADDING,
            right  : 0,
            bottom : 0,
        };
        obj._scrollArea = ScrollAreaHelper.create(obj._group, margins);

        obj._vbox.addItem(obj._scrollArea, 1); # 2nd param = stretch

        obj._scrollContent = ScrollAreaHelper.getContent(
            context  : obj._scrollArea,
            font     : "LiberationFonts/LiberationSans-Regular.ttf",
            fontSize : 16,
            alignment: "left-baseline"
        );

        obj._helpTexts = std.Vector.new();
        obj._propHelpText = props.globals.getNode(g_Addon.node.getPath() ~ "/addon-devel/help-text");

        obj._reDrawTexts(x: 0, y: 0, maxWidth: me.WINDOW_WIDTH - (me.PADDING * 2));
        obj._drawBottomBar();

        obj._keyActions();

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        call(PersistentDialog.del, [], me);
    },

    #
    # Resize callback from parent Dialog.
    #
    # @param  int  width
    # @param  int  height
    # @return void
    #
    _onResize: func(width, height) {
        me._reDrawTexts(0, 0, width - (me.PADDING * 2));
    },

    #
    # @param  int  x
    # @param  int  y
    # @param  int|nil  maxWidth
    # @return void
    #
    _reDrawTexts: func(x, y, maxWidth = nil) {
        me._scrollContent.removeAllChildren();
        me._helpTexts.clear();

        foreach (var node; me._propHelpText.getChildren("paragraph")) {
            var isHeader = math.mod(node.getIndex(), 2) == 0;
            var text = me._scrollContent.createChild("text")
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
    # @return void
    #
    _drawBottomBar: func() {
        var btnAddonDir = me._widget.getButton("Open Storage Folder", 200, func {
            Utils.openBrowser({ path: g_Addon.storagePath });
        });

        var btnClose = me._widget.getButton("Close", 75, func me.hide());

        var buttonBox = canvas.HBoxLayout.new();
        buttonBox.addItem(btnAddonDir);
        buttonBox.addItem(btnClose);

        me._vbox.addSpacing(10);
        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(10);
    },

    #
    # Handle keydown listener for window.
    #
    # @return void
    #
    _keyActions: func() {
        me._window.addEventListener("keydown", func(event) {
               if (event.key == "Up"     or event.key == "Down")     me._handleScrollKey(true,  event.key == "Up");
            elsif (event.key == "PageUp" or event.key == "PageDown") me._handleScrollKey(false, event.key == "PageUp");
        });
    },

    #
    # @param  bool  isArrow  If true then arrow up/down keys, otherwise page up/down keys.
    # @param  bool  isUp  If true then dy must be converted to negative.
    # @return void
    #
    _handleScrollKey: func(isArrow, isUp) {
        var dy = isArrow
            ? 20
            : ScrollAreaHelper.getScrollPageHeight(me._scrollArea);

        if (isUp) {
            dy = -dy;
        }

        me._scrollArea.vertScrollBarBy(dy);
    },
};
