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
# Migration class for SQLite
#
var Migration = {
    #
    # Constructor
    #
    # @param  hash  storage  SQLite Storage object
    # @return me
    #
    new: func(storage) {
        var me = { parents: [Migration] };

        me._dbHandler = storage.getDbHandler();

        me._migrations = [
            {
                name: "M2024_10_30_08_44_CreateMigrationsTable", function: func() {
                    var migration = M2024_10_30_08_44_CreateMigrationsTable.new(storage);
                    migration.up();
                },
            },
            {
                name: "M2024_10_30_13_01_CreateLogbooksTable", function: func() {
                    var migration = M2024_10_30_13_01_CreateLogbooksTable.new(storage);
                    migration.up();
                },
            },
            {
                name: "M2024_11_04_11_53_AddSimTimeColumns", function: func() {
                    var migration = M2024_11_04_11_53_AddSimTimeColumns.new(storage);
                    migration.up();
                },
            },
            {
                name: "M2024_11_06_22_42_AddSpeedColumns", function: func() {
                    var migration = M2024_11_06_22_42_AddSpeedColumns.new(storage);
                    migration.up();
                },
            },
            {
                name: "M2024_11_06_22_50_CreateTrackersTable", function: func() {
                    var migration = M2024_11_06_22_50_CreateTrackersTable.new(storage);
                    migration.up();
                },
            }
            # Add next migration here...
        ];

        return me;
    },

    #
    # Follow me._migrations step by step, check if the migration name is already
    # in the database, if not then execute the migration function
    #
    # @return void
    #
    migrate: func() {
        foreach (var migration; me._migrations) {
            if (!me._isMigrationExists(migration.name)) {
                logprint(LOG_ALERT, "Logbook Add-on - call migration: ", migration.name);

                migration.function();

                me._confirmMigration(migration.name);
            }
        }
    },

    #
    # Check if the table in the database exists
    #
    # @return bool  True if the table already exists
    #
    _isTableExist: func(tableName) {
        var query = sprintf("SELECT name FROM sqlite_master WHERE type='table' AND name='%s'", tableName);
        var result = sqlite.exec(me._dbHandler, query);
        return size(result);
    },

    #
    # Check if the specified migration has already been invoked
    #
    # @param  string  migrationName
    # @return bool
    #
    _isMigrationExists: func(migrationName) {
        if (!me._isTableExist(Storage.TABLE_MIGRATIONS)) {
            # We don't even have the migrations table yet, this is when we first run it
            return false;
        }

        var query = sprintf("SELECT * FROM `%s` WHERE `migration` = ?", Storage.TABLE_MIGRATIONS);
        var stmt = sqlite.prepare(me._dbHandler, query);
        var rows = sqlite.exec(me._dbHandler, stmt, migrationName);
        return size(rows);
    },

    #
    # Save the migration name to the migrations table to confirm that the migration was invoked
    #
    # @param  string  migrationName
    # @return void
    #
    _confirmMigration: func(migrationName) {
        var query = sprintf("INSERT INTO `%s` VALUES (NULL, ?)", Storage.TABLE_MIGRATIONS);
        var stmt = sqlite.prepare(me._dbHandler, query);
        sqlite.exec(me._dbHandler, stmt, migrationName);
    },
};