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
    # Print error log (in red color) with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    error: func(msgs...) {
        me._red(MY_LOG_LEVEL, msgs);
    },

    #
    # Print success log (in green color) with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    success: func(msgs...) {
        me._green(MY_LOG_LEVEL, msgs);
    },

    #
    # Print error log (in yellow color) with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    warning: func(msgs...) {
        me._yellow(MY_LOG_LEVEL, msgs);
    },

    #
    # Print log in red color with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    printRed: func(msgs...) {
        me._red(MY_LOG_LEVEL, msgs);
    },

    #
    # Print log in green color with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    printGreen: func(msgs...) {
        me._green(MY_LOG_LEVEL, msgs);
    },

    #
    # Print log in yellow color with MY_LOG_LEVEL.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    printYellow: func(msgs...) {
        me._yellow(MY_LOG_LEVEL, msgs);
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
    # Print error log (in red color) with LOG_ALERT level.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    alertError: func(msgs...) {
        me._red(LOG_ALERT, msgs);
    },

    #
    # Print success log (in green color) with LOG_ALERT level.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    alertSuccess: func(msgs...) {
        me._green(LOG_ALERT, msgs);
    },

    #
    # Print error log (in yellow color) with LOG_ALERT level.
    #
    # @param  vector  msgs...  List of texts.
    # @return void
    #
    alertWarning: func(msgs...) {
        me._yellow(LOG_ALERT, msgs);
    },

    #
    # Print log message in red color.
    #
    # @param  int  level  Log level.
    # @param  vector  msgs
    # @return void
    #
    _red: func(level, msgs) {
        me._logColor(level, msgs, me._RED);
    },

    #
    # Print log message in green color.
    #
    # @param  int  level  Log level.
    # @param  vector  msgs
    # @return void
    #
    _green: func(level, msgs) {
        me._logColor(level, msgs, me._GREEN);
    },

    #
    # Print log message in yellow color.
    #
    # @param  int  level  Log level.
    # @param  vector  msgs
    # @return void
    #
    _yellow: func(level, msgs) {
        me._logColor(level, msgs, me._YELLOW);
    },

    #
    # Print log message with given color.
    #
    # @param  int  level  Log level.
    # @param  vector  msgs
    # @param  string  color
    # @return void
    #
    _logColor: func(level, msgs, color) {
        logprint(level, globals.string.color(color, me._getFullMessage(msgs)));
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
