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
    WINDOW_WIDTH     : 1360,
    WINDOW_HEIGHT    : 720,
    V_PROFILE_HEIGHT : 300,
    FRACTION         : { labels: 1, map: 9 },
    #
    # Aircraft icon:
    #
    FAST_POS_CHANGE: 10,

    #
    # Constructor
    #
    # @param  hash  storage  Storage object
    # @return me
    #
    new: func(storage) {
        var me = {
            parents: [
                FlightAnalysisDialog,
                Dialog.new(
                    FlightAnalysisDialog.WINDOW_WIDTH,
                    FlightAnalysisDialog.WINDOW_HEIGHT,
                    "Flight Analysis"
                ),
            ],
            _storage  : storage,
            _logbookId: nil,
        };

        me._trackItems = nil;

        me.bgImage.hide();

        me.setPositionOnCenter();

        me._labelLatLonValue      = nil;
        me._labelAltValue         = nil;
        me._labelHdgTrueValue     = nil;
        me._labelAirspeedValue    = nil;
        me._labelGroundspeedValue = nil;
        me._labelTimestampValue   = nil;
        me._labelDistanceValue    = nil;

        me._buttonsGroup = me.canvas.createGroup();

        me._btnZoomMinus = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText("-")
            .listen("clicked", func { me._zoomOut(); })
            .setFixedSize(26, 26);

        me._labelZoom = canvas.gui.widgets.Label.new(me._buttonsGroup, canvas.style, {});

        me._btnZoomPlus  = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText("+")
            .listen("clicked", func { me._zoomIn(); })
            .setFixedSize(26, 26);

        me._btnStart   = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText("|<<")
            .listen("clicked", func { me._goStartTrack(); })
            .setFixedSize(26, 26);

        me._btnBackFast  = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText("<<")
            .listen("clicked", func { me._goPrevTrack(FlightAnalysisDialog.FAST_POS_CHANGE); })
            .setFixedSize(26, 26);

        me._btnBack    = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText("<")
            .listen("clicked", func { me._goPrevTrack(); })
            .setFixedSize(26, 26);

        me._btnForward = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText(">")
            .listen("clicked", func { me._goNextTrack(); })
            .setFixedSize(26, 26);

        me._btnForwardFast = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText(">>")
            .listen("clicked", func { me._goNextTrack(FlightAnalysisDialog.FAST_POS_CHANGE); })
            .setFixedSize(26, 26);

        me._btnEnd     = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText(">>|")
            .listen("clicked", func { me._goEndTrack(); })
            .setFixedSize(26, 26);

        me._mapView = nil;
        me._profileView = nil;

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Show this canvas dialog
    #
    # @param  int  logbookId
    # @return void
    #
    show: func(logbookId) {
        g_Sound.play('paper');

        me._logbookId = logbookId;
        me._trackItems = me._storage.getLogbookTracker(me._logbookId);

        me._drawContent();

        call(Dialog.show, [], me);
    },

    #
    # Draw whole dialog content
    #
    # @return void
    #
    _drawContent: func() {
        me.vbox.clear();

        me._scrollAreaLProfile = me.createScrollArea();
        me._scrollAreaVProfile = me.createScrollArea();

        var hBoxLayout = canvas.HBoxLayout.new();

        var vBoxLayoutInfo = me._drawInfoLabels();

        hBoxLayout.addSpacing(10);
        hBoxLayout.addItem(vBoxLayoutInfo, FlightAnalysisDialog.FRACTION.labels); # 2nd param = stretch
        hBoxLayout.addItem(me._scrollAreaLProfile, FlightAnalysisDialog.FRACTION.map); # 2nd param = stretch

        me.vbox.addItem(hBoxLayout, 2); # 2nd param = stretch
        me.vbox.addItem(me._scrollAreaVProfile, 1); # 2nd param = stretch

        me._scrollLProfileContent = me.getScrollAreaContent(me._scrollAreaLProfile);
        me._scrollVProfileContent = me.getScrollAreaContent(me._scrollAreaVProfile);

        me._drawScrollable();

        me._drawBottomBar();
    },

    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawInfoLabels: func() {
        var vBoxLayoutInfo = canvas.VBoxLayout.new();

        var labelLatLon           = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Latitude, Longitude");
        me._labelLatLonValue      = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0.00, 0.00");
        var labelAlt              = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Altitude");
        me._labelAltValue         = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 ft");
        var labelHdgTrue          = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Heading true / mag");
        me._labelHdgTrueValue     = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0° / 0°");
        var labelAirspeed         = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Airspeed");
        me._labelAirspeedValue    = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 kt");
        var labelGroundspeed      = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Groundspeed");
        me._labelGroundspeedValue = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 kt");
        var labelTimestamp        = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Flight Duration");
        me._labelTimestampValue   = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0");
        var labelDistance         = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Distance");
        me._labelDistanceValue    = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0 NM");

        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelLatLon);
        vBoxLayoutInfo.addItem(me._labelLatLonValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelAlt);
        vBoxLayoutInfo.addItem(me._labelAltValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelHdgTrue);
        vBoxLayoutInfo.addItem(me._labelHdgTrueValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelAirspeed);
        vBoxLayoutInfo.addItem(me._labelAirspeedValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelGroundspeed);
        vBoxLayoutInfo.addItem(me._labelGroundspeedValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelTimestamp);
        vBoxLayoutInfo.addItem(me._labelTimestampValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelDistance);
        vBoxLayoutInfo.addItem(me._labelDistanceValue);
        vBoxLayoutInfo.addStretch(2);

        return vBoxLayoutInfo;
    },

    #
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func() {
        # Lateral Profile

        me._mapView = canvas.gui.widgets.MapView.new(me._scrollLProfileContent, canvas.style, {});
        me._mapView.setSize(
            FlightAnalysisDialog.WINDOW_WIDTH - (FlightAnalysisDialog.WINDOW_WIDTH / (FlightAnalysisDialog.FRACTION.map)),
            560
        );
        me._mapView.setTrackItems(me._trackItems);


        # Vertical Profile

        me._profileView = canvas.gui.widgets.ProfileView.new(me._scrollVProfileContent, canvas.style, {});
        me._profileView.setSize(FlightAnalysisDialog.WINDOW_WIDTH, FlightAnalysisDialog.V_PROFILE_HEIGHT);
        me._profileView.setData(
            me._trackItems,
            me._storage.getLogbookTrackerMaxAlt(me._logbookId)
        );

        me._updateLabelValues();
    },

    #
    # Update values for all info labels
    #
    # @return void
    #
    _updateLabelValues: func() {
        if (me._trackItems == nil or size(me._trackItems) == 0) {
            return;
        }

        var row = me._trackItems[me._mapView.getPosition()];

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
    _goEndTrack: func() {
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
        var position = me._mapView.getPosition();

        me._btnStart.setEnabled(position > 0);
        me._btnBackFast.setEnabled(position > 0);
        me._btnBack.setEnabled(position > 0);
        me._btnForward.setEnabled(position < lastRowsIndex);
        me._btnForwardFast.setEnabled(position < lastRowsIndex);
        me._btnEnd.setEnabled(position < lastRowsIndex);

        me._updateLabelValues();
    },

    #
    # Draw bottom bar with buttons
    #
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        me._updateAfterChangePosition();

        var buttonBox = canvas.HBoxLayout.new();

        me._labelZoom.setText("Zoom " ~ me._mapView.getZoomLevel());

        var btnClose = canvas.gui.widgets.Button.new(me._buttonsGroup, canvas.style, {})
            .setText("Close")
            .listen("clicked", func { me.hide(); })
            .setFixedSize(65, 26);

        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnZoomMinus);
        buttonBox.addItem(me._labelZoom);
        buttonBox.addItem(me._btnZoomPlus);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnStart);
        buttonBox.addItem(me._btnBackFast);
        buttonBox.addItem(me._btnBack);
        buttonBox.addItem(me._btnForward);
        buttonBox.addItem(me._btnForwardFast);
        buttonBox.addItem(me._btnEnd);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return buttonBox;
    },
};
