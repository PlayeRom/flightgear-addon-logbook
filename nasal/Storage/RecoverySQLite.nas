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
# The RecoverySQLite class saves the current flight status to a DB every minute.
# When FG crashes, the log will not be lost.
#
var RecoverySQLite = {
    #
    # Constructor
    #
    # @param storage - Storage object
    # @return me
    #
    new: func(storage) {
        var me = {
            parents     : [RecoverySQLite],
            _storage    : storage,
            _objCallback: nil,
            _callback   : nil,
            _recordId   : nil,
            _inserted   : false,
        };

        me._timer = maketimer(60, me, me._update);

        me._storage.loadAllData();

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

        me.clear();

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
    # @param hash logData - LogData object
    # @return void
    #
    save: func(logData) {
        if (me._recordId == nil) {
            # insert
            if (!me._inserted) {
                # The inserted protects us from making more than one insert,
                # if there is no ID after the first insert then something is broken
                me._recordId = me._storage.addItem(logData);
                me._inserted = true;
            }
        }
        else {
            # update
            me._storage.updateItem(logData, me._recordId);
        }
    },

    #
    # Clear recovery variable
    #
    # @return void
    #
    clear: func() {
        me._recordId = nil;
        me._inserted = false;
    },

    #
    # @return int|nil
    #
    getRecordId: func() {
        return me._recordId;
    },
};
