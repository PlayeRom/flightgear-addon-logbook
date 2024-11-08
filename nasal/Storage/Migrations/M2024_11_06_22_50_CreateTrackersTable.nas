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

var M2024_11_06_22_50_CreateTrackersTable = {
    #
    # Constructor
    #
    # @param  hash  storageSQLite  StorageSQLite object
    # @return me
    #
    new: func(storageSQLite) {
        return {
            parents : [
                M2024_11_06_22_50_CreateTrackersTable,
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
        me._createTrackersTable();
    },

    #
    # Create a `migrations` table in the database
    #
    # @return void
    #
    _createTrackersTable: func() {
        var columns = [
            { name: "id",          type: "INTEGER PRIMARY KEY" },
            { name: "logbook_id",  type: "INTEGER" },
            { name: "timestamp",   type: "REAL" }, # duration of flight in hours
            { name: "lat",         type: "REAL" }, # aircraft position
            { name: "lon",         type: "REAL" }, # aircraft position
            { name: "alt_m",       type: "REAL" }, # aircraft altitude in meters
            { name: "elevation_m", type: "REAL" }, # elevation in metres of a lat,lon point on the scenery
            { name: "distance",    type: "REAL" }, # distance traveled from the starting point in nautical miles
        ];

        me.createTable(StorageSQLite.TABLE_TRACKERS, columns);
    },
};