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
    # @param  hash  db  DB handler
    # @return me
    #
    new: func(db) {
        var me = { parents: [MigrationSQLite] };

        me.db = db;

        me.migrations = {
            # TODO: add name and func as a next migration
            # "2024-10-30-migration-name": func (migrationName) {
            #     # TODO: add migration code here

            #     me.confirmMigration(migrationName);
            # },
        };

        return me;
    },

    #
    # Follow me.migrations step by step, check if the migration name is already
    # in the database, if not then execute the migration function
    #
    # @return void
    #
    doMigration: func() {
        foreach (var migrationName; keys(me.migrations)) {
            if (!me.isMigrationExists(migrationName)) {
                me.migrations[migrationName](migrationName);
            }
        }
    },

    #
    # @param  string  migrationName
    # @return bool
    #
    isMigrationExists: func(migrationName) {
        var query = sprintf("SELECT * FROM `%s` WHERE `migration` = ?", StorageSQLite.TABLE_MIGRATIONS);
        var stmt = sqlite.prepare(me.db, query);
        var rows = sqlite.exec(me.db, stmt, migrationName);
        return size(rows);
    },

    #
    # @param  string  migrationName
    # @return void
    #
    confirmMigration: func(migrationName) {
        var query = sprintf("INSERT INTO `%s` VALUES (NULL, ?)", StorageSQLite.TABLE_MIGRATIONS);
        var stmt = sqlite.prepare(me.db, query);
        sqlite.exec(me.db, stmt, migrationName);
    },
};
