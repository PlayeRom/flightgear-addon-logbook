#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# FilterData class
#
var FilterData = {
    #
    # Constructor
    #
    # @param  string  columnName
    # @param  string  value
    # @return me
    #
    new: func(columnName, value) {
        var me = {
            parents    : [FilterData],
            columnName : columnName,
            value      : value,
        };

        if (value == ""
            and (columnName == Columns.LANDING
              or columnName == Columns.CRASH)
            and Utils.isUsingSQLite()
        ) {
            # In the SQLite database, the `landing` and `crash` columns have
            # the value 0 and in the filter we have an empty string, so we need
            # to change the empty string to the value "0".
            me.value = "0";
        }

        return me;
    },

    #
    # @param  string  columnName
    # @param  string  value
    # @return bool
    #
    isMatch: func(columnName, value) {
        return me.columnName == columnName and me.value == value;
    },
};
