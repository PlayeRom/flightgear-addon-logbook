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
# Storage class to save logbook data to CSV file.
#
# @deprecated This will be phased out in favor of SQLite.
#
var Storage = {
    #
    # Constants
    #
    CSV_LOGBOOK_FILE : "logbook-v%s.csv",
    CSV_FILE_VERSION : "5",

    #
    # Column indexes of CSV file:
    #
    INDEX_DATE       : 0,
    INDEX_TIME       : 1,
    INDEX_AIRCRAFT   : 2,
    INDEX_VARIANT    : 3,
    INDEX_TYPE       : 4,
    INDEX_CALLSIGN   : 5,
    INDEX_FROM       : 6,
    INDEX_TO         : 7,
    INDEX_LANDING    : 8,
    INDEX_CRASH      : 9,
    INDEX_DAY        : 10,
    INDEX_NIGHT      : 11,
    INDEX_INSTRUMENT : 12,
    INDEX_MULTIPLAYER: 13,
    INDEX_SWIFT      : 14,
    INDEX_DURATION   : 15,
    INDEX_DISTANCE   : 16,
    INDEX_FUEL       : 17,
    INDEX_MAX_ALT    : 18,
    INDEX_NOTE       : 19,

    #
    # Constructor.
    #
    # @param  hash  filters  Filters object.
    # @param  hash  columns  Columns object.
    # @return hash
    #
    new: func(filters, columns) {
        var me = {
            parents : [Storage],
            _filters: filters,
            _columns: columns,
        };

        me._filePath      = me._getPathToFile(Storage.CSV_FILE_VERSION);
        me._addonNodePath = g_Addon.node.getPath();
        me._loadedData    = std.Vector.new();
        me._headersData   = [];
        me._withHeaders   = true;
        me._allData       = std.Vector.new();

        # Temporary filtered data as a cache for optimized viewing of large logs
        me._cachedData    = std.Vector.new();

        # Total lines in CSV file (without headers)
        me._totalLines    = -1;

        me._saveHeaders();

        # Callback for return results of loadDataRange
        me._callback = nil;

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        #
    },

    #
    # @param  string  version
    # @return string  Full path to file.
    #
    _getPathToFile: func(version) {
        return g_Addon.storagePath ~ "/" ~ sprintf(Storage.CSV_LOGBOOK_FILE, version);
    },

    #
    # Reset total amount to 0.
    #
    # @return void
    #
    _resetTotals: func() {
        foreach (var columnItem; me._columns.getAll()) {
            if (columnItem.totals != nil) {
                columnItem.totalVal = 0;
            }
        }
    },

    #
    # @return  bool  Return true if migration was done.
    #
    _migrateVersion: func() {
        var migrationCsv = MigrationCsv.new();

        var olderReleases = [
            # Keep the order from the newest to oldest
            "4",
            "3",
            "2",
            "1.0.1", # nothing has changed from v.1.0.0, so 1.0.0 = 1.1.0
            "1.0.0",
        ];

        foreach (var oldVersion; olderReleases) {
            var oldFile = me._getPathToFile(oldVersion);
            if (Utils.fileExists(oldFile)) {
                if (oldVersion == "1.0.1" or oldVersion == "1.0.0") {
                    # If there is no version 2 file, but older ones exist, migrate to version 2 first
                    var file_v2 = me._getPathToFile("2");
                    migrationCsv.migrateToFileVersion_2(oldFile, file_v2);

                    # Prepare variables to next migration
                    oldFile = file_v2;
                    oldVersion = "2";
                }

                if (oldVersion == "2") {
                    var file_v3 = me._getPathToFile("3");
                    migrationCsv.migrateToFileVersion_3(oldFile, file_v3);
                    # Prepare variables to next migration
                    oldFile = file_v3;
                    oldVersion = "3";
                }

                if (oldVersion == "3") {
                    var file_v4 = me._getPathToFile("4");
                    migrationCsv.migrateToFileVersion_4(oldFile, file_v4);
                    # Prepare variables to next migration
                    oldFile = file_v4;
                    oldVersion = "4";
                }

                if (oldVersion == "4") {
                    migrationCsv.migrateToFileVersion_5(oldFile, me._filePath);
                }

                return true;
            }
        }

        return false;
    },

    #
    # Copy file from older version to the newest.
    #
    # @param  string  oldFile
    # @param  string  newFile
    # @return void
    #
    _copyFile: func(oldFile, newFile) {
        var content = io.readfile(oldFile);

        var file = io.open(newFile, "w");
        io.write(file, content);
        io.close(file);
    },

    #
    # If logbook file doesn't exist then create it with headers.
    #
    # @return void
    #
    _saveHeaders: func() {
        if (!Utils.fileExists(me._filePath)) {
            if (!me._migrateVersion()) {
                var file = io.open(me._filePath, "a");
                io.write(file, me._getHeaderLine() ~ "\n");
                io.close(file);
            }
        }
    },

    #
    # @return string
    #
    _getHeaderLine: func() {
        return 'Date,' ~
               'Time,' ~
               'Aircraft,' ~
               'Variant,' ~
               'Type,' ~
               'Callsign,' ~
               'From,' ~
               'To,' ~
               'Landing,' ~
               'Crash,' ~
               'Day,' ~
               'Night,' ~
               'Instrument,' ~
               'Multiplayer,' ~
               'Swift,' ~
               'Duration,' ~
               'Distance,' ~
               'Fuel,' ~
               '"Max Alt",' ~
               'Note';
    },

    #
    # Store log data to logbook file.
    #
    # @param  hash  logData  LogData object.
    # @param  int  id|nil  Logbook ID for SQLite storage.
    # @param  bool  onlyIO  Set true for execute only I/O operation on the file,
    #     without rest of stuff (used only for CSV recovery).
    # @return void
    #
    saveLogData: func(logData, id = nil, onlyIO = 0) {
        var file = io.open(me._filePath, "a");
        me.addItem(logData, file);
        io.close(file);

        if (!onlyIO) {
            me._allData.append(logData);
            me._filters.append(logData);
            me._filters.sort();
            me._totalLines += 1;
            me._countTotals(logData.toListViewColumns(me._columns));
            me._filters.dirty = true;
        }
    },

    #
    # @param  hash  logData  LogData object.
    # @param  hash  file  file handler.
    # @return void
    #
    addItem: func(logData, file) {
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
    },

    #
    # @return void
    #
    loadAllData: func() {
        thread.newthread(func { me._loadAllData(); });
    },

    #
    # @return void
    #
    _loadAllData: func() {
        me._allData.clear();
        me._cachedData.clear();
        me._filters.clear();
        me._resetTotals();

        var file = io.open(me._filePath, "r");

        me._totalLines = -1; # don't count the headers
        var line = nil;
        while ((line = io.readln(file)) != nil) {
            if (line == "" or line == nil) { # skip empty row
                continue;
            }

            if (me._totalLines == -1) { # headers
                me._headersData = split(",", Utils.removeQuotes(line));
            }
            else { # data
                var items = split(",", Utils.removeQuotes(line));

                var logData = LogData.new();
                logData.fromVector(items);

                me._countTotals(logData.toListViewColumns(me._columns));

                me._filters.append(logData);
                me._allData.append(logData);

                me._cachedData.append({
                    id      : me._totalLines,
                    logData : logData,
                });
            }

            me._totalLines += 1;
        }

        io.close(file);

        me._filters.sort();

        # Un-dirty it, because this is the first loading and now everything is calculated, so the cache can be used
        me._filters.dirty = false;

        # Enable Logbook menu because we have a data
        gui.menuEnable("logbook-addon-main-dialog", true);

        Log.print("_loadAllData finished");
    },

    #
    # @param  hash  callback  Callback object called on finish.
    # @param  int  start  Start index counting from 0 as a first row of data.
    # @param  int  count  How many rows should be returned.
    # @param  bool  withHeaders  Set true when headers/filters must be change too in LogbookDialog canvas.
    # @return void
    #
    loadDataRange: func(callback, start, count, withHeaders) {
        me._callback    = callback;
        me._withHeaders = withHeaders;

        if (!me._filters.dirty and me._cachedData.size() > 0) {
            # Use a faster loop because we know that nothing has changed in the data

            me._loadedData.clear();
            var counter = 0;

            foreach (var hash; me._cachedData.vector[start:]) {
                var listViewColumns = hash.logData.toListViewColumns(me._columns);
                if (counter < count) {
                    me._loadedData.append({
                        id     : hash.id,
                        columns: listViewColumns,
                    });
                    counter += 1;
                }
                else {
                    break;
                }
            }

            # Add totals row to the end
            me._loadedData.append(me.getTotalsRow());

            # We have not used the thread here, but we must point out that it has ended
            g_isThreadPending = false;

            me._loadDataRangeThreadFinish();
        }
        else {
            # Run more complex loop with filters in a separate thread
            Thread.new().run(
                func { me._loadDataRange(start, count); },
                Callback.new(me._loadDataRangeThreadFinish, me),
                false,
            );
        }
    },

    #
    # @param  int  start  Start index counting from 0 as a first row of data.
    # @param  int  count  How many rows should be returned.
    # @return void
    #
    _loadDataRange: func(start, count) {
        me._loadedData.clear();

        var counter = 0;

        # Use a more complex loop because we know we have to recalculate everything from scratch

        var id = 0;
        me._cachedData.clear();
        me._resetTotals();
        me._totalLines = 0;

        foreach (var logData; me._allData.vector) {
            var listViewColumns = logData.toListViewColumns(me._columns);
            if (me._filters.isAllowedByFilter(logData)) {
                if (me._totalLines >= start and counter < count) {
                    me._loadedData.append({
                        id     : id,
                        columns: listViewColumns,
                    });
                    counter += 1;
                }

                me._totalLines += 1;
                me._countTotals(listViewColumns);

                me._cachedData.append({
                    id     : id,
                    logData: logData,
                });
            }

            id += 1;
        }

        # Add totals row to the end
        me._loadedData.append(me.getTotalsRow());

        me._filters.dirty = false;

        g_isThreadPending = false;
    },

    #
    # Callback function when the _loadDataRange finishes work.
    #
    # @return void
    #
    _loadDataRangeThreadFinish: func() {
        # Pass result to callback function
        me._callback.invoke(me._loadedData.vector, me._withHeaders);
    },

    #
    # Append totals row to loadedData.
    #
    # @return void
    #
    getTotalsRow: func() {
        var totalsData = [];
        var setTotalsLabel = false;

        foreach (var columnItem; me._columns.getAll()) {
            # For CSV always give everything regardless of visible flag
            # if (withCheckVisible and !columnItem.visible) {
            #     continue;
            # }

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

        return {
            id     : Columns.TOTALS_ROW_ID,
            columns: totalsData,
            font   : "LiberationFonts/LiberationMono-Bold.ttf",
        };
    },

    #
    # @param  int  rowIndex  Where 0 = first data row, not header row.
    # @param  string  columnName
    # @param  string  value
    # @return bool  Return true if successful.
    #
    editData: func(rowIndex, columnName, value) {
        if (rowIndex == nil or columnName == nil or value == nil) {
            Log.print("cannot save edited row");
            return false;
        }

        if (g_isThreadPending) {
            return false;
        }

        if (rowIndex < 0 or rowIndex >= me._allData.size()) {
            Log.print("cannot save edited row, index out of range");
            return false;
        }

        var columnIndex = me._columns.getColumnIndexByName(columnName);
        if (columnIndex == nil) {
            Log.print("cannot save edited row, columnName ", columnName, " not found");
            return false;
        }

        return Thread.new().run(
            func { me._editData(rowIndex, columnName, value, columnIndex); },
            Callback.new(me._editThreadFinish, me),
        );
    },

    #
    # @param  int  rowIndex  Where 0 = first data row, not header row.
    # @param  string  columnName
    # @param  string  value
    # @param  int  columnIndex
    # @return void
    #
    _editData: func(rowIndex, columnName, value, columnIndex) {
        var items = me._allData.vector[rowIndex].toVector(me._columns);

        if (columnName == Columns.DAY or columnName == Columns.NIGHT) {
            # Also update duration, which is the sum of day and night
            var oppositeColumn = columnName == Columns.DAY ? Columns.NIGHT : Columns.DAY;

            var oppositeIndex = me._columns.getColumnIndexByName(oppositeColumn);
            var durationIndex = me._columns.getColumnIndexByName(Columns.DURATION);

            if (oppositeIndex == nil or durationIndex == nil) {
                return;
            }

            items[durationIndex] = items[oppositeIndex] + value;
        }

        items[columnIndex] = value;
        me._allData.vector[rowIndex].fromVector(items);

        var columnItem = me._columns.getColumnByName(columnName);
        var reCalcTotals = columnItem.totals != nil;
        var resetFilters = me._filters.isColumnIndexFiltered(columnIndex);
        me._saveAllData(reCalcTotals, resetFilters);
    },

    #
    # Callback function when the editDataThread thread finishes work.
    #
    # @return void
    #
    _editThreadFinish: func() {
        gui.popupTip("The change has been saved!");

        # Get signal to reload data
        setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
    },

    #
    # @param  bool  reCalcTotals  Set true for recalculate totals, because data can changed.
    # @param  bool  resetFilters  Set true for reload filters, because data can changed.
    # @return void
    #
    _saveAllData: func(reCalcTotals, resetFilters) {
        # Do backup
        me._copyFile(me._filePath, me._filePath ~ ".bak");

        var file = io.open(me._filePath, "w");

        # Save headers
        io.write(file, me._getHeaderLine() ~ "\n");

        if (reCalcTotals) {
            me._resetTotals();
        }

        if (resetFilters) {
            me._filters.clear();
        }

        # Save data
        foreach (var logData; me._allData.vector) {
            me.addItem(logData, file);

            if (reCalcTotals) {
                me._countTotals(logData.toListViewColumns(me._columns));
            }

            if (resetFilters) {
                me._filters.append(logData);
            }
        }

        io.close(file);

        if (resetFilters) {
            me._filters.sort();
        }
    },

    #
    # Search header by text in given vector and return index of it.
    #
    # @param  string  headerText
    # @return int|nil
    #
    _getHeaderIndex: func(headerText) {
        if (g_isThreadPending) {
            return nil;
        }

        var index = 0;
        foreach (var text; me._headersData) {
            if (text == headerText) {
                return index;
            }

            index += 1;
        }

        return nil
    },

    #
    # Increase values in totals with given items data.
    #
    # @param  vector  columns  Vector of hashes, prepared to list view.
    # @return void
    #
    _countTotals: func(columns) {
        forindex (var index; columns) {
            var column = columns[index];

            var columnItem = me._columns.getColumnByIndex(index);
            if (columnItem == nil or columnItem.totals == nil) {
                continue;
            }

            if (columnItem.name == Columns.MAX_ALT) {
                if (num(column.data) > columnItem.totalVal) {
                    me._columns.setTotalValueByColumnName(columnItem.name, num(column.data));
                }
            }
            else {
                var value = columnItem.totalVal + (column.data == "" ? 0 : num(column.data));
                me._columns.setTotalValueByColumnName(columnItem.name, value);
            }
        }
    },

    #
    # Get total number of rows in CSV file (excluded headers row).
    #
    # @return int
    #
    getTotalLines: func() {
        return me._totalLines;
    },

    #
    # Get vector of data row by given index of row.
    #
    # @param  int  index  If -1 then return data with totals row.
    # @return hash|nil
    #
    getLogData: func(index) {
        if (g_isThreadPending) {
            Log.alert("getLogData in g_isThreadPending = true, return nil");
            return nil;
        }

        if (index == Columns.TOTALS_ROW_ID) {
            return me.getTotalsRow();
        }

        if (index == nil or index < 0 or index >= me._allData.size()) {
            Log.alert("getLogData, index(", index, ") out of range, return nil");
            return nil;
        }

        return {
            id     : index,
            columns: me._allData.vector[index].toListViewColumns(me._columns)
        };
    },

    #
    # @param  int  index  Index to delete.
    # @return bool
    #
    deleteLog: func(index) {
        if (index < 0 or index >= me._allData.size()) {
            Log.print("index out of range in deleteLog");
            return false;
        }

        return Thread.new().run(
            func { me._deleteLog(index); },
            Callback.new(me._deleteThreadFinish, me),
        );
    },

    #
    # @param  int  index  Index to delete.
    # @return void
    #
    _deleteLog: func(index) {
        me._allData.pop(index);

        me._totalLines -= 1;

        var reCalcTotals = true;
        var resetFilters = true;
        me._saveAllData(reCalcTotals, resetFilters);
    },

    #
    # Callback function when the deleteLogThread finishes work.
    #
    # @return void
    #
    _deleteThreadFinish: func() {
        gui.popupTip("The log has been deleted!");

        # Get signal to reload data
        setprop(me._addonNodePath ~ "/addon-devel/logbook-entry-deleted", true);
        setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
    },

    #
    # This is using only for SQLite version.
    #
    # @param  int|nil  index  Index to delete.
    # @return bool
    #
    deleteLogQuiet: func(index) {
        return false;
    },

    #
    # Export logbook from SQLite to CSV file as a separate thread job.
    #
    # @return void
    #
    exportToCsv: func() {
        gui.popupTip("This option is available only for FlightGear 2024.1 and later");
    },

    #
    # Insert current data to trackers table. This is using only for SQLite version.
    #
    # @param  int|nil  logbookId  Record ID of `logbooks` table.
    # @param  hash  data  Hash with data.
    # @return bool
    #
    addTrackerItem: func(logbookId, data) {
        Log.print("CSV version doesn't support tracker");

        return false;
    },
};
