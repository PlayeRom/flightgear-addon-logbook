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
# FlightAnalysis class used to collect data for flight analysis of the current session.
#
var FlightAnalysis = {
    #
    # Constants:
    #
    INTERVAL_AUTO_THRESHOLD: 1.0,

    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = { parents: [FlightAnalysis] };

        obj._callback = nil;
        obj._flightAnalysisDlg = nil;

        # obj._mpClockSecNode = props.globals.getNode("/sim/time/mp-clock-sec"); # elapse of real time
        obj._mpClockSecNode = props.globals.getNode("/sim/time/elapsed-sec");
        obj._rollDegNode    = props.globals.getNode("/orientation/roll-deg");
        obj._altAglFtNode   = props.globals.getNode("/position/altitude-agl-ft");

        obj._currentFlightData = std.Vector.new();
        obj._currentFlightMaxAlt = 0.0;

        obj._lastElapsedTime = obj._mpClockSecNode.getValue();
        obj._timestamp = 0;

        obj._lastIntervalSec = obj._getInitialIntervalSec();
        obj._timer = Timer.make(obj._lastIntervalSec, obj, obj._update);

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.stop();

        if (me._flightAnalysisDlg != nil) {
            me._flightAnalysisDlg.del();
        }
    },

    #
    # Get initial interval for timer.
    #
    # @return double
    #
    _getInitialIntervalSec: func() {
        var settingsValue = g_Settings.getTrackerIntervalSec();
        if (me._isAutoInterval(settingsValue)) {
            return me._getAutoIntervalSec();
        }

        return num(settingsValue);
    },

    #
    # Return true if setting TrackerIntervalSec is in auto mode.
    #
    # @return bool
    #
    _isAutoInterval: func(value) {
        return value < FlightAnalysis.INTERVAL_AUTO_THRESHOLD;
    },

    #
    # Change timer interval if needed.
    #
    # @return void
    #
    updateIntervalSec: func() {
        if (!me._isAutoInterval(g_Settings.getTrackerIntervalSec())) {
            # User set fixed interval value, so don't change it
            return;
        }

        var newInterval = me._getAutoIntervalSec();
        if (me._lastIntervalSec != newInterval) {
            me._lastIntervalSec = newInterval;
            me._update();
            me._timer.restart(newInterval);
        }
    },

    #
    # Get timer interval according to situation.
    #
    # @return double
    #
    _getAutoIntervalSec: func() {
        if (math.abs(me._rollDegNode.getValue()) > 5.0
            or me._altAglFtNode.getValue() <= 2000.0
        ) {
            # When we enter turns or are low altitude (during takeoff, landing, close to the mountains)
            # we want a more accurate record.
            return 5.0;
        }

        return 15.0;
    },

    #
    # @param  hash  callback  Callback object to get logbook data.
    # @return void
    #
    start: func(callback) {
        me.stop();

        me.clear();

        me._callback = callback;

        me._update();

        me._timer.start();
    },

    #
    # @return void
    #
    stop: func() {
        me._timer.stop();
    },

    #
    # Clear recovery variable.
    #
    # @return void
    #
    clear: func() {
        me._currentFlightData.clear();
        me._currentFlightMaxAlt = 0.0;
        me._lastElapsedTime = me._mpClockSecNode.getValue();
        me._timestamp = 0;
    },

    #
    # Timer update function.
    #
    # @return void
    #
    _update: func() {
        var data = me._callback.invoke();
        if (data == nil) {
            return;
        }

        var currentElapsedTime = me._mpClockSecNode.getValue();
        var diffElapsedTime = currentElapsedTime - me._lastElapsedTime;

        me._timestamp += diffElapsedTime;
        me._lastElapsedTime = currentElapsedTime;

        data.timestamp = me._timestamp / 3600; # convert sec to hours

        if (me._currentFlightMaxAlt < data.alt_m) {
            me._currentFlightMaxAlt = data.alt_m;
        }

        if (me._currentFlightMaxAlt < data.elevation_m) {
            me._currentFlightMaxAlt = data.elevation_m;
        }

        me._currentFlightData.append(data);

        if (me._flightAnalysisDlg != nil and me._flightAnalysisDlg.isWindowVisible()) {
            me._flightAnalysisDlg.appendData(data, me._currentFlightMaxAlt);
            me._flightAnalysisDlg.softUpdateView();
        }
    },

    #
    # Open Flight Analysis Dialog.
    #
    # @return void
    #
    showDialog: func() {
        var firstRun = me._flightAnalysisDlg == nil;
        if (firstRun) {
            me._flightAnalysisDlg = FlightAnalysisDialog.new(title: "Current Flight Analysis", liveUpdateMode: true);
        }

        me._flightAnalysisDlg.setData(
            trackItems       : me._currentFlightData.vector,
            maxAlt           : me._currentFlightMaxAlt,
            withResetPosition: false,
        );

        if (firstRun) {
            me._flightAnalysisDlg.hardUpdateView();
        }

        me._flightAnalysisDlg.show();

        if (!firstRun) {
            me._flightAnalysisDlg.softUpdateView();
        }

        me._flightAnalysisDlg.goEndTrack();
    },
};
