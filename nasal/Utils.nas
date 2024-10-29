#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Utils static methods
#
var Utils = {
    #
    # Check that file already exists.
    # From FG 2024.x we have io.exists() but for older versions we have to write it ourselves.
    #
    # @param string path
    # @return bool
    #
    fileExists: func(path) {
        return io.stat(path) != nil;
    },

    #
    # Remove all quotes from given text and return a new text without quotes
    #
    # @param string text
    # @return string
    #
    removeQuotes: func(text) {
        return string.replace(text, '"', '');
    },

    #
    # @return bool  Return true if running on FG version 2024.x and later
    #
    isFG2024Version: func() {
        var fgVersion = getprop("/sim/version/flightgear");
        var (major, minor, patch) = split(".", fgVersion);
        return major >= 2024;
    },
};