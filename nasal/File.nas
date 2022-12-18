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
    FILE_VERSION     : "2",
    INDEX_DATE       : 0,
    INDEX_TIME       : 1,
    INDEX_AIRCRAFT   : 2,
    INDEX_TYPE       : 3,
    INDEX_CALLSIGN   : 4,
    INDEX_FROM       : 5,
    INDEX_TO         : 6,
    INDEX_LANDINGS   : 7,
    INDEX_CRASH      : 8,
    INDEX_DAY        : 9,
    INDEX_NIGHT      : 10,
    INDEX_INSTRUMENT : 11,
    INDEX_DURATION   : 12,
    INDEX_DISTANCE   : 13,
    INDEX_FUEL       : 14,
    INDEX_MAX_ALT    : 15,
    INDEX_NOTE       : 16,

    #
    # Constructor
    #
    # hash addon - addons.Addon object
    # return me
    #
    new: func (addon, filters) {
        var me = {
            parents : [File],
            addon   : addon,
            filters : filters,
        };

        me.filePath      = addon.storagePath ~ "/" ~ sprintf(File.LOGBOOK_FILE, File.FILE_VERSION);
        me.addonNodePath = me.addon.node.getPath();
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
    # return void
    #
    resetTotals: func() {
        # Total amount of Landings, Crash, Day, Night, Instrument, Duration, Distance, Fuel, Max Alt
        me.totals = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    },

    #
    # return bool - Return true if migration was done
    #
    migrateVersion: func() {
        var olderReleases = [
            # Keep the order from the newest to oldest
            "1.0.1",
            "1.0.0",
        ];

        foreach (var oldVersion; olderReleases) {
            var oldFile = me.addon.storagePath ~ "/" ~ sprintf(File.LOGBOOK_FILE, oldVersion);
            if (me.exists(oldFile)) {
                if (File.FILE_VERSION == "2") {
                    FileMigration.new(me).migrateToFileVersion_2(oldFile, me.filePath);
                }
                else {
                    # Nothing changed, just copy whole file
                    me.copyFile(oldFile, me.filePath);
                }

                return true;
            }
        }

        return false;
    },

    #
    # Copy file from older version to the newest
    #
    # string oldFile
    # return void
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
    # return void
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
    # return string
    #
    getHeaderLine: func() {
        return 'Date,' ~
               'Time,' ~
               'Aircraft,' ~
               'Type,' ~
               'Callsign,' ~
               'From,' ~
               'To,' ~
               'Landings,' ~
               'Crash,' ~
               'Day,' ~
               'Night,' ~
               'Instrument,' ~
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
    # string path
    # return bool
    #
    exists: func(path) {
        return io.stat(path) != nil;
    },

    #
    # Store log data to logbook file
    #
    # hash logData - LogData object
    # bool onlyIO - Set true for execute only I/O operation on the file, without rest of stuff
    # return void
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
    # hash file - file handler
    # hash logData - LogData object
    # return void
    #
    saveItem: func(file, logData) {
        io.write(file, sprintf(
            "%s,%s,%s,%s,%s,%s,%s,%d,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
            logData.date,
            logData.time,
            logData.aircraft,
            logData.aircraftType,
            logData.callsign,
            logData.from,
            logData.to,
            logData.landings,
            logData.printCrash(),
            logData.day,
            logData.night,
            logData.instrument,
            logData.duration,
            logData.distance,
            logData.fuel,
            logData.maxAlt,
            logData.note
        ));
    },

    #
    # return void
    #
    loadAllData: func() {
        thread.newthread(func { me.loadAllDataThread(); });
    },

    #
    # return void
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
                    "allDataIndex" : me.totalLines,
                    "logData" : logData,
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
    # int start - Start index counting from 0 as a first row of data
    # int count - How many rows should be returned
    # return vector
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
                        "allDataIndex" : hash.allDataIndex,
                        "data" : vectorLogData,
                    });
                    counter += 1;
                }
                else {
                    break;
                }
            }

            call(me.callback, [me.loadedData, me.totals, me.withHeaders], me.objCallback);
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
    # int start - Start index counting from 0 as a first row of data
    # int count - How many rows should be returned
    # return void
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
                        "allDataIndex" : allDataIndex,
                        "data" : vectorLogData,
                    });
                    counter += 1;
                }

                me.totalLines += 1;
                me.countTotals(vectorLogData);

                me.cachedData.append({
                    "allDataIndex" : allDataIndex,
                    "logData" : logData,
                });
            }

            allDataIndex += 1;
        }

        me.filters.dirty = false;

        g_isThreadPanding = false;
    },

    #
    # Callback function when the loadDataRangeThread finishes work
    #
    # return void
    #
    loadDataRangeThreadFinish: func() {
        # Pass result to callback function
        call(me.callback, [me.loadedData, me.totals, me.withHeaders], me.objCallback);
    },

    #
    # int rowIndex - where 0 = first data row, not header row
    # string header
    # string value
    # return bool - Return true if successful
    #
    editData: func(rowIndex, header, value) {
        if (rowIndex == nil or header == nil or value == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row");
            return false;
        }

        if (g_isThreadPanding) {
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
    # int rowIndex - where 0 = first data row, not header row
    # string header
    # string value
    # int headerIndex
    # return void
    #
    editDataThread: func(rowIndex, header, value, headerIndex) {
        var items = me.allData.vector[rowIndex].toVector();
        items[headerIndex] = value;
        me.allData.vector[rowIndex].fromVector(items);

        var recalcTotals = headerIndex >= File.INDEX_LANDINGS and headerIndex <= File.INDEX_MAX_ALT;
        var resetFilters = me.filters.isColumnIndexFiltered(headerIndex);
        me.saveAllData(recalcTotals, resetFilters);
    },

    #
    # Callback function when the editDataThread thread finishes work
    #
    # return void
    #
    editThreadFinish: func() {
        gui.popupTip("The change has been saved!");

        # Get signal to reload data
        setprop(me.addonNodePath ~ "/addon-devel/reload-logbook", true);
    },

    #
    # bool recalcTotals - Set true for recalculate totals, because data can changed
    # bool resetFilters - Set true for reload filters, because data can changed
    # return void
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
    # string headerText
    # vector headersData
    # return int|nil
    #
    getHeaderIndex: func(headerText, headersData) {
        if (g_isThreadPanding) {
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
    # string text
    # return string
    #
    removeQuotes: func(text) {
        return string.replace(text, '"', '');
    },

    #
    # Increase values in me.totals vector with given items data
    #
    # vector items
    # return void
    #
    countTotals: func(items) {
        var index = 0;
        foreach (var text; items) {
            if (index >= File.INDEX_LANDINGS and
                index <= File.INDEX_FUEL
            ) {
                me.totals[index - File.INDEX_LANDINGS] += (text == "" ? 0 : text);
            }
            else if (index == File.INDEX_MAX_ALT) {
                if (text > me.totals[index - File.INDEX_LANDINGS]) {
                    me.totals[index - File.INDEX_LANDINGS] = text;
                }
            }

            index += 1;
        }
    },

    #
    # Get total number of rows in CSV file (excluded headers row)
    #
    # return int
    #
    getTotalLines: func() {
        me.totalLines;
    },

    #
    # Get vector with headers names
    #
    # return vector
    #
    getHeadersData: func() {
        me.headersData;
    },

    #
    # Get vector of data row by given index of row
    #
    # int index
    # return hash
    #
    getLogData: func(index) {
        if (g_isThreadPanding) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - getLogData in g_isThreadPanding = true, return nil");
            return nil;
        }

        return {
            "allDataIndex" : index,
            "data" : me.allData.vector[index].toVector()
        };
    },

    #
    # int index - Index to delete
    # return bool
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
    # int index - Index to delete
    # return void
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
    # return void
    #
    deleteThreadFinish: func() {
        gui.popupTip("The log has been deleted!");

        # Get signal to reload data
        setprop(me.addonNodePath ~ "/addon-devel/logbook-entry-deleted", true);
        setprop(me.addonNodePath ~ "/addon-devel/reload-logbook", true);
    },
};
