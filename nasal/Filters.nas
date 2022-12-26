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
    # @return me
    #
    new: func () {
        var me = { parents: [Filters] };

        me.data = {};
        me.data[File.INDEX_DATE]     = std.Vector.new();
        me.data[File.INDEX_AIRCRAFT] = std.Vector.new();
        me.data[File.INDEX_VARIANT]  = std.Vector.new();
        me.data[File.INDEX_TYPE]     = std.Vector.new();
        me.data[File.INDEX_CALLSIGN] = std.Vector.new();
        me.data[File.INDEX_FROM]     = std.Vector.new();
        me.data[File.INDEX_TO]       = std.Vector.new();
        me.data[File.INDEX_LANDINGS] = std.Vector.new();
        me.data[File.INDEX_CRASH]    = std.Vector.new();

        # Vector of FilterData objects
        me.appliedFilters = std.Vector.new();

        # The dirty true flag says that the data has been modified, e.g. by
        # applying a new filter or adding new data to be filtered, which means
        # we have to recalculate everything.
        me.dirty = false;

        return me;
    },

    #
    # Clear all filters
    #
    # @return void
    #
    clear: func() {
        foreach (var key; keys(me.data)) {
            me.data[key].clear();
        }
    },

    #
    # Append single row of data to filter data
    #
    # @param hash logData - LogData object
    # @return void
    #
    append: func(logData) {
        foreach (var index; keys(me.data)) {
            var value = logData.getFilterValueByIndex(index);
            if (!me.data[index].contains(value)) {
                me.data[index].append(value);
                me.dirty = true;
            }
        }
    },

    #
    # Sorting all filters
    #
    # @return void
    #
    sort: func() {
        foreach (var index; keys(me.data)) {
            if (me.data[index].size() > 1) {
                me.data[index].vector = sort(me.data[index].vector, string.icmp);
            }
        }
    },

    #
    # @param hash filterData - FilterData as {"index": column index, "value": "text"}
    # @return bool - Return true if filter is applied
    #
    applyFilter: func(filterData) {
        foreach (var item; me.appliedFilters.vector) {
            if (item.index == filterData.index) {
                if (item.value == filterData.value) {
                    # It is the same filter already applied, no changes are required
                    return false;
                }

                # Remove the same ID if already exist
                me.appliedFilters.remove(item);
                me.dirty = true;
                break;
            }
        }

        if (filterData.value != FilterSelector.CLEAR_FILTER_VALUE) {
            me.appliedFilters.append(filterData);
            me.dirty = true;
        }

        return me.dirty;
    },

    #
    # Return true if user used filter with given column index
    #
    # @param int index
    # @return bool
    #
    isApplied: func(index) {
        foreach (var item; me.appliedFilters.vector) {
            if (item.index == index) {
                return true;
            }
        }

        return false;
    },

    #
    # @param hash logData - LogData object
    # @return bool
    #
    isAllowedByFilter: func(logData) {
        var matchCounter = 0;
        foreach (var filterData; me.appliedFilters.vector) {
            foreach (var index; keys(me.data)) {
                if (filterData.isMatch(index, logData.getFilterValueByIndex(index))) {
                    matchCounter += 1;
                    continue;
                }
            }
        }

        # Return true if all filters have been met
        return matchCounter == me.appliedFilters.size();
    },

    #
    # @param int column - Index of column
    # @return vector|nil
    #
    getFilterItemsByColumnIndex: func(column) {
        foreach (var index; keys(me.data)) {
            if (column == index) {
                return me.data[column].vector;
            }
        }

        return nil;
    },

    #
    # @param int column - Index of column
    # @return string
    #
    getFilterTitleByColumnIndex: func(column) {
             if (column == File.INDEX_DATE)     return "Date filter";
        else if (column == File.INDEX_AIRCRAFT) return "Aircraft filter";
        else if (column == File.INDEX_VARIANT)  return "Variant filter";
        else if (column == File.INDEX_TYPE)     return "Type filter";
        else if (column == File.INDEX_CALLSIGN) return "Callsign filter";
        else if (column == File.INDEX_FROM)     return "From filter";
        else if (column == File.INDEX_TO)       return "To filter";
        else if (column == File.INDEX_LANDINGS) return "Landings filter";
        else if (column == File.INDEX_CRASH)    return "Crash filter";

        return "Filter";
    },

    #
    # @param int column
    # @return bool
    #
    isColumnIndexFiltered: func(column) {
        foreach (var index; keys(me.data)) {
            if (column == index) {
                return true;
            }
        }

        return false;
    },
};
