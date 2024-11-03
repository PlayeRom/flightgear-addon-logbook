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
        return {
            parents     : [FilterData],
            columnName  : columnName,
            value       : value,
        };
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
