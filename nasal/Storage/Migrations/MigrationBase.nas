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
# Base class for single DB migration
#
var MigrationBase = {
    #
    # Constructor
    #
    # @param  hash  dbHandler  DB handler
    # @return me
    #
    new: func(dbHandler) {
        return {
            parents  : [MigrationBase],
            _dbHandler: dbHandler,
        };
    },

    #
    # Create table in the database
    #
    # @param  string  tableName
    # @param  hash  columns  Vector of hashes with column `name` and `type`
    # @return void
    #
    createTable: func(tableName, columns) {
        var queryCols = "";
        foreach (var item; columns) {
            if (size(queryCols)) {
                queryCols ~= ", ";
            }

            queryCols ~= sprintf("`%s` %s", item.name, item.type);
        }

        var query = sprintf("CREATE TABLE %s (%s)", tableName, queryCols);
        sqlite.exec(me._dbHandler, query);
    },
};