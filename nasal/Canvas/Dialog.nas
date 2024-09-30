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
# Base Dialog class
#
var Dialog = {
    #
    # Constructor
    #
    # @param int width - Initial width of window
    # @param int height - Initial height of window
    # @param string title - Title of window in the top bar
    # @param bool resize - If true then user will be possible to resize the window
    # @param func|nil onResizeWidth - callback call when width of window was changed
    # @return me
    #
    new: func(width, height, title, resize = 0, onResizeWidth = nil) {
        var me = { parents: [Dialog] };

        me.addon    = addons.getAddon(ADDON_ID);
        me.width    = width;
        me.height   = height;

        me.style = g_Settings.isDarkStyle()
            ? me.getStyle().dark
            : me.getStyle().light;

        me.window = me.createCanvasWindow(width, height, title, resize);
        me.canvas = me.window.createCanvas().set("background", canvas.style.getColor("bg_color"));
        me.group  = me.canvas.createGroup();
        me.vbox   = canvas.VBoxLayout.new();
        me.canvas.setLayout(me.vbox);

        me.bgImage = me.group.createChild("image", "bgImage")
            .setFile("Textures/paper.png")
            .setTranslation(0, 0)
            # paper.png has 1360x1024 px
            .setSize(LogbookDialog.WINDOW_WIDTH, int((1024 / 1360) * LogbookDialog.WINDOW_WIDTH));
        me.toggleBgImage();

        if (resize and onResizeWidth != nil) {
            me.windowPropIndex = me.getWindowPropertyIndex(title);
            if (me.windowPropIndex > -1) {
                # Set listener for resize width of window
                setlistener("/sim/gui/canvas/window[" ~ me.windowPropIndex ~ "]/content-size[0]", func(node) {
                    onResizeWidth(node.getValue());
                });
            }
        }

        return me;
    },

    #
    # @param int width
    # @param int height
    # @param string title
    # @param bool resize
    # @return hash - canvas Window object
    #
    createCanvasWindow: func(width, height, title, resize) {
        var window = canvas.Window.new([width, height], "dialog")
            .set("title", title)
            .setBool("resize", resize);

        window.hide();

        var self = me;

        window.del = func() {
            # This method will be call after click on (X) button in canvas top
            # bar and here we want hide the window only.
            # FG 2024.x version provide destroy_on_close, but for 2020.3.x it's
            # unavailable, so we are handling it manually by this trick.
            call(Dialog.hide, [], self);
        };

        # Because window.del only hide the window, we have to add extra method
        # to really delete the window.
        window.destroy = func() {
            call(canvas.Window.del, [], me);
        };

        return window;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.window.destroy();
    },

    #
    # Set position on center of screen
    #
    # @param int|nil width, height - Dimension of window. If nil, the values provided by the constructor will be used.
    # @return void
    #
    setPositionOnCenter: func(width = nil, height = nil) {
        var screenW = me.getScreenWidth();
        var screenH = me.getScreenHeight();

        var w = width  == nil ? me.width  : width;
        var h = height == nil ? me.height : height;

        me.window.setPosition(
            int(screenW / 2 - w / 2),
            int(screenH / 2 - h / 2)
        );
    },

    #
    # @param vector|nil bgColor
    # @param hash|nil margins - Margins hash or nil
    # @return hash - gui.widgets.ScrollArea object
    #
    createScrollArea: func(bgColor = nil, margins = nil) {
        var scrollArea = canvas.gui.widgets.ScrollArea.new(me.group, canvas.style, {});
        scrollArea.setColorBackground(bgColor == nil ? canvas.style.getColor("bg_color") : bgColor);

        if (margins != nil) {
            scrollArea.setContentsMargins(margins.left, margins.top, margins.right, margins.bottom);
        }

        return scrollArea;
    },

    #
    # @param hash cGroup - Parent object as ScrollArea widget
    # @param string|nil font - Font file name
    # @param int|nil - Font size
    # @param string|nil alignment - Content alignment value
    # @return hash - content group of ScrollArea
    #
    getScrollAreaContent: func(cGroup, font = nil, fontSize = nil, alignment = nil) {
        var scrollContent = cGroup.getContent();

        if (font != nil) {
            scrollContent.set("font", font);
        }

        if (fontSize != nil) {
            scrollContent.set("character-size", fontSize);
        }

        if (alignment != nil) {
            scrollContent.set("alignment", alignment);
        }

        return scrollContent;
    },

    #
    # Show canvas dialog
    #
    # @return void
    #
    show: func() {
        me.window.raise();
        me.window.show();
    },

    #
    # Hide canvas dialog
    #
    # @param bool withRedraw
    # @return void
    #
    hide: func(withRedraw = 1) {
        me.window.hide();
    },

    #
    # Return true if window is showing
    #
    # @return bool
    #
    isWindowVisible: func() {
        return me.window.isVisible();
    },

    #
    # Get hash with dialog styles/themes
    #
    # @return hash
    #
    getStyle: func() {
        return {
            "dark": {
                NAME         : "dark",
                CANVAS_BG    : "#000000EE",
                LIST_BG      : [0.0, 0.0, 0.0, 0.9],
                TEXT_COLOR   : [0.8, 0.8, 0.8],
                HOVER_BG     : [0.2, 0.0, 0.0, 1.0],
                SELECTED_BAR : [0.0, 0.4, 0.0, 1.0],
            },
            "light": {
                NAME         : "light",
                CANVAS_BG    : canvas.style.getColor("bg_color"),
                LIST_BG      : [1.0, 1.0, 1.0, 0.01], # NOTE: opacity cannot be 0.0 because scroll bars glitches
                TEXT_COLOR   : [0.3, 0.3, 0.3],
                HOVER_BG     : [1.0, 1.0, 0.5, 1.0],
                SELECTED_BAR : [0.5, 1.0, 0.5, 1.0],
            },
        };
    },

    #
    # @param string title
    # @return int - return index of window in property tree or -1 if not found.
    #
    getWindowPropertyIndex: func(title) {
        var highest = -1; # We are looking for the highest index for support dev reload the add-on
        foreach (var window; props.globals.getNode("/sim/gui/canvas").getChildren("window")) {
            var propTitle = window.getChild("title");
            if (propTitle != nil and title == propTitle.getValue()) {
                if (window.getIndex() > highest) {
                    highest = window.getIndex();
                }
            }
        }

        return highest;
    },

    #
    # Hide background image for "dark" theme and show it for "light" theme
    #
    # @return void
    #
    toggleBgImage: func() {
        me.style.NAME == "dark"
            ? me.bgImage.hide()
            : me.bgImage.show();
    },

    #
    # Get X position of this window
    #
    # @return int
    #
    getPosX: func() {
        return me.window.get("tf/t[0]");
    },

    #
    # Get Y position of this window
    #
    # @return int
    #
    getPosY: func() {
        return me.window.get("tf/t[1]");
    },

    #
    # @return int
    #
    getScreenWidth: func() {
        return getprop("/sim/gui/canvas/size[0]");
    },

    #
    # @return int
    #
    getScreenHeight: func() {
        return getprop("/sim/gui/canvas/size[1]");
    },
};
