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
# StorageSQLite class to save logbook data to data base
#
var StorageSQLite = {
    #
    # Constants
    #
    LOGBOOK_FILE    : "logbook.sqlite",
    TABLE_LOGBOOKS  : "logbooks",
    TABLE_MIGRATIONS: "migrations",

    #
    # Constructor
    #
    # @param hash filters - Filters object
    # @return me
    #
    new: func(filters) {
        var me = {
            parents : [StorageSQLite],
            filters : filters,
        };

        me.filePath      = me.getPathToFile();
        me.dbHandler     = nil;
        me.loadedData    = [];
        me.headersData   = [
            'Date',
            'Time',
            'Aircraft',
            'Variant',
            'Type',
            'Callsign',
            'From',
            'To',
            'Landing',
            'Crash',
            'Day',
            'Night',
            'Instrument',
            'Multiplayer',
            'Swift',
            'Duration',
            'Distance',
            'Fuel',
            'Max Alt',
            'Note',
        ];
        me.withHeaders   = true;

        me.totals        = [];
        me.resetTotals();

        me.openDb();

        # Callback for return results of loadDataRange
        me.objCallback = nil;
        me.callback    = func;

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.closeDb();
    },

    #
    # @return string  Full path to sqlite file
    #
    getPathToFile: func() {
        return g_Addon.storagePath ~ "/" ~ StorageSQLite.LOGBOOK_FILE;
    },

    #
    # @return void
    #
    resetTotals: func() {
        # Total amount
        me.totals = [
            0, # Landing
            0, # Crash
            0, # Day
            0, # Night
            0, # Instrument
            0, # Multiplayer
            0, # Swift
            0, # Duration
            0, # Distance
            0, # Fuel
            0, # Max Alt
        ];
    },

    #
    # Open DB connection, create table if not exist and import data from CSV file
    #
    # @return void
    #
    openDb: func() {
        me.closeDb();

        me.dbHandler = sqlite.open(me.filePath);

        MigrationSQLite.new(me).migrate();
    },

    #
    # Close DB connection
    #
    closeDb: func() {
        if (me.dbHandler != nil) {
            sqlite.close(me.dbHandler);
            me.dbHandler = nil;
        }
    },

    #
    # Export logbook from SQLite to CSV file as a separate thread job
    #
    # @return void
    #
    exportToCsv: func() {
        thread.newthread(func { me._exportToCsv(); });
    },

    #
    # Export logbook from SQLite to CSV file
    #
    # @return void
    #
    _exportToCsv: func() {
        var year   = getprop("/sim/time/real/year");
        var month  = getprop("/sim/time/real/month");
        var day    = getprop("/sim/time/real/day");
        var hour   = getprop("/sim/time/real/hour");
        var minute = getprop("/sim/time/real/minute");
        var second = getprop("/sim/time/real/second");

        var csvFile = sprintf("%s/logbook-export-%d-%02d-%02d-%02d-%02d-%02d.csv", g_Addon.storagePath, year, month, day, hour, minute, second);

        var file = io.open(csvFile, "w");

        var headerRow = "";
        foreach (var header; me.headersData) {
            if (headerRow != "") {
                headerRow ~= ",";
            }

            if (Utils.isSpace(header)) {
                header = '"' ~ header ~ '"';
            }

            headerRow ~= header;
        }

        io.write(file, headerRow ~ "\n");

        var query = sprintf("SELECT * FROM %s", StorageSQLite.TABLE_LOGBOOKS);
        foreach (var row; sqlite.exec(me.dbHandler, query)) {
            var logData = LogData.new();
            logData.fromDb(row);

            io.write(file, sprintf(
                "%s,%s,\"%s\",%s,%s,%s,%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
                logData.date,
                logData.time,
                logData.aircraft,
                logData.variant,
                logData.aircraft_type,
                logData.callsign,
                logData.from,
                logData.to,
                logData.printLanding(),
                logData.printCrash(),
                logData.day,
                logData.night,
                logData.instrument,
                logData.multiplayer,
                logData.swift,
                logData.duration,
                logData.distance,
                logData.fuel,
                logData.max_alt,
                logData.note
            ));
        }

        io.close(file);

        gui.popupTip("Exported to file " ~ csvFile);
    },

    #
    # Store log data to DB
    #
    # @param  hash  logData  LogData object
    # @param  int  id|nill  Record ID for SQLite storage
    # @param  bool  onlyIO  Set true for execute only I/O operation on the file,
    #                       without rest of stuff (used only for CSV recovery)
    # @return void
    #
    saveLogData: func(logData, id = nil, onlyIO = 0) {
        id == nil
            ? me.addItem(logData) # insert
            : me.updateItem(logData, id); # update

        if (!onlyIO) {
            me.filters.append(logData);
            me.filters.sort();

            # Build where from filters
            var where = me.getWhereQueryFilters();
            me.updateTotalsValues(where);

            me.filters.dirty = true;
        }
    },

    #
    # Insert LogData into database
    #
    # @param  hash  logData  LogData object
    # @param  hash  db|nil  DB handler or nil
    # @return int|nil  ID of new record, or nil
    #
    addItem: func(logData, db = nil) {
        if (db == nil) {
            db = me.dbHandler;
        }

        var query = sprintf("INSERT INTO %s VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", StorageSQLite.TABLE_LOGBOOKS);
        var stmt = sqlite.prepare(db, query);
        sqlite.exec(db, stmt,
            logData.date,
            logData.time,
            logData.aircraft,
            logData.variant,
            logData.aircraft_type,
            logData.callsign,
            logData.from,
            logData.to,
            logData.landing,
            logData.crash,
            logData.day,
            logData.night,
            logData.instrument,
            logData.multiplayer,
            logData.swift,
            logData.duration,
            logData.distance,
            logData.fuel,
            logData.max_alt,
            logData.note,
        );

        var rows = sqlite.exec(db, "SELECT last_insert_rowid() AS id");
        if (size(rows)) {
            return rows[0].id;
        }

        return nil;
    },

    #
    # Update record with given ID
    #
    # @param  hash  logData  LogData object
    # @param  int  id  Record ID
    # @return void
    #
    updateItem: func(logData, id) {
        var query = sprintf("UPDATE %s
            SET `date` = ?,
                `time` = ?,
                `aircraft` = ?,
                `variant` = ?,
                `aircraft_type` = ?,
                `callsign` = ?,
                `from` = ?,
                `to` = ?,
                `landing` = ?,
                `crash` = ?,
                `day` = ?,
                `night` = ?,
                `instrument` = ?,
                `multiplayer` = ?,
                `swift` = ?,
                `duration` = ?,
                `distance` = ?,
                `fuel` = ?,
                `max_alt` = ?,
                `note` = ?
            WHERE id = ?", StorageSQLite.TABLE_LOGBOOKS);

        var stmt = sqlite.prepare(me.dbHandler, query);
        sqlite.exec(me.dbHandler, stmt,
            logData.date,
            logData.time,
            logData.aircraft,
            logData.variant,
            logData.aircraft_type,
            logData.callsign,
            logData.from,
            logData.to,
            logData.landing,
            logData.crash,
            logData.day,
            logData.night,
            logData.instrument,
            logData.multiplayer,
            logData.swift,
            logData.duration,
            logData.distance,
            logData.fuel,
            logData.max_alt,
            logData.note,
            id
        );
    },

    #
    # Convert row from DB to vector
    #
    # @param  hash  row  Row from table
    # @return vector
    #
    dbRowToVector: func(row) {
        var logData = LogData.new();
        logData.fromDb(row);
        return logData.toVector();
    },

    #
    # Load all data for filters
    #
    # @return void
    #
    loadAllData: func() {
        me.filters.clear();
        me.resetTotals();

        me.updateFilterData("date", StorageCsv.INDEX_DATE);
        me.updateFilterData("aircraft", StorageCsv.INDEX_AIRCRAFT);
        me.updateFilterData("variant", StorageCsv.INDEX_VARIANT);
        me.updateFilterData("aircraft_type", StorageCsv.INDEX_TYPE);
        me.updateFilterData("callsign", StorageCsv.INDEX_CALLSIGN);
        me.updateFilterData("`from`", StorageCsv.INDEX_FROM);
        me.updateFilterData("`to`", StorageCsv.INDEX_TO);
        me.updateFilterData("landing", StorageCsv.INDEX_LANDING);
        me.updateFilterData("crash", StorageCsv.INDEX_CRASH);

        # Un-dirty it, because this is the first loading and now everything is calculated, so the cache can be used
        me.filters.dirty = false;

        # Enable Logbook menu because we have a data
        gui.menuEnable("logbook-addon", true);

        logprint(MY_LOG_LEVEL, "Logbook Add-on - loadAllDataThread finished");
    },

    #
    # Update given filter with data from DB
    #
    # @param  string  columnName
    # @param  int  dataIndex
    # @return void
    #
    updateFilterData: func(columnName, dataIndex) {
        if (dataIndex == StorageCsv.INDEX_DATE) {
            columnName = "strftime('%Y', " ~ columnName ~ ")"; # get only a year from `date` column
        }

        # COLLATE NOCASE - ignore case sensitivity during sorting
        var frm = "
            SELECT
                DISTINCT %s AS value
            FROM %s
            ORDER BY value COLLATE NOCASE ASC";
        var query = sprintf(frm, columnName, StorageSQLite.TABLE_LOGBOOKS);
        var rows = sqlite.exec(me.dbHandler, query);

        foreach (var row; rows) {
            var value = dataIndex == StorageCsv.INDEX_DATE
                ? substr(row.value, 0, 4) # get year only
                : row.value;

            me.filters.data[dataIndex].append(value);
        }
    },

    #
    # @param  hash  objCallback  Owner object of callback function
    # @param  func  callback  Callback function called on finish
    # @param  int  start  Start index counting from 0 as a first row of data
    # @param  int  count  How many rows should be returned
    # @param  bool  withHeaders
    # @return void
    #
    loadDataRange: func(objCallback, callback, start, count, withHeaders) {
        me.objCallback = objCallback;
        me.callback    = callback;
        me.withHeaders = withHeaders;

        me.loadedData = [];

        # Build where from filters
        var where = me.getWhereQueryFilters();

        var query = sprintf("SELECT * FROM %s %s LIMIT %d OFFSET %d", StorageSQLite.TABLE_LOGBOOKS, where, count, start);
        foreach (var row; sqlite.exec(me.dbHandler, query)) {
            var vectorLogData = me.dbRowToVector(row);
            append(me.loadedData, {
                allDataIndex: row.id,
                data        : vectorLogData,
            });
        }

        me.updateTotalsValues(where);

        # Add totals row to the end
        me.appendTotalsRow();

        # We have not used the thread here, but we must point out that it has ended
        g_isThreadPending = false;

        me.loadDataRangeThreadFinish();
    },

    #
    # Callback function when the loadDataRangeThread finishes work
    #
    # @return void
    #
    loadDataRangeThreadFinish: func() {
        # Pass result to callback function
        call(me.callback, [me.loadedData, me.withHeaders], me.objCallback);
    },

    #
    # @return string
    #
    getWhereQueryFilters: func() {
        var where = "";
        foreach (var filterData; me.filters.appliedFilters.vector) {
            where ~= (size(where) == 0)
                ? "WHERE "
                : "AND ";

            var columnName = filterData.dbColumnName;
            if (columnName == "date") {
                # For date column the value is a year only
                where ~= "`" ~ columnName ~ "` LIKE '" ~ filterData.value ~ "%' ";
            }
            else {
                where ~= "`" ~ columnName ~ "` = '" ~ filterData.value ~ "' ";
            }
        }

        return where;
    },

    #
    # @param  string  where  SQL query condition
    # @return void
    #
    updateTotalsValues: func(where) {
        var query = sprintf("SELECT
                SUM(landing) AS landing,
                SUM(crash) AS crash,
                SUM(day) AS day,
                SUM(night) AS night,
                SUM(instrument) AS instrument,
                SUM(multiplayer) AS multiplayer,
                SUM(swift) AS swift,
                SUM(duration) AS duration,
                SUM(distance) AS distance,
                SUM(fuel) AS fuel,
                MAX(max_alt) AS max_alt
            FROM %s %s", StorageSQLite.TABLE_LOGBOOKS, where);
        var rows = sqlite.exec(me.dbHandler, query);

        if (size(rows) == 0) {
            return;
        }

        var row = rows[0];

        me.totals[0]  = row.landing;
        me.totals[1]  = row.crash;
        me.totals[2]  = row.day;
        me.totals[3]  = row.night;
        me.totals[4]  = row.instrument;
        me.totals[5]  = row.multiplayer;
        me.totals[6]  = row.swift;
        me.totals[7]  = row.duration;
        me.totals[8]  = row.distance;
        me.totals[9]  = row.fuel;
        me.totals[10] = row.max_alt;
    },

    #
    # Append totals row to loadedData
    #
    # @return void
    #
    appendTotalsRow: func() {
        append(me.loadedData, {
            allDataIndex : -1,
            data         : [
                "", # <- empty columns before "Totals:" text
                "",
                "",
                "",
                "",
                "",
                "",
                "Totals:",
            ],
        });

        forindex (var index; me.totals) {
            append(
                me.loadedData[size(me.loadedData) - 1].data,
                sprintf(StorageCsv.TOTAL_FORMATS[index], me.totals[index])
            );
        }
    },

    #
    # @param  int  id  Record ID in table
    # @param  string  header
    # @param  string  value
    # @return bool  Return true if successful
    #
    editData: func(id, header, value) {
        if (id == nil or header == nil or value == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row");
            return false;
         }

        if (g_isThreadPending) {
            return false;
        }

        var columnName = me.getColumnNameByHeader(header);
        if (columnName == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, header ", header, " not found");
            return false;
        }

        var query = sprintf("UPDATE %s SET %s = ? WHERE id = ?", StorageSQLite.TABLE_LOGBOOKS, columnName);
        var stmt = sqlite.prepare(me.dbHandler, query);
        sqlite.exec(me.dbHandler, stmt, value, id); # always returns an empty vector

        gui.popupTip("The change has been saved!");

        return true;
    },

    #
    # Get DB column name by header name
    #
    # @param  string  header
    # @return int|nil
    #
    getColumnNameByHeader: func(header) {
        if (g_isThreadPending) {
            return nil;
        }

             if (header == "Data")        return "date";
        else if (header == "Time")        return "time";
        else if (header == "Aircraft")    return "aircraft";
        else if (header == "Variant")     return "variant";
        else if (header == "Type")        return "aircraft_type";
        else if (header == "Callsign")    return "callsign";
        else if (header == "From")        return "from";
        else if (header == "To")          return "to";
        else if (header == "Landing")     return "landing";
        else if (header == "Crash")       return "crash";
        else if (header == "Day")         return "day";
        else if (header == "Night")       return "night";
        else if (header == "Instrument")  return "instrument";
        else if (header == "Multiplayer") return "multiplayer";
        else if (header == "Swift")       return "swift";
        else if (header == "Duration")    return "duration";
        else if (header == "Distance")    return "distance";
        else if (header == "Fuel")        return "fuel";
        else if (header == "Max Alt")     return "max_alt";
        else if (header == "Note")        return "note";

        return nil;
    },

    #
    # Get DB column name by index of column
    #
    # @param  int  index  Column index
    # @return int|nil
    #
    getColumnNameByIndex: func(index) {
             if (index == StorageCsv.INDEX_DATE)        return "date";
        else if (index == StorageCsv.INDEX_TIME)        return "time";
        else if (index == StorageCsv.INDEX_AIRCRAFT)    return "aircraft";
        else if (index == StorageCsv.INDEX_VARIANT)     return "variant";
        else if (index == StorageCsv.INDEX_TYPE)        return "aircraft_type";
        else if (index == StorageCsv.INDEX_CALLSIGN)    return "callsign";
        else if (index == StorageCsv.INDEX_FROM)        return "from";
        else if (index == StorageCsv.INDEX_TO)          return "to";
        else if (index == StorageCsv.INDEX_LANDING)     return "landing";
        else if (index == StorageCsv.INDEX_CRASH)       return "crash";
        else if (index == StorageCsv.INDEX_DAY)         return "day";
        else if (index == StorageCsv.INDEX_NIGHT)       return "night";
        else if (index == StorageCsv.INDEX_INSTRUMENT)  return "instrument";
        else if (index == StorageCsv.INDEX_MULTIPLAYER) return "multiplayer";
        else if (index == StorageCsv.INDEX_SWIFT)       return "swift";
        else if (index == StorageCsv.INDEX_DURATION)    return "duration";
        else if (index == StorageCsv.INDEX_DISTANCE)    return "distance";
        else if (index == StorageCsv.INDEX_FUEL)        return "fuel";
        else if (index == StorageCsv.INDEX_MAX_ALT)     return "max_alt";
        else if (index == StorageCsv.INDEX_NOTE)        return "note";

        return nil;
    },

    #
    # Get total number of rows in CSV file (excluded headers row)
    #
    # @return int
    #
    getTotalLines: func() {
        # Build where from filters
        var where = me.getWhereQueryFilters();

        var query = sprintf("SELECT COUNT(*) AS count FROM %s %s", StorageSQLite.TABLE_LOGBOOKS, where);
        var rows = sqlite.exec(me.dbHandler, query);

        if (size(rows)) {
            return rows[0].count;
        }

        return 0;
    },

    #
    # Get vector with headers names
    #
    # @return vector
    #
    getHeadersData: func() {
        return me.headersData;
    },

    #
    # Get vector of data row by given id of row
    #
    # @param  int  id
    # @return hash|nil
    #
    getLogData: func(id) {
        if (id == nil) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData, index(", index, ") out of range, return nil");
            return nil;
        }

        if (g_isThreadPending) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData in g_isThreadPending = true, return nil");
            return nil;
        }

        var query = sprintf("SELECT * FROM %s WHERE id = ?", StorageSQLite.TABLE_LOGBOOKS);
        var stmt = sqlite.prepare(me.dbHandler, query);

        var rows = sqlite.exec(me.dbHandler, stmt, id);
        if (size(rows) == 0) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData, id(", id, ") out of range, return nil");
            return nil;
        }

        var row = rows[0];

        return {
            allDataIndex: row.id,
            data        : me.dbRowToVector(row),
        };
    },

    #
    # @param  int  id  ID to delete
    # @return bool
    #
    deleteLog: func(id) {
        if (id == nil or id < 0) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - ID out of range in deleteLog");
            return false;
        }

        var query = sprintf("DELETE FROM %s WHERE id = ?", StorageSQLite.TABLE_LOGBOOKS);
        var stmt = sqlite.prepare(me.dbHandler, query);
        sqlite.exec(me.dbHandler, stmt, id);

        gui.popupTip("The log has been deleted!");

        return true;
    },
};
