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

var M2024_10_30_08_44_CreateMigrationsTable = {
    #
    # Constructor
    #
    # @param  hash  storageSQLite  StorageSQLite object
    # @return me
    #
    new: func(storageSQLite) {
        return {
            parents : [
                M2024_10_30_08_44_CreateMigrationsTable,
                MigrationBase.new(storageSQLite.getDbHandler()),
            ],
        };
    },

    #
    # Run the migrations
    #
    # @return void
    #
    up: func() {
        me._createMigrationsTable();
    },

    #
    # Create a `migrations` table in the database
    #
    # @return void
    #
    _createMigrationsTable: func() {
        var columns = [
            { name: "id",        type: "INTEGER PRIMARY KEY" },
            { name: "migration", type: "TEXT" },
        ];

        call(MigrationBase.createTable, [StorageSQLite.TABLE_MIGRATIONS, columns], me);
    },
};