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
    # @param  string  path
    # @return bool
    #
    fileExists: func(path) {
        return io.stat(path) != nil;
    },

    #
    # Remove all quotes from given text and return a new text without quotes
    #
    # @param  string  text
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

    #
    # Return true when Storage is using SQLite instead of CSV file
    #
    # @return bool
    #
    isUsingSQLite: func() {
        return Utils.isFG2024Version();
    },

    #
    # Check if the given string contains a space
    #
    # @param  string  text
    # @return bool
    #
    isSpace: func(text) {
        var parts = split(" ", text);
        return size(parts) > 1;
    },

    #
    # Convert value to string
    #
    # @param  string|int|double  value
    # @return string
    #
    toString: func(value) {
        return sprintf("%s", value);
    },

    #
    # Convert decimal hours to hours:minutes:seconds, e.g. 1.5 -> 1:30
    #
    # @param  double|string  hoursDecimal
    # @return string
    #
    decimalHoursToHuman: func(decimalHours) {
        var hours = math.floor(decimalHours);
        var fractionalPart = decimalHours - hours;

        var minutes = math.floor(fractionalPart * 60);
        var seconds = math.floor((fractionalPart * 60 - minutes) * 60);

        return sprintf("%d:%02.0f:%02.0f", hours, minutes, seconds);
    },
};