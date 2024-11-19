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
# Exporter class handle export SQLite to CSV file
#
var Exporter = {
    #
    # Constants
    #
    USE_FILE_SELECTOR: false,

    #
    # Constructor
    #
    # @param  hash  columns  Columns object
    # @return me
    #
    new: func(columns) {
        return {
            parents   : [Exporter],
            _columns  : columns,
        };
    },

    #
    # Destructor
    #
    del: func() {
        #
    },

    #
    # Export logbook from SQLite to CSV file as a separate thread job
    #
    # @return void
    #
    exportToCsv: func() {
        if (Exporter.USE_FILE_SELECTOR) {
            var selector = gui.FileSelector.new(
                func(node) {             # callback function
                    me._runInThread(node.getValue());
                },
                "Export to CSV",         # dialog title
                "Save",                  # button text
                ["*.csv"],               # pattern for displayed files
                g_Addon.storagePath,     # start dir as $FG_HOME/Export/Addons/org.flightgear.addons.logbook/
                me._getCsvFileName()     # default file name
            );

            selector.open();
        }
        else {
            me._runInThread(sprintf("%s/%s", g_Addon.storagePath, me._getCsvFileName()));
        }
    },

    #
    # @param  string  fileName  Full path with file name
    # @return bool
    #
    _runInThread: func(fileName) {
        thread.newthread(func { me._exportToCsv(fileName); });
    },

    #
    # Get CSV file name for export
    #
    # @return string
    #
    _getCsvFileName: func() {
        var year   = getprop("/sim/time/real/year");
        var month  = getprop("/sim/time/real/month");
        var day    = getprop("/sim/time/real/day");
        var hour   = getprop("/sim/time/real/hour");
        var minute = getprop("/sim/time/real/minute");
        var second = getprop("/sim/time/real/second");

        return sprintf("logbook-export-%d-%02d-%02d-%02d-%02d-%02d.csv", year, month, day, hour, minute, second);
    },

    #
    # Export logbook from SQLite to CSV file
    #
    # @param  string  fileName  Full path with file name
    # @return void
    #
    _exportToCsv: func(fileName) {
        var file = io.open(fileName, "w");

        var headerRow = "";
        foreach (var columnItem; me._columns.getAll()) {
            if (headerRow != "") {
                headerRow ~= ",";
            }

            headerRow ~= Utils.isSpace(columnItem.header)
                ? '"' ~ columnItem.header ~ '"'
                :       columnItem.header;
        }

        io.write(file, headerRow ~ "\n");

        var query = sprintf("SELECT * FROM %s", Storage.TABLE_LOGBOOKS);
        foreach (var row; DB.exec(query)) {
            var logData = LogData.new();
            logData.fromDb(row);

            io.write(file, sprintf(
                "%s,%s,%s,%s,%s,%s,\"%s\",%s,%s,%s,%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,%.0f,%.02f,\"%s\"\n",
                logData.date,
                logData.time,
                logData.sim_utc_date,
                logData.sim_utc_time,
                logData.sim_local_date,
                logData.sim_local_time,
                logData.aircraft,
                logData.variant,
                logData.aircraft_type,
                logData.callsign,
                logData.from,
                logData.to,
                logData.printLanding(),
                logData.printCrash(),
                logData.day,
                logData.night,
                logData.instrument,
                logData.multiplayer,
                logData.swift,
                logData.duration,
                logData.distance,
                logData.fuel,
                logData.max_alt,
                logData.max_groundspeed_kt,
                logData.max_mach,
                logData.note
            ));
        }

        io.close(file);

        gui.popupTip("Exported to file " ~ fileName);
    },
};
