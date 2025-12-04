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
# Storage class to save logbook data to data base.
#
var Storage = {
    #
    # Constants:
    #
    LOGBOOK_FILE    : "logbook.sqlite",
    TABLE_LOGBOOKS  : "logbooks",
    TABLE_MIGRATIONS: "migrations",
    TABLE_TRACKERS  : "trackers",

    #
    # For old CSV storage maintenance:
    #
    CSV_LOGBOOK_FILE : "logbook-v%s.csv",
    CSV_FILE_VERSION : "5",

    #
    # Constructor.
    #
    # @param  hash  filters  Filters object.
    # @param  hash  columns  Columns object.
    # @return hash
    #
    new: func(filters, columns) {
        var obj = {
            parents  : [Storage],
            _filters : filters,
            _columns : columns,
        };

        obj._exporter = Exporter.new(columns);

        obj._filePath    = obj._getPathToFile();
        obj._loadedData  = std.Vector.new();

        DB.open(obj._filePath);

        Migration.new().migrate();

        gui.menuEnable("logbook-addon-export-csv", true);

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func {
        me._exporter.del();
        DB.close();
    },

    #
    # @return string  Full path to sqlite file.
    #
    _getPathToFile: func {
        return g_Addon.storagePath ~ "/" ~ Storage.LOGBOOK_FILE;
    },

    #
    # Export logbook from SQLite to CSV file as a separate thread job.
    #
    # @return void
    #
    exportToCsv: func {
        me._exporter.exportToCsv();
    },

    #
    # Store log data to DB.
    #
    # @param  hash  logData  LogData object.
    # @param  int|nil  logbookId  Record ID of `logbooks` table.
    # @param  bool  onlyIO  Set true for execute only I/O operation on the file,
    #     without rest of stuff (used only for CSV recovery).
    # @return void
    #
    saveLogData: func(logData, logbookId = nil, onlyIO = 0) {
        logbookId == nil
            ? me.addItem(logData) # insert
            : me.updateItem(logData, logbookId); # update

        if (!onlyIO) {
            me._filters.append(logData);
            me._filters.sort();

            # Build where from filters
            var where = me._getWhereQueryFilters();
            me._updateTotalsValues(where);
        }
    },

    #
    # Insert LogData into database.
    #
    # @param  hash  logData  LogData object.
    # @return int|nil  ID of new record, or nil.
    #
    addItem: func(logData) {
        var query = "INSERT INTO " ~ Storage.TABLE_LOGBOOKS
            ~ " VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        DB.exec(
            query,
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
            logData.sim_utc_date,
            logData.sim_utc_time,
            logData.sim_local_date,
            logData.sim_local_time,
            logData.max_groundspeed_kt,
            logData.max_mach,
        );

        var rows = DB.exec("SELECT last_insert_rowid() AS id");
        if (size(rows)) {
            return rows[0].id;
        }

        return nil;
    },

    #
    # Update record with given ID.
    #
    # @param  hash  logData  LogData object.
    # @param  int  logbookId  Record ID of `logbooks` table.
    # @return void
    #
    updateItem: func(logData, logbookId) {
        var query = "UPDATE " ~ Storage.TABLE_LOGBOOKS
            ~ " SET `date` = ?,
                `time` = ?,
                `sim_utc_date` = ?,
                `sim_utc_time` = ?,
                `sim_local_date` = ?,
                `sim_local_time` = ?,
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
                `note` = ?,
                `max_groundspeed_kt` = ?,
                `max_mach` = ?
            WHERE id = ?";

        DB.exec(
            query,
            logData.date,
            logData.time,
            logData.sim_utc_date,
            logData.sim_utc_time,
            logData.sim_local_date,
            logData.sim_local_time,
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
            logData.max_groundspeed_kt,
            logData.max_mach,
            logbookId
        );
    },

    #
    # Insert current data to trackers table.
    #
    # @param  int|nil  logbookId  Record ID of `logbooks` table.
    # @param  hash  data  Hash with data.
    # @return bool
    #
    addTrackerItem: func(logbookId, data) {
        if (logbookId == nil) {
            return false;
        }

        var query = "INSERT INTO " ~ Storage.TABLE_TRACKERS
            ~ " VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        DB.exec(
            query,
            logbookId,
            data.timestamp,
            data.lat,
            data.lon,
            data.alt_m,
            data.elevation_m,
            data.distance,
            data.heading_true,
            data.heading_mag,
            data.groundspeed,
            data.airspeed,
            data.pitch,
            data.wind_heading,
            data.wind_speed,
        );

        return true;
    },

    #
    # Convert row from DB to vector.
    #
    # @param  hash  row  Row from table.
    # @return vector
    #
    _dbRowToVector: func(row) {
        var logData = LogData.new();
        return logData.fromDbToListViewColumns(row, me._columns);
    },

    #
    # Load all data for filters, called once on startup.
    #
    # @return void
    #
    loadAllData: func {
        me._loadAllFilters();

        # Enable Logbook menu because we have a data
        gui.menuEnable("logbook-addon-main-dialog", true);

        Log.print("loadAllData finished");
    },

    #
    # Load all filters from database.
    #
    # @return void
    #
    _loadAllFilters: func {
        me._filters.clear();

        me._updateFilterData(me._columns.getColumnDate());
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
    # Update given filter with data from DB.
    #
    # @param  string  columnName
    # @param  hash|nil  where  As hash {column: 'text': value: 'text'}.
    # @param  int  start  Start index counting from 0 as a first row of data, if -1 then don't use it.
    # @param  int  count  How many rows should be returned, if -1 then don't use it.
    # @return void
    #
    _updateFilterData: func(columnName, where = nil, start = -1, count = -1) {
        var sqlColumnName = "`" ~ columnName ~ "`";
        if (columnName == me._columns.getColumnDate()) {
            sqlColumnName = "strftime('%Y', " ~ sqlColumnName ~ ")"; # get only a year from `date` column
        }

        var query = "
            SELECT
                DISTINCT " ~ sqlColumnName ~ " AS `value`
            FROM `" ~ Storage.TABLE_LOGBOOKS ~ "`";

        if (where != nil) {
            query ~= sprintf(" WHERE `%s` = '%s'", where.column, where.value);
        }

        # COLLATE NOCASE - ignore case sensitivity during sorting.
        query ~= " ORDER BY value COLLATE NOCASE ASC";

        if (start > -1 and count > -1) {
            query ~= sprintf(" LIMIT %d OFFSET %d", count, start);
        }

        var rows = DB.exec(query);
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
        if (columnName == me._columns.getColumnDate()) {
            return substr(value, 0, 4) # get year only
        }

        if (columnName == Columns.LANDING
            or columnName == Columns.CRASH
        ) {
            # We can't provide int for filters because we Filters.sort by strings.
            return value ? "1" : "";
        }

        return value;
    },

    #
    # Load logbook data with given range, called when user open the Logbook dialog or change its page.
    #
    # @param  hash  callback  Callback object called on finish.
    # @param  int  start  Start index counting from 0 as a first row of data.
    # @param  int  count  How many rows should be returned.
    # @param  bool  withHeaders  Set true when headers/filters must be change too in LogbookDialog canvas.
    # @return void
    #
    loadDataRange: func(callback, start, count, withHeaders) {
        me._loadedData.clear();

        var where = me._getWhereQueryFilters();

        var query = "SELECT " ~ me._getSelectLoadDataRange()
            ~ " FROM " ~ Storage.TABLE_LOGBOOKS
            ~ " " ~ where
            ~ " ORDER BY `id` DESC"
            ~ " LIMIT ? OFFSET ?;";

        foreach (var row; DB.exec(query, count, start)) {
            var logData = LogData.new();

            me._loadedData.append({
                id     : row.id,
                columns: logData.fromDbToListViewColumns(row, me._columns),
            });
        }

        me._updateTotalsValues(where);

        # Add totals row to the end
        me._loadedData.append(me.getTotalsRow());

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

        # Pass result to callback function
        callback.invoke(me._loadedData.vector, withHeaders);
    },

    #
    # Build where from filters.
    #
    # @return string
    #
    _getWhereQueryFilters: func {
        var where = "";
        foreach (var filterData; me._filters.appliedFilters.vector) {
            where ~= (size(where) == 0)
                ? "WHERE "
                : "AND ";

            var columnName = filterData.columnName;
            if (columnName == me._columns.getColumnDate()) {
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
    # Build select columns according to visibility flag.
    #
    # @return string
    #
    _getSelectLoadDataRange: func {
        var select = "`id`";

        foreach (var columnItem; me._columns.getAll()) {
            if (columnItem.visible) {
                select ~= ", `" ~ columnItem.name ~ "`";
            }
        }

        return select;
    },

    #
    # @param  string  where  SQL query condition.
    # @param  bool  withCheckVisible  If true then invisible columns will be skipped,
    #                                 otherwise all columns will be updated.
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

        if (select == "") {
            return;
        }

        # query = "SELECT SUM(landing) as landing, SUM..., FROM logbooks WHERE ..."
        var query = sprintf("SELECT %s FROM %s %s", select, Storage.TABLE_LOGBOOKS, where);
        var rows = DB.exec(query);

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
    # Append totals row to loadedData.
    #
    # @param  bool  withCheckVisible  If false then return even those columns which have visible set to false.
    # @return void
    #
    getTotalsRow: func(withCheckVisible = 1) {
        if (!withCheckVisible) {
            # Build where from filters
            var where = me._getWhereQueryFilters();
            me._updateTotalsValues(where: where, withCheckVisible: false);
        }

        var totalsData = [];
        var setTotalsLabel = false;

        foreach (var columnItem; me._columns.getAll()) {
            if (withCheckVisible and !columnItem.visible) {
                continue;
            }

            if (columnItem.totals == nil) {
                append(totalsData, {
                    width: columnItem.width,
                    data : "", # blank column
                });
            }
            else {
                if (!setTotalsLabel) {
                    # Set the "Totals" label for the last added empty item
                    var count = size(totalsData);
                    if (count > 1) {
                        totalsData[count - 2].colspan = 2;
                        totalsData[count - 2].align   = "right";
                        totalsData[count - 2].data    = "Totals:";

                        totalsData[count - 1].colspan = 0;

                        setTotalsLabel = true;
                    }
                }

                append(totalsData, {
                    width: columnItem.width,
                    data : sprintf(columnItem.totalFrm, columnItem.totalVal),
                });
            }
        }

        if (!setTotalsLabel) {
            # The Totals label is still not set, because each column with totals
            # is not displayed, so set it to the last column.
            var count = size(totalsData);
            if (count > 1) {
                totalsData[count - 2].colspan = 2;
                totalsData[count - 2].align   = "right";
                totalsData[count - 2].data    = "Totals";

                totalsData[count - 1].colspan = 0;
            }
        }

        return {
            id     : Columns.TOTALS_ROW_ID,
            columns: totalsData,
            font   : "LiberationFonts/LiberationMono-Bold.ttf",
        };
    },

    #
    # @param  int  logbookId  Logbook ID in `logbooks` table.
    # @param  string  columnName
    # @param  string  value
    # @return bool  Return true if successful.
    #
    editData: func(logbookId, columnName, value) {
        if (logbookId == nil or columnName == nil or value == nil) {
            Log.error("cannot save edited row");
            return false;
        }

        if (g_isThreadPending) {
            return false;
        }

        if (columnName == Columns.DAY or columnName == Columns.NIGHT) {
            # Also update duration, which is the sum of day and night
            DB.exec("BEGIN TRANSACTION;");

            var oppositeColumn = columnName == Columns.DAY ? Columns.NIGHT : Columns.DAY;

            # Get value of opposite column
            var query = "SELECT `" ~ oppositeColumn ~ "`"
                ~ " FROM `" ~ Storage.TABLE_LOGBOOKS ~ "`"
                ~ " WHERE `id` = ?;";

            var rows = DB.exec(query, logbookId);
            if (!size(rows)) {
                DB.exec("ROLLBACK;");
                return false;
            }

            var oppositeValue = rows[0][oppositeColumn];

            query = "UPDATE `" ~ Storage.TABLE_LOGBOOKS ~ "`"
                ~ " SET `" ~ columnName ~ "` = ?, `" ~ Columns.DURATION ~ "` = ? + ?"
                ~ " WHERE `id` = ?;";

            DB.exec(query, value, value, oppositeValue, logbookId); # always returns an empty vector
            DB.exec("COMMIT;");
        }
        else {
            var query = "UPDATE `" ~ Storage.TABLE_LOGBOOKS ~ "`"
                ~ " SET `" ~ columnName ~ "` = ?"
                ~ " WHERE `id` = ?;";

            DB.exec(query, value, logbookId); # always returns an empty vector
        }

        gui.popupTip("The change has been saved!");

        return true;
    },

    #
    # Get total number of rows in CSV file (excluded headers row).
    #
    # @return int
    #
    getTotalLines: func {
        # Build where from filters
        var where = me._getWhereQueryFilters();

        var query = sprintf("SELECT COUNT(*) AS `count` FROM `%s` %s", Storage.TABLE_LOGBOOKS, where);
        var rows = DB.exec(query);

        if (size(rows)) {
            return rows[0].count;
        }

        return 0;
    },

    #
    # Get vector of data row by given id of row.
    #
    # @param  int  logbookId  If -1 then return data with totals row.
    # @return hash|nil
    #
    getLogData: func(logbookId) {
        if (g_isThreadPending) {
            Log.alertWarning("getLogData in g_isThreadPending = true, return nil");
            return nil;
        }

        if (logbookId == Columns.TOTALS_ROW_ID) {
            return me.getTotalsRow(withCheckVisible: false);
        }

        if (logbookId == nil) {
            Log.alertError("getLogData, index(", index, ") out of range, return nil");
            return nil;
        }

        var query = sprintf("SELECT * FROM %s WHERE id = ?", Storage.TABLE_LOGBOOKS);
        var rows = DB.exec(query, logbookId);
        if (size(rows) == 0) {
            Log.alertError("getLogData, logbookId(", logbookId, ") out of range, return nil");
            return nil;
        }

        var row = rows[0];

        return {
            id     : row.id,
            columns: me._dbRowToVector(row),
        };
    },

    #
    # @param  int|nil  logbookId  Logbook ID to delete.
    # @return bool
    #
    deleteLog: func(logbookId) {
        if (me.deleteLogQuiet(logbookId)) {
            gui.popupTip("The log has been deleted!");
            return true;
        }

        return false;
    },

    #
    # @param  int|nil  logbookId  Logbook ID to delete.
    # @return bool
    #
    deleteLogQuiet: func(logbookId) {
        if (logbookId == nil or logbookId < 0) {
            Log.error("ID out of range in deleteLog");
            return false;
        }

        var query = sprintf("DELETE FROM %s WHERE id = ?", Storage.TABLE_LOGBOOKS);
        DB.exec(query, logbookId);

        # Delete data from trackers
        query = sprintf("DELETE FROM %s WHERE logbook_id = ?", Storage.TABLE_TRACKERS);
        DB.exec(query, logbookId);

        return true;
    },

    #
    # Get tracker data for given logbook ID.
    #
    # @param  int|nil  logbookId  Logbook ID which tracker data should be returned.
    # @return vector|nil
    #
    getLogbookTracker: func(logbookId) {
        if (logbookId == nil) {
            return nil;
        }

        var query = sprintf("SELECT * FROM %s WHERE logbook_id = ?", Storage.TABLE_TRACKERS);
        var rows = DB.exec(query, logbookId);

        return rows;
    },

    #
    # Get max altitude value in tracker data for given logbook ID.
    #
    # @param  int|nil  logbookId  Logbook ID which max altitude should be returned.
    # @return double|nil
    #
    getLogbookTrackerMaxAlt: func(logbookId) {
        if (logbookId == nil) {
            return nil;
        }

        var query = "SELECT MAX(CASE WHEN alt_m > elevation_m THEN alt_m ELSE elevation_m END) AS `max_alt` "
            ~ "FROM " ~ Storage.TABLE_TRACKERS
            ~ " WHERE logbook_id = ?";
        var rows = DB.exec(query, logbookId);

        if (size(rows)) {
            return rows[0].max_alt;
        }

        return nil;
    },

    #
    # Vacuum SQLite file.
    #
    # @return bool
    #
    vacuumSQLite: func {
        var rows = DB.exec("VACUUM;");
        return isvec(rows) and size(rows) == 0;
    },
};
