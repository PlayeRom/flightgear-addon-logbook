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
    # @param  hash  storage  SQLite Storage object
    # @return me
    #
    new: func(storage) {
        return {
            parents : [
                M2024_11_04_11_53_AddSimTimeColumns,
                MigrationBase.new(storage.getDbHandler()),
            ],
            _storage: storage,
        };
    },

    #
    # Run the migrations
    #
    # @return void
    #
    up: func() {
        me.addColumnToTable(Storage.TABLE_LOGBOOKS, 'sim_utc_date');
        me.addColumnToTable(Storage.TABLE_LOGBOOKS, 'sim_utc_time');

        me.addColumnToTable(Storage.TABLE_LOGBOOKS, 'sim_local_date');
        me.addColumnToTable(Storage.TABLE_LOGBOOKS, 'sim_local_time');

        me._copyFromReal();
    },

    #
    # Copy real date and time to sim date and time
    #
    # @return void
    #
    _copyFromReal: func() {
        var querySelect = sprintf("SELECT `id`, `date`, `time` FROM %s", Storage.TABLE_LOGBOOKS);
        var rows = sqlite.exec(me._storage.getDbHandler(), querySelect);

        var queryInsert = sprintf(
            "UPDATE %s SET `sim_utc_date` = ?, `sim_utc_time` = ?, `sim_local_date` = ?, `sim_local_time` = ? WHERE `id` = ?",
            Storage.TABLE_LOGBOOKS
        );

        var stmt = sqlite.prepare(me._storage.getDbHandler(), queryInsert);

        foreach (var item; rows) {
            sqlite.exec(me._storage.getDbHandler(), stmt,
                item.date,
                item.time,
                item.date,
                item.time,
                item.id
            );
        }
    },
};
