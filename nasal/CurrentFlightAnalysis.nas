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
# CurrentFlightAnalysis class used to collect data for flight analysis of the current session
#
var CurrentFlightAnalysis = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = {
            parents           : [CurrentFlightAnalysis],
            _objCallback      : nil,
            _callback         : nil,
            _flightAnalysisDlg: nil,
        };

        me._timer = maketimer(g_Settings.getTrackerIntervalSec(), me, me._update);

        me._currentFlightData = std.Vector.new();
        me._currentFlightMaxAlt = 0.0;
        me._timestamp = 0;

        return me;
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
    # @param hash objCallback - Class as owner of callback
    # @param func callback
    # @return void
    #
    start: func(objCallback, callback) {
        me.stop();

        me.clear();

        me._objCallback = objCallback;
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
    # Clear recovery variable
    #
    # @return void
    #
    clear: func() {
        me._currentFlightData.clear();
        me._currentFlightMaxAlt = 0.0;
        me._timestamp = 0;
    },

    #
    # Timer update function
    #
    # @return void
    #
    _update: func() {
        var data = call(me._callback, [], me._objCallback);
        if (data == nil) {
            return;
        }

        data.timestamp = me._timestamp / 3600; # convert sec to hours
        me._timestamp += g_Settings.getTrackerIntervalSec();

        if (me._currentFlightMaxAlt < data.alt_m) {
            me._currentFlightMaxAlt = data.alt_m;
        }

        if (me._currentFlightMaxAlt < data.elevation_m) {
            me._currentFlightMaxAlt = data.elevation_m;
        }

        me._currentFlightData.append(data);

        if (me._flightAnalysisDlg != nil and me._flightAnalysisDlg.isWindowVisible()) {
            me._flightAnalysisDlg.setData(me._currentFlightData.vector, me._currentFlightMaxAlt, false);
            me._flightAnalysisDlg.softUpdateView();
        }
    },

    #
    # Open Flight Analysis Dialog
    #
    # @return void
    #
    showFlightAnalysisDialog: func() {
        var firstRun = me._flightAnalysisDlg == nil;
        if (firstRun) {
            me._flightAnalysisDlg = FlightAnalysisDialog.new();
        }

        me._flightAnalysisDlg.setData(me._currentFlightData.vector, me._currentFlightMaxAlt, false);

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
