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
# Aircraft class
#
var Aircraft = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func {
        return { parents: [Aircraft] };
    },

    #
    # Get primary aircraft name read from directory name
    #
    # @return string
    #
    getAircraftPrimary: func {
        var dirSplit = split("/", utf8.substr(getprop("/sim/aircraft-dir"), 0));
        var length = size(dirSplit);
        if (length > 0) {
            return dirSplit[length - 1];
        }

        return me.getAircraftId();
    },

    #
    # Get the exact aircraft name as its unique ID (variant)
    #
    # @return string
    #
    getAircraftId: func {
        # When "/sim/aircraft" exists, this property contains the correct ID.
        # This is a case that can occur when an aircraft has multiple variants.
        var aircraft = me._removeHangarName(getprop("/sim/aircraft"));
        return aircraft == nil
            ? me._removeHangarName(getprop("/sim/aircraft-id"))
            : aircraft;
    },

    #
    # Remove hangar name from aircraft ID
    #
    # @param  string|nil  aircraft  Aircraft ID probably with hangar name
    # @return string|nil  Aircraft ID without hangar name
    #
    _removeHangarName: func(aircraft) {
        if (aircraft == nil) {
            return nil;
        }

        var aircraftLength = size(aircraft);

        # Known hangars
        var hangarPatterns = [
            "org.flightgear.fgaddon.stable_????.*",
            "org.flightgear.fgaddon.trunk.*",
            "de.djgummikuh.hangar.octal450.*",
            "de.djgummikuh.hangar.fgmembers.*",
            "de.djgummikuh.hangar.oprf.*",
            "de.djgummikuh.hangar.*",
            "com.gitlab.fg_shfsn.hangar.*",
            "www.daveshangar.org.*",
            "www.seahorsecorral.org.*",
        ];

        foreach (var pattern; hangarPatterns) {
            if (string.match(aircraft, pattern)) {
                var urlLength = size(pattern) - 1; # minus 1 for not count `*` char
                return substr(aircraft, urlLength, aircraftLength - urlLength);
            }
        }

        # We're still not trim, so try to trim to the last dot (assumed that aircraft ID cannot has dot char)
        for (var i = aircraftLength - 1; i >= 0; i -= 1) {
            if (aircraft[i] == `.`) {
                return substr(aircraft, i + 1, aircraftLength - i);
            }
        }

        return aircraft;
    },

    #
    # Return true when aircraftId is UFO or FG Video Assistant
    #
    # @param  string  aircraftId
    # @return bool
    #
    isUfo: func(aircraftId) {
        return aircraftId == "ufo"
            or aircraftId == "mibs";
    },

    #
    # Return true when aircraftPrimary is SpaceShuttle
    #
    # @param  string  aircraftPrimary
    # @return bool
    #
    isSpaceShuttle: func(aircraftPrimary) {
        return aircraftPrimary == "SpaceShuttle";
    },
};
