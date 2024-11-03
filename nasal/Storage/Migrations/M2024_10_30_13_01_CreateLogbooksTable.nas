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
    # @param  hash  storageSQLite  StorageSQLite object
    # @return me
    #
    new: func(storageSQLite) {
        return {
            parents : [
                M2024_10_30_13_01_CreateLogbooksTable,
                MigrationBase.new(storageSQLite.getDbHandler()),
            ],
            _storageSQLite: storageSQLite,
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

        me.createTable(StorageSQLite.TABLE_LOGBOOKS, columns);
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

        var db = me._storageSQLite.getDbHandler();

        var file = io.open(csvFile, "r");

        var counter = -1; # from -1 for don't count the headers
        while ((line = io.readln(file)) != nil) {
            if (line == "" or line == nil) {
                continue; # skip empty row
            }

            if (counter > -1) { # skip headers
                var items = split(",", Utils.removeQuotes(line));

                var query = sprintf("INSERT INTO %s VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", StorageSQLite.TABLE_LOGBOOKS);
                var stmt = sqlite.prepare(db, query);
                sqlite.exec(db, stmt,
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
    },
};
