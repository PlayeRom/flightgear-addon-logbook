#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Columns class
#
var Columns = {
    #
    # Constants column names
    #
    DATE          : "date", # real date
    TIME          : "time", # real time
    SIM_UTC_DATE  : "sim_utc_date",
    SIM_UTC_TIME  : "sim_utc_time",
    SIM_LOC_DATE  : "sim_local_date",
    SIM_LOC_TIME  : "sim_local_time",
    AIRCRAFT      : "aircraft",
    VARIANT       : "variant",
    AC_TYPE       : "aircraft_type",
    CALLSIGN      : "callsign",
    FROM          : "from",
    TO            : "to",
    LANDING       : "landing",
    CRASH         : "crash",
    DAY           : "day",
    NIGHT         : "night",
    INSTRUMENT    : "instrument",
    MULTIPLAYER   : "multiplayer",
    SWIFT         : "swift",
    DURATION      : "duration",
    DISTANCE      : "distance",
    FUEL          : "fuel",
    MAX_ALT       : "max_alt",
    NOTE          : "note",

    TOTALS_ROW_ID: -1,

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = {
            parents       : [Columns],
            _isUsingSQLite: Utils.isUsingSQLite(),
        };

        # Default columns state
        # * name     - column name in SQLite DB
        # * header   - header name in LogbookDialog (and CSV file)
        # * width    - width of column in LogbookDialog
        # * visible  - if true then column is visible in LogbookDialog
        # * totals   - SQL function for totals row or nil if column should not be displayed in totals
        # * totalVal - value for total row (if totals != nil)
        # * totalFrm - formatting value for total row (if totals != nil)
        me._allColumnsSQLite = [
            { name: Columns.DATE,         header: "Real date",      width:  80, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.TIME,         header: "Real time",      width:  55, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.SIM_UTC_DATE, header: "Sim UTC date",   width:  80, visible: false, totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.SIM_UTC_TIME, header: "Sim UTC time",   width:  55, visible: false, totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.SIM_LOC_DATE, header: "Sim local date", width:  80, visible: false, totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.SIM_LOC_TIME, header: "Sim local time", width:  55, visible: false, totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.AIRCRAFT,     header: "Aircraft",       width: 150, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.VARIANT,      header: "Variant",        width: 150, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.AC_TYPE,      header: "Type",           width:  80, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.CALLSIGN,     header: "Callsign",       width:  80, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.FROM,         header: "From",           width:  55, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.TO,           header: "To",             width:  55, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.LANDING,      header: "Landing",        width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%d",   },
            { name: Columns.CRASH,        header: "Crash",          width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%d",   },
            { name: Columns.DAY,          header: "Day",            width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.NIGHT,        header: "Night",          width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.INSTRUMENT,   header: "Instrument",     width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.MULTIPLAYER,  header: "Multiplayer",    width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.SWIFT,        header: "Swift",          width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.DURATION,     header: "Duration",       width:  60, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.DISTANCE,     header: "Distance",       width:  60, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.FUEL,         header: "Fuel",           width:  80, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.MAX_ALT,      header: "Max Alt",        width:  70, visible: true,  totals: "MAX", totalVal: 0,  totalFrm: "%.0f", },
            { name: Columns.NOTE,         header: "Note",           width: 150, visible: false, totals: nil,   totalVal: "", totalFrm: "%.0f", },
        ];

        me._allColumnsCsv = [
            { name: Columns.DATE,         header: "Date",           width:  80, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.TIME,         header: "Time",           width:  55, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.AIRCRAFT,     header: "Aircraft",       width: 150, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.VARIANT,      header: "Variant",        width: 150, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.AC_TYPE,      header: "Type",           width:  80, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.CALLSIGN,     header: "Callsign",       width:  80, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.FROM,         header: "From",           width:  55, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.TO,           header: "To",             width:  55, visible: true,  totals: nil,   totalVal: "", totalFrm: "",     },
            { name: Columns.LANDING,      header: "Landing",        width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%d",   },
            { name: Columns.CRASH,        header: "Crash",          width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%d",   },
            { name: Columns.DAY,          header: "Day",            width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.NIGHT,        header: "Night",          width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.INSTRUMENT,   header: "Instrument",     width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.MULTIPLAYER,  header: "Multiplayer",    width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.SWIFT,        header: "Swift",          width:  50, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.DURATION,     header: "Duration",       width:  60, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.DISTANCE,     header: "Distance",       width:  60, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.FUEL,         header: "Fuel",           width:  80, visible: true,  totals: "SUM", totalVal: 0,  totalFrm: "%.2f", },
            { name: Columns.MAX_ALT,      header: "Max Alt",        width:  70, visible: true,  totals: "MAX", totalVal: 0,  totalFrm: "%.0f", },
            { name: Columns.NOTE,         header: "Note",           width: 150, visible: false, totals: nil,   totalVal: "", totalFrm: "%.0f", },
        ];

        me._allColumns = me._isUsingSQLite
            ? me._allColumnsSQLite
            : me._allColumnsCsv;

        me._allColumnsSize = size(me._allColumns);

        me._widths = std.Vector.new();

        me.updateColumnsVisible();

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
    # @return vector  Vector with all columns
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
    # Return the sum of the widths of the visible columns
    #
    # @return int
    #
    getSumWidth: func() {
        var sum = 0;

        foreach (var columnItem; me._allColumns) {
            if (columnItem.visible) {
                sum += columnItem.width;
            }
        }

        return sum;
    },

    #
    # Get column hash by index of column
    #
    # @param  int  index  Column index as StorageCsv.INDEX_...
    # @return hash|nil
    #
    getColumnByIndex: func(index) {
        if (index < 0 or index >= me._allColumnsSize) {
            return nil;
        }

        return me._allColumns[index];
    },

    #
    # Get column hash by column name
    #
    # @param  string  name  Column name
    # @return hash|nil
    #
    getColumnByName: func(name) {
        foreach (var columnItem; me._allColumns) {
            if (columnItem.name == name) {
                return columnItem;
            }
        }

        return nil;
    },

    #
    # Get column index by column name
    #
    # @param  string  columnName
    # @return int|nil
    #
    getColumnIndexByName: func(columnName) {
        forindex (var index; me._allColumns) {
            if (me._allColumns[index].name == columnName) {
                return index;
            }
        }

        return nil;
    },

    #
    # Set total value for given column name
    #
    # @param  string  columnName
    # @param  double  totalValue
    # @return void
    #
    setTotalValueByColumnName: func(columnName, totalValue) {
        var index = me.getColumnIndexByName(columnName);
        if (index != nil) {
            me._allColumns[index].totalVal = totalValue;
        }
    },

    #
    # Get date column depend of option
    #
    # @return string
    #
    getColumnDate: func() {
        var dataTimeDisplay = g_Settings.getDateTimeDisplay();
        if (dataTimeDisplay == Settings.DATE_TIME_SIM_UTC) {
            return Columns.SIM_UTC_DATE;
        }
        else if (dataTimeDisplay == Settings.DATE_TIME_SIM_LOC) {
            return Columns.SIM_LOC_DATE;
        }

        return Columns.DATE;
    },

    #
    # Get time column depend of option
    #
    # @return string
    #
    getColumnTime: func() {
        var dataTimeDisplay = g_Settings.getDateTimeDisplay();
        if (dataTimeDisplay == Settings.DATE_TIME_SIM_UTC) {
            return Columns.SIM_UTC_TIME;
        }
        else if (dataTimeDisplay == Settings.DATE_TIME_SIM_LOC) {
            return Columns.SIM_LOC_TIME;
        }

        return Columns.TIME;
    },

    #
    # Update column visible by settings
    #
    # @return void
    #
    updateColumnsVisible: func() {
        var dataTimeDisplay = g_Settings.getDateTimeDisplay();
        var columnsVisible = g_Settings.getColumnsVisible();

        me._widths.clear();

        foreach (var columnItem; me._allColumns) {
            if (me._isUsingSQLite) {
                if (columnItem.name == Columns.DATE or columnItem.name == Columns.TIME) {
                    columnItem.visible = dataTimeDisplay == Settings.DATE_TIME_REAL;
                }
                else if (columnItem.name == Columns.SIM_UTC_DATE or columnItem.name == Columns.SIM_UTC_TIME) {
                    columnItem.visible = dataTimeDisplay == Settings.DATE_TIME_SIM_UTC;
                }
                else if (columnItem.name == Columns.SIM_LOC_DATE or columnItem.name == Columns.SIM_LOC_TIME) {
                    columnItem.visible = dataTimeDisplay == Settings.DATE_TIME_SIM_LOC;
                }
                else if (contains(columnsVisible, columnItem.name)) {
                    columnItem.visible = columnsVisible[columnItem.name];
                }
            }

            if (columnItem.visible) {
                me._widths.append(columnItem.width);
            }
        }
    },
};
