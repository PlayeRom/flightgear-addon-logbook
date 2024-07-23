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
# File class to save data to the logbook CSV file
#
var File = {
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
    # @param hash addon - addons.Addon object
    # @param hash filters - Filters object
    # @return me
    #
    new: func (addon, filters) {
        var me = {
            parents : [File],
            addon   : addon,
            filters : filters,
        };

        me.filePath      = me.getPathToFile(File.FILE_VERSION);
        me.addonNodePath = me.addon.node.getPath();
        me.fileMigration = nil;
        me.loadedData    = [];
        me.headersData   = [];
        me.withHeaders   = true;
        me.allData       = std.Vector.new();

        # Temporary filtered data as a cache for optimized viewing of large logs
        me.cachedData    = std.Vector.new();

        me.totals        = [];
        me.resetTotals();

        # Total lines in CSV file (without headers)
        me.totalLines    = -1;

        me.saveHeaders();

        # Callback for return results of loadDataRange
        me.objCallback = nil;
        me.callback    = func;

        return me;
    },

    #
    # @param string version
    # return string - full path to file
    #
    getPathToFile: func(version) {
        return me.addon.storagePath ~ "/" ~ sprintf(File.LOGBOOK_FILE, version);
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
    # @return bool - Return true if migration was done
    #
    migrateVersion: func() {
        me.fileMigration = FileMigration.new(me);

        var olderReleases = [
            # Keep the order from the newest to oldest
            "4",
            "3",
            "2",
            "1.0.1", # nothing has changed from v.1.0.0, so 1.0.0 = 1.1.0
            "1.0.0",
        ];

        foreach (var oldVersion; olderReleases) {
            var oldFile = me.getPathToFile(oldVersion);
            if (me.exists(oldFile)) {
                if (oldVersion == "1.0.1" or oldVersion == "1.0.0") {
                    # If there is no version 2 file, but older ones exist, migrate to version 2 first
                    var file_v2 = me.getPathToFile("2");
                    me.fileMigration.migrateToFileVersion_2(oldFile, file_v2);

                    # Prepare variables to next migration
                    oldFile = file_v2;
                    oldVersion = "2";
                }

                if (oldVersion == "2") {
                    var file_v3 = me.getPathToFile("3");
                    me.fileMigration.migrateToFileVersion_3(oldFile, file_v3);
                    # Prepare variables to next migration
                    oldFile = file_v3;
                    oldVersion = "3";
                }

                if (oldVersion == "3") {
                    var file_v4 = me.getPathToFile("4");
                    me.fileMigration.migrateToFileVersion_4(oldFile, file_v4);
                    # Prepare variables to next migration
                    oldFile = file_v4;
                    oldVersion = "4";
                }

                if (oldVersion == "4") {
                    me.fileMigration.migrateToFileVersion_5(oldFile, me.filePath);
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
    copyFile: func(oldFile, newFile) {
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
    saveHeaders: func() {
        if (!me.exists(me.filePath)) {
            if (!me.migrateVersion()) {
                var file = io.open(me.filePath, "a");
                io.write(file, me.getHeaderLine() ~ "\n");
                io.close(file);
            }
        }
    },

    #
    # @return string
    #
    getHeaderLine: func() {
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
    # Check that file already exists.
    # From FG 2020.4 (next) we have io.exists() but for older versions we have to write it ourselves.
    #
    # @param string path
    # @return bool
    #
    exists: func(path) {
        return io.stat(path) != nil;
    },

    #
    # Store log data to logbook file
    #
    # @param hash logData - LogData object
    # @param bool onlyIO - Set true for execute only I/O operation on the file, without rest of stuff
    # @return void
    #
    saveData: func(logData, onlyIO = 0) {
        var file = io.open(me.filePath, "a");
        me.saveItem(file, logData);
        io.close(file);

        if (!onlyIO) {
            me.allData.append(logData);
            me.filters.append(logData);
            me.filters.sort();
            me.totalLines += 1;
            me.countTotals(logData.toVector());
            me.filters.dirty = true;
        }
    },

    #
    # @param hash file - file handler
    # @param hash logData - LogData object
    # @return void
    #
    saveItem: func(file, logData) {
        io.write(file, sprintf(
            "%s,%s,\"%s\",%s,%s,%s,%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
            logData.date,
            logData.time,
            logData.aircraft,
            logData.variant,
            logData.aircraftType,
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
            logData.maxAlt,
            logData.note
        ));
    },

    #
    # @return void
    #
    loadAllData: func() {
        thread.newthread(func { me.loadAllDataThread(); });
    },

    #
    # @return void
    #
    loadAllDataThread: func() {
        me.allData.clear();
        me.cachedData.clear();
        me.filters.clear();
        me.resetTotals();

        var file = io.open(me.filePath, "r");

        me.totalLines = -1; # don't count the headers
        var line = nil;
        while ((line = io.readln(file)) != nil) {
            if (line == "" or line == nil) { # skip empty row
                continue;
            }

            if (me.totalLines == -1) { # headers
                me.headersData = split(",", me.removeQuotes(line));
            }
            else { # data
                var items = split(",", me.removeQuotes(line));

                var logData = LogData.new();
                logData.fromVector(items);

                me.countTotals(items);

                me.filters.append(logData);
                me.allData.append(logData);

                me.cachedData.append({
                    allDataIndex : me.totalLines,
                    logData      : logData,
                });
            }

            me.totalLines += 1;
        }

        io.close(file);

        me.filters.sort();

        # Un-dirty it, because this is the first loading and now everything is calculated, so the cache can be used
        me.filters.dirty = false;

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
        me.objCallback = objCallback;
        me.callback    = callback;
        me.withHeaders = withHeaders;

        if (!me.filters.dirty and me.cachedData.size() > 0) {
            # Use a faster loop because we know that nothing has changed in the data

            me.loadedData = [];
            var counter = 0;

            foreach (var hash; me.cachedData.vector[start:]) {
                var vectorLogData = hash.logData.toVector();
                if (counter < count) {
                    append(me.loadedData, {
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
            me.appendTotalsRow();

            # We have not used the thread here, but we must point out that it has ended
            g_isThreadPending = false;

            call(me.callback, [me.loadedData, me.withHeaders], me.objCallback);
        }
        else {
            # Run more complex loop with filters in a separate thread
            Thread.new().run(
                func { me.loadDataRangeThread(start, count); },
                me,
                me.loadDataRangeThreadFinish,
                false
            );
        }
    },

    #
    # @param int start - Start index counting from 0 as a first row of data
    # @param int count - How many rows should be returned
    # @return void
    #
    loadDataRangeThread: func(start, count) {
        me.loadedData = [];

        var counter = 0;

        # Use a more complex loop because we know we have to recalculate everything from scratch

        var allDataIndex = 0;
        me.cachedData.clear();
        me.resetTotals();
        me.totalLines = 0;

        foreach (var logData; me.allData.vector) {
            var vectorLogData = logData.toVector();
            if (me.filters.isAllowedByFilter(logData)) {
                if (me.totalLines >= start and counter < count) {
                    append(me.loadedData, {
                        allDataIndex : allDataIndex,
                        data         : vectorLogData,
                    });
                    counter += 1;
                }

                me.totalLines += 1;
                me.countTotals(vectorLogData);

                me.cachedData.append({
                    allDataIndex : allDataIndex,
                    logData      : logData,
                });
            }

            allDataIndex += 1;
        }

        # Add totals row to the end
        me.appendTotalsRow();

        me.filters.dirty = false;

        g_isThreadPending = false;
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
                sprintf(File.TOTAL_FORMATS[index], me.totals[index])
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

        if (rowIndex < 0 or rowIndex >= me.allData.size()) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, index out of range");
            return false;
        }

        var headerIndex = me.getHeaderIndex(header, me.headersData);
        if (headerIndex == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, header ", header, " not found");
            return false;
        }

        return Thread.new().run(
            func { me.editDataThread(rowIndex, header, value, headerIndex); },
            me,
            me.editThreadFinish
        );
    },

    #
    # @param int rowIndex - where 0 = first data row, not header row
    # @param string header
    # @param string value
    # @param int headerIndex
    # @return void
    #
    editDataThread: func(rowIndex, header, value, headerIndex) {
        var items = me.allData.vector[rowIndex].toVector();
        items[headerIndex] = value;
        me.allData.vector[rowIndex].fromVector(items);

        var recalcTotals = headerIndex >= File.INDEX_LANDING and headerIndex <= File.INDEX_MAX_ALT;
        var resetFilters = me.filters.isColumnIndexFiltered(headerIndex);
        me.saveAllData(recalcTotals, resetFilters);
    },

    #
    # Callback function when the editDataThread thread finishes work
    #
    # @return void
    #
    editThreadFinish: func() {
        gui.popupTip("The change has been saved!");

        # Get signal to reload data
        setprop(me.addonNodePath ~ "/addon-devel/reload-logbook", true);
    },

    #
    # @param bool recalcTotals - Set true for recalculate totals, because data can changed
    # @param bool resetFilters - Set true for reload filters, because data can changed
    # @return void
    #
    saveAllData: func(recalcTotals, resetFilters) {
        # Do backup
        me.copyFile(me.filePath, me.filePath ~ ".bak");

        var file = io.open(me.filePath, "w");

        # Save headers
        io.write(file, me.getHeaderLine() ~ "\n");

        if (recalcTotals) {
            me.resetTotals();
        }

        if (resetFilters) {
            me.filters.clear();
        }

        # Save data
        foreach (var logData; me.allData.vector) {
            me.saveItem(file, logData);

            if (recalcTotals) {
                me.countTotals(logData.toVector());
            }

            if (resetFilters) {
                me.filters.append(logData);
            }
        }

        io.close(file);

        if (resetFilters) {
            me.filters.sort();
        }
    },

    #
    # Search header by text in given vector and return index of it
    #
    # @param string headerText
    # @param vector headersData
    # @return int|nil
    #
    getHeaderIndex: func(headerText, headersData) {
        if (g_isThreadPending) {
            return nil;
        }

        var index = 0;
        foreach (var text; headersData) {
            if (text == headerText) {
                return index;
            }

            index += 1;
        }

        return nil
    },

    #
    # Remove all quotes from given text and return a new text without quotes
    #
    # @param string text
    # @return string
    #
    removeQuotes: func(text) {
        return string.replace(text, '"', '');
    },

    #
    # Increase values in me.totals vector with given items data
    #
    # @param vector items
    # @return void
    #
    countTotals: func(items) {
        var index = 0;
        foreach (var text; items) {
            var totalIndex = me.getTotalIndexFromColumnIndex(index);
            if (totalIndex != -1) {
                if (index == File.INDEX_MAX_ALT) {
                    if (text > me.totals[totalIndex]) {
                        me.totals[totalIndex] = text;
                    }
                }
                else {
                    me.totals[totalIndex] += (text == "" ? 0 : text);
                }
            }

            index += 1;
        }
    },

    #
    # @param int columnIndex
    # @return int
    #
    getTotalIndexFromColumnIndex: func(columnIndex) {
             if (columnIndex == File.INDEX_LANDING)     return 0; # me.totals[0]
        else if (columnIndex == File.INDEX_CRASH)       return 1; # me.totals[1] etc.
        else if (columnIndex == File.INDEX_DAY)         return 2;
        else if (columnIndex == File.INDEX_NIGHT)       return 3;
        else if (columnIndex == File.INDEX_INSTRUMENT)  return 4;
        else if (columnIndex == File.INDEX_MULTIPLAYER) return 5;
        else if (columnIndex == File.INDEX_SWIFT)       return 6;
        else if (columnIndex == File.INDEX_DURATION)    return 7;
        else if (columnIndex == File.INDEX_DISTANCE)    return 8;
        else if (columnIndex == File.INDEX_FUEL)        return 9;
        else if (columnIndex == File.INDEX_MAX_ALT)     return 10;

        return -1; # error
    },

    #
    # Get total number of rows in CSV file (excluded headers row)
    #
    # @return int
    #
    getTotalLines: func() {
        me.totalLines;
    },

    #
    # Get vector with headers names
    #
    # @return vector
    #
    getHeadersData: func() {
        me.headersData;
    },

    #
    # Get vector of data row by given index of row
    #
    # @param int index
    # @return hash|nil
    #
    getLogData: func(index) {
        if (index == nil or index < 0 or index >= me.allData.size()) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData, index(", index, ") out of range, return nil");
            return nil;
        }

        if (g_isThreadPending) {
            logprint(LOG_ALERT, "Logbook Add-on - getLogData in g_isThreadPending = true, return nil");
            return nil;
        }

        return {
            allDataIndex : index,
            data         : me.allData.vector[index].toVector()
        };
    },

    #
    # @param int index - Index to delete
    # @return bool
    #
    deleteLog: func(index) {
        if (index < 0 or index >= me.allData.size()) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - index out of range in deleteLog");
            return false;
        }

        return Thread.new().run(
            func { me.deleteLogThread(index); },
            me,
            me.deleteThreadFinish
        );
    },

    #
    # @param int index - Index to delete
    # @return void
    #
    deleteLogThread: func(index) {
        me.allData.pop(index);

        me.totalLines -= 1;

        var recalcTotals = true;
        var resetFilters = true;
        me.saveAllData(recalcTotals, resetFilters);
    },

    #
    # Callback function when the deleteLogThread finishes work
    #
    # @return void
    #
    deleteThreadFinish: func() {
        gui.popupTip("The log has been deleted!");

        # Get signal to reload data
        setprop(me.addonNodePath ~ "/addon-devel/logbook-entry-deleted", true);
        setprop(me.addonNodePath ~ "/addon-devel/reload-logbook", true);
    },
};
