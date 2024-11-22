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
    # @param  func  onResetCounters
    # @param  func  onUpdate
    # @return me
    #
    new: func(onResetCounters, onUpdate) {
        var me = { parents: [BaseCounter] };

        me._propElapsedSec = props.globals.getNode("/sim/time/elapsed-sec");

        me._onResetCountersCallback = onResetCounters;
        me._onUpdateCallback        = onUpdate;

        me._isRealTimeDuration = g_Settings.isRealTimeDuration();
        me._lastElapsedSec     = me._isRealTimeDuration ? 0 : me._getElapsedSec();

        # me._isReplayMode       = false;
        me._isRunning          = false;

        return me;
    },

    #
    # Reset all environment counters
    #
    # @return void
    #
    resetCounters: func() {
        if (me._onResetCountersCallback != nil) {
            me._onResetCountersCallback();
        }

        me._lastElapsedSec = me._isRealTimeDuration ? 0 : me._getElapsedSec();
        me._isRunning      = true;
    },

    #
    # Update all environment counters
    #
    # @return void
    #
    update: func() {
        if (!me._isRunning) {
            return;
        }

        var currentElapsedSec = me._isRealTimeDuration ? 0 : me._getElapsedSec();

        var diffElapsedSec = me._isRealTimeDuration
            ? Logbook.MAIN_TIMER_INTERVAL
            : (currentElapsedSec - me._lastElapsedSec);

        if (me._onUpdateCallback != nil) {
            me._onUpdateCallback(diffElapsedSec);
        }

        me._lastElapsedSec = currentElapsedSec;
    },

    #
    # Get elapsed time in seconds in simulation.
    # The "/sim/time/elapsed-sec" property is count automatically and also paused when sim is paused.
    #
    # @return double
    #
    _getElapsedSec: func() {
        return me._propElapsedSec.getValue();
    },

    #
    # Set replay mode flag. If true then sim is in replay mode and the counters should not be updated.
    # The problem is that elapsed-sec in reply mode is continuing counting, so we have to handle it manually.
    #
    # @param  bool  isReplayMode
    # @return void
    #
    # _setReplayMode: func(isReplayMode) {
    #     me._isReplayMode = isReplayMode;
    # },
};
