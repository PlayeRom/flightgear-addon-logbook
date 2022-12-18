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
# Global aliases for boolean types to distinguish the use of "int" from "bool".
# NOTE: unfortunately, it doesn't work as an assignment of a default value for a function parameter!
#
var true  = 1;
var false = 0;

#
# MY_LOG_LEVEL is using in logprint() to quickly change all logs visibility used in "logbook" namespace.
# The flags like LOG_ALERT, LOG_INFO etc. are available from FG 2020.1.
#
var MY_LOG_LEVEL = LOG_INFO;

var ADDON_ID = "org.flightgear.addons.logbook";

#
# Global object of Logbook
#
var g_Logbook = nil;

#
# This flag indicates that a separate thread is running (for loading data) and
# other actions should be temporarily blocked.
#
var g_isThreadPanding = false;

#
# Initialize Logbook
#
# addon - Addon object
#
var init = func (addon) {
    g_Logbook = Logbook.new(addon);
}

#
# Uninitialize Logbook
#
var uninit = func () {
    if (g_Logbook != nil) {
        g_Logbook.del();
    }
}
