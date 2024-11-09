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
# FlightPreviewDialog class
#
var FlightPreviewDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH     : 1360,
    WINDOW_HEIGHT    : 900,
    V_PROFILE_HEIGHT : 350,
    PADDING          : 0,
    #
    # Aircraft icon:
    #
    PIXEL_DIFF     : 9,  # The difference in height in pixels between adjacent flight profile points
    AC_ANGLE       : 20, # Angle in degrees to rotate the airplane icon up or down
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
                FlightPreviewDialog,
                Dialog.new(
                    FlightPreviewDialog.WINDOW_WIDTH,
                    FlightPreviewDialog.WINDOW_HEIGHT,
                    "Flight Preview"
                ),
            ],
            _storage  : storage,
            _logbookId: nil,
        };

        me._trackItems = nil;

        me.bgImage.hide();

        me.setPositionOnCenter();

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
            .listen("clicked", func { me._goPrevTrack(FlightPreviewDialog.FAST_POS_CHANGE); })
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
            .listen("clicked", func { me._goNextTrack(FlightPreviewDialog.FAST_POS_CHANGE); })
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

        var margins = {
            left   : FlightPreviewDialog.PADDING,
            top    : FlightPreviewDialog.PADDING,
            right  : FlightPreviewDialog.PADDING,
            bottom : 0,
        };

        var hBoxLayout = canvas.HBoxLayout.new();

        var vBoxLayoutInfo = canvas.VBoxLayout.new();

        var labelLat = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Latitude");
        me._labelLatValue = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0");

        var labelLon = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Longitude");
        me._labelLonValue = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0");

        var labelTimestamp = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Flight Duration");
        me._labelTimestampValue = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0");

        var labelAlt = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Altitude");
        me._labelAltValue = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0");

        var _labelDistance = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("Distance");
        me._labelDistanceValue = canvas.gui.widgets.Label.new(me.group, canvas.style, {}).setText("0");

        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelLat);
        vBoxLayoutInfo.addItem(me._labelLatValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelLon);
        vBoxLayoutInfo.addItem(me._labelLonValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelTimestamp);
        vBoxLayoutInfo.addItem(me._labelTimestampValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(labelAlt);
        vBoxLayoutInfo.addItem(me._labelAltValue);
        vBoxLayoutInfo.addStretch(1);
        vBoxLayoutInfo.addItem(_labelDistance);
        vBoxLayoutInfo.addItem(me._labelDistanceValue);
        vBoxLayoutInfo.addStretch(2);

        hBoxLayout.addSpacing(10);
        hBoxLayout.addItem(vBoxLayoutInfo, 1); # 2nd param = stretch

        me._scrollAreaLProfile = me.createScrollArea(nil, margins);
        hBoxLayout.addItem(me._scrollAreaLProfile, 7); # 2nd param = stretch
        me._scrollLProfileContent = me.getScrollAreaContent(me._scrollAreaLProfile);


        me.vbox.addItem(hBoxLayout, 2); # 2nd param = stretch

        me._scrollAreaVProfile = me.createScrollArea(nil, margins);
        me.vbox.addItem(me._scrollAreaVProfile, 1); # 2nd param = stretch
        me._scrollVProfileContent = me.getScrollAreaContent(me._scrollAreaVProfile);

        me._drawScrollable();

        me._drawBottomBar();
    },

    _updateLabels: func() {
        var row = me._trackItems[me._mapView.getPosition()];

        me._labelLatValue.setText(sprintf("%.03f", row.lat));
        me._labelLonValue.setText(sprintf("%.03f", row.lon));
        me._labelTimestampValue.setText(Utils.decimalHoursToHuman(row.timestamp));
        me._labelAltValue.setText(sprintf("%.0f ft", row.alt_m * globals.M2FT));
        me._labelDistanceValue.setText(sprintf("%.02f NM", row.distance));
    },

    #
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func() {
        # Lateral Profile

        me._mapView = canvas.gui.widgets.MapView.new(me._scrollLProfileContent, canvas.style, {});
        me._mapView.setSize(FlightPreviewDialog.WINDOW_WIDTH, 600);
        me._mapView.setTrackItems(me._trackItems);


        # Vertical Profile

        me._profileView = canvas.gui.widgets.ProfileView.new(me._scrollVProfileContent, canvas.style, {});
        me._profileView.setSize(FlightPreviewDialog.WINDOW_WIDTH, FlightPreviewDialog.V_PROFILE_HEIGHT);
        me._profileView.setData(
            me._trackItems,
            me._storage.getLogbookTrackerMaxAlt(me._logbookId)
        );

        me._updateLabels();
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

        me._updateLabels();
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
