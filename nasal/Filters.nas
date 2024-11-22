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
    new: func() {
        var me = { parents: [Filters] };

        # Filter data for each column by which we can filter, loaded in Storage.loadAllData
        me.data = {};
        me.data[Columns.DATE]         = std.Vector.new();
        me.data[Columns.SIM_UTC_DATE] = std.Vector.new();
        me.data[Columns.SIM_LOC_DATE] = std.Vector.new();
        me.data[Columns.AIRCRAFT]     = std.Vector.new();
        me.data[Columns.VARIANT]      = std.Vector.new();
        me.data[Columns.AC_TYPE]      = std.Vector.new();
        me.data[Columns.CALLSIGN]     = std.Vector.new();
        me.data[Columns.FROM]         = std.Vector.new();
        me.data[Columns.TO]           = std.Vector.new();
        me.data[Columns.LANDING]      = std.Vector.new();
        me.data[Columns.CRASH]        = std.Vector.new();

        # Vector of FilterData objects
        me.appliedFilters = std.Vector.new();

        # The dirty true flag says that the data has been modified, e.g. by
        # applying a new filter or adding new data to be filtered, which means
        # we have to recalculate everything.
        # This is only for CSV, SQLite doesn't need it.
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
    # @param  hash  logData  LogData object
    # @return void
    #
    append: func(logData) {
        foreach (var columnName; keys(me.data)) {
            var value = logData.getFilterValueByColumnName(columnName);
            if (!me.data[columnName].contains(value)) {
                me.data[columnName].append(value);
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
        foreach (var columnName; keys(me.data)) {
            if (me.data[columnName].size() > 1) {
                me.data[columnName].vector = sort(me.data[columnName].vector, string.icmp);
            }
        }
    },

    #
    # @param  hash  filterData  FilterData as {"columnName": column name, "value": "text"}
    # @return bool  Return true if filter is applied
    #
    applyFilter: func(filterData) {
        foreach (var item; me.appliedFilters.vector) {
            if (item.columnName == filterData.columnName) {
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
    # Return true if user used filter with given column name
    #
    # @param  string  columnName
    # @return bool
    #
    isApplied: func(columnName) {
        foreach (var item; me.appliedFilters.vector) {
            if (item.columnName == columnName) {
                return true;
            }
        }

        return false;
    },

    #
    # Return value if user used filter with given column name
    #
    # @param  string  columnName
    # @return string|nil
    #
    getAppliedValueForFilter: func(columnName) {
        foreach (var item; me.appliedFilters.vector) {
            if (item.columnName == columnName) {
                return item.value;
            }
        }

        return nil;
    },

    #
    # @param  hash  logData  LogData object
    # @return bool
    #
    isAllowedByFilter: func(logData) {
        var matchCounter = 0;
        foreach (var filterData; me.appliedFilters.vector) {
            foreach (var columnName; keys(me.data)) {
                if (filterData.isMatch(columnName, logData.getFilterValueByColumnName(columnName))) {
                    matchCounter += 1;
                    continue;
                }
            }
        }

        # Return true if all filters have been met
        return matchCounter == me.appliedFilters.size();
    },

    #
    # @param  string  column  Column name
    # @return vector|nil
    #
    getFilterItemsByColumnName: func(columnName) {
        if (contains(me.data, columnName)) {
            return me.data[columnName].vector;
        }

        return nil;
    },

    #
    # @param  int  column
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
