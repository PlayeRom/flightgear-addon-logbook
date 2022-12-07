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
# File class to save data to the logbook CSV file
#
var File = {
    #
    # Constants
    #
    LOGBOOK_FILE : "logbook.csv",

    #
    # Constructor
    #
    new: func (addon) {
        var me = { parents: [File] };

        me.filePath = addon.storagePath ~ "/" ~ File.LOGBOOK_FILE;

        me.saveHeaders();

        return me;
    },

    #
    # If logbook file doesn't exist then create it with headers
    #
    saveHeaders: func() {
        if (!me.exists(me.filePath)) {
            var file = io.open(me.filePath, "a");
            io.write(file,
                'Date,' ~
                'Time,' ~
                'Aircraft,' ~
                'Callsign,' ~
                'From,' ~
                'To,' ~
                'Landings,' ~
                'Crash,' ~
                'Day,' ~
                'Night,' ~
                'Instrument,' ~
                'Duration,' ~
                'Distance,' ~
                'Fuel,' ~
                '"Max Alt",' ~
                'Note' ~
                "\n"
            );
            io.close(file);
        }
    },

    #
    # Check taht file already exists.
    # From FG 2020.4 (next) we have io.exists() but for older versions we have to write it ourselves.
    #
    # return bool
    #
    exists: func(path) {
        return io.stat(path) != nil;
    },

    #
    # Store log data to logbook file
    #
    # LogData logData - LogData object
    #
    saveData: func(logData) {
        var file = io.open(me.filePath, "a");
        io.write(file, sprintf(
            "%s,%s,%s,%s,%s,%s,%d,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,\"%s\"\n",
            logData.date,
            logData.time,
            logData.aircraft,
            logData.callsign,
            logData.from,
            logData.to,
            logData.landings,
            logData.printCrash(),
            logData.day,
            logData.night,
            logData.instrument,
            logData.duration,
            logData.distance,
            logData.fuel,
            logData.maxAlt,
            logData.note
        ));
        io.close(file);
    },
};
