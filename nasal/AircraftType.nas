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
# AircraftType class
#
var AircraftType = {
    #
    # Constants
    #
    HELICOPTER : "heli",
    BALLOON    : "balloon",   # including airships (zeppelins)
    SPACE      : "space",
    SEAPLANE   : "seaplane",  # including amphibious
    MILITARY   : "military",
    GLIDER     : "glider",    # including Parachutist
    TURBOPROP  : "turboprop",
    BIZJET     : "bizjet",
    AIRLINER   : "airliner",
    GA_SINGLE  : "ga-single", # small piston single-engine
    GA_MULTI   : "ga-multi",  # small piston multi-engine
    OTHERS     : "others",    # undefined or not recognized

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [AircraftType] };

        me.tagsNode = props.globals.getNode("/sim/tags");

        return me;
    },

    #
    # Get aircraft type according to tags
    #
    # @return string
    #
    getType: func() {
        var type = me.getTypeByTags();
        if (type != AircraftType.OTHERS) {
            return type;
        }

        return me.manualSelection();
    },

    #
    # Get aircraft type according to tags
    #
    # @return string
    #
    getTypeByTags: func() {
        if (me.tagsNode == nil) {
            # No tags, nothing to check
            return AircraftType.OTHERS;
        }

        if (me.searchTag({"or" : ["helicopter"], "and" : []})) {
            return AircraftType.HELICOPTER;
        }

        if (me.searchTag({"or" : ["balloon", "airship"], "and" : []})) {
            return AircraftType.BALLOON;
        }

        if (me.searchTag({"or" : ["spaceship"], "and" : []})) {
            return AircraftType.SPACE;
        }

        if (me.searchTag({"or" : ["seaplane", "amphibious"], "and" : []})) {
            # Handle exception where the aircraft has multiple versions i.e. with wheels and floats,
            # but tags are the same for all versions so it finds the seaplane when it has wheels.
            var aircraftId = Aircraft.getAircraftId();
            if (aircraftId == "dhc6") {
                var desc = getprop("/sim/description");
                if (   string.match(desc, "*Wheels")
                    or string.match(desc, "*Skis")
                ) {
                    return AircraftType.TURBOPROP;
                }
            }
            else if (aircraftId == "dhc2W") {
                var desc = getprop("/sim/description");
                if (string.match(desc, "*Wheels")) {
                    return AircraftType.GA_SINGLE;
                }
            }

            return AircraftType.SEAPLANE;
        }

        if (me.searchTag({"or" : ["fighter", "interceptor", "combat", "bomber", "tanker", "carrier"], "and" : []})) { # cargo, transport?
            return AircraftType.MILITARY;
        }

        if (me.searchTag({"or" : ["glider"], "and" : []})) {
            return AircraftType.GLIDER;
        }

        if (me.searchTag({"or" : ["turboprop"], "and" : []})) {
            return AircraftType.TURBOPROP;
        }

        if (me.searchTag({"or" : ["bizjet"], "and" : ["business", "jet"]})) {
            return AircraftType.BIZJET;
        }

        if (   me.searchTag({"or" : ["jet", "turbojet"], "and" : ["passenger", "4-engine"]})
            or me.searchTag({"or" : [],                  "and" : ["passenger", "four-engine"]})
            or me.searchTag({"or" : [],                  "and" : ["passenger", "6-engine"]})
            or me.searchTag({"or" : [],                  "and" : ["passenger", "six-engine"]})
        ) {
            return AircraftType.AIRLINER;
        }

        if (   me.searchTag({"or" : [], "and" : ["piston", "single-engine"]})
            or me.searchTag({"or" : [], "and" : ["piston", "1-engine"]})
            or me.searchTag({"or" : [], "and" : ["propeller", "single-engine"]})
            or me.searchTag({"or" : [], "and" : ["propeller", "1-engine"]})
        ) {
            var aircraftId = Aircraft.getAircraftId();
            if (   string.match(aircraftId, "*-float") # for c172p
                or string.match(aircraftId, "*-amphibious")
            ) {
                return AircraftType.SEAPLANE;
            }

            return AircraftType.GA_SINGLE;
        }

        if (me.searchTag({"or" : ["piston", "propeller"], "and" : []})) {
            return AircraftType.GA_MULTI;
        }

        return AircraftType.OTHERS;
    },

    #
    # Serach group of tags
    #
    # @param hash itemsToSearch - Hash with 2 key "or" and "and" indicated to the vectors of tags.
    #       Vector of "or" means that this function return true if at least one is found.
    #       Vector of "and" means that this function return true if all of them are found.
    #       Both vectors ("or" and "and") are working with "or" logic.
    # @return bool - Return true if tag or group of tags is found
    #
    searchTag: func(itemsToSearch) {
        var andCounter = 0;
        var andSize = size(itemsToSearch["and"]);

        foreach (var tagNode; me.tagsNode.getChildren("tag")) {
            var tag = tagNode.getValue();
            foreach (var search; itemsToSearch["or"]) {
                if (search == tag) {
                    return true;
                }
            }

            foreach (var search; itemsToSearch["and"]) {
                if (search == tag) {
                    andCounter += 1;
                }
            }
        }

        return andSize > 0 and andCounter == andSize;
    },

    #
    # Manual assignment of the type of known aircraft
    #
    # @return string
    #
    manualSelection: func() {
        var aircraftId = Aircraft.getAircraftId();

        if (substr(aircraftId, 0, 5) == "ask21" # ask21, ask21mi, ask21-jsb, ask21mi-jsb
            or aircraftId == "Perlan2"
            or aircraftId == "horsa"
            or aircraftId == "bocian"
            or aircraftId == "sportster"
        ) {
            return AircraftType.GLIDER;
        }

        if (string.match(aircraftId, "Embraer[0-9][0-9][0-9]") # Embraer170, Embraer175, Embraer190, Embraer195
            or aircraftId == "EmbraerLineage1000"
        ) {
            return AircraftType.AIRLINER;
        }

        if (aircraftId == "alphaelectro") {
            return AircraftType.GA_SINGLE;
        }

        return AircraftType.OTHERS;
    },

    #
    # Get vector for all types
    #
    # @return vector
    #
    getVector: func() {
        return [
            AircraftType.AIRLINER,
            AircraftType.BALLOON,
            AircraftType.BIZJET,
            AircraftType.GLIDER,
            AircraftType.GA_MULTI,
            AircraftType.GA_SINGLE,
            AircraftType.HELICOPTER,
            AircraftType.MILITARY,
            AircraftType.SEAPLANE,
            AircraftType.SPACE,
            AircraftType.TURBOPROP,
            AircraftType.OTHERS,
        ];
    },
};
