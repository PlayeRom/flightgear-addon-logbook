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
    TITLE         : "Logbook Help",

    #
    # Constructor.
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

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, HelpDialog);  # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        var margins = {
            left   : HelpDialog.PADDING,
            top    : HelpDialog.PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollArea = ScrollAreaHelper.create(me._group, margins);

        me._vbox.addItem(me._scrollArea, 1); # 2nd param = stretch

        me._scrollContent = ScrollAreaHelper.getContent(
            context  : me._scrollArea,
            font     : "LiberationFonts/LiberationSans-Regular.ttf",
            fontSize : 16,
            alignment: "left-baseline"
        );

        me._helpTexts = std.Vector.new();
        me._propHelpText = props.globals.getNode(g_Addon.node.getPath() ~ "/addon-devel/help-text");

        me._reDrawTexts(x: 0, y: 0, maxWidth: HelpDialog.WINDOW_WIDTH - (HelpDialog.PADDING * 2));
        me._drawBottomBar();

        me._keyActions();

        return me;
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
        me._reDrawTexts(x: 0, y: 0, maxWidth: width - (HelpDialog.PADDING * 2));
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
    # @return ghost  HBoxLayout object with button.
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

    #
    # Handle keydown listener for window.
    #
    # @return void
    #
    _keyActions: func() {
        me._window.addEventListener("keydown", func(event) {
            # Possible fields of event:
            #   event.key - key as name
            #   event.keyCode - key as code
            # Modifiers:
            #   event.shiftKey
            #   event.ctrlKey
            #   event.altKey
            #   event.metaKey

            if (event.key == "Up") {
                me._scrollArea.vertScrollBarBy(-3);
            } elsif (event.key == "Down") {
                me._scrollArea.vertScrollBarBy(3);
            } elsif (event.key == "PageUp") {
                me._scrollArea.vertScrollBarBy(-45);
            } elsif (event.key == "PageDown") {
                me._scrollArea.vertScrollBarBy(45);
            }
        });
    },
};
