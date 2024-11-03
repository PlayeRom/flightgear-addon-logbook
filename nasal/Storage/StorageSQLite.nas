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
    # @param  hash  filters  Filters object
    # @param  hash  columns  Columns object
    # @return me
    #
    new: func(filters, columns) {
        var me = {
            parents : [StorageSQLite],
            _filters: filters,
            _columns: columns,
        };

        me._filePath    = me._getPathToFile();
        me._dbHandler   = nil;
        me._loadedData  = [];
        me._withHeaders = true;

        me._totals      = [];
        me._resetTotals();

        me._openDb();

        # Callback for return results of loadDataRange
        me._objCallback = nil;
        me._callback    = func;

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._closeDb();
    },

    #
    # @return string  Full path to sqlite file
    #
    _getPathToFile: func() {
        return g_Addon.storagePath ~ "/" ~ StorageSQLite.LOGBOOK_FILE;
    },

    #
    # @return void
    #
    _resetTotals: func() {
        # Total amount
        me._totals = [
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
    _openDb: func() {
        me._closeDb();

        me._dbHandler = sqlite.open(me._filePath);

        MigrationSQLite.new(me).migrate();
    },

    #
    # Close DB connection
    #
    _closeDb: func() {
        if (me._dbHandler != nil) {
            sqlite.close(me._dbHandler);
            me._dbHandler = nil;
        }
    },

    #
    # @return ghost  DB handler object
    #
    getDbHandler: func() {
        return me._dbHandler;
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
        foreach (var columnItem; me._columns.getAll()) {
            if (headerRow != "") {
                headerRow ~= ",";
            }

            headerRow ~= Utils.isSpace(columnItem.header)
                ? '"' ~ columnItem.header ~ '"'
                :       columnItem.header;
        }

        io.write(file, headerRow ~ "\n");

        var query = sprintf("SELECT * FROM %s", StorageSQLite.TABLE_LOGBOOKS);
        foreach (var row; sqlite.exec(me._dbHandler, query)) {
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
            me._filters.append(logData);
            me._filters.sort();

            # Build where from filters
            var where = me._getWhereQueryFilters();
            me._updateTotalsValues(where);

            me._filters.dirty = true;
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
            db = me._dbHandler;
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

        var stmt = sqlite.prepare(me._dbHandler, query);
        sqlite.exec(me._dbHandler, stmt,
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
    _dbRowToVector: func(row) {
        var logData = LogData.new();
        logData.fromDb(row);
        return logData.toVector();
    },

    #
    # Load all data for filters, called once on startup
    #
    # @return void
    #
    loadAllData: func() {
        me._resetTotals();
        me._loadAllFilters();

        # Enable Logbook menu because we have a data
        gui.menuEnable("logbook-addon", true);

        logprint(MY_LOG_LEVEL, "Logbook Add-on - loadAllDataThread finished");
    },

    #
    # Load all filters from database
    #
    _loadAllFilters: func() {
        me._filters.clear();

        me._updateFilterData("date",          StorageCsv.INDEX_DATE);
        me._updateFilterData("aircraft",      StorageCsv.INDEX_AIRCRAFT);
        me._updateFilterData("variant",       StorageCsv.INDEX_VARIANT);
        me._updateFilterData("aircraft_type", StorageCsv.INDEX_TYPE);
        me._updateFilterData("callsign",      StorageCsv.INDEX_CALLSIGN);
        me._updateFilterData("`from`",        StorageCsv.INDEX_FROM);
        me._updateFilterData("`to`",          StorageCsv.INDEX_TO);
        me._updateFilterData("landing",       StorageCsv.INDEX_LANDING);
        me._updateFilterData("crash",         StorageCsv.INDEX_CRASH);

        # Un-dirty it, because this is the first loading and now everything is calculated, so the cache can be used
        me._filters.dirty = false;
    },

    #
    # Update given filter with data from DB
    #
    # @param  string  columnName
    # @param  int  dataIndex
    # @param  hash|nil  where  As hash {column: 'text': value: 'text'}
    # @param  int  start  Start index counting from 0 as a first row of data, if -1 then don't use it
    # @param  int  count  How many rows should be returned, if -1 then don't use it
    # @return void
    #
    _updateFilterData: func(columnName, dataIndex, where = nil, start = -1, count = -1) {
        if (dataIndex == StorageCsv.INDEX_DATE) {
            columnName = "strftime('%Y', " ~ columnName ~ ")"; # get only a year from `date` column
        }

        # COLLATE NOCASE - ignore case sensitivity during sorting
        var frm = "
            SELECT
                DISTINCT %s AS value
            FROM %s";

        if (where != nil) {
            frm ~= sprintf(" WHERE `%s` = '%s'", where.column, where.value);
        }

        frm ~= " ORDER BY value COLLATE NOCASE ASC";

        if (start > -1 and count > -1) {
            frm ~= sprintf(" LIMIT %d OFFSET %d", count, start);
        }

        var query = sprintf(frm, columnName, StorageSQLite.TABLE_LOGBOOKS);
        var rows = sqlite.exec(me._dbHandler, query);

        if (size(rows)) {
            me._filters.data[dataIndex].clear();

            foreach (var row; rows) {
                var value = me._gatValueFilter(row.value, dataIndex);

                me._filters.data[dataIndex].append(value);
            }
        }
    },

    #
    # @param  string|int  value
    # @param  int  dataIndex
    # @return string
    #
    _gatValueFilter: func(value, dataIndex) {
        if (dataIndex == StorageCsv.INDEX_DATE) {
            return  substr(value, 0, 4) # get year only
        }
        else if (dataIndex == StorageCsv.INDEX_LANDING
              or dataIndex == StorageCsv.INDEX_CRASH
        ) {
            # we can't provide int for filters because we Filters.sort by strings
            return value ? "1" : "";
        }

        return value;
    },

    #
    # Load logbook data with given range, called when user open the Logbook dialog or change its page
    #
    # @param  hash  objCallback  Owner object of callback function
    # @param  func  callback  Callback function called on finish
    # @param  int  start  Start index counting from 0 as a first row of data
    # @param  int  count  How many rows should be returned
    # @param  bool  withHeaders  Set true when headers/filters must be change too in LogbookDialog canvas.
    # @return void
    #
    loadDataRange: func(objCallback, callback, start, count, withHeaders) {
        me._objCallback = objCallback;
        me._callback    = callback;
        me._withHeaders = withHeaders;

        me._loadedData = [];

        # Build where from filters
        var where = me._getWhereQueryFilters();

        var query = sprintf("SELECT * FROM %s %s LIMIT %d OFFSET %d", StorageSQLite.TABLE_LOGBOOKS, where, count, start);
        foreach (var row; sqlite.exec(me._dbHandler, query)) {
            var vectorLogData = me._dbRowToVector(row);
            append(me._loadedData, {
                allDataIndex: row.id,
                data        : vectorLogData,
            });
        }

        me._updateTotalsValues(where);

        # Add totals row to the end
        me._appendTotalsRow();

        # Update aircraft variants filter, to show only variant of selected aircraft
        var aircraft = me._filters.getAppliedValueForFilter(StorageCsv.INDEX_AIRCRAFT);
        if (aircraft == nil) {
            # Apply all variant values to filter
            me._updateFilterData("variant", StorageCsv.INDEX_VARIANT);
        }
        else {
            # Apply variant filters according to selected aircraft
            var where = { column: "aircraft", value: aircraft };
            me._updateFilterData("variant", StorageCsv.INDEX_VARIANT, where, start, count);
        }

        me._loadDataRangeThreadFinish();
    },

    #
    # Callback function when the loadDataRange finishes work
    #
    # @return void
    #
    _loadDataRangeThreadFinish: func() {
        # Pass result to callback function
        call(me._callback, [me._loadedData, me._withHeaders], me._objCallback);
    },

    #
    # @return string
    #
    _getWhereQueryFilters: func() {
        var where = "";
        foreach (var filterData; me._filters.appliedFilters.vector) {
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
    _updateTotalsValues: func(where) {
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
        var rows = sqlite.exec(me._dbHandler, query);

        if (size(rows) == 0) {
            return;
        }

        var row = rows[0];

        me._totals[0]  = row.landing;
        me._totals[1]  = row.crash;
        me._totals[2]  = row.day;
        me._totals[3]  = row.night;
        me._totals[4]  = row.instrument;
        me._totals[5]  = row.multiplayer;
        me._totals[6]  = row.swift;
        me._totals[7]  = row.duration;
        me._totals[8]  = row.distance;
        me._totals[9]  = row.fuel;
        me._totals[10] = row.max_alt;
    },

    #
    # Append totals row to loadedData
    #
    # @return void
    #
    _appendTotalsRow: func() {
        append(me._loadedData, {
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

        forindex (var index; me._totals) {
            append(
                me._loadedData[size(me._loadedData) - 1].data,
                sprintf(StorageCsv.TOTAL_FORMATS[index], me._totals[index])
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

        var columnName = me._columns.getColumnNameByHeader(header);
        if (columnName == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, header ", header, " not found");
            return false;
        }

        var query = sprintf("UPDATE %s SET %s = ? WHERE id = ?", StorageSQLite.TABLE_LOGBOOKS, columnName);
        var stmt = sqlite.prepare(me._dbHandler, query);
        sqlite.exec(me._dbHandler, stmt, value, id); # always returns an empty vector

        gui.popupTip("The change has been saved!");

        return true;
    },

    #
    # Get total number of rows in CSV file (excluded headers row)
    #
    # @return int
    #
    getTotalLines: func() {
        # Build where from filters
        var where = me._getWhereQueryFilters();

        var query = sprintf("SELECT COUNT(*) AS count FROM %s %s", StorageSQLite.TABLE_LOGBOOKS, where);
        var rows = sqlite.exec(me._dbHandler, query);

        if (size(rows)) {
            return rows[0].count;
        }

        return 0;
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

        var query = sprintf("SELECT * FROM %s WHERE id = ?", StorageSQLite.TABLE_LOGBOOKS);
        var stmt = sqlite.prepare(me._dbHandler, query);

        var rows = sqlite.exec(me._dbHandler, stmt, id);
        if (size(rows) == 0) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData, id(", id, ") out of range, return nil");
            return nil;
        }

        var row = rows[0];

        return {
            allDataIndex: row.id,
            data        : me._dbRowToVector(row),
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
        var stmt = sqlite.prepare(me._dbHandler, query);
        sqlite.exec(me._dbHandler, stmt, id);

        gui.popupTip("The log has been deleted!");

        return true;
    },
};
