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
# Base Dev class.
# This is for development purposes only.
#
var DevBase = {
    #
    # Constructor.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @return hash
    #
    new: func(addon) {
        return {
            parents: [DevBase],
            _addon: addon,
        };
    },

    #
    # Print log with ALERT level.
    #
    # @param  vector  msg...  List of texts.
    # @return void
    #
    _printLog: func(msg...) {
        logprint(LOG_ALERT, me._addon.name, " ----- ", string.join("", msg));
    },
};
