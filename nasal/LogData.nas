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
    new: func(
        date         = "",  # Take-off date (real)
        time         = "",  # Take-off time (real)
        simUtcDate   = "",  # Take-off date (sim UTC)
        simUtcTime   = "",  # Take-off time (sim UTC)
        simLocalDate = "",  # Take-off date (sim local)
        simLocalTime = "",  # Take-off time (sim local)
        aircraft     = "",  # Primary aircraft from dir (/sim/aircraft-dir)
        variant      = "",  # Aircraft ID as a variant (/sim/aircraft)
        aircraftType = "",  # Aircraft type
        callsign     = "",  # Pilot callsign
        from         = "",  # ICAO departure airport (if take-off from the ground)
        to           = "",  # ICAO destination airport (if landed)
        landing      = 0,   # 1 (true) means that aircraft landed
        crash        = 0,   # 1 (true) means that aircraft crashed
        day          = 0.0, # Total flight time during the day (hours)
        night        = 0.0, # Total flight time during the night (hours)
        instrument   = 0.0, # Total flight time during the IMC (hours)
        multiplayer  = 0.0, # Total flight time in multiplayer mode (hours)
        swift        = 0.0, # Total flight time with connection to swift (hours)
        duration     = 0.0, # Total flight time as sum of day and night (hours)
        distance     = 0.0, # The distance traveled during the flight in nautical miles
        fuel         = 0.0, # Amount of fuel used in US gallons
        maxAlt       = 0.0, # The maximum altitude reached during the flight in feet
        maxGsKt      = 0.0, # The maximum groundspeed in knots
        maxMach      = 0.0, # The maximum speed in Mach number
        note         = "",  # Full aircraft name as default
    ) {
        var me = { parents: [LogData] };

        # Member names the same as in the database!
        me.date               = date;
        me.time               = time;
        me.sim_utc_date       = simUtcDate;
        me.sim_utc_time       = simUtcTime;
        me.sim_local_date     = simLocalDate;
        me.sim_local_time     = simLocalTime;
        me.aircraft           = aircraft;
        me.variant            = variant;
        me.aircraft_type      = aircraftType;
        me.callsign           = callsign;
        me.from               = from;
        me.to                 = to;
        me.landing            = landing;
        me.crash              = crash;
        me.day                = day;
        me.night              = night;
        me.instrument         = instrument;
        me.multiplayer        = multiplayer;
        me.swift              = swift;
        me.duration           = duration;
        me.distance           = distance;
        me.fuel               = fuel;
        me.max_alt            = maxAlt;
        me.max_groundspeed_kt = maxGsKt;
        me.max_mach           = maxMach;
        me.note               = note;

        return me;
    },

    #
    # Set the take-off real date
    #
    # @param  string  date  Take-off date
    # @return me
    #
    setRealDate: func(date) {
        me.date = date;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDate = ", date);

        return me;
    },

    #
    # Get only year from real date
    #
    # @return string
    #
    _getRealYear: func() {
        return substr(me.date, 0, 4);
    },

    #
    # Get only year from sim UTC date
    #
    # @return string
    #
    _getSimUtcYear: func() {
        return substr(me.sim_utc_date, 0, 4);
    },

    #
    # Get only year from sim local date
    #
    # @return string
    #
    _getSimLocalYear: func() {
        return substr(me.sim_local_date, 0, 4);
    },

    #
    # Set the take-off real time
    #
    # @param  string  time  Take-off time
    # @return me
    #
    setRealTime: func(time) {
        me.time = time;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setTime = ", time);

        return me;
    },

    #
    # Set the take-off sim UTC date
    #
    # @param  string  date  Take-off date
    # @return me
    #
    setSimUtcDate: func(date) {
        me.sim_utc_date = date;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setSimUtcDate = ", date);

        return me;
    },

    #
    # Set the take-off sim UTC time
    #
    # @param  string  time  Take-off time
    # @return me
    #
    setSimUtcTime: func(time) {
        me.sim_utc_time = time;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setSimUtcTime = ", time);

        return me;
    },

    #
    # Set the take-off sim local date
    #
    # @param  string  date  Take-off date
    # @return me
    #
    setSimLocalDate: func(date) {
        me.sim_local_date = date;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setSimLocalDate = ", date);

        return me;
    },

    #
    # Set the take-off sim local time
    #
    # @param  string  time  Take-off time
    # @return me
    #
    setSimLocalTime: func(time) {
        me.sim_local_time = time;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setSimLocalTime = ", time);

        return me;
    },

    #
    # Set the primary aircraft from /sim/aircraft-dir
    #
    # @param  string  aircraft
    # @return me
    #
    setAircraft: func(aircraft) {
        me.aircraft = aircraft;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setAircraft = ", me.aircraft);

        return me;
    },

    #
    # Set the aircraft variant as /sim/aircraft. If not exist then use /sim/aircraft-id.
    #
    # @param  string  aircraftId
    # @return me
    #
    setVariant: func(aircraftId) {
        me.variant = aircraftId;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setVariant = ", me.variant);

        return me;
    },

    #
    # Set the aircraft type
    #
    # @param  string  type
    # @return me
    #
    setAircraftType: func(type) {
        me.aircraft_type = type;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setAircraftType = ", me.aircraft_type);

        return me;
    },

    #
    # Set the callsign
    #
    # @param  string  callsign
    # @return me
    #
    setCallsign: func(callsign) {
        me.callsign = me._getCsvSafeText(callsign);
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setCallsign = ", me.callsign);

        return me;
    },

    #
    # Set the ICAO departure airport
    #
    # @param  string  from  ICAO departure airport
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
    # @param  string  to  ICAO destination airport
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
        me.landing = true;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setLanding = 1");

        return me;
    },

    #
    # Get landing flag state as a value to save to the file
    #
    # @return string
    #
    printLanding: func() {
        return me.landing ? "1" : "";
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
    # @param  double  day  Total flight time during the day (in h)
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
    # @param  double  night  Total flight time during the night (in h)
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
    # @param  double  instrument  Total flight time during the IMC (in h)
    # @return me
    #
    setInstrument: func(instrument) {
        me.instrument = instrument;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setInstrument = ", instrument);

        return me;
    },

    #
    # Set the total flight time in multiplayer mode (hours)
    #
    # @param  double  multiplayer  Total flight time in multiplayer mode (hours)
    # @return me
    #
    setMultiplayer: func(multiplayer) {
        me.multiplayer = multiplayer;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setMultiplayer = ", multiplayer);

        return me;
    },

    #
    # Set the total flight time with connection to swift (hours)
    #
    # @param  double  multiplayer  Total flight time with connection to swift (hours)
    # @return me
    #
    setSwift: func(swift) {
        me.swift = swift;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setSwift = ", swift);

        return me;
    },

    #
    # Set the total flight time as sum of day and night
    #
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
    # @param  double  distance  Distance traveled during the flight in nautical miles
    # @return me
    #
    setDistance: func(distance) {
        me.distance = distance;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setDistance = ", distance);

        return me;
    },

    #
    # Set the amount of fuel used
    #
    # @param  double  fuel  Amount of fuel used
    # @return me
    #
    setFuel: func(fuel) {
        me.fuel = fuel;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setFuel = ", fuel);

        return me;
    },

    #
    # Set the max altitude
    #
    # @param  double  maxAlt  Max altitude in feet
    # @return me
    #
    setMaxAlt: func(maxAlt) {
        me.max_alt = maxAlt;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setMaxAlt = ", maxAlt);

        return me;
    },

    #
    # Set the max groundspeed in knots
    #
    # @param  double  maxGsKt  Max groundspeed in knots
    # @return me
    #
    setMaxGroundspeedKt: func(maxGsKt) {
        me.max_groundspeed_kt = maxGsKt;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setMaxGroundspeedKt = ", maxGsKt);

        return me;
    },

    #
    # Set the max speed in Mach number
    #
    # @param  double  maxMach  Max speed in Mach number
    # @return me
    #
    setMaxMach: func(maxMach) {
        me.max_mach = maxMach;
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setMaxMach = ", maxMach);

        return me;
    },

    #
    # Set the note
    #
    # @param  string  note
    # @return me
    #
    setNote: func(note) {
        me.note = me._getCsvSafeText(note);
        logprint(MY_LOG_LEVEL, "Logbook Add-on - setNote = ", me.note);

        return me;
    },

    #
    # @param  string|nil  text
    # @return string
    #
    _getCsvSafeText: func(text) {
        if (text == nil or text == "") {
            return "";
        }

        text = string.replace(text, ',', ''); # remove , chars
        return string.replace(text, '"', ''); # remove " chars
    },

    #
    # Convert LogData to vector using all columns (only for CSV)
    #
    # @param  hash  columns  Columns object
    # @return vector
    #
    toVector: func(columns) {
        var vector = [];

        foreach (var columnItem; columns.getAll()) {
            append(vector, me._formatData(columnItem.name));
        }

        return vector;
    },

    #
    # Convert LogData to vector for using in ListView widget (only for CSV)
    #
    # @param  hash  columns  Columns object
    # @return vector
    #
    toListViewColumns: func(columns) {
        var vector = [];

        foreach (var columnItem; columns.getAll()) {
            append(vector, {
                width  : columnItem.width,
                data   : me._formatData(columnItem.name),
            });
        }

        return vector;
    },

    #
    # Apply given vector to this object (only for CSV)
    #
    # @param  vector  items
    # @return void
    #
    fromVector: func(items) {
        me.date          = items[Storage.INDEX_DATE];
        me.time          = items[Storage.INDEX_TIME];
        me.aircraft      = items[Storage.INDEX_AIRCRAFT];
        me.variant       = items[Storage.INDEX_VARIANT];
        me.aircraft_type = items[Storage.INDEX_TYPE];
        me.callsign      = items[Storage.INDEX_CALLSIGN];
        me.from          = items[Storage.INDEX_FROM];
        me.to            = items[Storage.INDEX_TO];
        me.landing       = items[Storage.INDEX_LANDING] == 1;
        me.crash         = items[Storage.INDEX_CRASH] == 1;
        me.day           = items[Storage.INDEX_DAY];
        me.night         = items[Storage.INDEX_NIGHT];
        me.instrument    = items[Storage.INDEX_INSTRUMENT];
        me.multiplayer   = items[Storage.INDEX_MULTIPLAYER];
        me.swift         = items[Storage.INDEX_SWIFT];
        me.duration      = items[Storage.INDEX_DURATION];
        me.distance      = items[Storage.INDEX_DISTANCE];
        me.fuel          = items[Storage.INDEX_FUEL];
        me.max_alt       = items[Storage.INDEX_MAX_ALT];
        me.note          = items[Storage.INDEX_NOTE];
    },

    #
    # Apply given hash to this object (only for SQLite)
    #
    # @param  hash  row  Hash from DB with all columns
    # @return void
    #
    fromDb: func(row) {
        foreach (var key; keys(row)) {
            if (key == "id") {
                continue;
            }

            me[key] = row[key];
        }
    },

    #
    # Apply given row hash from DB to this object and return vector of columns for ListView widget
    #
    # @param  hash  row  Hash from DB, not all columns can be included here, depending on SELECT in SQL query
    # @param  hash  columns  Columns object
    # @return vector
    #
    fromDbToListViewColumns: func(row, columns) {
        var vector = [];

        foreach (var columnItem; columns.getAll()) {
            if (contains(row, columnItem.name)) {
                me[columnItem.name] = row[columnItem.name];

                append(vector, {
                    width  : columnItem.width,
                    data   : me._formatData(columnItem.name),
                });
            }
        }

        return vector;
    },

    #
    # Get formatted data to display in LogbookDialog
    #
    # @param  string  columnName
    # @return string|double|int
    #
    _formatData: func(columnName) {
        if (columnName == Columns.LANDING) {
            return me.printLanding();
        }
        elsif (columnName == Columns.CRASH) {
            return me.printCrash();
        }
        elsif (columnName == Columns.DAY
            or columnName == Columns.NIGHT
            or columnName == Columns.INSTRUMENT
            or columnName == Columns.MULTIPLAYER
            or columnName == Columns.SWIFT
            or columnName == Columns.DURATION
            or columnName == Columns.DISTANCE
            or columnName == Columns.FUEL
        ) {
            return sprintf("%.02f", me[columnName]);
        }
        elsif (columnName == Columns.MAX_ALT) {
            return sprintf("%.0f",  me.max_alt);
        }
        elsif (columnName == Columns.MAX_GS_KT) {
            return sprintf("%.0f",  me.max_groundspeed_kt);
        }
        elsif (columnName == Columns.MAX_MACH) {
            return sprintf("%.02f",  me.max_mach);
        }

        return me[columnName];
    },

    #
    # Get value for filters
    #
    # @param  string  columnName  Column name
    # @return string|nil
    #
    getFilterValueByColumnName: func(columnName) {
             if (columnName == Columns.DATE)         return me._getRealYear();
        else if (columnName == Columns.SIM_UTC_DATE) return me._getSimUtcYear();
        else if (columnName == Columns.SIM_LOC_DATE) return me._getSimLocalYear();
        else if (columnName == Columns.AIRCRAFT)     return me.aircraft;
        else if (columnName == Columns.VARIANT)      return me.variant;
        else if (columnName == Columns.AC_TYPE)      return me.aircraft_type;
        else if (columnName == Columns.CALLSIGN)     return me.callsign;
        else if (columnName == Columns.FROM)         return me.from;
        else if (columnName == Columns.TO)           return me.to;
        else if (columnName == Columns.LANDING)      return me.printLanding();
        else if (columnName == Columns.CRASH)        return me.printCrash();

        return nil;
    },

    #
    # Get copy object of me
    #
    # @return hash  LogData object
    #
    getClone: func() {
        return LogData.new(
            me.date,
            me.time,
            me.sim_utc_date,
            me.sim_utc_time,
            me.sim_local_date,
            me.sim_local_time,
            me.aircraft,
            me.variant,
            me.aircraft_type,
            me.callsign,
            me.from,
            me.to,
            me.landing,
            me.crash,
            me.day,
            me.night,
            me.instrument,
            me.multiplayer,
            me.swift,
            me.duration,
            me.distance,
            me.fuel,
            me.max_alt,
            me.max_groundspeed_kt,
            me.max_mach,
            me.note,
        );
    },
};
