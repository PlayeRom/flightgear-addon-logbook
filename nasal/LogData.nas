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
    # return me
    #
    new: func () {
        var me = { parents: [LogData] };

        me.date         = "";    # Take-off date (real)
        me.time         = "";    # Take-off time (real)
        me.aircraft     = "";    # Aircraft ID
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
    # string date - Take-off date
    # return me
    #
    setDate: func (date) {
        me.date = date;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDate = ", date);

        return me;
    },

    #
    # Get only year from date
    #
    # return string
    #
    getYear: func() {
        return substr(me.date, 0, 4);
    },

    #
    # Set the take-off time
    #
    # string time - Take-off time
    # return me
    #
    setTime: func (time) {
        me.time = time;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setTime = ", time);

        return me;
    },

    #
    # Set the aircraft ID
    #
    # string aircraft - Aircraft ID
    # return me
    #
    setAircraft: func (aircraft) {
        me.aircraft = me.removeHangarName(aircraft);
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setAircraft = ", me.aircraft);

        return me;
    },

    #
    # Set the aircraft type
    #
    # string type
    # return me
    #
    setAircraftType: func (type) {
        me.aircraftType = type;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setAircraftType = ", me.aircraftType);

        return me;
    },

    #
    # Remove hangar name from aircraft ID
    #
    # string aircraft - Aircraft ID probably with hangar name
    # return string - Aircraft ID without hangar name
    #
    removeHangarName: func(aircraft) {
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
    # string callsign
    # return me
    #
    setCallsign: func(callsign) {
        me.callsign = callsign;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setCallsign = ", callsign);

        return me;
    },

    #
    # Set the ICAO departure airport
    #
    # string from - ICAO departure airport
    # return me
    #
    setFrom: func(from) {
        me.from = from;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setFrom = ", from);

        return me;
    },

    #
    # Set the ICAO destination airport
    #
    # string to - ICAO destination airport
    # return me
    #
    setTo: func(to) {
        me.to = to;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setTo = ", to);

        return me;
    },

    #
    # Set flag that aircraft landed
    #
    # return me
    #
    setLanding: func() {
        me.landings = 1;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setLanding = 1");

        return me;
    },

    #
    # Set flag that aircraft crashed
    #
    # return me
    #
    setCrash: func() {
        me.crash = true;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setCrash = 1");

        return me;
    },

    #
    # Get crash flag state as a value to save to the file
    #
    # return string
    #
    printCrash: func() {
        return me.crash ? "1" : "";
    },

    #
    # Set the total flight time during the day (in h)
    #
    # double day - Total flight time during the day (in h)
    # return me
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
    # double night - Total flight time during the night (in h)
    # return me
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
    # double instrument - Total flight time during the IMC (in h)
    # return me
    #
    setInstrument: func(instrument) {
        me.instrument = instrument;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setInstrument = ", instrument);

        return me;
    },

    #
    # Set the total flight time as sum of day and night
    # return me
    #
    setDuration: func() {
        me.duration = me.day + me.night;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDuration = ", me.duration);

        return me;
    },

    #
    # Set the distance traveled during the flight in nautical miles
    #
    # double distance - distance traveled during the flight in nautical miles
    # return me
    #
    setDistance: func (distance) {
        me.distance = distance;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDistance = ", distance);

        return me;
    },

    #
    # Set the amount of fuel used
    #
    # double fuel - amount of fuel used
    # return me
    #
    setFuel: func (fuel) {
        me.fuel = fuel;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setFuel = ", fuel);

        return me;
    },

    #
    # Set the max altitude
    #
    # double maxAlt - max altitude in feets
    # return me
    #
    setMaxAlt: func (maxAlt) {
        me.maxAlt = maxAlt;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setMaxAlt = ", maxAlt);

        return me;
    },

    #
    # Set the note
    #
    # string note - note
    # return me
    #
    setNote: func (note) {
        me.note = note;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setNote = ", note);

        return me;
    },

    #
    # Convert hash to vector
    #
    # return vector
    #
    toVector: func() {
        var vector = [];
        append(vector, me.date);
        append(vector, me.time);
        append(vector, me.aircraft);
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
    # vector items
    # return void
    #
    fromVector: func(items) {
        me.date         = items[0];
        me.time         = items[1];
        me.aircraft     = items[2];
        me.aircraftType = items[3];
        me.callsign     = items[4];
        me.from         = items[5];
        me.to           = items[6];
        me.landings     = items[7];
        me.crash        = items[8] == "1" or items[8] == true ? true : false;
        me.day          = items[9];
        me.night        = items[10];
        me.instrument   = items[11];
        me.duration     = items[12];
        me.distance     = items[13];
        me.fuel         = items[14];
        me.maxAlt       = items[15];
        me.note         = items[16];
    },

    #
    # int index - Column index
    # return string|nil
    #
    getFilterValueByIndex: func(index) {
        if (index == File.INDEX_DATE) {
            return me.getYear();
        }
        else if (index == File.INDEX_AIRCRAFT) {
            return me.aircraft;
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
};
