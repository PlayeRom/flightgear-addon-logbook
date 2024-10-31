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
# StorageCsv class to save logbook data to CSV file
#
# @deprecated This will be phased out in favor of StorageSQLite
#
var StorageCsv = {
    #
    # Constants
    #
    LOGBOOK_FILE     : "logbook-v%s.csv",
    FILE_VERSION     : "5",

    # Column indexes:
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

    TOTAL_FORMATS        : [
        "%d",   # landing
        "%d",   # crash
        "%.2f", # day
        "%.2f", # night
        "%.2f", # instrument
        "%.2f", # multiplayer
        "%.2f", # swift
        "%.2f", # duration
        "%.2f", # distance
        "%.0f", # fuel
        "%.0f", # max alt
    ],

    #
    # Constructor
    #
    # @param hash filters - Filters object
    # @return me
    #
    new: func(filters) {
        var me = {
            parents : [StorageCsv],
            _filters: filters,
        };

        me._filePath      = me._getPathToFile(StorageCsv.FILE_VERSION);
        me._addonNodePath = g_Addon.node.getPath();
        me._loadedData    = [];
        me._headersData   = [];
        me._withHeaders   = true;
        me._allData       = std.Vector.new();

        # Temporary filtered data as a cache for optimized viewing of large logs
        me._cachedData    = std.Vector.new();

        me._totals        = [];
        me._resetTotals();

        # Total lines in CSV file (without headers)
        me._totalLines    = -1;

        me._saveHeaders();

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
        #
    },

    #
    # @param string version
    # @return string - full path to file
    #
    _getPathToFile: func(version) {
        return g_Addon.storagePath ~ "/" ~ sprintf(StorageCsv.LOGBOOK_FILE, version);
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
    # @return bool - Return true if migration was done
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
    # Copy file from older version to the newest
    #
    # @param string oldFile
    # @param string newFile
    # @return void
    #
    _copyFile: func(oldFile, newFile) {
        var content = io.readfile(oldFile);

        var file = io.open(newFile, "w");
        io.write(file, content);
        io.close(file);
    },

    #
    # If logbook file doesn't exist then create it with headers
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
    # Store log data to logbook file
    #
    # @param  hash  logData  LogData object
    # @param  int  id|nill  Record ID for SQLite storage
    # @param  bool  onlyIO  Set true for execute only I/O operation on the file,
    #                       without rest of stuff (used only for CSV recovery)
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
            me._countTotals(logData.toVector());
            me._filters.dirty = true;
        }
    },

    #
    # @param hash logData - LogData object
    # @param hash file - file handler
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

                me._countTotals(items);

                me._filters.append(logData);
                me._allData.append(logData);

                me._cachedData.append({
                    allDataIndex : me._totalLines,
                    logData      : logData,
                });
            }

            me._totalLines += 1;
        }

        io.close(file);

        me._filters.sort();

        # Un-dirty it, because this is the first loading and now everything is calculated, so the cache can be used
        me._filters.dirty = false;

        # Enable Logbook menu because we have a data
        gui.menuEnable("logbook-addon", true);

        logprint(MY_LOG_LEVEL, "Logbook Add-on - loadAllDataThread finished");
    },

    #
    # @param hash objCallback - owner object of callback function
    # @param func callback - callback function called on finish
    # @param int start - Start index counting from 0 as a first row of data
    # @param int count - How many rows should be returned
    # @param bool withHeaders
    # @return void
    #
    loadDataRange: func(objCallback, callback, start, count, withHeaders) {
        me._objCallback = objCallback;
        me._callback    = callback;
        me._withHeaders = withHeaders;

        if (!me._filters.dirty and me._cachedData.size() > 0) {
            # Use a faster loop because we know that nothing has changed in the data

            me._loadedData = [];
            var counter = 0;

            foreach (var hash; me._cachedData.vector[start:]) {
                var vectorLogData = hash.logData.toVector();
                if (counter < count) {
                    append(me._loadedData, {
                        allDataIndex : hash.allDataIndex,
                        data         : vectorLogData,
                    });
                    counter += 1;
                }
                else {
                    break;
                }
            }

            # Add totals row to the end
            me._appendTotalsRow();

            # We have not used the thread here, but we must point out that it has ended
            g_isThreadPending = false;

            me._loadDataRangeThreadFinish();
        }
        else {
            # Run more complex loop with filters in a separate thread
            Thread.new().run(
                func { me._loadDataRange(start, count); },
                me,
                me._loadDataRangeThreadFinish,
                false
            );
        }
    },

    #
    # @param int start - Start index counting from 0 as a first row of data
    # @param int count - How many rows should be returned
    # @return void
    #
    _loadDataRange: func(start, count) {
        me._loadedData = [];

        var counter = 0;

        # Use a more complex loop because we know we have to recalculate everything from scratch

        var allDataIndex = 0;
        me._cachedData.clear();
        me._resetTotals();
        me._totalLines = 0;

        foreach (var logData; me._allData.vector) {
            var vectorLogData = logData.toVector();
            if (me._filters.isAllowedByFilter(logData)) {
                if (me._totalLines >= start and counter < count) {
                    append(me._loadedData, {
                        allDataIndex : allDataIndex,
                        data         : vectorLogData,
                    });
                    counter += 1;
                }

                me._totalLines += 1;
                me._countTotals(vectorLogData);

                me._cachedData.append({
                    allDataIndex : allDataIndex,
                    logData      : logData,
                });
            }

            allDataIndex += 1;
        }

        # Add totals row to the end
        me._appendTotalsRow();

        me._filters.dirty = false;

        g_isThreadPending = false;
    },

    #
    # Callback function when the _loadDataRange finishes work
    #
    # @return void
    #
    _loadDataRangeThreadFinish: func() {
        # Pass result to callback function
        call(me._callback, [me._loadedData, me._withHeaders], me._objCallback);
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
    # @param int rowIndex - where 0 = first data row, not header row
    # @param string header
    # @param string value
    # @return bool - Return true if successful
    #
    editData: func(rowIndex, header, value) {
        if (rowIndex == nil or header == nil or value == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row");
            return false;
        }

        if (g_isThreadPending) {
            return false;
        }

        if (rowIndex < 0 or rowIndex >= me._allData.size()) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, index out of range");
            return false;
        }

        var headerIndex = me._getHeaderIndex(header);
        if (headerIndex == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, header ", header, " not found");
            return false;
        }

        return Thread.new().run(
            func { me._editData(rowIndex, header, value, headerIndex); },
            me,
            me._editThreadFinish
        );
    },

    #
    # @param int rowIndex - where 0 = first data row, not header row
    # @param string header
    # @param string value
    # @param int headerIndex
    # @return void
    #
    _editData: func(rowIndex, header, value, headerIndex) {
        var items = me._allData.vector[rowIndex].toVector();
        items[headerIndex] = value;
        me._allData.vector[rowIndex].fromVector(items);

        var recalcTotals = headerIndex >= StorageCsv.INDEX_LANDING and headerIndex <= StorageCsv.INDEX_MAX_ALT;
        var resetFilters = me._filters.isColumnIndexFiltered(headerIndex);
        me._saveAllData(recalcTotals, resetFilters);
    },

    #
    # Callback function when the editDataThread thread finishes work
    #
    # @return void
    #
    _editThreadFinish: func() {
        gui.popupTip("The change has been saved!");

        # Get signal to reload data
        setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
    },

    #
    # @param bool recalcTotals - Set true for recalculate totals, because data can changed
    # @param bool resetFilters - Set true for reload filters, because data can changed
    # @return void
    #
    _saveAllData: func(recalcTotals, resetFilters) {
        # Do backup
        me._copyFile(me._filePath, me._filePath ~ ".bak");

        var file = io.open(me._filePath, "w");

        # Save headers
        io.write(file, me._getHeaderLine() ~ "\n");

        if (recalcTotals) {
            me._resetTotals();
        }

        if (resetFilters) {
            me._filters.clear();
        }

        # Save data
        foreach (var logData; me._allData.vector) {
            me.addItem(logData, file);

            if (recalcTotals) {
                me._countTotals(logData.toVector());
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
    # Search header by text in given vector and return index of it
    #
    # @param string headerText
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
    # Increase values in me._totals vector with given items data
    #
    # @param vector items
    # @return void
    #
    _countTotals: func(items) {
        var index = 0;
        foreach (var text; items) {
            var totalIndex = me._getTotalIndexFromColumnIndex(index);
            if (totalIndex != -1) {
                if (index == StorageCsv.INDEX_MAX_ALT) {
                    if (text > me._totals[totalIndex]) {
                        me._totals[totalIndex] = text;
                    }
                }
                else {
                    me._totals[totalIndex] += (text == "" ? 0 : text);
                }
            }

            index += 1;
        }
    },

    #
    # @param int columnIndex
    # @return int
    #
    _getTotalIndexFromColumnIndex: func(columnIndex) {
             if (columnIndex == StorageCsv.INDEX_LANDING)     return 0; # me._totals[0]
        else if (columnIndex == StorageCsv.INDEX_CRASH)       return 1; # me._totals[1] etc.
        else if (columnIndex == StorageCsv.INDEX_DAY)         return 2;
        else if (columnIndex == StorageCsv.INDEX_NIGHT)       return 3;
        else if (columnIndex == StorageCsv.INDEX_INSTRUMENT)  return 4;
        else if (columnIndex == StorageCsv.INDEX_MULTIPLAYER) return 5;
        else if (columnIndex == StorageCsv.INDEX_SWIFT)       return 6;
        else if (columnIndex == StorageCsv.INDEX_DURATION)    return 7;
        else if (columnIndex == StorageCsv.INDEX_DISTANCE)    return 8;
        else if (columnIndex == StorageCsv.INDEX_FUEL)        return 9;
        else if (columnIndex == StorageCsv.INDEX_MAX_ALT)     return 10;

        return -1; # error
    },

    #
    # Get total number of rows in CSV file (excluded headers row)
    #
    # @return int
    #
    getTotalLines: func() {
        return me._totalLines;
    },

    #
    # Get vector with headers names
    #
    # @return vector
    #
    getHeadersData: func() {
        return me._headersData;
    },

    #
    # Get vector of data row by given index of row
    #
    # @param int index
    # @return hash|nil
    #
    getLogData: func(index) {
        if (index == nil or index < 0 or index >= me._allData.size()) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData, index(", index, ") out of range, return nil");
            return nil;
        }

        if (g_isThreadPending) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData in g_isThreadPending = true, return nil");
            return nil;
        }

        return {
            allDataIndex : index,
            data         : me._allData.vector[index].toVector()
        };
    },

    #
    # @param int index - Index to delete
    # @return bool
    #
    deleteLog: func(index) {
        if (index < 0 or index >= me._allData.size()) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - index out of range in deleteLog");
            return false;
        }

        return Thread.new().run(
            func { me._deleteLog(index); },
            me,
            me._deleteThreadFinish
        );
    },

    #
    # @param int index - Index to delete
    # @return void
    #
    _deleteLog: func(index) {
        me._allData.pop(index);

        me._totalLines -= 1;

        var recalcTotals = true;
        var resetFilters = true;
        me._saveAllData(recalcTotals, resetFilters);
    },

    #
    # Callback function when the deleteLogThread finishes work
    #
    # @return void
    #
    _deleteThreadFinish: func() {
        gui.popupTip("The log has been deleted!");

        # Get signal to reload data
        setprop(me._addonNodePath ~ "/addon-devel/logbook-entry-deleted", true);
        setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
    },
};
