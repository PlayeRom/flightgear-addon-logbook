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
# The CSV Recovery class saves the current flight status to a separate file at a given INTERVAL_SEC.
# When FG crashes, the recovery file data will be rewritten to the main log file on restart.
#
var Recovery = {
    #
    # Constants
    #
    RECOVERY_FILE: "recovery-v%s.csv",
    INTERVAL_SEC : 20,

    #
    # Constructor
    #
    # @param  hash  storage  CSV Storage object
    # @return me
    #
    new: func(storage) {
        var me = {
            parents     : [Recovery],
            _storage    : storage,
            _objCallback: nil,
            _callback   : nil,
        };

        me._filePath = g_Addon.storagePath ~ "/" ~ sprintf(Recovery.RECOVERY_FILE, Storage.CSV_FILE_VERSION);
        me._timer    = maketimer(Recovery.INTERVAL_SEC, me, me._update);

        me._restore();

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
    # @param  hash  objCallback  Class as owner of callback
    # @param  func  callback
    # @return void
    #
    start: func(objCallback, callback) {
        me.stop();

        me._objCallback = objCallback;
        me._callback = callback;
        me._timer.start();
    },

    #
    # @return void
    #
    stop: func() {
        me._timer.stop();
    },

    #
    # Timer update function
    #
    # @return void
    #
    _update: func() {
        call(me._callback, [], me._objCallback);
    },

    #
    # Save log data to recovery file
    #
    # @param  hash  logData  LogData object
    # @return void
    #
    save: func(logData) {
        var file = io.open(me._filePath, "w");
        me._storage.addItem(logData, file);
        io.close(file);
    },

    #
    # Clear recovery file
    #
    # @return void
    #
    clear: func() {
        var file = io.open(me._filePath, "w");
        io.close(file);
    },

    #
    # Not used for CSV, but needed to unify calls with SQLite
    #
    # @return nil
    #
    getLogbookId: func() {
        return nil;
    },

    #
    # Retrieve the log from the recovery file if it exists, write it to the main log file,
    # clear recovery file and load the entire main log file.
    #
    # @return void
    #
    _restore: func() {
        if (Utils.fileExists(me._filePath)) {
            var file = io.open(me._filePath, "r");
            var line = io.readln(file);
            io.close(file);

            if (line != nil) {
                var items = split(",", Utils.removeQuotes(line));
                var logData = LogData.new();
                logData.fromVector(items);

                me._storage.saveLogData(logData, nil, true);

                me.clear();
            }
        }

        me._storage.loadAllData();
    },
};
