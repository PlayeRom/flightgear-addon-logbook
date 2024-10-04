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
# A class for handling a thread, catching the completion of its job
# and passing the callback to the main thread using a timer.
#
var Thread = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        return {
            parents     : [Thread],
            timer       : nil,
            isPending   : false,
            objCallback : nil,
            callback    : func,
        };
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        if (me.timer != nil) {
            me.timer.stop();
        }
    },

    #
    # @param func threadFunc
    # @param hash objCallback
    # @param func callback
    # @param bool isLockByGlobal
    # @return bool
    #
    run: func(threadFunc, objCallback, callback, isLockByGlobal = 1) {
        if (isLockByGlobal and g_isThreadPending) {
            return false;
        }

        me.objCallback = objCallback;
        me.callback = callback;

        g_isThreadPending = true;
        me.isPending = true;

        thread.newthread(func {
            threadFunc();
            me.isPending = false;
        });

        me.timer = maketimer(0.1, me, me.checkEnd);
        me.timer.start();

        return true;
    },

    #
    # Timer callback function
    #
    # @return void
    #
    checkEnd: func() {
        if (me.isPending) {
            # Still working, skip it
            return;
        }

        # Stop yourself
        me.timer.stop();

        # Call the finish callback
        call(me.callback, [], me.objCallback);
    },
};
