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
    new: func () {
        var me = { parents: [LogData] };

        me.date       = "";    # Take-off date (real)
        me.time       = "";    # Take-off time (real)
        me.aircraft   = "";    # Aircraft ID
        me.callsign   = "";    # Pilot callsign
        me.from       = "";    # ICAO departure airport (if take-off from the ground)
        me.to         = "";    # ICAO destination airport (if landed)
        me.landings   = 0;     # Number of landings
        me.crash      = false; # 1 means that aircraft crashed
        me.day        = 0.0;   # Total flight time during the day (hours)
        me.night      = 0.0;   # Total flight time during the night (hours)
        me.instrument = 0.0;   # Total flight time during the IMC (hours)
        me.duration   = 0.0;   # Total flight time as sum of day and night (hours)
        me.distance   = 0.0;   # The distance traveled during the flight in nautical miles
        me.fuel       = 0.0;   # Amount of fuel used in US gallons
        me.maxAlt     = 0.0;   # The maximum altitude reached during the flight in feets
        me.note       = "";    # Full aircraft anme as default

        return me;
    },

    #
    # Set the take-off date
    #
    # string date - Take-off date
    #
    setDate: func (date) {
        me.date = date;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDate = ", date);

        return me;
    },

    #
    # Set the take-off time
    #
    # string time - Take-off time
    #
    setTime: func (time) {
        me.time = time;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setTime = ", time);

        return me;
    },

    #
    # Set the aircraft ID
    #
    # string id - Aircraft ID
    #
    setAircraft: func (aircraft) {
        me.aircraft = me.removeHangarName(aircraft);
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setAircraft = ", me.aircraft);

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
    #
    setTo: func(to) {
        me.to = to;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setTo = ", to);

        return me;
    },

    #
    # Set flag that aircraft landed
    #
    setLanding: func() {
        me.landings = 1;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setLanding = 1");

        return me;
    },

    #
    # Set flag that aircraft crashed
    #
    setCrash: func() {
        me.crash = true;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setCrash = 1");

        return me;
    },

    #
    # Get crash flag state as a value to save to the file
    #
    printCrash: func() {
        return me.crash ? "1" : "";
    },

    #
    # Set the total flight time during the day (in h)
    #
    # double day - Total flight time during the day (in h)
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
    #
    setInstrument: func(instrument) {
        me.instrument = instrument;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setInstrument = ", instrument);

        return me;
    },

    #
    # Set the total flight time as sum of day and night
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
    #
    setNote: func (note) {
        me.note = note;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setNote = ", note);

        return me;
    },
};
