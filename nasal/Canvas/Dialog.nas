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
# Base Dialog class.
#
var Dialog = {
    CLASS: "Dialog",

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
        var me = {
            parents: [Dialog],
            _width : width,
            _height: height,
        };

        me._childMe = nil;
        me._childCls = nil;

        # Recognize the path to the canvas property.
        # For FG versions up to and including 2024 this is ‘/sim/gui/canvas’, but for the dev version it is ‘/canvas/desktop’
        # TODO: fix it in future when 2024 will be obsolete and "/canvas/desktop" will be a standard.
        me._isCanvas2024 = props.globals.getNode("/sim/gui/canvas") != nil;
        me._canvasNode = props.globals.getNode(me.getPathToCanvas());

        me.style = g_Settings.isDarkStyle()
            ? me.getStyle().dark
            : me.getStyle().light;

        me._window = me._createCanvasWindow(me._width, me._height, title, resize);
        me._canvas = me._window.createCanvas().set("background", canvas.style.getColor("bg_color"));
        me._group  = me._canvas.createGroup();
        me._vbox   = canvas.VBoxLayout.new();
        me._canvas.setLayout(me._vbox);

        me.bgImage = me._group.createChild("image", "bgImage")
            .setFile("Textures/paper.png")
            .setTranslation(0, 0)
            # paper.png has 1360x1024 px
            .setSize(LogbookDialog.MAX_WINDOW_WIDTH, int((1024 / 1360) * LogbookDialog.MAX_WINDOW_WIDTH));
        me.toggleBgImage();

        me._handleKeys();

        me._windowPropIndex = nil;

        me._listeners = Listeners.new();

        if (resize and onResize != nil) {
            me._windowPropIndex = me._getWindowPropertyIndex(title);
            if (me._windowPropIndex > -1) {
                # Our goal is to observe the change in width and height, but we want to call onResize only once,
                # regardless of whether only the width, height or both values have changed.
                # FG handles the following listeners in such a way that it will always trigger both, even if only one of
                # the sizes has changed. Therefore, we handle both listeners with a timer, where each triggered of the
                # listener extends the life of the timer, until finally the listeners stop triggered and the timer
                # function finally executes and executes only once.
                var resizeTimer = Timer.makeSelf(0.1, func() {
                    resizeTimer.stop();

                    me._width  = int(me.getInnerWidth());
                    me._height = int(me.getInnerHeight());

                    onResize(me._width, me._height);
                });

                # Set listener for resize width of window
                me._listeners.add(
                    node: me.getPathToCanvas() ~ "/window[" ~ me._windowPropIndex ~ "]/content-size[0]",
                    code: func() {
                        resizeTimer.isRunning
                            ? resizeTimer.restart(0.1)
                            : resizeTimer.start();
                    },
                );

                me._listeners.add(
                    node: me.getPathToCanvas() ~ "/window[" ~ me._windowPropIndex ~ "]/content-size[1]",
                    code: func() {
                        resizeTimer.isRunning
                            ? resizeTimer.restart(0.1)
                            : resizeTimer.start();
                    },
                );
            }
        }

        return me;
    },

    #
    # @param  int  width
    # @param  int  height
    # @param  string  title
    # @param  bool  resize
    # @return ghost  Canvas Window object.
    #
    _createCanvasWindow: func(width, height, title, resize) {
        var type = "dialog";
        var id = nil; # default
        var allowFocus = true; # default

        var window = canvas.Window.new([width, height], type, id, allowFocus)
            .set("title", title)
            .setBool("resize", resize);

        window.hide();

        var self = me;

        window.del = func() {
            # This method will be call after click on (X) button in canvas top
            # bar and here we want hide the window only.
            # FG version 2024.x supports the destroy_on_close flag, which could
            # be set to false, then FG would call hide() on the window itself,
            # but this will not give us the ability to call the child's hide()
            # function.

            self._callMethodByChild("hide");
        };

        return window;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._listeners.del();

        # Since we override window.del() to only hide the window, we need to actually destroy the window here by:
        call(canvas.Window.del, [], me._window);
    },

    #
    # Set position on center of screen.
    #
    # @param  int|nil  width, height  Dimension of window. If nil, the values provided by the constructor will be used.
    # @return void
    #
    setPositionOnCenter: func(width = nil, height = nil) {
        var screenW = me.getScreenWidth();
        var screenH = me.getScreenHeight();

        var w = width  or me._width;
        var h = height or me._height;

        var newX = int(screenW / 2 - w / 2);
        var newY = int(screenH / 2 - h / 2);

        # Prevent the window top bar from going off-screen. It can happened if
        # FG will open in small resolution.
        if (newX < 0) {
            newX = 0;
        }

        if (newY < 0) {
            newY = 35; # Leave some space for FG main menu bar
        }

        me._window.setPosition(newX, newY);
    },

    #
    # @param  vector|nil  bgColor
    # @param  hash|nil  margins  Margins hash or nil
    # @return ghost  canvas.gui.widgets.ScrollArea object
    #
    createScrollArea: func(bgColor = nil, margins = nil) {
        var scrollArea = canvas.gui.widgets.ScrollArea.new(me._group, canvas.style, {});
        scrollArea.setColorBackground(bgColor == nil ? canvas.style.getColor("bg_color") : bgColor);

        if (margins != nil) {
            scrollArea.setContentsMargins(margins.left, margins.top, margins.right, margins.bottom);
        }

        return scrollArea;
    },

    #
    # @param  ghost  context  Parent object as ScrollArea widget
    # @param  string|nil  font  Font file name
    # @param  int|nil  fontSize  Font size
    # @param  string|nil  alignment  Content alignment value
    # @return ghost  Content group of ScrollArea
    #
    getScrollAreaContent: func(context, font = nil, fontSize = nil, alignment = nil) {
        var scrollContent = context.getContent();

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
    # Show canvas dialog.
    #
    # @return void
    #
    show: func() {
        me._window.raise();
        me._window.show();
    },

    #
    # Hide canvas dialog.
    #
    # @return void
    #
    hide: func() {
        me._window.hide();
    },

    #
    # Return true if window is showing.
    #
    # @return bool
    #
    isWindowVisible: func() {
        return me._window.isVisible();
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
                LIST_BG      : [1.0, 1.0, 1.0, 0.0022], # TODO: opacity should be 0.0 but isn't because scroll bars glitches
                TEXT_COLOR   : [0.3, 0.3, 0.3],
                HOVER_BG     : [1.0, 1.0, 0.5, 1.0],
                SELECTED_BAR : [0.5, 1.0, 0.5, 1.0],
            },
        };
    },

    #
    # @param  string  title
    # @return int  Return index of window in property tree or -1 if not found.
    #
    _getWindowPropertyIndex: func(title) {
        var highest = -1; # We are looking for the highest index for support dev reload the add-on
        foreach (var window; me._canvasNode.getChildren("window")) {
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
    # Get X position of this window.
    #
    # @return int
    #
    getPosX: func() {
        return me._window.get("tf/t[0]");
    },

    #
    # Get Y position of this window.
    #
    # @return int
    #
    getPosY: func() {
        return me._window.get("tf/t[1]");
    },

    #
    # Get outer width of this window.
    #
    # @return double
    #
    getOuterWidth: func() {
        return me._window.get("size[0]");
    },

    #
    # Get outer height of this window.
    #
    # @return double
    #
    getOuterHeight: func() {
        return me._window.get("size[1]");
    },

    #
    # Get inner/content width of this window.
    #
    # @return double
    #
    getInnerWidth: func() {
        return me._window.get("content-size[0]");
    },

    #
    # Get inner/content height of this window.
    #
    # @return double
    #
    getInnerHeight: func() {
        return me._window.get("content-size[1]");
    },

    #
    # Get width of screen.
    #
    # @return int
    #
    getScreenWidth: func() {
        return getprop(me.getPathToCanvas() ~ "/size[0]");
    },

    #
    # Get height of screen.
    #
    # @return int
    #
    getScreenHeight: func() {
        return getprop(me.getPathToCanvas() ~ "/size[1]");
    },

    #
    # Get path to canvas properties which depend of FG version.
    #
    # @return string
    #
    getPathToCanvas: func() {
        if (me._isCanvas2024) {
            return "/sim/gui/canvas";
        }

        return "/canvas/desktop";
    },

    #
    # Let the Dialog (parent) know who their child is.
    # Call this method in the child constructor if your child class needs
    # to call its stuff in methods like hide() or del().
    #
    # @param  hash  childMe  Child instance of object.
    # @param  hash  childCls  Child class hash.
    # @return void
    #
    setChild: func(childMe, childCls) {
        me._childMe = childMe;
        me._childCls = childCls;
    },

    #
    # Call child given method if exists.
    #
    # @param  string  funcName  Method name to call.
    # @return bool  Return true if function has been called, otherwise return false.
    #
    _callMethodByChild: func(funcName) {
        if (me._childMe != nil and me._childCls != nil and typeof(me._childCls[funcName]) == "func") {
            Log.print("Dialog._callMethodByChild(", funcName, ") - by child ", me._childCls.CLASS);
            return call(me._childCls[funcName], [], me._childMe);
        }

        if (me._childCls == nil) {
            Log.print("Dialog._callMethodByChild(", funcName, ") - NO child");
        } else {
            Log.print("Dialog._callMethodByChild(", funcName, ") - child ", me._childCls.CLASS, " has no function ", funcName);
        }

        # Child doesn't have give function name, so run it by self.
        return call(Dialog[funcName], [], me);
    },

    #
    # Handle keydown listener for window.
    #
    # @return void
    #
    _handleKeys: func() {
        me._window.addEventListener("keydown", func(event) {
            # Possible fields of event:
            #   event.key - key as name
            #   event.keyCode - key as code
            # Modifiers:
            #   event.shiftKey
            #   event.ctrlKey
            #   event.altKey
            #   event.metaKey

            if (event.key == "Escape") {
                me._callMethodByChild("hide");
            }
        });
    },
};
