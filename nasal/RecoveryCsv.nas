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
# The RecoveryCsv class saves the current flight status to a separate file every minute.
# When FG crashes, the recovery file data will be rewritten to the main log file on restart.
#
var RecoveryCsv = {
    #
    # Constants
    #
    RECOVERY_FILE : "recovery-v%s.csv",

    #
    # Constructor
    #
    # @param hash addon - addons.Addon object
    # @param storage - Storage object
    # @return me
    #
    new: func(addon, storage) {
        var me = {
            parents     : [RecoveryCsv],
            storage     : storage,
            objCallback : nil,
            callback    : nil,
            recordId    : nil, # not used for CSV, but needed to unify calls with SQLite
        };

        me.filePath = addon.storagePath ~ "/" ~ sprintf(RecoveryCsv.RECOVERY_FILE, StorageCsv.FILE_VERSION);
        me.timer    = maketimer(60, me, me.update);

        me.restore();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.stop();
    },

    #
    # @param hash objCallback - Class as owner of callback
    # @param func callback
    # @return void
    #
    start: func(objCallback, callback) {
        me.stop();

        me.objCallback = objCallback;
        me.callback = callback;
        me.timer.start();
    },

    #
    # @return void
    #
    stop: func() {
        me.timer.stop();
    },

    #
    # Timer update function
    #
    # @return void
    #
    update: func() {
        call(me.callback, [], me.objCallback);
    },

    #
    # Save log data to recovery file
    #
    # @param hash logData - LogData object
    # @return void
    #
    save: func(logData) {
        var file = io.open(me.filePath, "w");
        me.storage.addItem(logData, file);
        io.close(file);
    },

    #
    # Clear recovery file
    #
    # @return void
    #
    clear: func() {
        var file = io.open(me.filePath, "w");
        io.close(file);
    },

    #
    # Retrieve the log from the recovery file if it exists, write it to the main log file,
    # clear recovery file and load the entire main log file.
    #
    # @return void
    #
    restore: func() {
        if (Utils.fileExists(me.filePath)) {
            var file = io.open(me.filePath, "r");
            var line = io.readln(file);
            io.close(file);

            if (line != nil) {
                var items = split(",", Utils.removeQuotes(line));
                var logData = LogData.new();
                logData.fromVector(items);

                me.storage.saveLogData(logData, nil, true);

                me.clear();
            }
        }

        me.storage.loadAllData();
    },
};
