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

var M2024_10_30_31_01_CreateLogbooksTable = {
    #
    # Constructor
    #
    # @param  hash  storageSQLite  StorageSQLite object
    # @return me
    #
    new: func(storageSQLite) {
        return {
            parents : [
                M2024_10_30_31_01_CreateLogbooksTable,
                MigrationBase.new(storageSQLite.dbHandler),
            ],
            storageSQLite: storageSQLite,
        };
    },

    #
    # Run the migrations
    #
    # @return void
    #
    up: func() {
        me._createLogbooksTable();
        me._importCsvToDb();
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

        call(MigrationBase.createTable, [StorageSQLite.TABLE_LOGBOOKS, columns], me);
    },

    #
    # Import data from CSV file to DB
    #
    # @return void
    #
    _importCsvToDb: func() {
        var csvFile = g_Addon.storagePath ~ "/" ~ sprintf(StorageCsv.LOGBOOK_FILE, StorageCsv.FILE_VERSION);
        if (!Utils.fileExists(csvFile)) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on, importCsvToDb failed, file \"", csvFile, "\" doesn't exist");
            return;
        }

        var file = io.open(csvFile, "r");

        var counter = -1; # from -1 for don't count the headers
        while ((line = io.readln(file)) != nil) {
            if (line == "" or line == nil) {
                continue; # skip empty row
            }

            if (counter > -1) { # skip headers
                var items = split(",", Utils.removeQuotes(line));

                var logData = LogData.new();
                logData.fromVector(items);

                me.storageSQLite.addItem(logData);
            }

            counter += 1;
        }

        io.close(file);
    },
};