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
    # int id
    # string value
    # return me
    #
    new: func(id, value) {
        return {
            parents : [FilterData],
            id      : id,
            value   : value,
        };
    },

    #
    # hash filterHash
    # int id - FilterSelector ID
    # string value
    # return bool
    #
    isMatch: func(id, value) {
        return me.id == id and me.value == value;
    },
};
