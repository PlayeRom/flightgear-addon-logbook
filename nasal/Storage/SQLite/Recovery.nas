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
# The SQLite Recovery class saves the current flight status to the database
# at a given interval by INTERVAL_SEC.
# When FG crashes, the log will not be lost.
#
var Recovery = {
    #
    # Constants
    #
    INTERVAL_SEC: 20,

    #
    # Constructor
    #
    # @param  storage  Storage object
    # @return hash
    #
    new: func(storage) {
        var me = {
            parents : [Recovery],
            _storage: storage,
        };

        me._callback  = nil;
        me._logbookId = nil;
        me._inserted  = false;

        me._timer = maketimer(Recovery.INTERVAL_SEC, me, me._update);

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
    # @param  hash  callback  Callback object.
    # @return void
    #
    start: func(callback) {
        me.stop();

        me.clear();

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
        me._callback.invoke();
    },

    #
    # Save log data to recovery file
    #
    # @param  hash  logData  LogData object
    # @return void
    #
    save: func(logData) {
        if (me._logbookId == nil) {
            # insert
            if (!me._inserted) {
                # The inserted protects us from making more than one insert,
                # if there is no ID after the first insert then something is broken
                me._logbookId = me._storage.addItem(logData);
                me._inserted = true;
            }
        }
        else {
            # update
            me._storage.updateItem(logData, me._logbookId);
        }
    },

    #
    # Clear recovery variable
    #
    # @return void
    #
    clear: func() {
        me._logbookId = nil;
        me._inserted = false;
    },

    #
    # @return int|nil
    #
    getLogbookId: func() {
        return me._logbookId;
    },
};
