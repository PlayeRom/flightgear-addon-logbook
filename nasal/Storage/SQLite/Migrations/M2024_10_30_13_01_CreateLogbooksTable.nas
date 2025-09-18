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

var M2024_10_30_13_01_CreateLogbooksTable = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents : [
                M2024_10_30_13_01_CreateLogbooksTable,
                MigrationBase.new(),
            ],
        };
    },

    #
    # Run the migrations
    #
    # @return void
    #
    up: func() {
        me._migrateCsvToLatestVersion();
        me._createLogbooksTable();
        me._importCsvToDb();
    },

    #
    # Migrate CSV file to the latest version
    #
    # @return void
    #
    _migrateCsvToLatestVersion: func() {
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
            var oldFile = me._getPathToCsvFile(oldVersion);
            if (Utils.fileExists(oldFile)) {
                if (oldVersion == "1.0.1" or oldVersion == "1.0.0") {
                    # If there is no version 2 file, but older ones exist, migrate to version 2 first
                    var file_v2 = me._getPathToCsvFile("2");
                    migrationCsv.migrateToFileVersion_2(oldFile, file_v2);

                    # Prepare variables to next migration
                    oldFile = file_v2;
                    oldVersion = "2";
                }

                if (oldVersion == "2") {
                    var file_v3 = me._getPathToCsvFile("3");
                    migrationCsv.migrateToFileVersion_3(oldFile, file_v3);
                    # Prepare variables to next migration
                    oldFile = file_v3;
                    oldVersion = "3";
                }

                if (oldVersion == "3") {
                    var file_v4 = me._getPathToCsvFile("4");
                    migrationCsv.migrateToFileVersion_4(oldFile, file_v4);
                    # Prepare variables to next migration
                    oldFile = file_v4;
                    oldVersion = "4";
                }

                if (oldVersion == "4") {
                    var file_v5 = me._getPathToCsvFile("5");
                    migrationCsv.migrateToFileVersion_5(oldFile, file_v5);
                }

                return;
            }
        }
    },

    #
    # @param  string  version
    # @return string  Full path to file
    #
    _getPathToCsvFile: func(version) {
        return g_Addon.storagePath ~ "/" ~ sprintf(Storage.CSV_LOGBOOK_FILE, version);
    },

     #
    # Create a `logbooks` table in the database
    #
    # @return void
    #
    _createLogbooksTable: func() {
        var columns = [
            { name: "id",            type: "INTEGER PRIMARY KEY" },
            { name: "date",          type: "TEXT" },
            { name: "time",          type: "TEXT" },
            { name: "aircraft",      type: "TEXT" },
            { name: "variant",       type: "TEXT" },
            { name: "aircraft_type", type: "TEXT" },
            { name: "callsign",      type: "TEXT" },
            { name: "from",          type: "TEXT" },
            { name: "to",            type: "TEXT" },
            { name: "landing",       type: "INTEGER" },
            { name: "crash",         type: "INTEGER" },
            { name: "day",           type: "REAL" },
            { name: "night",         type: "REAL" },
            { name: "instrument",    type: "REAL" },
            { name: "multiplayer",   type: "REAL" },
            { name: "swift",         type: "REAL" },
            { name: "duration",      type: "REAL" },
            { name: "distance",      type: "REAL" },
            { name: "fuel",          type: "REAL" },
            { name: "max_alt",       type: "REAL" },
            { name: "note",          type: "TEXT" },
        ];

        me.createTable(Storage.TABLE_LOGBOOKS, columns);
    },

    #
    # Import data from CSV file to DB
    #
    # @return void
    #
    _importCsvToDb: func() {
        var csvFile = me._getPathToCsvFile(Storage.CSV_FILE_VERSION);
        if (!Utils.fileExists(csvFile)) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on, importCsvToDb failed, file \"", csvFile, "\" doesn't exist");
            return;
        }

        var file = io.open(csvFile, "r");

        var query = sprintf("INSERT INTO %s VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", Storage.TABLE_LOGBOOKS);
        var stmt = DB.prepare(query);

        var counter = -1; # from -1 for don't count the headers
        while ((line = io.readln(file)) != nil) {
            if (line == "" or line == nil) {
                continue; # skip empty row
            }

            if (counter > -1) { # skip headers
                var items = split(",", Utils.removeQuotes(line));

                DB.exec(
                    stmt,
                    items[0],           # date
                    items[1],           # time
                    items[2],           # aircraft
                    items[3],           # variant
                    items[4],           # aircraft_type
                    items[5],           # callsign
                    items[6],           # from
                    items[7],           # to
                    num(items[8]) == 1, # landing
                    num(items[9]) == 1, # crash
                    num(items[10]),     # day
                    num(items[11]),     # night
                    num(items[12]),     # instrument
                    num(items[13]),     # multiplayer
                    num(items[14]),     # swift
                    num(items[15]),     # duration
                    num(items[16]),     # distance
                    num(items[17]),     # fuel
                    num(items[18]),     # max_alt
                    items[19],          # note
                );
            }

            counter += 1;
        }

        io.close(file);

        DB.finalize(stmt);
    },
};
