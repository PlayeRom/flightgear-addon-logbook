#
# Framework Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Base class for windows that are to be created on a window open action and
# destroyed when the window is closed.
# This means that the user may see a delay in the window being created.
#
var TransientDialog = {
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
    new: func(width, height, title, resize = 0, onResize = nil) {
        var obj = {
            parents: [
                TransientDialog,
                Dialog.new(width, height, title, resize, onResize),
            ],
        };

        obj._handleKeys();

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override Dialog
    #
    del: func {
        call(Dialog.del, [], me);
    },

    #
    # Show canvas dialog.
    #
    # @return void
    # @override Dialog
    #
    show: func {
        call(Dialog.show, [], me);
    },

    #
    # Hide canvas dialog.
    #
    # @return void
    # @override Dialog
    #
    hide: func {
        call(Dialog.hide, [], me);
    },

    #
    # Handle keydown listener for window.
    #
    # @return void
    #
    _handleKeys: func {
        me._window.addEventListener('keydown', func(event) {
            # Possible fields of event:
            #   event.key - key as name
            #   event.keyCode - key as code
            # Modifiers:
            #   event.shiftKey
            #   event.ctrlKey
            #   event.altKey
            #   event.metaKey

            if (event.key == 'Escape') {
                me.del();
            }
        });
    },
};
