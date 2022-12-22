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
# Class LogData represent the row in the logbook.
#
var LogData = {
    #
    # Constructor
    #
    # @return me
    #
    new: func () {
        var me = { parents: [LogData] };

        me.date         = "";    # Take-off date (real)
        me.time         = "";    # Take-off time (real)
        me.aircraft     = "";    # Aircraft ID (/sim/aircraft-id)
        me.variant      = "";    # Aircraft variant (/sim/aircraft)
        me.aircraftType = "";    # Aircraft type
        me.callsign     = "";    # Pilot callsign
        me.from         = "";    # ICAO departure airport (if take-off from the ground)
        me.to           = "";    # ICAO destination airport (if landed)
        me.landings     = 0;     # Number of landings
        me.crash        = false; # 1 means that aircraft crashed
        me.day          = 0.0;   # Total flight time during the day (hours)
        me.night        = 0.0;   # Total flight time during the night (hours)
        me.instrument   = 0.0;   # Total flight time during the IMC (hours)
        me.duration     = 0.0;   # Total flight time as sum of day and night (hours)
        me.distance     = 0.0;   # The distance traveled during the flight in nautical miles
        me.fuel         = 0.0;   # Amount of fuel used in US gallons
        me.maxAlt       = 0.0;   # The maximum altitude reached during the flight in feets
        me.note         = "";    # Full aircraft name as default

        return me;
    },

    #
    # Set the take-off date
    #
    # @param string date - Take-off date
    # @return me
    #
    setDate: func (date) {
        me.date = date;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDate = ", date);

        return me;
    },

    #
    # Get only year from date
    #
    # @return string
    #
    getYear: func() {
        return substr(me.date, 0, 4);
    },

    #
    # Set the take-off time
    #
    # @param string time - Take-off time
    # @return me
    #
    setTime: func (time) {
        me.time = time;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setTime = ", time);

        return me;
    },

    #
    # Set the aircraft ID (/sim/aircraft-id)
    #
    # @return me
    #
    setAircraft: func () {
        me.aircraft = me.removeHangarName(getprop("/sim/aircraft-id"));
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setAircraft = ", me.aircraft);

        return me;
    },

    #
    # Set the aircraft variant as /sim/aircraft. If not exist then use /sim/aircraft-id.
    #
    # @return me
    #
    setVariant: func () {
        var aircraftId = me.removeHangarName(getprop("/sim/aircraft-id"));
        # When "/sim/aircraft" exists, this property contains the correct ID.
        # This is a case that can occur when an aircraft has multiple variants.
        var aircraft = me.removeHangarName(getprop("/sim/aircraft"));
        me.variant = aircraft == nil ? aircraftId : aircraft;

        logprint(MY_LOG_LEVEL, "Logbook Add-on - setVariant = ", me.variant);

        return me;
    },

    #
    # Set the aircraft type
    #
    # @param string type
    # @return me
    #
    setAircraftType: func (type) {
        me.aircraftType = type;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setAircraftType = ", me.aircraftType);

        return me;
    },

    #
    # Remove hangar name from aircraft ID
    #
    # @param string|nil aircraft - Aircraft ID probably with hangar name
    # @return string|nil - Aircraft ID without hangar name
    #
    removeHangarName: func(aircraft) {
        if (aircraft == nil) {
            return nil;
        }

        var aircraftLength = size(aircraft);

        # Known hangars
        var hangars = [
            "org.flightgear.fgaddon.stable_????.",
            "org.flightgear.fgaddon.trunk.",
        ];

        foreach (var pattern; hangars) {
            if (string.match(aircraft, pattern ~ "*")) {
                var urlLength = size(pattern);
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
    # Set the callsign
    #
    # @param string callsign
    # @return me
    #
    setCallsign: func(callsign) {
        me.callsign = me.getCsvSafeText(callsign);
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setCallsign = ", me.callsign);

        return me;
    },

    #
    # Set the ICAO departure airport
    #
    # @param string from - ICAO departure airport
    # @return me
    #
    setFrom: func(from) {
        me.from = from;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setFrom = ", from);

        return me;
    },

    #
    # Set the ICAO destination airport
    #
    # @param string to - ICAO destination airport
    # @return me
    #
    setTo: func(to) {
        me.to = to;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setTo = ", to);

        return me;
    },

    #
    # Set flag that aircraft landed
    #
    # @return me
    #
    setLanding: func() {
        me.landings = 1;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setLanding = 1");

        return me;
    },

    #
    # Set flag that aircraft crashed
    #
    # @return me
    #
    setCrash: func() {
        me.crash = true;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setCrash = 1");

        return me;
    },

    #
    # Get crash flag state as a value to save to the file
    #
    # @return string
    #
    printCrash: func() {
        return me.crash ? "1" : "";
    },

    #
    # Set the total flight time during the day (in h)
    #
    # @param double day - Total flight time during the day (in h)
    # @return me
    #
    setDay: func(day) {
        me.day = day;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDay = ", day);
        me.setDuration();

        return me;
    },

    #
    # Set the total flight time during the night (in h)
    #
    # @param double night - Total flight time during the night (in h)
    # @return me
    #
    setNight: func(night) {
        me.night = night;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setNight = ", night);
        me.setDuration();

        return me;
    },

    #
    # Set the total flight time during the IMC (in h)
    #
    # @param double instrument - Total flight time during the IMC (in h)
    # @return me
    #
    setInstrument: func(instrument) {
        me.instrument = instrument;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setInstrument = ", instrument);

        return me;
    },

    #
    # Set the total flight time as sum of day and night
    # @return me
    #
    setDuration: func() {
        me.duration = me.day + me.night;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDuration = ", me.duration);

        return me;
    },

    #
    # Set the distance traveled during the flight in nautical miles
    #
    # @param double distance - distance traveled during the flight in nautical miles
    # @return me
    #
    setDistance: func (distance) {
        me.distance = distance;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDistance = ", distance);

        return me;
    },

    #
    # Set the amount of fuel used
    #
    # @param double fuel - amount of fuel used
    # @return me
    #
    setFuel: func (fuel) {
        me.fuel = fuel;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setFuel = ", fuel);

        return me;
    },

    #
    # Set the max altitude
    #
    # @param double maxAlt - max altitude in feets
    # @return me
    #
    setMaxAlt: func (maxAlt) {
        me.maxAlt = maxAlt;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setMaxAlt = ", maxAlt);

        return me;
    },

    #
    # Set the note
    #
    # @param string note - note
    # @return me
    #
    setNote: func (note) {
        me.note = me.getCsvSafeText(note);
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setNote = ", me.note);

        return me;
    },

    #
    # @param string|nil text
    # @return string
    #
    getCsvSafeText: func(text) {
        if (text == nil or text == "") {
            return "";
        }

        text = string.replace(text, ',', ''); # remove , chars
        return string.replace(text, '"', ''); # remove " chars
    },

    #
    # Convert hash to vector
    #
    # @return vector
    #
    toVector: func() {
        var vector = [];
        append(vector, me.date);
        append(vector, me.time);
        append(vector, me.aircraft);
        append(vector, me.variant);
        append(vector, me.aircraftType);
        append(vector, me.callsign);
        append(vector, me.from);
        append(vector, me.to);
        append(vector, me.landings);
        append(vector, me.printCrash());
        append(vector, sprintf("%.02f", me.day));
        append(vector, sprintf("%.02f", me.night));
        append(vector, sprintf("%.02f", me.instrument));
        append(vector, sprintf("%.02f", me.duration));
        append(vector, sprintf("%.02f", me.distance));
        append(vector, sprintf("%.02f", me.fuel));
        append(vector, sprintf("%.0f", me.maxAlt));
        append(vector, me.note);

        return vector;
    },

    #
    # Apply given vector to this object
    #
    # @param vector items
    # @return void
    #
    fromVector: func(items) {
        me.date         = items[File.INDEX_DATE];
        me.time         = items[File.INDEX_TIME];
        me.aircraft     = items[File.INDEX_AIRCRAFT];
        me.variant      = items[File.INDEX_VARIANT];
        me.aircraftType = items[File.INDEX_TYPE];
        me.callsign     = items[File.INDEX_CALLSIGN];
        me.from         = items[File.INDEX_FROM];
        me.to           = items[File.INDEX_TO];
        me.landings     = items[File.INDEX_LANDINGS];
        me.crash        = items[File.INDEX_CRASH] == "1" or items[File.INDEX_CRASH] == true ? true : false;
        me.day          = items[File.INDEX_DAY];
        me.night        = items[File.INDEX_NIGHT];
        me.instrument   = items[File.INDEX_INSTRUMENT];
        me.duration     = items[File.INDEX_DURATION];
        me.distance     = items[File.INDEX_DISTANCE];
        me.fuel         = items[File.INDEX_FUEL];
        me.maxAlt       = items[File.INDEX_MAX_ALT];
        me.note         = items[File.INDEX_NOTE];
    },

    #
    # @param int index - Column index
    # @return string|nil
    #
    getFilterValueByIndex: func(index) {
        if (index == File.INDEX_DATE) {
            return me.getYear();
        }
        else if (index == File.INDEX_AIRCRAFT) {
            return me.aircraft;
        }
        else if (index == File.INDEX_VARIANT) {
            return me.variant;
        }
        else if (index == File.INDEX_TYPE) {
            return me.aircraftType;
        }
        else if (index == File.INDEX_CALLSIGN) {
            return me.callsign;
        }
        else if (index == File.INDEX_FROM) {
            return me.from;
        }
        else if (index == File.INDEX_TO) {
            return me.to;
        }
        else if (index == File.INDEX_LANDINGS) {
            return me.landings;
        }
        else if (index == File.INDEX_CRASH) {
            return me.printCrash();
        }

        return nil;
    },

    #
    # Get copy object of me
    #
    # @return hash - LogData object
    #
    getClone: func() {
        var clone = LogData.new();
        clone.date         = me.date;
        clone.time         = me.time;
        clone.aircraft     = me.aircraft;
        clone.variant      = me.variant;
        clone.aircraftType = me.aircraftType;
        clone.callsign     = me.callsign;
        clone.from         = me.from;
        clone.to           = me.to;
        clone.landings     = me.landings;
        clone.crash        = me.crash;
        clone.day          = me.day;
        clone.night        = me.night;
        clone.instrument   = me.instrument;
        clone.duration     = me.duration;
        clone.distance     = me.distance;
        clone.fuel         = me.fuel;
        clone.maxAlt       = me.maxAlt;
        clone.note         = me.note;

        return clone;
    },
};
