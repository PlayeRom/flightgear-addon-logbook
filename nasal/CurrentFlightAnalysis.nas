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
    # Constants
    #
    TIMER_INTERVAL: 5,

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
            _isDialogOpened   : false,
        };

        me._timer = maketimer(CurrentFlightAnalysis.TIMER_INTERVAL, me, me._update);

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
        me._timestamp += CurrentFlightAnalysis.TIMER_INTERVAL;

        if (me._currentFlightMaxAlt < data.alt_m) {
            me._currentFlightMaxAlt = data.alt_m;
        }

        if (me._currentFlightMaxAlt < data.elevation_m) {
            me._currentFlightMaxAlt = data.elevation_m;
        }

        me._currentFlightData.append(data);

        if (me._flightAnalysisDlg != nil and me._isDialogOpened) {
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
            me._flightAnalysisDlg = FlightAnalysisDialog.new(me._onCanvasClosed, me);
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

        me._isDialogOpened = true;
    },

    #
    # Callback function called when Flight Analysis Dialog is about to be closed
    #
    # @return void
    #
    _onCanvasClosed: func() {
        me._isDialogOpened = false;
    },
};
