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
        var me = {
            parents      : [Thread],
            _isPending   : false,
            _objCallback : nil,
            _callback    : func,
        };

        me._timer = maketimer(0.1, me, me._checkEnd);

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        if (me._timer != nil) {
            me._timer.stop();
        }
    },

    #
    # @param  func  threadFunc  Task to be done in the thread
    # @param  hash  objCallback  The object to which the function passed in callback belongs
    # @param  func  callback  Function that will be called when the thread finishes its task
    # @param  bool  isLockByGlobal
    # @return bool
    #
    run: func(threadFunc, objCallback, callback, isLockByGlobal = 1) {
        if (isLockByGlobal and g_isThreadPending) {
            return false;
        }

        me._objCallback = objCallback;
        me._callback = callback;

        g_isThreadPending = true;
        me._isPending = true;

        thread.newthread(func {
            threadFunc();
            me._isPending = false;
        });

        me._timer.start();

        return true;
    },

    #
    # Timer callback function
    #
    # @return void
    #
    _checkEnd: func() {
        if (me._isPending) {
            # Still working, skip it
            return;
        }

        # Stop yourself
        me._timer.stop();

        # Call the finish callback
        call(me._callback, [], me._objCallback);
    },
};
