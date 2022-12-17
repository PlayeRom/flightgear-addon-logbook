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

        me.date           = std.Vector.new();
        me.aircrafts      = std.Vector.new();
        me.aircraftTypes  = std.Vector.new();
        me.airportsFrom   = std.Vector.new();
        me.airportsTo     = std.Vector.new();

        # Vector of FilterData objects
        me.appliedFilters = std.Vector.new();

        return me;
    },

    #
    # Clear all filters
    #
    # return void
    #
    clear: func() {
        me.date.clear();
        me.aircrafts.clear();
        me.aircraftTypes.clear();
        me.airportsFrom.clear();
        me.airportsTo.clear();
    },

    #
    # Append single row of data
    #
    # hash logData - LogData object
    # return void
    #
    append: func(logData) {
        # Add unique year
        var year = logData.getYear();
        if (!me.date.contains(year)) {
            me.date.append(year);
        }

        # Add unique aircraft IDs
        if (!me.aircrafts.contains(logData.aircraft)) {
            me.aircrafts.append(logData.aircraft);
        }

        # Add unique aircraft types
        if (!me.aircraftTypes.contains(logData.aircraftType)) {
            me.aircraftTypes.append(logData.aircraftType);
        }

        # Add unique airport from
        if (logData.from != "" and !me.airportsFrom.contains(logData.from)) {
            me.airportsFrom.append(logData.from);
        }

        # Add unique airport to
        if (logData.to != "" and !me.airportsTo.contains(logData.to)) {
            me.airportsTo.append(logData.to);
        }
    },

    #
    # Sorting all filters
    #
    # return void
    #
    sort: func() {
        if (me.date.size() > 1) {
            me.date.vector = sort(me.date.vector, string.icmp);
        }

        if (me.aircrafts.size() > 1) {
            me.aircrafts.vector = sort(me.aircrafts.vector, string.icmp);
        }

        if (me.aircraftTypes.size() > 1) {
            me.aircraftTypes.vector = sort(me.aircraftTypes.vector, string.icmp);
        }

        if (me.airportsFrom.size() > 1) {
            me.airportsFrom.vector = sort(me.airportsFrom.vector, string.icmp);
        }

        if (me.airportsTo.size() > 1) {
            me.airportsTo.vector = sort(me.airportsTo.vector, string.icmp);
        }
    },

    #
    # hash filterData - FilterData as {"id": filterId, "value": "text"}
    # return void
    #
    applyFilter: func(filterData) {
        foreach (var item; me.appliedFilters.vector) {
            if (item.id == filterData.id) {
                # Remove the same ID if already exist
                me.appliedFilters.remove(item);
                break;
            }
        }

        if (filterData.value != FilterSelector.CLEAR_FILTER_VALUE) {
            me.appliedFilters.append(filterData);
        }
    },

    #
    # Return true if user used filter for Date header
    #
    # return bool
    #
    isAppliedDate: func() {
        return me.isApplied(FilterSelector.ID_DATE);
    },

    #
    # Return true if user used filter for Aircraft header
    #
    # return bool
    #
    isAppliedAircraft: func() {
        return me.isApplied(FilterSelector.ID_AC);
    },

    #
    # Return true if user used filter for Aircraft Type header
    #
    # return bool
    #
    isAppliedAircraftType: func() {
        return me.isApplied(FilterSelector.ID_AC_TYPE);
    },

    #
    # Return true if user used filter for airport "from"
    #
    # return bool
    #
    isAppliedAirportFrom: func() {
        return me.isApplied(FilterSelector.ID_AIRPORT_FROM);
    },

    #
    # Return true if user used filter for airport "to"
    #
    # return bool
    #
    isAppliedAirportTo: func() {
        return me.isApplied(FilterSelector.ID_AIRPORT_TO);
    },

    #
    # Return true if user used filter with given ID
    #
    # int id
    # return bool
    #
    isApplied: func(id) {
        foreach (var item; me.appliedFilters.vector) {
            if (item.id == id) {
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
        foreach (var filterData; me.appliedFilters.vector) {
            if (filterData.isMatch(FilterSelector.ID_DATE, logData.getYear())) {
                matchCounter += 1;
                continue;
            }

            if (filterData.isMatch(FilterSelector.ID_AC, logData.aircraft)) {
                matchCounter += 1;
                continue;
            }

            if (filterData.isMatch(FilterSelector.ID_AC_TYPE, logData.aircraftType)) {
                matchCounter += 1;
                continue;
            }

            if (filterData.isMatch(FilterSelector.ID_AIRPORT_FROM, logData.from)) {
                matchCounter += 1;
                continue;
            }

            if (filterData.isMatch(FilterSelector.ID_AIRPORT_TO, logData.to)) {
                matchCounter += 1;
                continue;
            }
        }

        # Return true if all filters have been met
        return matchCounter == size(me.appliedFilters.vector);
    },

    #
    # int column - Index of column
    # return vector|nil
    #
    getFilterItemsByColumnIndex: func(column) {
             if (column == File.INDEX_DATE)          return me.date.vector;
        else if (column == File.INDEX_AIRCRAFT)      return me.aircrafts.vector;
        else if (column == File.INDEX_AIRCRAFT_TYPE) return me.aircraftTypes.vector;
        else if (column == File.INDEX_FROM)          return me.airportsFrom.vector;
        else if (column == File.INDEX_TO)            return me.airportsTo.vector;

        return nil;
    },

    #
    # int column - Index of column
    # return string|nil
    #
    getFilerTitleByColumnIndex: func(column) {
             if (column == File.INDEX_DATE)          return "Date filter";
        else if (column == File.INDEX_AIRCRAFT)      return "Aircraft filter";
        else if (column == File.INDEX_AIRCRAFT_TYPE) return "Aircraft type filter";
        else if (column == File.INDEX_FROM)          return "Airport from filter";
        else if (column == File.INDEX_TO)            return "Airport to filter";

        return nil;
    },

    #
    # int column - Index of column
    # return int|nil
    #
    getFilerSelectorIdByColumnIndex: func(column) {
             if (column == File.INDEX_DATE)          return FilterSelector.ID_DATE;
        else if (column == File.INDEX_AIRCRAFT)      return FilterSelector.ID_AC;
        else if (column == File.INDEX_AIRCRAFT_TYPE) return FilterSelector.ID_AC_TYPE;
        else if (column == File.INDEX_FROM)          return FilterSelector.ID_AIRPORT_FROM;
        else if (column == File.INDEX_TO)            return FilterSelector.ID_AIRPORT_TO;

        return nil;
    },

    #
    # int column
    # return bool
    #
    isColumnIndexFiltered: func(column) {
        return column == File.INDEX_DATE or
               column == File.INDEX_AIRCRAFT or
               column == File.INDEX_AIRCRAFT_TYPE or
               column == File.INDEX_FROM or
               column == File.INDEX_TO;
    },
};
