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
            storage     : storage,
            objCallback : nil,
            callback    : nil,
            recordId    : nil,
            inserted    : false,
        };

        me.timer = maketimer(60, me, me.update);

        me.storage.loadAllData();

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
        if (me.recordId == nil) {
            # insert
            if (!me.inserted) {
                # The inserted protects us from making more than one insert,
                # if there is no ID after the first insert then something is broken
                me.recordId = me.storage.addItem(logData);
                me.inserted = true;
            }
        }
        else {
            # update
            me.storage.updateItem(logData, me.recordId);
        }
    },

    #
    # Clear recovery variable
    #
    # @return void
    #
    clear: func() {
        me.recordId = nil;
        me.inserted = false;
    },
};
