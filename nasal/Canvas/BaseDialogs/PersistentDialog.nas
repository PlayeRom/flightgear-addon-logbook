#
# CanvasSkeleton Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Base class for windows that are to be created once, when the simulator starts.
# The window opening action calls the show() method, and the closing action
# calls the hide() method. The window is not destroyed until the simulator exits.
# This means that the user will not see a delay in the window being created.
#
var PersistentDialog = {
    #
    # Constructor.
    #
    # @param  int  width  Initial width of window.
    # @param  int  height  Initial height of window.
    # @param  string  title  Title of window in the top bar.
    # @param  bool  resize  If true then user will be possible to resize the window.
    # @param  func|nil  onResize  Callback call when width or height of window was changed.
    # @return hash
    #
    new: func(width, height, title, resize = false, onResize = nil) {
        var obj = {
            parents: [
                PersistentDialog,
                Dialog.new(width, height, title, resize, onResize),
            ],
        };

        obj._window.hide();

        var self = obj;
        obj._window.del = func() {
            # This method will be call after click on (X) button in canvas top
            # bar and here we want hide the window only.
            # FG version 2024.x supports the destroy_on_close flag, which could
            # be set to false, then FG would call hide() on the window itself,
            # but this will not give us the ability to call the child's hide()
            # function.

            self._callMethodByChild("hide");
        };

        obj._childMe = nil;
        obj._childCls = nil;

        obj._usePositionOnCenter = false;

        obj._handleKeys();

        obj._posCenterTimer = nil;

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override Dialog
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Show canvas dialog.
    #
    # @return void
    # @override Dialog
    #
    show: func() {
        call(Dialog.show, [], me);
    },

    #
    # Hide canvas dialog.
    #
    # @return void
    # @override Dialog
    #
    hide: func() {
        call(Dialog.hide, [], me);
    },

    #
    # Set position on center of screen.
    #
    # @param  int|nil  width, height  Dimension of window. If nil, the values provided by the constructor will be used.
    # @return void
    # @override Dialog
    #
    setPositionOnCenter: func(width = nil, height = nil) {
        if (me._posCenterTimer) {
            me._posCenterTimer.stop();
        }

        call(Dialog.setPositionOnCenter, [width, height], me.parents[1]);

        if (!me._usePositionOnCenter) {
            me._usePositionOnCenter = true;
            me._addScreenSizeListeners();
        }
    },

    #
    # Add listeners for screen size changes.
    #
    # @return void
    #
    _addScreenSizeListeners: func() {
        me._posCenterTimer = Timer.make(0.1, me, me.setPositionOnCenter);

        me._listeners.add(
            node: me._getPathToCanvas() ~ "/size[0]",
            code: func me._handleSizeChange(),
            type: Listeners.ON_CHANGE_ONLY,
        );

        me._listeners.add(
            node: me._getPathToCanvas() ~ "/size[1]",
            code: func me._handleSizeChange(),
            type: Listeners.ON_CHANGE_ONLY,
        );
    },

    #
    # Method triggered when changing the FlightGear window resolution.
    # The timer prevents setPositionOnCenter from being called multiple times
    # when the width and height change simultaneously, or when the window is
    # stretched with the mouse.
    #
    # @return void
    #
    _handleSizeChange: func() {
        if (me._usePositionOnCenter) {
            me._posCenterTimer.isRunning
                ? me._posCenterTimer.restart(0.1)
                : me._posCenterTimer.start();
        }
    },

    #
    # Let the Dialog (parent) know who their child is.
    # Call this method in the child constructor if your child class needs
    # to call its stuff in methods like hide() or del().
    #
    # @param  hash  childMe  Child instance of object ("me").
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
            return call(me._childCls[funcName], [], me._childMe);
        }

        # Child doesn't have give function name, so run it by self.
        return call(PersistentDialog[funcName], [], me);
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
