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
# The Recovery class saves the current flight status to a separate file every minute.
# When FG crashes, the recovery file data will be rewritten to the main log file on restart.
#
var Recovery = {
    #
    # Constants
    #
    RECOVERY_FILE : "recovery-v%s.csv",

    #
    # Constructor
    #
    # return me
    #
    new: func (addon, file) {
        var me = {
            parents     : [Recovery],
            file        : file,
            objCallback : nil,
            callback    : nil,
        };

        me.filePath = addon.storagePath ~ "/" ~ sprintf(Recovery.RECOVERY_FILE, File.FILE_VERSION);
        me.timer    = maketimer(60, me, me.update);

        me.restore();

        return me;
    },

    #
    # Uninitialize Recovery module
    #
    # return void
    #
    del: func() {
        me.stop();
    },

    #
    # hash objCallback - Class as owner of callback
    # func callback
    # return void
    #
    start: func(objCallback, callback) {
        me.stop();

        me.objCallback = objCallback;
        me.callback = callback;
        me.timer.start();
    },

    #
    # return void
    #
    stop: func() {
        me.timer.stop();
    },

    #
    # Timer update function
    #
    # return void
    #
    update: func() {
        call(me.callback, [], me.objCallback);
    },

    #
    # Save log data to recovery file
    #
    # return void
    #
    save: func(logData) {
        var file = io.open(me.filePath, "w");
        me.file.saveItem(file, logData);
        io.close(file);
    },

    #
    # Clear recovery file
    #
    # return void
    #
    clear: func() {
        var file = io.open(me.filePath, "w");
        io.close(file);
    },

    #
    # Retrieve the log from the recovery file if it exists, write it to the main log file,
    # clear recovery file and load the entire main log file.
    #
    # return void
    #
    restore: func() {
        if (!me.file.exists(me.filePath)) {
            return;
        }

        var file = io.open(me.filePath, "r");
        var line = io.readln(file);
        io.close(file);

        if (line != nil) {
            var items = split(",", me.file.removeQuotes(line));
            var logData = LogData.new();
            logData.fromVector(items);

            me.file.saveData(logData, true);

            me.clear();
        }

        me.file.loadAllData();
    },
};
