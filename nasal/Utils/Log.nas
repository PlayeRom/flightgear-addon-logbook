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
# Log class with own log format.
#
var Log = {
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
