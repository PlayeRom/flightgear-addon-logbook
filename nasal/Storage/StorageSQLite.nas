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
        return logData.toVector(me._columns);
    },

    #
    # Load all data for filters, called once on startup
    #
    # @return void
    #
    loadAllData: func() {
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

        me._updateFilterData(Columns.DATE);
        me._updateFilterData(Columns.AIRCRAFT);
        me._updateFilterData(Columns.VARIANT);
        me._updateFilterData(Columns.AC_TYPE);
        me._updateFilterData(Columns.CALLSIGN);
        me._updateFilterData(Columns.FROM);
        me._updateFilterData(Columns.TO);
        me._updateFilterData(Columns.LANDING);
        me._updateFilterData(Columns.CRASH);
    },

    #
    # Update given filter with data from DB
    #
    # @param  string  columnName
    # @param  hash|nil  where  As hash {column: 'text': value: 'text'}
    # @param  int  start  Start index counting from 0 as a first row of data, if -1 then don't use it
    # @param  int  count  How many rows should be returned, if -1 then don't use it
    # @return void
    #
    _updateFilterData: func(columnName, where = nil, start = -1, count = -1) {
        var sqlColumnName = "`" ~ columnName ~ "`";
        if (columnName == Columns.DATE) {
            sqlColumnName = "strftime('%Y', " ~ sqlColumnName ~ ")"; # get only a year from `date` column
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

        var query = sprintf(frm, sqlColumnName, StorageSQLite.TABLE_LOGBOOKS);
        var rows = sqlite.exec(me._dbHandler, query);

        if (size(rows)) {
            me._filters.data[columnName].clear();

            foreach (var row; rows) {
                var value = me._gatValueFilter(row.value, columnName);

                me._filters.data[columnName].append(value);
            }
        }
    },

    #
    # @param  string|int  value
    # @param  string  columnName
    # @return string
    #
    _gatValueFilter: func(value, columnName) {
        if (columnName == Columns.DATE) {
            return  substr(value, 0, 4) # get year only
        }
        else if (columnName == Columns.LANDING
              or columnName == Columns.CRASH
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

        Thread.new().run(
            func { me._loadDataRange(start, count); },
            me,
            me._loadDataRangeThreadFinish,
            false
        );
    },


    #
    # Load logbook data with given range
    #
    # @param  int  start  Start index counting from 0 as a first row of data
    # @param  int  count  How many rows should be returned
    # @return void
    #
    _loadDataRange: func(start, count) {
        me._loadedData = [];

        var where = me._getWhereQueryFilters();

        var query = "SELECT " ~ me._getSelectLoadDataRange()
            ~ " FROM " ~ StorageSQLite.TABLE_LOGBOOKS
            ~ " " ~ where
            ~ " LIMIT " ~ count ~ " OFFSET " ~ start;

        foreach (var row; sqlite.exec(me._dbHandler, query)) {
            var logData = LogData.new();

            append(me._loadedData, {
                id   : row.id,
                data : logData.fromDbToVector(row, me._columns),
            });
        }

        me._updateTotalsValues(where);

        # Add totals row to the end
        append(me._loadedData, me.getTotalsRow());

        # Update aircraft variants filter, to show only variant of selected aircraft
        var aircraft = me._filters.getAppliedValueForFilter(Columns.AIRCRAFT);
        if (aircraft == nil) {
            # Apply all variant values to filter
            me._updateFilterData(Columns.VARIANT);
        }
        else {
            # Apply variant filters according to selected aircraft
            var where = { column: Columns.AIRCRAFT, value: aircraft };
            me._updateFilterData(Columns.VARIANT, where, start, count);
        }

        g_isThreadPending = false;
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
    # Build where from filters
    #
    # @return string
    #
    _getWhereQueryFilters: func() {
        var where = "";
        foreach (var filterData; me._filters.appliedFilters.vector) {
            where ~= (size(where) == 0)
                ? "WHERE "
                : "AND ";

            var columnName = filterData.columnName;
            if (columnName == Columns.DATE) {
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
    # Build select columns according to visibility flag
    #
    # @return string
    #
    _getSelectLoadDataRange: func() {
        var select = "`id`";

        foreach (var columnItem; me._columns.getAll()) {
            if (columnItem.visible) {
                select ~= ", `" ~ columnItem.name ~ "`";
            }
        }

        return select;
    },

    #
    # @param  string  where  SQL query condition
    # @return void
    #
    _updateTotalsValues: func(where, withCheckVisible = 1) {
        var select = "";
        foreach (var columnItem; me._columns.getAll()) {
            if (withCheckVisible and !columnItem.visible) {
                continue;
            }

            if (columnItem.totals != nil) {
                if (select != "") {
                    select ~= ", ";
                }

                select ~= columnItem.totals ~ "(`" ~ columnItem.name ~ "`) AS `" ~ columnItem.name ~ "`";
            }
        }

        # query = "SELECT SUM(landing) as landing, SUM..., FROM logbooks WHERE ..."
        var query = sprintf("SELECT %s FROM %s %s", select, StorageSQLite.TABLE_LOGBOOKS, where);
        var rows = sqlite.exec(me._dbHandler, query);

        if (size(rows) == 0) {
            return;
        }

        # row it's hash with fields as column names
        var row = rows[0];

        foreach (var columnName; keys(row)) {
            var value = row[columnName];
            me._columns.setTotalValueByColumnName(columnName, value);
        }
    },

    #
    # Append totals row to loadedData
    #
    # @param  bool  withCheckVisible  If true false return even those columns which have visible set to false
    # @return void
    #
    getTotalsRow: func(withCheckVisible = 1) {
        if (!withCheckVisible) {
            # Build where from filters
            var where = me._getWhereQueryFilters();
            me._updateTotalsValues(where, false);
        }

        var totalsData = [];
        var setTotalsLabel = false;

        foreach (var columnItem; me._columns.getAll()) {
            if (withCheckVisible and !columnItem.visible) {
                continue;
            }

            if (columnItem.totals == nil) {
                append(totalsData, "");
            }
            else {
                if (!setTotalsLabel) {
                    # Set the "Totals" label for the last added empty item
                    var count = size(totalsData);
                    if (count > 0) {
                        totalsData[count - 1] = "Totals:";
                        setTotalsLabel = true;
                    }
                }

                append(totalsData, sprintf(columnItem.totalFrm, columnItem.totalVal));
            }
        }

        return {
            id  : Columns.TOTALS_ROW_ID,
            data: totalsData,
        };
    },

    #
    # @param  int  id  Record ID in table
    # @param  string  columnName
    # @param  string  value
    # @return bool  Return true if successful
    #
    editData: func(id, columnName, value) {
        if (id == nil or columnName == nil or value == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row");
            return false;
        }

        if (g_isThreadPending) {
            return false;
        }

        var query = sprintf("UPDATE %s SET `%s` = ? WHERE id = ?", StorageSQLite.TABLE_LOGBOOKS, columnName);
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
    # @param  int  id  If -1 then return data with totals row
    # @return hash|nil
    #
    getLogData: func(id) {
        if (g_isThreadPending) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData in g_isThreadPending = true, return nil");
            return nil;
        }

        if (id == Columns.TOTALS_ROW_ID) {
            return me.getTotalsRow(false);
        }

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
            id   : row.id,
            data : me._dbRowToVector(row),
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
