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
    # Constants
    #
    ID_LOGBOOK : 1,
    ID_DETAILS : 2,
    ID_INPUT   : 3,
    ID_DELETE  : 4,
    ID_ABOUT   : 5,
    ID_HELP    : 6,

    #
    # Constructor
    #
    # int id - ID of the Dialog as one of constants ID_LOGBOOK, ID_DETAILS, etc.
    # int width - Initial width of window
    # int height - Initial height of window
    # string title - Title of window in the top bar
    # bool resize - If true then user will be possible to resize the window
    # return me
    #
    new: func(id, width, height, title, resize = 0) {
        var me = { parents: [Dialog] };

        me.addon  = addons.getAddon(ADDON_ID);
        me.dialogId = id;

        me.settings = Settings.new(me.addon);

        me.style = me.settings.isDarkStyle()
            ? me.getStyle().dark
            : me.getStyle().light;

        me.window = me.createCanvasWindow(id, width, height, title, resize);
        me.canvas = me.window.createCanvas().set("background", canvas.style.getColor("bg_color"));
        me.group  = me.canvas.createGroup();
        me.vbox   = canvas.VBoxLayout.new();
        me.canvas.setLayout(me.vbox);

        return me;
    },

    #
    # Destructor
    #
    # return void
    #
    del: func() {
        me.window.destroy();
    },

    #
    # int id
    # int width
    # int height
    # string title
    # bool resize
    # return hash - canvas Window object
    #
    createCanvasWindow: func(id, width, height, title, resize) {
        var window = canvas.Window.new([width, height], "dialog")
            .set("title", title)
            .setBool("resize", resize);

        window.hide();

        window.del = func() {
            # This method will be call after click on (X) button in canvas top
            # bar and here we want hide the window only.
            # FG next version provide destroy_on_close, but for 2020.3.x it's
            # unavailable, so we are handling it manually by this trick.

            # WARNING!! me.hide it's not the same hide method presented below in line ~150,
            # me = window, not my Dialog.nas
            call(me.hide, [], me);

            if (id == Dialog.ID_DETAILS) {
                # Set property redraw-logbook for remove selected bar
                setprop(addons.getAddon(ADDON_ID).node.getPath() ~ "/addon-devel/redraw-logbook", true);
            }

            if (id == Dialog.ID_INPUT) {
                # Set property redraw-details for remove selected bar
                setprop(addons.getAddon(ADDON_ID).node.getPath() ~ "/addon-devel/redraw-details", true);
            }
        };

        # Because window.del only hide the window, we have to add extra method
        # to really delete the window.
        window.destroy = func() {
            call(canvas.Window.del, [], me);
        };

        return window;
    },

    #
    # Set position on center of screen
    #
    # return void
    #
    setPositionOnCenter: func(width, height) {
        var screenW = getprop("/sim/gui/canvas/size[0]");
        var screenH = getprop("/sim/gui/canvas/size[1]");

        me.window.setPosition(
            screenW / 2 - width / 2,
            screenH / 2 - height / 2
        );
    },

    #
    # vector|nil bgColor
    # hash|nil margins - Margins hash or nil
    # return hash - gui.widgets.ScrollArea object
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
    # hash cGroup - Pareent object as ScrollArea widget
    # string|nil font - Font file name
    # int|nil - Font size
    # string|nil alignment - Content alignment value
    # return hash - content group of ScrollArea
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
    # return void
    #
    show: func() {
        me.window.raise();
        me.window.show();
    },

    #
    # Hide canvas dialog
    #
    # return void
    #
    hide: func() {
        me.window.hide();
    },

    #
    # Return true if window is showing
    #
    # return bool
    #
    isWindowVisible: func() {
        return me.window.isVisible();
    },

    #
    # return int
    #
    getDialogId: func() {
        return me.dialogId;
    },

    #
    # Get hash with dialog styles/themes
    #
    # return hash
    #
    getStyle: func() {
        return {
            "dark": {
                NAME         : "dark",
                CANVAS_BG    : "#000000EE",
                # GROUP_BG     : [0.3, 0.3, 0.3],
                TEXT_COLOR   : [0.8, 0.8, 0.8],
                HOVER_BG     : [0.2, 0.0, 0.0, 1.0],
                SELECTED_BAR : [0.0, 0.4, 0.0, 1.0],
            },
            "light": {
                NAME         : "light",
                CANVAS_BG    : canvas.style.getColor("bg_color"),
                # GROUP_BG    : [0.7, 0.7, 0.7],
                TEXT_COLOR   : [0.3, 0.3, 0.3],
                HOVER_BG     : [1.0, 1.0, 0.5, 1.0],
                SELECTED_BAR : [0.5, 1.0, 0.5, 1.0],
            },
        };
    },
};
