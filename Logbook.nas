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
# The flags like LOG_ALERT, LOG_INFO etc. are available from FG 2020.1.
#
var MY_LOG_LEVEL = LOG_INFO;

var ADDON_ID = "org.flightgear.addons.logbook";

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
# Initialize Logbook
#
# @param hash addon - addons.Addon object
# @return void
#
var init = func(addon) {
    g_Addon = addon;

    # Disable Logbook menu because we have to load data first in thread
    gui.menuEnable("logbook-addon", false);
    gui.menuEnable("logbook-addon-flight-analysis", false);

    # Disable others menus because of delayTimer
    gui.menuEnable("logbook-addon-help", false);
    gui.menuEnable("logbook-addon-about", false);

    g_Settings = Settings.new();
    g_Sound    = Sound.new();

    # Delay loading of the whole addon so as not to break the MCDUs for aircraft like A320, A330. The point is that,
    # for example, the A320 hard-coded the texture index from /canvas/by-index/texture[15]. But this add-on creates its
    # canvas textures earlier than the airplane, which will cause that at index 15 there will be no MCDU texture but
    # the texture from the add-on. So thanks to this delay, the textures of the plane will be created first, and then
    # the textures of this add-on.
    var delayTimer = maketimer(3, func() {
        g_Logbook = Logbook.new();

        gui.menuEnable("logbook-addon-flight-analysis", true);
        gui.menuEnable("logbook-addon-help", true);
        gui.menuEnable("logbook-addon-about", true);
    });
    delayTimer.singleShot = true;
    delayTimer.start();
};

#
# Uninitialize Logbook
#
# @return void
#
var uninit = func() {
    if (g_Logbook != nil) {
        g_Logbook.del();
    }

    if (g_Sound != nil) {
        g_Sound.del();
    }

    if (g_Settings != nil) {
        g_Settings.del();
    }
};
