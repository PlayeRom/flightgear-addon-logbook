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
    LOGBOOK_FILE   : "logbook-v%s.csv",
    FILE_VERSION   : "1.0.1",
    INDEX_LANDINGS : 6,
    INDEX_FUEL     : 13,
    INDEX_MAX_ALT  : 14,
    INDEX_NOTE     : 15,

    #
    # Constructor
    #
    # addons.Addon addon
    #
    new: func (addon) {
        var me = { parents: [File] };

        me.addon       = addon;
        me.filePath    = addon.storagePath ~ "/" ~ sprintf(File.LOGBOOK_FILE, File.FILE_VERSION);
        me.loadedData  = [];
        me.headersData = [];

        me.allData     = [];

        me.totals      = [];
        me.resetTotals();

        # Total lines in CSV file (without headers)
        me.totalLines  = -1;

        me.saveHeaders();

        return me;
    },

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
            "1.0.0",
        ];

        foreach (var oldVersion; olderReleases) {
            var oldFile = me.addon.storagePath ~ "/" ~ sprintf(File.LOGBOOK_FILE, oldVersion);
            if (me.exists(oldFile)) {
                me.copyFile(oldFile, me.filePath);
                return true;
            }
        }

        return false;
    },

    #
    # Copy file from older version to the newest
    #
    # string oldFile
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
    # return bool
    #
    exists: func(path) {
        return io.stat(path) != nil;
    },

    #
    # Store log data to logbook file
    #
    # hash logData - LogData object
    # return void
    #
    saveData: func(logData) {
        var file = io.open(me.filePath, "a");
        me.saveItem(file, logData);
        io.close(file);

        append(me.allData, logData);
        me.totalLines += 1;
        me.countTotals(logData.toVector());
    },

    #
    # hash file - file handler
    # hash logData - LogData object
    # return void
    #
    saveItem: func(file, logData) {
        io.write(file, sprintf(
            "%s,%s,%s,%s,%s,%s,%d,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
            logData.date,
            logData.time,
            logData.aircraft,
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
        me.allData = [];
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

                append(me.allData, logData);
            }

            me.totalLines += 1;
        }

        io.close(file);
    },

    #
    # int start - Start index counting from 0 as a first row of data
    # int count - How many rows should be returned
    # return vector
    #
    loadDataRange: func(start, count) {
        me.loadedData = [];

        if (size(me.allData) > 0) {
            var counter = 0;
            foreach (var logData; me.allData[start:]) {
                if (counter < count) {
                    append(me.loadedData, logData.toVector());
                    counter += 1;
                }
                else {
                    break;
                }
            }
        }

        return me.loadedData;
    },

    #
    # int rowIndex - where 0 = first data row, now header row
    # string header
    # string value
    # return bool - Return true of successful
    #
    editData: func(rowIndex, header, value) {
        if (rowIndex == nil or header == nil or value == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row");
            return false;
        }

        if (rowIndex >= size(me.allData)) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, index out of range");
            return false;
        }

        var headerIndex = me.getHeaderIndex(header, me.headersData);
        if (headerIndex == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - cannot save edited row, header ", header, " not found");
            return false;
        }

        var items = me.allData[rowIndex].toVector();
        items[headerIndex] = value;
        me.allData[rowIndex].fromVector(items);

        var recalcTotals = headerIndex >= File.INDEX_LANDINGS and headerIndex <= File.INDEX_MAX_ALT;
        me.saveAllData(recalcTotals);

        return true;
    },

    #
    # bool recalcTotals
    # return void
    #
    saveAllData: func(recalcTotals) {
        # Do backup
        me.copyFile(me.filePath, me.filePath ~ ".bak");

        var file = io.open(me.filePath, "w");

        # Save headers
        io.write(file, me.getHeaderLine() ~ "\n");

        # Save data
        if (recalcTotals) {
            me.resetTotals();
        }

        foreach (var logData; me.allData) {
            me.saveItem(file, logData);

            # Recalculate totals, because data can changed
            if (recalcTotals) {
                me.countTotals(logData.toVector());
            }
        }

        io.close(file);
    },

    #
    # string headerText
    # vector headersData
    # return int|nil
    #
    getHeaderIndex: func(headerText, headersData) {
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
    # string text
    # return string
    #
    removeQuotes: func(text) {
        return string.replace(text, '"', '');
    },

    #
    # vector items
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
    # return vector
    #
    getTotalsData: func() {
        return me.totals;
    },

    #
    # return int
    #
    getTotalLines: func() {
        me.totalLines;
    },

    #
    # return vector
    #
    getHeadersData: func() {
        me.headersData;
    },

    #
    # int index
    # return vector
    #
    getLogData: func(index) {
        return me.allData[index].toVector();
    },
};
