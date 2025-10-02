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

    # This name doesn't matter, as long as no one writes it in the aircraft's tags:
    TERMINATE  : "logbook-terminate-mark",

    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [AircraftType] };

        me._tagsNode = props.globals.getNode("/sim/tags");

        me._tags = {};

        if (me._tagsNode != nil) {
            foreach (var tagNode; me._tagsNode.getChildren("tag")) {
                var tag = tagNode == nil ? nil : tagNode.getValue();
                if (tag != nil) {
                    me._tags[tag] = 1;
                }
            }
        }

        return me;
    },

    #
    # Get aircraft type according to tags
    #
    # @return string
    #
    getType: func() {
        var type = me._getTypeByTags();
        if (type != AircraftType.OTHERS) {
            return type;
        }

        return me._manualSelection();
    },

    #
    # Get aircraft type according to tags
    #
    # @return string
    #
    _getTypeByTags: func() {
        if (me._tagsNode == nil) {
            # No tags, nothing to check
            return AircraftType.OTHERS;
        }

        # The order of the tags matters because it determines what will be found first.
        var rules = [
            { tag: "helicopter",  value: AircraftType.HELICOPTER },
            { tag: "balloon",     value: AircraftType.BALLOON },
            { tag: "airship",     value: AircraftType.BALLOON },
            { tag: "spaceship",   value: AircraftType.SPACE },
            { tag: "seaplane",    value: AircraftType.SEAPLANE },
            { tag: "amphibious",  value: AircraftType.SEAPLANE },
            { tag: "fighter",     value: AircraftType.MILITARY },
            { tag: "interceptor", value: AircraftType.MILITARY },
            { tag: "combat",      value: AircraftType.MILITARY },
            { tag: "bomber",      value: AircraftType.MILITARY },
            { tag: "tanker",      value: AircraftType.MILITARY },
            { tag: "carrier",     value: AircraftType.MILITARY },
            { tag: "glider",      value: AircraftType.GLIDER },
            { tag: "turboprop",   value: AircraftType.TURBOPROP },
            { tag: "bizjet",      value: AircraftType.BIZJET },
            { tag: "business",    value: [
                { tag: "jet",                  value: AircraftType.BIZJET },
                { tag: AircraftType.TERMINATE, value: nil }, # nil = continue searching
            ]},
            { tag: "jet",         value: AircraftType.AIRLINER },
            { tag: "turbojet",    value: AircraftType.AIRLINER },
            { tag: "passenger",   value: [
                { tag: "4-engine",    value: AircraftType.AIRLINER },
                { tag: "four-engine", value: AircraftType.AIRLINER },
                { tag: "6-engine",    value: AircraftType.AIRLINER },
                { tag: "six-engine",  value: AircraftType.AIRLINER },
                { tag: AircraftType.TERMINATE, value: nil }, # nil = continue searching
            ]},
            { tag: "piston", value: [
                { tag: "single-engine",        value: AircraftType.GA_SINGLE },
                { tag: "1-engine",             value: AircraftType.GA_SINGLE },
                { tag: AircraftType.TERMINATE, value: AircraftType.GA_MULTI }, # If none of the above
            ]},
            { tag: "propeller", value: [
                { tag: "single-engine",        value: AircraftType.GA_SINGLE },
                { tag: "1-engine",             value: AircraftType.GA_SINGLE },
                { tag: AircraftType.TERMINATE, value: AircraftType.GA_MULTI }, # If none of the above
            ]},
        ];

        var type = me._getTypeByTagRules(rules);

        # Extra special conditions:
        if (type == AircraftType.SEAPLANE) {
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
            } elsif (aircraftId == "dhc2W") {
                var desc = getprop("/sim/description");
                if (string.match(desc, "*Wheels")) {
                    return AircraftType.GA_SINGLE;
                }
            }
        } elsif (type == AircraftType.GA_SINGLE) {
            var aircraftId = Aircraft.getAircraftId();
            if (   string.match(aircraftId, "*-float") # for c172p
                or string.match(aircraftId, "*-amphibious")
            ) {
                return AircraftType.SEAPLANE;
            }
        }

        return type;
    },

    #
    # @param  vector  rules  Vector of hashes with tag rules.
    # @return string
    #
    _getTypeByTagRules: func(rules) {
        foreach (var rule; rules) {
            if (!contains(me._tags, rule.tag)) {
                continue;
            }

            if (typeof(rule.value) == "vector") {
                foreach (var subRule; rule.value) {
                    if (contains(me._tags, subRule.tag)) {
                        return subRule.value;
                    }

                    if (subRule.tag == AircraftType.TERMINATE and subRule.value != nil) {
                        return subRule.value;
                    }
                }

                continue;
            }

            return rule.value;
        }

        return AircraftType.OTHERS;
    },

    #
    # Manual assignment of the type of known aircraft
    #
    # @return string
    #
    _manualSelection: func() {
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
    # Get vector with all types
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
