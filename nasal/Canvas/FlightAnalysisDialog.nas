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
# FlightAnalysisDialog class
#
var FlightAnalysisDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH    : 1360,
    WINDOW_HEIGHT   : 720,
    PADDING         : 10,
    FRACTION        : { labels: 1, map: 9 },
    #
    # Aircraft icon:
    #
    FAST_POS_CHANGE : 10,

    #
    # Constructor
    #
    # @param  func|nil  onCanvasClosed
    # @param  ghost|nil   objCallback
    # @return me
    #
    new: func(onCanvasClosed = nil, objCallback = nil) {
        var me = {
            parents: [
                FlightAnalysisDialog,
                Dialog.new(
                    FlightAnalysisDialog.WINDOW_WIDTH,
                    FlightAnalysisDialog.WINDOW_HEIGHT,
                    "Logbook Flight Analysis",
                    true, # <- resizable
                ),
            ],
            _trackItems    : nil,
            _trackSize     : 0,
            _onCanvasClosed: onCanvasClosed,
            _objCallback   : objCallback,
        };

        me.bgImage.hide();

        me.setPositionOnCenter();

        # Override window del method (X button on bar) for stop _playTimer
        var self = me;
        me.window.del = func() {
            call(FlightAnalysisDialog.hide, [], self);
        };

        me._playTimer = maketimer(0.2, me, me._onPlayUpdate);

        me._mapView = canvas.gui.widgets.MapView.new(me.group, canvas.style, {});
        me._mapView.setUpdatePositionCallback(me._mapViewUpdatePosition, me);
        me._mapView.setUpdateZoomCallback(me._mapViewUpdateZoom, me);

        me._profileView = canvas.gui.widgets.ProfileView.new(me.group, canvas.style, {});
        me._profileView.setUpdateCallback(me._profileViewUpdatePosition, me);

        me._drawContent();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._playTimer.stop();

        if (me._onCanvasClosed != nil) {
            call(me._onCanvasClosed, [], me._objCallback);
        }

        call(Dialog.del, [], me);
    },

    #
    # Show this canvas dialog
    #
    # @return void
    #
    show: func() {
        g_Sound.play('paper');

        me._updateAfterChangePosition();

        call(Dialog.show, [], me);
    },

    #
    # Show this canvas dialog
    #
    # @return void
    #
    hide: func() {
        me._playTimer.stop();

        if (me._onCanvasClosed != nil) {
            call(me._onCanvasClosed, [], me._objCallback);
        }

        call(Dialog.hide, [], me);
    },

    #
    # Set track data
    #
    # @param  vector  logData  Vector of hashes with all path points
    # @param  double  maxAlt  Max altitude of aircraft or terrain elevation
    # @param  bool  withReset  If true then aircraft position will be set to 0
    # @return void
    #
    setData: func(logData, maxAlt, withReset = 1) {
        me._trackItems = logData;
        me._trackSize = size(me._trackItems);

        # Put data to widgets
        me._mapView.setTrackItems(me._trackItems, me._trackSize, withReset);
        me._profileView.setTrackItems(me._trackItems, me._trackSize, maxAlt, withReset);
    },

    #
    # Redraw hole widgets from strach
    #
    hardUpdateView: func() {
        me._mapView.hardUpdateView();
        me._profileView.hardUpdateView();

        me._updateAfterChangePosition();
    },

    #
    # Soft redraw widgets, however profile must be always hard redraw
    #
    softUpdateView: func() {
        me._mapView.softUpdateView();
        me._profileView.hardUpdateView();

        me._updateAfterChangePosition();
    },

    #
    # Draw whole dialog content
    #
    # @return void
    #
    _drawContent: func() {
        var hBoxLayout = canvas.HBoxLayout.new();

        var vBoxLayoutInfo = me._drawInfoLabels();

        hBoxLayout.addSpacing(FlightAnalysisDialog.PADDING);
        hBoxLayout.addItem(vBoxLayoutInfo, FlightAnalysisDialog.FRACTION.labels); # 2nd param = stretch
        hBoxLayout.addItem(me._mapView, FlightAnalysisDialog.FRACTION.map); # 2nd param = stretch

        me.vbox.addItem(hBoxLayout, 2); # 2nd param = stretch

        var hBoxProfile = canvas.HBoxLayout.new();
        hBoxProfile.addSpacing(FlightAnalysisDialog.PADDING);
        hBoxProfile.addItem(me._profileView);
        hBoxProfile.addSpacing(FlightAnalysisDialog.PADDING);

        me.vbox.addSpacing(FlightAnalysisDialog.PADDING);
        me.vbox.addItem(hBoxProfile, 1); # 2nd param = stretch

        me._updateLabelValues();

        me._drawBottomBar();
    },

    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawInfoLabels: func() {
        me._labelLatLon           = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Latitude, Longitude");
        me._labelLatLonValue      = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0.00, 0.00");
        me._labelAlt              = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Altitude");
        me._labelAltValue         = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 ft");
        me._labelHdgTrue          = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Heading true / mag");
        me._labelHdgTrueValue     = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0° / 0°");
        me._labelAirspeed         = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Airspeed");
        me._labelAirspeedValue    = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 kt");
        me._labelGroundspeed      = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Groundspeed");
        me._labelGroundspeedValue = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 kt");
        me._labelTimestamp        = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Flight Duration");
        me._labelTimestampValue   = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0");
        me._labelDistance         = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Distance");
        me._labelDistanceValue    = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 NM");

        var vBoxLayoutInfo = canvas.VBoxLayout.new();

        vBoxLayoutInfo.addSpacing(FlightAnalysisDialog.PADDING);
        vBoxLayoutInfo.addItem(me._labelLatLon);
        vBoxLayoutInfo.addItem(me._labelLatLonValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(me._labelAlt);
        vBoxLayoutInfo.addItem(me._labelAltValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(me._labelHdgTrue);
        vBoxLayoutInfo.addItem(me._labelHdgTrueValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(me._labelAirspeed);
        vBoxLayoutInfo.addItem(me._labelAirspeedValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(me._labelGroundspeed);
        vBoxLayoutInfo.addItem(me._labelGroundspeedValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(me._labelTimestamp);
        vBoxLayoutInfo.addItem(me._labelTimestampValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(me._labelDistance);
        vBoxLayoutInfo.addItem(me._labelDistanceValue);
        vBoxLayoutInfo.addStretch(2);
        vBoxLayoutInfo.addSpacing(FlightAnalysisDialog.PADDING);

        return vBoxLayoutInfo;
    },

    #
    # Update values for all info labels
    #
    # @return void
    #
    _updateLabelValues: func() {
        if (me._trackItems == nil or me._trackSize == 0) {
            return;
        }

        var row = me._trackItems[me._mapView.getTrackPosition()];

        me._labelLatLonValue.setText(sprintf("%.03f, %.03f", row.lat, row.lon));
        me._labelAltValue.setText(sprintf("%.0f ft", row.alt_m * globals.M2FT));
        me._labelHdgTrueValue.setText(sprintf("%.0f° / %.0f°", row.heading_true, row.heading_mag));
        me._labelAirspeedValue.setText(sprintf("%.0f kt", row.airspeed));
        me._labelGroundspeedValue.setText(sprintf("%.0f kt", row.groundspeed));
        me._labelTimestampValue.setText(Utils.decimalHoursToHuman(row.timestamp));
        me._labelDistanceValue.setText(sprintf("%.02f NM", row.distance));
    },

    #
    # Zoom in the map
    #
    # @return void
    #
    _zoomIn: func() {
        me._mapView.zoomIn();
        me._updateAfterZoom();
    },

    #
    # Zoom out the map
    #
    # @return void
    #
    _zoomOut: func() {
        me._mapView.zoomOut();
        me._updateAfterZoom();
    },

    #
    # Update label and buttons according to current zoom level
    #
    # @return void
    #
    _updateAfterZoom: func() {
        var zoom = me._mapView.getZoomLevel();

        me._labelZoom.setText("Zoom " ~ zoom);

        me._btnZoomMinus.setEnabled(zoom > canvas.gui.widgets.MapView.ZOOM_MIN);
        me._btnZoomPlus.setEnabled(zoom < canvas.gui.widgets.MapView.ZOOM_MAX);
    },

    #
    # Move aircraft to first position on the map and profile
    #
    # @return void
    #
    _goStartTrack: func() {
        me._mapView.goStartTrack();
        me._profileView.goStartTrack();

        me._updateAfterChangePosition();
    },

    #
    # Move aircraft to last position on the map and profile
    #
    # @return void
    #
    goEndTrack: func() {
        me._mapView.goEndTrack();
        me._profileView.goEndTrack();

        me._updateAfterChangePosition();
    },

    #
    # Move the aircraft position forward by the specified interval
    #
    # @param  int  interval
    # @return void
    #
    _goNextTrack: func(interval = 1) {
        me._mapView.goNextTrack(interval);
        me._profileView.goNextTrack(interval);

        me._updateAfterChangePosition();
    },

    #
    # Move the aircraft position backward by the specified interval
    #
    # @param  int  interval
    # @return void
    #
    _goPrevTrack: func(interval = 1) {
        me._mapView.goPrevTrack(interval);
        me._profileView.goPrevTrack(interval);

        me._updateAfterChangePosition();
    },

    #
    # Update buttons according to current aircraft position
    #
    # @return void
    #
    _updateAfterChangePosition: func() {
        var lastRowsIndex = me._mapView.getTrackLastIndex();
        var position = me._mapView.getTrackPosition();

        me._btnStart.setEnabled(position > 0);
        me._btnBackFast.setEnabled(position > 0);
        me._btnBack.setEnabled(position > 0);
        me._btnPlay.setEnabled(position < lastRowsIndex);
        me._btnForward.setEnabled(position < lastRowsIndex);
        me._btnForwardFast.setEnabled(position < lastRowsIndex);
        me._btnEnd.setEnabled(position < lastRowsIndex);

        me._updateLabelValues();
    },

    #
    # Callback function called from MapView when user click on the map
    #
    # @param  int  position  New aircraft position
    # @return void
    #
    _mapViewUpdatePosition: func(position) {
        me._profileView.setTrackPosition(position);

        me._updateAfterChangePosition();
    },

    #
    # Callback function called from MapView when user change zoom by scroll
    #
    # @return void
    #
    _mapViewUpdateZoom: func() {
        me._updateAfterZoom();
    },

    #
    # Callback function called from ProfileView when user click on diagram
    #
    # @param  int  position  New aircraft position
    # @return void
    #
    _profileViewUpdatePosition: func(position) {
        me._mapView.setTrackPosition(position);

        me._updateAfterChangePosition();
    },

    #
    # Draw bottom bar with buttons
    #
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        me._labelZoom    = canvas.gui.widgets.Label.new(me.group, canvas.style, {})
            .setText("Zoom " ~ me._mapView.getZoomLevel());

        me._btnZoomMinus   = me._createButtonNarrow("-",   func { me._zoomOut(); });
        me._btnZoomPlus    = me._createButtonNarrow("+",   func { me._zoomIn(); });

        me._btnStart       = me._createButtonNarrow("|<<", func { me._goStartTrack(); });
        me._btnBackFast    = me._createButtonNarrow("<<",  func { me._goPrevTrack(FlightAnalysisDialog.FAST_POS_CHANGE); });
        me._btnBack        = me._createButtonNarrow("<",   func { me._goPrevTrack(); });
        me._btnForward     = me._createButtonNarrow(">",   func { me._goNextTrack(); });
        me._btnForwardFast = me._createButtonNarrow(">>",  func { me._goNextTrack(FlightAnalysisDialog.FAST_POS_CHANGE); });
        me._btnEnd         = me._createButtonNarrow(">>|", func { me._goEndTrack(); });

        me._btnPlay        = me._createButtonWide("Play",  func { me._togglePlay(); });
        var btnClose       = me._createButtonWide("Close", func { me.hide(); });

        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnZoomMinus);
        buttonBox.addItem(me._labelZoom);
        buttonBox.addItem(me._btnZoomPlus);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnStart);
        buttonBox.addItem(me._btnBackFast);
        buttonBox.addItem(me._btnBack);
        buttonBox.addItem(me._btnPlay);
        buttonBox.addItem(me._btnForward);
        buttonBox.addItem(me._btnForwardFast);
        buttonBox.addItem(me._btnEnd);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(FlightAnalysisDialog.PADDING);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(FlightAnalysisDialog.PADDING);

        me._updateAfterChangePosition();

        return buttonBox;
    },

    #
    # @param  string  label
    # @param  func  clickedCallback
    # @return ghost  Button widget
    #
    _createButtonNarrow: func(label, clickedCallback) {
        return me._createButton(label, clickedCallback).setFixedSize(26, 26);
    },

    #
    # @param  string  label
    # @param  func  clickedCallback
    # @return ghost  Button widget
    #
    _createButtonWide: func(label, clickedCallback) {
        return me._createButton(label, clickedCallback).setFixedSize(65, 26);
    },

    #
    # @param  string  label
    # @param  func  clickedCallback
    # @return ghost  Button widget
    #
    _createButton: func(label, clickedCallback) {
        return canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(label)
            .listen("clicked", clickedCallback)
    },

    #
    # Start/stop play animation of fly
    #
    # @return void
    #
    _togglePlay: func() {
        if (me._playTimer.isRunning) {
            me._playTimer.stop();
            me._btnPlay.setText("Start");
        }
        else {
            me._playTimer.start();
            me._btnPlay.setText("Stop");
        }
    },

    #
    # Play animation update timer callback
    #
    # @return void
    #
    _onPlayUpdate: func() {
        var position = me._mapView.getTrackPosition();
        if (position < me._trackSize - 1) {
            me._goNextTrack();
        }
        else {
            me._playTimer.stop();
            me._btnPlay.setText("Start");
        }
    },
};
