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
# Global object of VersionChecker.
#
var g_VersionChecker = nil;

#
# Create objects from add-on namespace.
#
var Bootstrap = {
    #
    # Initialize objects.
    #
    # @return void
    #
    init: func {
        g_VersionChecker = VersionChecker.make();

        Application.callHook('onInit');

        me._delayCanvasLoading(func {
            Application.callHook('onInitCanvas');

            # Check the version at the end, because dialogs must first register
            # their callbacks to VersionChecker in their constructors.
            g_VersionChecker.checkLastVersion();
        });
    },

    #
    # Uninitialize objects.
    #
    # @return void
    #
    uninit: func {
        if (g_VersionChecker != nil) {
            g_VersionChecker.del();
        }

        Profiler.clear();
    },

    #
    # Delay loading the entire Canvas add-on to avoid damaging aircraft displays such as A320, A330. The point is that,
    # for example, the A320 hard-coded the texture index from /canvas/by-index/texture[15]. But this add-on may creates
    # its canvas textures earlier than the airplane, which will cause that at index 15 there will be no texture of some
    # display but the texture from the add-on. So thanks to this delay, the textures of the plane will be created first,
    # and then the textures of this add-on.
    #
    # @param  func  callback
    # @return void
    #
    _delayCanvasLoading: func(callback) {
        # Disable menu items responsible for launching persistent dialogs.
        var menu = MenuStateHandler.new();
        menu.toggleItems(false);

        Timer.singleShot(3, func {
            callback();

            # Enable menu items responsible for launching persistent dialogs.
            var excluded = Application.callHook('excludedMenuNamesForEnabled', {});

            menu.toggleItems(true, excluded);
        });
    },
};
