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
# Columns class
#
var Columns = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = {
            parents : [Columns],
        };

        # Default columns state
        # * name    - column name in SQLite DB
        # * width   - width of column in LogbookDialog
        # * visible - if true then column is visible in LogbookDialog
        # * header  - header name in LogbookDialog (and CSV file)
        me._allColumns = [
            { name: "date",          width:  85, visible: true,  header: "Date" },
            { name: "time",          width:  50, visible: true,  header: "Time" },
            { name: "aircraft",      width: 150, visible: true,  header: "Aircraft" },
            { name: "variant",       width: 150, visible: true,  header: "Variant" },
            { name: "aircraft_type", width:  80, visible: true,  header: "Type" },
            { name: "callsign",      width:  80, visible: true,  header: "Callsign" },
            { name: "from",          width:  55, visible: true,  header: "From" },
            { name: "to",            width:  55, visible: true,  header: "To" },
            { name: "landing",       width:  50, visible: true,  header: "Landing" },
            { name: "crash",         width:  50, visible: true,  header: "Crash" },
            { name: "day",           width:  50, visible: true,  header: "Day" },
            { name: "night",         width:  50, visible: true,  header: "Night" },
            { name: "instrument",    width:  50, visible: true,  header: "Instrument" },
            { name: "multiplayer",   width:  50, visible: true,  header: "Multiplayer" },
            { name: "swift",         width:  50, visible: true,  header: "Swift" },
            { name: "duration",      width:  60, visible: true,  header: "Duration" },
            { name: "distance",      width:  60, visible: true,  header: "Distance" },
            { name: "fuel",          width:  80, visible: true,  header: "Fuel" },
            { name: "max_alt",       width:  70, visible: true,  header: "Max Alt" },
            { name: "note",          width: 150, visible: false, header: "Note" },
        ];

        me._widths = std.Vector.new();

        me.buildWidthsVector();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        #
    },

    #
    # @return void
    #
    buildWidthsVector: func() {
        me._widths.clear();

        foreach (var item; me._allColumns) {
            if (item.visible) {
                me._widths.append(item.width);
            }
        }
    },

    #
    # @return vector  Vector of hashes
    #
    getAll: func() {
        return me._allColumns;
    },

    #
    # Get vector of widths for visible columns
    #
    # @return vector  Vector of integers
    #
    getWidths: func() {
        return me._widths.vector;
    },

    #
    # Get DB column name by header name
    #
    # @param  string  header
    # @return int|nil
    #
    getColumnNameByHeader: func(header) {
        foreach (var item; me._allColumns) {
            if (item.header == header) {
                return item.name;
            }
        }

        return nil;
    },

    #
    # Get DB column name by index of column
    #
    # @param  int  index  Column index as StorageCsv.INDEX_...
    # @return int|nil
    #
    getColumnNameByIndex: func(index) {
        if (index < 0 or index >= size(me._allColumns)) {
            return nil;
        }

        return me._allColumns[index].name;
    },
};
