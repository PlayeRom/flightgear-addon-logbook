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
# FileMigration class
#
var FileMigration = {
    #
    # Constructor
    #
    # hash file - File object
    # return me
    #
    new: func (file) {
        var me = { parents: [FileMigration] };

        me.file = file;

        return me;
    },

    #
    # string oldFilePath
    # string newFilePath
    # retrun void
    #
    migrateToFileVersion_2: func(oldFilePath, newFilePath) {
        # Add extra column "Type" (as aircraft type) after "Aircraft" column
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
                io.write(fileNew, me.file.getHeaderLine() ~ "\n");
            }
            else { # data
                var items = split(",", me.file.removeQuotes(line));
                io.write(fileNew, sprintf(
                    "%s,%s,%s,%s,%s,%s,%s,%d,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f,\"%s\"\n",
                    items[0],            # date
                    items[1],            # time
                    items[2],            # aircraft
                    AircraftType.OTHERS, # aircraftType - we dont know the type, so set "others"
                    items[3],            # callsign
                    items[4],            # from
                    items[5],            # to
                    items[6],            # landings
                    items[7],            # crash
                    items[8],            # day
                    items[9],            # night
                    items[10],           # instrument
                    items[11],           # duration
                    items[12],           # distance
                    items[13],           # fuel
                    items[14],           # maxAlt
                    items[15]            # note
                ));
            }

            linesCounter += 1;
        }

        io.close(fileOld);
        io.close(fileNew);
    },
};
