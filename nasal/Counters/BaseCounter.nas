#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2023 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# BaseCounter class for update counters durations
#
var BaseCounter = {
    #
    # Constructor
    #
    # @param func onResetCounters
    # @param func onUpdate
    # @return me
    #
    new: func(onResetCounters, onUpdate) {
        var me = { parents: [BaseCounter] };

        me.onResetCountersCallback = onResetCounters;
        me.onUpdateCallback = onUpdate;

        me.isRealTimeDuration = g_Settings.isRealTimeDuration();
        me.lastElapsedSec     = me.isRealTimeDuration ? 0 : me.getElapsedSec();

        # me.isReplayMode       = false;
        me.isRunning          = false;

        return me;
    },

    #
    # Reset all environment counters
    #
    # @return void
    #
    resetCounters: func() {
        if (me.onResetCountersCallback != nil) {
            me.onResetCountersCallback();
        }

        me.lastElapsedSec = me.isRealTimeDuration ? 0 : me.getElapsedSec();
        me.isRunning      = true;
    },

    #
    # Update all environment counters
    #
    # @return void
    #
    update: func() {
        if (!me.isRunning) {
            return;
        }

        var currentElapsedSec = me.isRealTimeDuration ? 0 : me.getElapsedSec();

        var diffElapsedSec = me.isRealTimeDuration
            ? Logbook.MAIN_TIMER_INTERVAL
            : (currentElapsedSec - me.lastElapsedSec);

        if (me.onUpdateCallback != nil) {
            me.onUpdateCallback(diffElapsedSec);
        }

        me.lastElapsedSec = currentElapsedSec;
    },

    #
    # Get elapsed time in seconds in simulation.
    # The "/sim/time/elapsed-sec" property is count automatically and also paused when sim is paused.
    #
    # @return double
    #
    getElapsedSec: func() {
        return getprop("/sim/time/elapsed-sec");
    },

    #
    # Set replay mode flag. If true then sim is in replay mode and the counters should not be updated.
    # The problem is that elapsed-sec in reply mode is continuing counting, so we have to handle it manually.
    #
    # @param bool isReplayMode
    # @return void
    #
    # setReplayMode: func(isReplayMode) {
    #     me.isReplayMode = isReplayMode;
    # },
};
