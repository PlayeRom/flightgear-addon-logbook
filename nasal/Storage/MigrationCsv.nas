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
# MigrationCsv class
#
var MigrationCsv = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        return { parents: [MigrationCsv] };
    },

    #
    # @param string oldFilePath
    # @param string newFilePath
    # @param func headerLineCallback
    # @param func dataRowCallback
    # @return void
    #
    _migrate: func(oldFilePath, newFilePath, headerLineCallback, dataRowCallback) {
        var fileOld = io.open(oldFilePath, "r");
        var fileNew = io.open(newFilePath, "w");
        var line = nil;
        var linesCounter = -1;
        while ((line = io.readln(fileOld)) != nil) {
            if (line == "" or line == nil) { # skip empty row
                continue;
            }

            if (linesCounter == -1) { # headers
                # save new headers
                io.write(fileNew, headerLineCallback() ~ "\n");
            }
            else { # data
                var items = split(",", Utils.removeQuotes(line));
                io.write(fileNew, dataRowCallback(items));
            }

            linesCounter += 1;
        }

        io.close(fileOld);
        io.close(fileNew);
    },

    #
    # @param string oldFilePath
    # @param string newFilePath
    # @return void
    #
    migrateToFileVersion_2: func(oldFilePath, newFilePath) {
        # Add extra column "Type" (as aircraft type) after "Aircraft" column

        me._migrate(oldFilePath, newFilePath, func() {
            return 'Date,' ~
                   'Time,' ~
                   'Aircraft,' ~
                   'Type,' ~      # <- new column
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
                   'Note';
        }, func(items) {
            return sprintf(
                "%s,%s,%s,%s,%s,%s,%s,%d,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
                items[0],            # date
                items[1],            # time
                items[2],            # aircraft
                AircraftType.OTHERS, # aircraftType - we don't know the type, so set "others"
                items[3],            # callsign
                items[4],            # from
                items[5],            # to
                items[6],            # landing
                items[7],            # crash
                items[8],            # day
                items[9],            # night
                items[10],           # instrument
                items[11],           # duration
                items[12],           # distance
                items[13],           # fuel
                items[14],           # maxAlt
                items[15]            # note
            );
        });
    },

    #
    # @param string oldFilePath
    # @param string newFilePath
    # @return void
    #
    migrateToFileVersion_3: func(oldFilePath, newFilePath) {
        # Add extra column "Variant" (as aircraft variant) after "Aircraft" column

        me._migrate(oldFilePath, newFilePath, func() {
            return 'Date,' ~
                   'Time,' ~
                   'Aircraft,' ~
                   'Variant,' ~   # <- new column
                   'Type,' ~
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
                   'Note';
        }, func(items) {
            return sprintf(
                "%s,%s,%s,%s,%s,%s,%s,%s,%d,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
                items[0],  # date
                items[1],  # time
                items[2],  # aircraft
                items[2],  # variant - we don't know the variant, so set the same like aircraft
                items[3],  # type
                items[4],  # callsign
                items[5],  # from
                items[6],  # to
                items[7],  # landings
                items[8],  # crash
                items[9],  # day
                items[10], # night
                items[11], # instrument
                items[12], # duration
                items[13], # distance
                items[14], # fuel
                items[15], # maxAlt
                items[16]  # note
            );
        });
    },

    #
    # @param string oldFilePath
    # @param string newFilePath
    # @return void
    #
    migrateToFileVersion_4: func(oldFilePath, newFilePath) {
        # Rename "Landings" to "Landing", add quotes for "Aircraft" column

        me._migrate(oldFilePath, newFilePath, func() {
            return 'Date,' ~
                   'Time,' ~
                   'Aircraft,' ~
                   'Variant,' ~
                   'Type,' ~
                   'Callsign,' ~
                   'From,' ~
                   'To,' ~
                   'Landing,' ~ # Landings to Landing
                   'Crash,' ~
                   'Day,' ~
                   'Night,' ~
                   'Instrument,' ~
                   'Duration,' ~
                   'Distance,' ~
                   'Fuel,' ~
                   '"Max Alt",' ~
                   'Note';
        }, func(items) {
            return sprintf(
                "%s,%s,\"%s\",%s,%s,%s,%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
                items[0],  # date
                items[1],  # time
                items[2],  # aircraft
                items[3],  # variant
                items[4],  # type
                items[5],  # callsign
                items[6],  # from
                items[7],  # to
                items[8] == 1 ? "1" : "",  # landing
                items[9],  # crash
                items[10], # day
                items[11], # night
                items[12], # instrument
                items[13], # duration
                items[14], # distance
                items[15], # fuel
                items[16], # maxAlt
                items[17]  # note
            );
        });
    },

    #
    # @param string oldFilePath
    # @param string newFilePath
    # @return void
    #
    migrateToFileVersion_5: func(oldFilePath, newFilePath) {
        # Add new columns for multiplayer durations

        me._migrate(oldFilePath, newFilePath, func() {
            return 'Date,' ~
                   'Time,' ~
                   'Aircraft,' ~
                   'Variant,' ~
                   'Type,' ~
                   'Callsign,' ~
                   'From,' ~
                   'To,' ~
                   'Landing,' ~
                   'Crash,' ~
                   'Day,' ~
                   'Night,' ~
                   'Instrument,' ~
                   'Multiplayer,' ~ # <- new column, flight duration with multiplayer
                   'Swift,' ~       # <- new column, flight duration with connection to swift
                   'Duration,' ~
                   'Distance,' ~
                   'Fuel,' ~
                   '"Max Alt",' ~
                   'Note';
        }, func(items) {
            return sprintf(
                "%s,%s,\"%s\",%s,%s,%s,%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
                items[0],  # date
                items[1],  # time
                items[2],  # aircraft
                items[3],  # variant
                items[4],  # type
                items[5],  # callsign
                items[6],  # from
                items[7],  # to
                items[8] == 1 ? "1" : "",  # landing
                items[9],  # crash
                items[10], # day
                items[11], # night
                items[12], # instrument
                0.0,       # multiplayer
                0.0,       # swift
                items[13], # duration
                items[14], # distance
                items[15], # fuel
                items[16], # maxAlt
                items[17]  # note
            );
        });
    },
};
