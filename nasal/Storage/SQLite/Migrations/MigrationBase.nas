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
    # @return hash
    #
    new: func() {
        return { parents: [MigrationBase] };
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
        DB.exec(query);
    },

    #
    # Add column to table
    #
    # @param  string  tableName
    # @param  string  columnName
    # @param  string  type  Column type, default TEXT
    # @param  string  default  Default value of column, default NULL
    # @return void
    #
    addColumnToTable: func(tableName, columnName, type = "TEXT", default = "NULL") {
        var query = sprintf("ALTER TABLE `%s` ADD COLUMN `%s` %s DEFAULT %s", tableName, columnName, type, default);
        DB.exec(query);
    },
};