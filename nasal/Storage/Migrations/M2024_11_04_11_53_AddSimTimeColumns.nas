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

var M2024_11_04_11_53_AddSimTimeColumns = {
    #
    # Constructor
    #
    # @param  hash  storageSQLite  StorageSQLite object
    # @return me
    #
    new: func(storageSQLite) {
        return {
            parents : [
                M2024_11_04_11_53_AddSimTimeColumns,
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
        me.addColumnToTable(StorageSQLite.TABLE_LOGBOOKS, 'sim_utc_date');
        me.addColumnToTable(StorageSQLite.TABLE_LOGBOOKS, 'sim_utc_time');

        me.addColumnToTable(StorageSQLite.TABLE_LOGBOOKS, 'sim_local_date');
        me.addColumnToTable(StorageSQLite.TABLE_LOGBOOKS, 'sim_local_time');

        me._copyFromReal();
    },

    #
    # Copy real date and time to sim date and time
    #
    # @return void
    #
    _copyFromReal: func() {
        var querySelect = sprintf("SELECT `id`, `date`, `time` FROM %s", StorageSQLite.TABLE_LOGBOOKS);
        var rows = sqlite.exec(me._storageSQLite.getDbHandler(), querySelect);

        var queryInsert = sprintf(
            "UPDATE %s SET `sim_utc_date` = ?, `sim_utc_time` = ?, `sim_local_date` = ?, `sim_local_time` = ? WHERE `id` = ?",
            StorageSQLite.TABLE_LOGBOOKS
        );

        var stmt = sqlite.prepare(me._storageSQLite.getDbHandler(), queryInsert);

        foreach (var item; rows) {
            sqlite.exec(me._storageSQLite.getDbHandler(), stmt,
                item.date,
                item.time,
                item.date,
                item.time,
                item.id
            );
        }
    },
};