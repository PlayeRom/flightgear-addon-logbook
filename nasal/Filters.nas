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
    # Constructor
    #
    # return me
    #
    new: func () {
        var me = { parents: [Filters] };

        me.aircrafts      = std.Vector.new();
        me.aircraftTypes  = std.Vector.new();
        me.appliedFilters = std.Vector.new();

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

    #
    # Sorting all filters
    #
    # return void
    #
    sort: func() {
        if (me.aircrafts.size() > 1) {
            me.aircrafts.vector = sort(me.aircrafts.vector, string.icmp);
        }

        if (me.aircraftTypes.size() > 1) {
            me.aircraftTypes.vector = sort(me.aircraftTypes.vector, string.icmp);
        }
    },

    #
    # hash filters - {"id": filterId, "value": "text"}
    # return void
    #
    applyFilter: func(filter) {
        foreach (var item; me.appliedFilters.vector) {
            if (item["id"] == filter["id"]) {
                # Remove the same ID if already exist
                me.appliedFilters.remove(item);
                break;
            }
        }

        if (filter["value"] != FilterSelector.CLEAR_FILTER_VALUE) {
            me.appliedFilters.append(filter);
        }
    },

    #
    # Return true if user used filter for Aircraft header
    #
    # return bool
    #
    isAppliedAircraft: func() {
        foreach (var item; me.appliedFilters.vector) {
            if (item["id"] == FilterSelector.ID_AC) {
                return true;
            }
        }

        return false;
    },

    #
    # Return true if user used filter for Aircraft Type header
    #
    # return bool
    #
    isAppliedAircraftType: func() {
        foreach (var item; me.appliedFilters.vector) {
            if (item["id"] == FilterSelector.ID_AC_TYPE) {
                return true;
            }
        }

        return false;
    },

    #
    # hash logData - LogData object
    # return bool
    #
    isAllowedByFilter: func(logData) {
        var matchCounter = 0;
        foreach (var filterHash; me.appliedFilters.vector) {
            if (filterHash["id"] == FilterSelector.ID_AC and filterHash["value"] == logData.aircraft) {
                matchCounter += 1;
            }

            if (filterHash["id"] == FilterSelector.ID_AC_TYPE and filterHash["value"] == logData.aircraftType) {
                matchCounter += 1;
            }
        }

        # Return true if all filters have been met
        return matchCounter == size(me.appliedFilters.vector);
    },
};
