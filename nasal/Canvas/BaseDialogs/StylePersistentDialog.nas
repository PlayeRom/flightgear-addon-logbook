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
# Layer for PersistentDialog that adds styles/themes support.
#
var StylePersistentDialog = {
    CLASS: "StylePersistentDialog",

    #
    # Dialog styles/themes:
    #
    _STYLES: {
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
            LIST_BG      : [1.0, 1.0, 1.0, 0.0022], # TODO: opacity should be 0.0 but isn't because scroll bars glitches
            TEXT_COLOR   : canvas.style.getColor("text_color"),
            HOVER_BG     : [1.0, 1.0, 0.5, 1.0],
            SELECTED_BAR : [0.5, 1.0, 0.5, 1.0],
        },
    },

    #
    # Constructor
    #
    # @param  int  width  Initial width of window.
    # @param  int  height  Initial height of window.
    # @param  string  title  Title of window in the top bar.
    # @param  bool  resize  If true then user will be possible to resize the window.
    # @param  func|nil  onResize  Callback call when width or height of window was changed.
    # @return hash
    #
    new: func(width, height, title, resize = 0, onResize = nil) {
        var obj = {
            parents: [
                StylePersistentDialog,
                PersistentDialog.new(width, height, title, resize, onResize),
            ],
        };

        obj._style = g_Settings.isDarkStyle()
            ? obj.getStyle().dark
            : obj.getStyle().light;

        obj._bgImage = obj._group.createChild("image", "bgImage")
            .setFile("Textures/paper.png")
            .setTranslation(0, 0)
            # paper.png has 1360x1024 px
            .setSize(LogbookDialog.MAX_WINDOW_WIDTH, int((1024 / 1360) * LogbookDialog.MAX_WINDOW_WIDTH));

        obj.toggleBgImage();

        return obj;
    },

    #
    # Let the Dialog (parent) know who their child is.
    # Call this method in the child constructor if your child class needs
    # to call its stuff in methods like hide() or del().
    #
    # @param  hash  childMe  Child instance of object.
    # @param  hash  childCls  Child class hash.
    # @return void
    # @override PersistentDialog
    #
    setChild: func(childMe, childCls) {
        call(PersistentDialog.setChild, [childMe, childCls], me.parents[1]);
    },

    #
    # Set position on center of screen.
    #
    # @param  int|nil  width, height  Dimension of window. If nil, the values provided by the constructor will be used.
    # @return void
    # @override PersistentDialog
    #
    setPositionOnCenter: func(width = nil, height = nil) {
        call(PersistentDialog.setPositionOnCenter, [width, height], me.parents[1]);
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func {
        call(PersistentDialog.del, [], me);
    },

    #
    # Show canvas dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    show: func {
        call(PersistentDialog.show, [], me);
    },

    #
    # Hide canvas dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    hide: func {
        call(PersistentDialog.hide, [], me);
    },

    #
    # Get hash with dialog styles/themes
    #
    # @return hash
    #
    getStyle: func {
        return StylePersistentDialog._STYLES;
    },

    #
    # Hide background image for "dark" theme and show it for "light" theme
    #
    # @return void
    #
    toggleBgImage: func {
        me._style.NAME == "dark"
            ? me._bgImage.hide()
            : me._bgImage.show();
    },
};
