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

        # Total amount of Landings, Crash, Day, Night, Instrument, Duration, Distance, Fuel, Max Alt
        me.totals = [0, 0, 0, 0, 0, 0, 0, 0, 0];

        # Total lines in CSV file (without headers)
        me.totalLines = -1;

        me.saveHeaders();

        return me;
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
                me.copyFile(oldFile);
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
    copyFile: func(oldFile) {
        var content = io.readfile(oldFile);

        var file = io.open(me.filePath, "w");
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
    # LogData logData - LogData object
    #
    saveData: func(logData) {
        var file = io.open(me.filePath, "a");
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
        io.close(file);
    },

    #
    # int start - Start index counting from 0 as a first row of data
    # int count - How many rows should be returned
    # return vector
    #
    loadData: func(start, count) {
        me.loadedData = [];
        me.totals = [0, 0, 0, 0, 0, 0, 0, 0, 0];

        var file = io.open(me.filePath, "r");

        me.totalLines = -1; # don't count the headers
        var counter = 0;
        var line = nil;
        while ((line = io.readln(file)) != nil) {
            if (line == "" or line == nil) { # skip empty row
                continue;
            }

            if (me.totalLines == -1) { # headers
                me.headersData = split(",", me.removeQuotes(line));
            }
            else { # data
                var items = split(",", line);
                me.countTotals(items);

                if (me.totalLines >= start and counter < count) {
                    # remove quotes from note column
                    items[File.INDEX_NOTE] = me.removeQuotes(items[File.INDEX_NOTE]);

                    append(me.loadedData, items);
                    counter += 1;
                }
            }

            me.totalLines += 1;
        }

        io.close(file);

        return me.loadedData;
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
};
