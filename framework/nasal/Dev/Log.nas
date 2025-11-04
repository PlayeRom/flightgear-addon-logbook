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
# MY_LOG_LEVEL is using in Log.print() to quickly change all logs visibility used in addon's namespace.
# This variable can be set in the `.env` file using `MY_LOG_LEVEL`, so you should not modify the code here.
# Possible values: LOG_ALERT, LOG_WARN, LOG_INFO, LOG_DEBUG, LOG_BULK.
#
var MY_LOG_LEVEL = LOG_INFO;

#
# Log class with own log format.
#
var Log = {
    #
    # Colors for texts in console:
    #
    _RED   : '31',
    _GREEN : '32',
    _YELLOW: '33',

    #
    # Print log with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    print: func(msgs...) {
        logprint(MY_LOG_LEVEL, me._getFullMessage(msgs));
    },

    #
    # Print success log (in green color) with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    success: func(msgs...) {
        me._green(msgs);
    },

    #
    # Print error log (in red color) with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    error: func(msgs...) {
        me._red(msgs);
    },

    #
    # Print log in red color with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    printRed: func(msgs...) {
        me._red(msgs);
    },

    #
    # Print log in green color with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    printGreen: func(msgs...) {
        me._green(msgs);
    },

    #
    # Print log in yellow color with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    printYellow: func(msgs...) {
        me._yellow(msgs);
    },

    #
    # Print log with ALERT level, which means the log will always be printed.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    alert: func(msgs...) {
        logprint(LOG_ALERT, me._getFullMessage(msgs));
    },

    #
    # Get full log message.
    #
    # @param  vector  msgs
    # @return string
    #
    _getFullMessage: func(msgs) {
        return g_Addon.name ~ ' ----- ' ~ me._join(msgs);
    },

    #
    # Print log message in red color.
    #
    # @param  vector  msgs
    # @return void
    #
    _red: func(msgs) {
        logprint(MY_LOG_LEVEL, globals.string.color(me._RED, me._getFullMessage(msgs)));
    },

    #
    # Print log message in green color.
    #
    # @param  vector  msgs
    # @return void
    #
    _green: func(msgs) {
        logprint(MY_LOG_LEVEL, globals.string.color(me._GREEN, me._getFullMessage(msgs)));
    },

    #
    # Print log message in yellow color.
    #
    # @param  vector  msgs
    # @return void
    #
    _yellow: func(msgs) {
        logprint(MY_LOG_LEVEL, globals.string.color(me._YELLOW, me._getFullMessage(msgs)));
    },

    #
    # Join vector elements to one string.
    #
    # @param  vector  msgs
    # @return string
    #
    _join: func(msgs) {
        var str = '';
        foreach (var msg; msgs) {
            if (msg == nil) {
                msg = 'nil';
            }

            str ~= msg;
        }

        return str;
    },
};
