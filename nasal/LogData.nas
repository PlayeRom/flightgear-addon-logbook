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
    # @return hash
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
        return {
            parents           : [LogData],

            # Member names the same as in the database!
            date              : date,
            time              : time,
            sim_utc_date      : simUtcDate,
            sim_utc_time      : simUtcTime,
            sim_local_date    : simLocalDate,
            sim_local_time    : simLocalTime,
            aircraft          : aircraft,
            variant           : variant,
            aircraft_type     : aircraftType,
            callsign          : callsign,
            from              : from,
            to                : to,
            landing           : landing,
            crash             : crash,
            day               : day,
            night             : night,
            instrument        : instrument,
            multiplayer       : multiplayer,
            swift             : swift,
            duration          : duration,
            distance          : distance,
            fuel              : fuel,
            max_alt           : maxAlt,
            max_groundspeed_kt: maxGsKt,
            max_mach          : maxMach,
            note              : note,
        };
    },

    #
    # Set the take-off real date
    #
    # @param  string  date  Take-off date
    # @return hash
    #
    setRealDate: func(date) {
        me.date = date;
        Log.print("setDate = ", date);

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
    # @return hash
    #
    setRealTime: func(time) {
        me.time = time;
        Log.print("setTime = ", time);

        return me;
    },

    #
    # Set the take-off sim UTC date
    #
    # @param  string  date  Take-off date
    # @return hash
    #
    setSimUtcDate: func(date) {
        me.sim_utc_date = date;
        Log.print("setSimUtcDate = ", date);

        return me;
    },

    #
    # Set the take-off sim UTC time
    #
    # @param  string  time  Take-off time
    # @return hash
    #
    setSimUtcTime: func(time) {
        me.sim_utc_time = time;
        Log.print("setSimUtcTime = ", time);

        return me;
    },

    #
    # Set the take-off sim local date
    #
    # @param  string  date  Take-off date
    # @return hash
    #
    setSimLocalDate: func(date) {
        me.sim_local_date = date;
        Log.print("setSimLocalDate = ", date);

        return me;
    },

    #
    # Set the take-off sim local time
    #
    # @param  string  time  Take-off time
    # @return hash
    #
    setSimLocalTime: func(time) {
        me.sim_local_time = time;
        Log.print("setSimLocalTime = ", time);

        return me;
    },

    #
    # Set the primary aircraft from /sim/aircraft-dir
    #
    # @param  string  aircraft
    # @return hash
    #
    setAircraft: func(aircraft) {
        me.aircraft = aircraft;
        Log.print("setAircraft = ", me.aircraft);

        return me;
    },

    #
    # Set the aircraft variant as /sim/aircraft. If not exist then use /sim/aircraft-id.
    #
    # @param  string  aircraftId
    # @return hash
    #
    setVariant: func(aircraftId) {
        me.variant = aircraftId;
        Log.print("setVariant = ", me.variant);

        return me;
    },

    #
    # Set the aircraft type
    #
    # @param  string  type
    # @return hash
    #
    setAircraftType: func(type) {
        me.aircraft_type = type;
        Log.print("setAircraftType = ", me.aircraft_type);

        return me;
    },

    #
    # Set the callsign
    #
    # @param  string  callsign
    # @return hash
    #
    setCallsign: func(callsign) {
        me.callsign = me._getCsvSafeText(callsign);
        Log.print("setCallsign = ", me.callsign);

        return me;
    },

    #
    # Set the ICAO departure airport
    #
    # @param  string  from  ICAO departure airport
    # @return hash
    #
    setFrom: func(from) {
        me.from = from;
        Log.print("setFrom = ", from);

        return me;
    },

    #
    # Set the ICAO destination airport
    #
    # @param  string  to  ICAO destination airport
    # @return hash
    #
    setTo: func(to) {
        me.to = to;
        Log.print("setTo = ", to);

        return me;
    },

    #
    # Set flag that aircraft landed
    #
    # @return hash
    #
    setLanding: func() {
        me.landing = true;
        Log.print("setLanding = 1");

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
    # @return hash
    #
    setCrash: func() {
        me.crash = true;
        Log.print("setCrash = 1");

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
    # @return hash
    #
    setDay: func(day) {
        me.day = day;
        Log.print("setDay = ", day);
        me.setDuration();

        return me;
    },

    #
    # Set the total flight time during the night (in h)
    #
    # @param  double  night  Total flight time during the night (in h)
    # @return hash
    #
    setNight: func(night) {
        me.night = night;
        Log.print("setNight = ", night);
        me.setDuration();

        return me;
    },

    #
    # Set the total flight time during the IMC (in h)
    #
    # @param  double  instrument  Total flight time during the IMC (in h)
    # @return hash
    #
    setInstrument: func(instrument) {
        me.instrument = instrument;
        Log.print("setInstrument = ", instrument);

        return me;
    },

    #
    # Set the total flight time in multiplayer mode (hours)
    #
    # @param  double  multiplayer  Total flight time in multiplayer mode (hours)
    # @return hash
    #
    setMultiplayer: func(multiplayer) {
        me.multiplayer = multiplayer;
        Log.print("setMultiplayer = ", multiplayer);

        return me;
    },

    #
    # Set the total flight time with connection to swift (hours)
    #
    # @param  double  multiplayer  Total flight time with connection to swift (hours)
    # @return hash
    #
    setSwift: func(swift) {
        me.swift = swift;
        Log.print("setSwift = ", swift);

        return me;
    },

    #
    # Set the total flight time as sum of day and night
    #
    # @return hash
    #
    setDuration: func() {
        me.duration = me.day + me.night;
        Log.print("setDuration = ", me.duration);

        return me;
    },

    #
    # Set the distance traveled during the flight in nautical miles
    #
    # @param  double  distance  Distance traveled during the flight in nautical miles
    # @return hash
    #
    setDistance: func(distance) {
        me.distance = distance;
        Log.print("setDistance = ", distance);

        return me;
    },

    #
    # Set the amount of fuel used
    #
    # @param  double  fuel  Amount of fuel used
    # @return hash
    #
    setFuel: func(fuel) {
        me.fuel = fuel;
        Log.print("setFuel = ", fuel);

        return me;
    },

    #
    # Set the max altitude
    #
    # @param  double  maxAlt  Max altitude in feet
    # @return hash
    #
    setMaxAlt: func(maxAlt) {
        me.max_alt = maxAlt;
        Log.print("setMaxAlt = ", maxAlt);

        return me;
    },

    #
    # Set the max groundspeed in knots
    #
    # @param  double  maxGsKt  Max groundspeed in knots
    # @return hash
    #
    setMaxGroundspeedKt: func(maxGsKt) {
        me.max_groundspeed_kt = maxGsKt;
        Log.print("setMaxGroundspeedKt = ", maxGsKt);

        return me;
    },

    #
    # Set the max speed in Mach number
    #
    # @param  double  maxMach  Max speed in Mach number
    # @return hash
    #
    setMaxMach: func(maxMach) {
        me.max_mach = maxMach;
        Log.print("setMaxMach = ", maxMach);

        return me;
    },

    #
    # Set the note
    #
    # @param  string  note
    # @return hash
    #
    setNote: func(note) {
        me.note = me._getCsvSafeText(note);
        Log.print("setNote = ", me.note);

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
    # Convert LogData to vector for using in LogbookList widget (only for CSV)
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
    # Apply given row hash from DB to this object and return vector of columns for LogbookList widget
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
        elsif (columnName == Columns.SIM_UTC_DATE) return me._getSimUtcYear();
        elsif (columnName == Columns.SIM_LOC_DATE) return me._getSimLocalYear();
        elsif (columnName == Columns.AIRCRAFT)     return me.aircraft;
        elsif (columnName == Columns.VARIANT)      return me.variant;
        elsif (columnName == Columns.AC_TYPE)      return me.aircraft_type;
        elsif (columnName == Columns.CALLSIGN)     return me.callsign;
        elsif (columnName == Columns.FROM)         return me.from;
        elsif (columnName == Columns.TO)           return me.to;
        elsif (columnName == Columns.LANDING)      return me.printLanding();
        elsif (columnName == Columns.CRASH)        return me.printCrash();

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
