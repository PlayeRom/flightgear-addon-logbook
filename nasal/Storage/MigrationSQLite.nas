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
# MigrationSQLite class
#
var MigrationSQLite = {
    #
    # Constructor
    #
    # @param  hash  storageSQLite  StorageSQLite object
    # @return me
    #
    new: func(storageSQLite) {
        var me = { parents: [MigrationSQLite] };

        me.dbHandler = storageSQLite.dbHandler;

        me.migrations = {
            "M2024_10_30_08_44_CreateMigrationsTable": func() {
                var migration = M2024_10_30_08_44_CreateMigrationsTable.new(storageSQLite);
                migration.up();
            },
            "M2024_10_30_13_01_CreateLogbooksTable": func() {
                var migration = M2024_10_30_13_01_CreateLogbooksTable.new(storageSQLite);
                migration.up();
            },
            # Add next migration here...
        };

        return me;
    },

    #
    # Follow me.migrations step by step, check if the migration name is already
    # in the database, if not then execute the migration function
    #
    # @return void
    #
    migrate: func() {
        foreach (var migrationName; keys(me.migrations)) {
            if (!me.isMigrationExists(migrationName)) {
                logprint(LOG_ALERT, "Logbook Add-on - call migration: ", migrationName);

                me.migrations[migrationName]();

                me.confirmMigration(migrationName);
            }
        }
    },

    #
    # Check if the table in the database exists
    #
    # @return bool  True if the table already exists
    #
    isTableExist: func(tableName) {
        var query = sprintf("SELECT name FROM sqlite_master WHERE type='table' AND name='%s'", tableName);
        var result = sqlite.exec(me.dbHandler, query);
        return size(result);
    },

    #
    # Check if the specified migration has already been invoked
    #
    # @param  string  migrationName
    # @return bool
    #
    isMigrationExists: func(migrationName) {
        if (!me.isTableExist(StorageSQLite.TABLE_MIGRATIONS)) {
            # We don't even have the migrations table yet, this is when we first run it
            return false;
        }

        var query = sprintf("SELECT * FROM `%s` WHERE `migration` = ?", StorageSQLite.TABLE_MIGRATIONS);
        var stmt = sqlite.prepare(me.dbHandler, query);
        var rows = sqlite.exec(me.dbHandler, stmt, migrationName);
        return size(rows);
    },

    #
    # Save the migration name to the migrations table to confirm that the migration was invoked
    #
    # @param  string  migrationName
    # @return void
    #
    confirmMigration: func(migrationName) {
        var query = sprintf("INSERT INTO `%s` VALUES (NULL, ?)", StorageSQLite.TABLE_MIGRATIONS);
        var stmt = sqlite.prepare(me.dbHandler, query);
        sqlite.exec(me.dbHandler, stmt, migrationName);
    },
};
