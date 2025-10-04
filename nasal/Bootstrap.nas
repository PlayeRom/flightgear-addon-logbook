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
# MY_LOG_LEVEL is using in logprint() to quickly change all logs visibility used in "logbook" namespace.
# Possible flags: LOG_ALERT, LOG_WARN, LOG_INFO, LOG_DEBUG, LOG_BULK.
#
var MY_LOG_LEVEL = LOG_INFO;

#
# Global object of addons.Addon
#
var g_Addon = nil;

#
# Global object of Settings
#
var g_Settings = nil;

#
# Global object of Sound
#
var g_Sound = nil;

#
# Global object of Logbook
#
var g_Logbook = nil;

#
# This flag indicates that a separate thread is running (for loading data) and
# other actions should be temporarily blocked.
#
var g_isThreadPending = false;

#
# Create objects from add-on namespace.
#
var Bootstrap = {
    #
    # Initialize objects from add-on namespace.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @return void
    #
    init: func(addon) {
        g_Addon = addon;

        # Create $FG_HOME/Export/Addons/org.flightgear.addons.logbook directory
        g_Addon.createStorageDir();

        Bootstrap._initDevMode();

        # Disable Logbook menu because we have to load data first in thread
        gui.menuEnable("logbook-addon-main-dialog", false);
        gui.menuEnable("logbook-addon-flight-analysis", false);
        gui.menuEnable("logbook-addon-export-csv", false); # this will be enabled only on FG version >= 2024

        # Disable others menus because of delayTimer
        gui.menuEnable("logbook-addon-help", false);
        gui.menuEnable("logbook-addon-about", false);

        g_Settings = Settings.new();
        g_Sound    = Sound.new();

        # Delay loading of the whole addon so as not to break the MCDUs for aircraft like A320, A330. The point is that,
        # for example, the A320 hard-coded the texture index from /canvas/by-index/texture[15]. But this add-on creates
        # its canvas textures earlier than the airplane, which will cause that at index 15 there will be no MCDU texture
        # but the texture from the add-on. So thanks to this delay, the textures of the plane will be created first, and
        # then the textures of this add-on.
        Timer.singleShot(3, func() {
            g_Logbook = Logbook.new();

            gui.menuEnable("logbook-addon-flight-analysis", true);
            gui.menuEnable("logbook-addon-help", true);
            gui.menuEnable("logbook-addon-about", true);
        });
    },

    #
    # Uninitialize object from add-on namespace.
    #
    # @return void
    #
    uninit: func() {
        if (g_Logbook != nil) {
            g_Logbook.del();
        }

        if (g_Sound != nil) {
            g_Sound.del();
        }

        if (g_Settings != nil) {
            g_Settings.del();
        }
    },

    #
    # Handle development mode (.env file).
    #
    # @return void
    #
    _initDevMode: func() {
        var env = DevEnv.new();

        var logLevel = env.getValue("MY_LOG_LEVEL");
        if (logLevel != nil) {
            MY_LOG_LEVEL = logLevel;
        }

        g_isDevMode = env.getBoolValue("DEV_MODE");

        if (g_isDevMode) {
            var reloadMenu = DevReloadMenu.new();

            env.getBoolValue("RELOAD_MENU")
                ? reloadMenu.addMenu()
                : reloadMenu.removeMenu();

            DevReloadMultiKey.addMultiKeyCmd(env.getValue("RELOAD_MULTIKEY_CMD"));
        }
    },
};
