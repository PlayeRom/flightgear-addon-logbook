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
    # @param int index - Column index as File.INDEX_[...]
    # @param string value
    # @return me
    #
    new: func(index, value) {
        return {
            parents : [FilterData],
            index   : index,
            value   : value,
        };
    },

    #
    # @param hash filterHash
    # @param int index - Column index as File.INDEX_[...]
    # @param string value
    # @return bool
    #
    isMatch: func(index, value) {
        return me.index == index and me.value == value;
    },
};
