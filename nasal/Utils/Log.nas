#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Log class with own log format.
#
var Log = {
    #
    # Print log with MY_LOG_LEVEL.
    #
    # @param  vector  msg...  List of texts.
    # @return void
    #
    print: func(msg...) {
        logprint(MY_LOG_LEVEL, Log._getFullMessage(string.join("", msg)));
    },

    #
    # Print log with ALERT level.
    #
    # @param  vector  msg...  List of texts.
    # @return void
    #
    alert: func(msg...) {
        logprint(LOG_ALERT, Log._getFullMessage(string.join("", msg)));
    },

    #
    # Get full log message.
    #
    # @param  string  msg
    # @return string
    #
    _getFullMessage: func(msg) {
        return g_Addon.name ~ " ----- " ~ msg;
    },
};
