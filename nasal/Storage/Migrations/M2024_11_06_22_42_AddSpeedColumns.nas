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

var M2024_11_06_22_42_AddSpeedColumns = {
    #
    # Constructor
    #
    # @param  hash  storageSQLite  StorageSQLite object
    # @return me
    #
    new: func(storageSQLite) {
        return {
            parents : [
                M2024_11_06_22_42_AddSpeedColumns,
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
        me.addColumnToTable(StorageSQLite.TABLE_LOGBOOKS, "max_groundspeed_kt", "REAL", "0.0");
        me.addColumnToTable(StorageSQLite.TABLE_LOGBOOKS, "max_mach", "REAL", "0.0");
    },
};