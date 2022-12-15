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
# Filters class
#
var Filters = {
    #
    # Constants
    #


    #
    # Constructor
    #
    # return me
    #
    new: func () {
        var me = { parents: [Filters] };

        me.aircrafts = std.Vector.new();
        me.aircraftTypes = std.Vector.new();

        return me;
    },

    #
    # Clear all filters
    #
    # return void
    #
    clear: func() {
        me.aircrafts.clear();
        me.aircraftTypes.clear();
    },

    #
    # Append single row of data
    #
    # hash logData - LogData object
    # return void
    #
    append: func(logData) {
        # Add unique aircraft IDs
        if (!me.aircrafts.contains(logData.aircraft)) {
            me.aircrafts.append(logData.aircraft);
        }

        # Add unique aircraft types
        if (!me.aircraftTypes.contains(logData.aircraftType)) {
            me.aircraftTypes.append(logData.aircraftType);
        }
    },
};
