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
    # @return hash
    #
    new: func() {
        var obj = { parents: [Thread] };

        obj._isPending = false;
        obj._callback = nil;

        obj._timer = Timer.make(0.1, obj, obj._checkEnd);

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._timer.stop();
    },

    #
    # @param  func  threadFunc  Task to be done in the thread
    # @param  hash  callback  Callback object that will be called when the thread finishes its task
    # @param  bool  isLockByGlobal
    # @return bool
    #
    run: func(threadFunc, callback, isLockByGlobal = true) {
        if (isLockByGlobal and g_isThreadPending) {
            return false;
        }

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
        me._callback.invoke();
    },
};
