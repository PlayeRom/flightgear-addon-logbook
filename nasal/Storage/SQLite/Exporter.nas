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
# Exporter class handle export SQLite to CSV file.
#
var Exporter = {
    #
    # Constructor
    #
    # @param  hash  columns  Columns object.
    # @return hash
    #
    new: func(columns) {
        return {
            parents : [Exporter],
            _columns: columns,
        };
    },

    #
    # Destructor
    #
    del: func() {
        #
    },

    #
    # Export logbook and trackers from SQLite to CSV file as a separate thread job.
    #
    # @return void
    #
    exportToCsv: func() {
        thread.newthread(func {
            var (logbook, tracker) = me._getCsvFileNames();

            me._exportLogbookToCsv(logbook);
            me._exportTrackerToCsv(tracker);

            gui.popupTip("Exported to file " ~ logbook);
        });
    },

    #
    # Get CSV file name for export.
    #
    # @return vector  First file name for logbook table, second for tracker.
    #
    _getCsvFileNames: func() {
        var year   = getprop("/sim/time/real/year");
        var month  = getprop("/sim/time/real/month");
        var day    = getprop("/sim/time/real/day");
        var hour   = getprop("/sim/time/real/hour");
        var minute = getprop("/sim/time/real/minute");
        var second = getprop("/sim/time/real/second");

        var timestamp = sprintf("%d-%02d-%02d-%02d-%02d-%02d", year, month, day, hour, minute, second);

        return [
            sprintf("%s/export-%s-logbook.csv", g_Addon.storagePath, timestamp),
            sprintf("%s/export-%s-tracker.csv", g_Addon.storagePath, timestamp),
        ];
    },

    #
    # Export logbooks table from SQLite to CSV file.
    #
    # @param  string  fileName  Full path with file name.
    # @return void
    #
    _exportLogbookToCsv: func(fileName) {
        var file = io.open(fileName, "w");

        var headersRow = "";
        foreach (var columnItem; me._columns.getAll()) {
            if (headersRow != "") {
                headersRow ~= ",";
            }

            headersRow ~= Utils.isSpace(columnItem.header)
                ? '"' ~ columnItem.header ~ '"'
                :       columnItem.header;
        }

        headersRow = "ID," ~ headersRow;

        io.write(file, headersRow ~ "\n");

        foreach (var row; DB.exec(sprintf("SELECT * FROM %s;", Storage.TABLE_LOGBOOKS))) {
            var logData = LogData.new();
            logData.fromDb(row);

            io.write(file, sprintf(
                "%d,%s,%s,%s,%s,%s,%s,\"%s\",%s,%s,%s,%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,%.0f,%.02f,\"%s\"\n",
                row.id,
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
    },

    #
    # Export trackers table from SQLite to CSV file.
    #
    # @param  string  fileName  Full path with file name.
    # @return void
    #
    _exportTrackerToCsv: func(fileName) {
        var file = io.open(fileName, "w");

        var headersRow = "";
        foreach (var row; DB.exec("SELECT `name` FROM pragma_table_info(?);", Storage.TABLE_TRACKERS)) {
            if (headersRow != "") {
                headersRow ~= ",";
            }

            headersRow ~= me._columnNameToHuman(row.name);
        }

        io.write(file, headersRow ~ "\n");

        foreach (var row; DB.exec(sprintf("SELECT * FROM %s;", Storage.TABLE_TRACKERS))) {
            io.write(file, sprintf(
                "%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                row.id,
                row.logbook_id,
                row.timestamp,
                row.lat,
                row.lon,
                row.alt_m,
                row.elevation_m,
                row.distance,
                row.heading_true,
                row.heading_mag,
                row.groundspeed,
                row.airspeed,
                row.pitch,
                row.wind_heading,
                row.wind_speed,
            ));
        }

        io.close(file);
    },

    #
    # Change the technical name of a table column to something more human.
    #
    # @param  string  columnName  Column name in DB.
    # @return string  Human column name.
    #
    _columnNameToHuman: func(columnName) {
        if (columnName == "id")           return 'ID';
        if (columnName == "logbook_id")   return '"Logbook ID"';
        if (columnName == "timestamp")    return 'Timestamp';
        if (columnName == "lat")          return 'Latitude';
        if (columnName == "lon")          return 'Longitude';
        if (columnName == "alt_m")        return '"Altitude (meters)"';
        if (columnName == "elevation_m")  return '"Elevation (meters)"';
        if (columnName == "distance")     return '"Distance (NM)"';
        if (columnName == "heading_true") return '"True heading (deg)"';
        if (columnName == "heading_mag")  return '"Magnetic heading (deg)"';
        if (columnName == "groundspeed")  return '"Groundspeed (kt)"';
        if (columnName == "airspeed")     return '"Airspeed (kt)"';
        if (columnName == "pitch")        return '"Pitch (deg)"';
        if (columnName == "wind_heading") return '"Wind heading (deg)"';
        if (columnName == "wind_speed")   return '"Wind speed (kt)"';

        return '?';
    },
};
