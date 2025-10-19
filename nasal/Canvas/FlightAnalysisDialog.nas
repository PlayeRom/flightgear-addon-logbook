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
# FlightAnalysisDialog class.
#
var FlightAnalysisDialog = {
    CLASS: "FlightAnalysisDialog",

    #
    # Constants:
    #
    PADDING : 10,
    FRACTION: { labels: 2, map: 11 },
    #
    # Aircraft icon:
    #
    FAST_POS_CHANGE : 10,

    #
    # Constructor.
    #
    # @param  string  title
    # @param  bool  liveUpdateMode
    # @return hash
    #
    new: func(title, liveUpdateMode = false) {
        var obj = {
            parents: [
                FlightAnalysisDialog,
                PersistentDialog.new(
                    width : 1360,
                    height: 720,
                    title : title,
                    resize: true,
                ),
            ],
            _liveUpdateMode : liveUpdateMode,
            _isFG2024Version: Utils.isFG2024Version(),
        };

        call(PersistentDialog.setChild, [obj, FlightAnalysisDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._widget = WidgetHelper.new(obj._group);

        obj._playTimer = Timer.make(0.2, obj, obj._onPlayUpdate);
        obj._playSpeed = 16;

        obj._infoView = canvas.gui.widgets.FlightInfo.new(obj._group);

        obj._mapView = canvas.gui.widgets.FlightMap.new(obj._group);
        obj._mapView.setUpdatePositionCallback(obj._mapViewUpdatePosition, obj);
        obj._mapView.setUpdateZoomCallback(obj._mapViewUpdateZoom, obj);
        obj._mapView.setLiveUpdateMode(liveUpdateMode);

        obj._profileView = canvas.gui.widgets.FlightProfile.new(obj._group);
        obj._profileView.setUpdatePositionCallback(obj._profileViewUpdatePosition, obj);
        obj._profileView.setUpdateZoomCallback(obj._profileViewUpdateZoom, obj);
        obj._profileView.setLiveUpdateMode(liveUpdateMode);

        obj._drawContent();

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._playTimer.stop();

        call(PersistentDialog.del, [], me);
    },

    #
    # Show this canvas dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    show: func() {
        g_Sound.play('paper');

        me.setMapProvider(g_Settings.getMapProvider());
        me._mapView.softUpdateView(forceSetTile: true); # to change map provider

        me._updateAfterChangePosition();
        me._updateAfterZoom();
        me._btnPlay.setText("Play");

        call(PersistentDialog.show, [], me);
    },

    #
    # Hide this canvas dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    hide: func() {
        me._playTimer.stop();

        call(PersistentDialog.hide, [], me);
    },

    #
    # Set map provider by name.
    #
    # @param  string  name  Map provider name: "OpenStreetMap" or "OpenTopoMap".
    # @return void
    #
    setMapProvider: func(name) {
        if (name == Settings.MAP_PROVIDER_TOPO) {
            me._mapView.setOpenTopoMap();
        }
        else { # OpenStreetMap as default
            me._mapView.setOpenStreetMap();
        }
    },

    #
    # Set track data.
    #
    # @param  vector  trackItems  Vector of hashes with all path points.
    # @param  double  maxAlt  Max altitude of aircraft or terrain elevation.
    # @param  bool  withResetPosition  If true then aircraft position will be set to 0.
    # @return void
    #
    setData: func(trackItems, maxAlt, withResetPosition = 1) {
        # Put data to widgets
        me._mapView.setTrackItems(trackItems, withResetPosition);
        me._profileView.setTrackItems(trackItems, maxAlt, withResetPosition);
    },

    #
    # Add one hash point.
    #
    # @param  hash  trackItem  Hash of one path point.
    # @param  double  maxAlt  Max altitude of aircraft or terrain elevation.
    # @return void
    #
    appendData: func(trackItem, maxAlt) {
        # Put data to widgets
        me._mapView.appendTrackItem(trackItem);
        me._profileView.appendTrackItem(trackItem, maxAlt);
    },

    #
    # Redraw hole widgets from strach.
    #
    # @return void
    #
    hardUpdateView: func() {
        me._mapView.hardUpdateView();
        me._profileView.hardUpdateView();

        me._updateAfterChangePosition();
    },

    #
    # Soft redraw widgets, however profile must be always hard redraw.
    #
    # @return void
    #
    softUpdateView: func() {
        me._mapView.softUpdateView();
        me._profileView.hardUpdateView();

        me._updateAfterChangePosition();
    },

    #
    # Draw whole dialog content.
    #
    # @return void
    #
    _drawContent: func() {
        var hBoxLayout = canvas.HBoxLayout.new();

        hBoxLayout.addSpacing(me.PADDING);
        hBoxLayout.addItem(me._infoView, me.FRACTION.labels); # 2nd param = stretch
        hBoxLayout.addItem(me._mapView, me.FRACTION.map); # 2nd param = stretch

        me._vbox.addItem(hBoxLayout, 2); # 2nd param = stretch

        var hBoxProfile = canvas.HBoxLayout.new();
        hBoxProfile.addSpacing(me.PADDING);
        hBoxProfile.addItem(me._profileView);
        hBoxProfile.addSpacing(me.PADDING);

        me._vbox.addSpacing(me.PADDING);
        me._vbox.addItem(hBoxProfile, 1); # 2nd param = stretch

        me._updateLabelValues();

        me._drawBottomBar();
    },

    #
    # Update values for all info labels.
    #
    # @return void
    #
    _updateLabelValues: func() {
        if (me._mapView.getTrackItemsSize() <= 0) {
            return;
        }

        var item = me._mapView.getCurrentTrackItem();

        me._infoView
            .setLatLon(item.lat, item.lon)
            .setAltitudes(msl: item.alt_m * globals.M2FT, agl: (item.alt_m - item.elevation_m) * globals.M2FT)
            .setHeadings(item.heading_true, item.heading_mag)
            .setSpeeds(item.airspeed, item.groundspeed)
            .setWind(item.wind_heading, item.wind_speed)
            .setTimestamp(Utils.decimalHoursToHuman(item.timestamp))
            .setDistance(item.distance);
    },

    #
    # Zoom in the profile view.
    #
    # @return void
    #
    _zoomIn: func() {
        if (me._liveUpdateMode) {
            return;
        }

        me._profileView.zoomIn();
        me._updateAfterZoom();
    },

    #
    # Zoom out the profile view.
    #
    # @return void
    #
    _zoomOut: func() {
        if (me._liveUpdateMode) {
            return;
        }

        me._profileView.zoomOut();
        me._updateAfterZoom();
    },

    #
    # Update label and buttons according to current zoom level.
    #
    # @return void
    #
    _updateAfterZoom: func() {
        var zoom = me._profileView.getZoomLevel();

        me._labelZoom.setText("Zoom " ~ zoom ~ "x");

        if (me._liveUpdateMode) {
            me._btnZoomMinus.setEnabled(false);
            me._btnZoomPlus.setEnabled(false);
            return;
        }

        me._btnZoomMinus.setEnabled(zoom > canvas.gui.widgets.FlightProfile.ZOOM_MIN);
        me._btnZoomPlus.setEnabled(zoom < me._profileView.getMaxZoomLevel());
    },

    #
    # Move aircraft to first position on the map and profile.
    #
    # @return void
    #
    _goStartTrack: func() {
        me._mapView.goStartTrack();
        me._profileView.goStartTrack();

        me._updateAfterChangePosition();
    },

    #
    # Move aircraft to last position on the map and profile.
    #
    # @return void
    #
    goEndTrack: func() {
        me._mapView.goEndTrack();
        me._profileView.goEndTrack();

        me._updateAfterChangePosition();
    },

    #
    # Move the aircraft position forward by the specified interval.
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
    # Move the aircraft position backward by the specified interval.
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
    # Update buttons according to current aircraft position.
    #
    # @return void
    #
    _updateAfterChangePosition: func() {
        var lastRowsIndex = me._mapView.getTrackLastIndex();
        var position = me._mapView.getTrackPosition();

        me._labelFrame.setText(sprintf("Frame %d/%d", position + 1, me._mapView.getTrackItemsSize()));

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
    # Callback function called from FlightMap when user click on the map.
    #
    # @param  int  position  New aircraft position.
    # @return void
    #
    _mapViewUpdatePosition: func(position) {
        me._profileView.setTrackPosition(position);

        me._updateAfterChangePosition();
    },

    #
    # Callback function called from FlightMap when user change zoom by scroll.
    #
    # @return void
    #
    _mapViewUpdateZoom: func() {
        # nothing here
    },

    #
    # Callback function called from FlightProfile when user change zoom by scroll.
    #
    # @return void
    #
    _profileViewUpdateZoom: func() {
        me._updateAfterZoom();
    },

    #
    # Callback function called from FlightProfile when user click on diagram.
    #
    # @param  int  position  New aircraft position.
    # @return void
    #
    _profileViewUpdatePosition: func(position) {
        me._mapView.setTrackPosition(position);

        me._updateAfterChangePosition();
    },

    #
    # Draw bottom bar with buttons.
    #
    # @return ghost  HBoxLayout object with button.
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        me._labelZoom      = me._widget.getLabel("Zoom " ~ me._mapView.getZoomLevel());

        me._btnZoomMinus   = me._widget.getButton("-",   26, func me._zoomOut());
        me._btnZoomPlus    = me._widget.getButton("+",   26, func me._zoomIn());

        me._labelFrame     = me._widget.getLabel(sprintf("Frame %d/%d", 1, me._mapView.getTrackItemsSize()));

        me._btnStart       = me._widget.getButton("|<<",  26, func me._goStartTrack());
        me._btnBackFast    = me._widget.getButton("<<",   26, func me._goPrevTrack(me.FAST_POS_CHANGE));
        me._btnBack        = me._widget.getButton("<",    26, func me._goPrevTrack());
        me._btnPlay        = me._widget.getButton("Play", 65, func me._togglePlay());
        me._btnForward     = me._widget.getButton(">",    26, func me._goNextTrack());
        me._btnForwardFast = me._widget.getButton(">>",   26, func me._goNextTrack(me.FAST_POS_CHANGE));
        me._btnEnd         = me._widget.getButton(">>|",  26, func me.goEndTrack());


        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnZoomMinus);
        buttonBox.addItem(me._labelZoom);
        buttonBox.addItem(me._btnZoomPlus);
        buttonBox.addStretch(2);
        buttonBox.addItem(me._labelFrame);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnStart);
        buttonBox.addItem(me._btnBackFast);
        buttonBox.addItem(me._btnBack);
        buttonBox.addItem(me._btnPlay);
        buttonBox.addItem(me._btnForward);
        buttonBox.addItem(me._btnForwardFast);
        buttonBox.addItem(me._btnEnd);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._drawSpeedSelector());
        buttonBox.addStretch(2);
        buttonBox.addItem(me._drawProfileModeSelector());
        buttonBox.addStretch(1);

        me._vbox.addSpacing(me.PADDING);
        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(me.PADDING);

        me._updateAfterChangePosition();

        return buttonBox;
    },

    #
    # Draw animation speed selection control.
    #
    # @return ghost  Canvas object depend of FG version.
    #
    _drawSpeedSelector: func() {
        if (me._isFG2024Version) {
            var label = me._widget.getLabel("Speed");

            var items = [
                { label:  "1x", value:  1 },
                { label:  "2x", value:  2 },
                { label:  "4x", value:  4 },
                { label:  "8x", value:  8 },
                { label: "16x", value: 16 },
                { label: "32x", value: 32 },
            ];

            var comboBox = ComboBoxHelper.create(me._group, items, 70, 26);
            comboBox.setSelectedByValue(me._playSpeed);
            comboBox.listen("selected-item-changed", func(e) {
                me._playSpeed = e.detail.value;
            });

            var buttonBox = canvas.HBoxLayout.new();
            buttonBox.addItem(label);
            buttonBox.addItem(comboBox);

            return buttonBox;
        }

        # Canvas in the FG 2020 version does not have a combobox, so we only have information about the speed
        return me._widget.getLabel("Speed " ~ me._playSpeed ~ "x");
    },

    #
    # Draw a profile mode selection control.
    #
    # @return ghost  Canvas object depend of FG version.
    #
    _drawProfileModeSelector: func() {
        if (me._isFG2024Version) {
            var buttonBox = canvas.HBoxLayout.new();

            var label = me._widget.getLabel("Profile mode");

            var items = [
                { label: "distance", value: canvas.gui.widgets.FlightProfile.DRAW_MODE_DISTANCE },
                { label: "time",     value: canvas.gui.widgets.FlightProfile.DRAW_MODE_TIMESTAMP },
            ];

            var comboBox = ComboBoxHelper.create(me._group, items, 100, 26);
            comboBox.setSelectedByValue(canvas.gui.widgets.FlightProfile.DRAW_MODE_DISTANCE);
            comboBox.listen("selected-item-changed", func(e) {
                me._profileView.setDrawMode(e.detail.value);
            });

            buttonBox.addItem(label);
            buttonBox.addItem(comboBox);

            return buttonBox;
        }

        var checkbox = me._widget.getCheckBox("Profile mode as time", false)
            .setEnabled(true);

        checkbox.listen("toggled", func(e) {
            var mode = e.detail.checked
                ? canvas.gui.widgets.FlightProfile.DRAW_MODE_TIMESTAMP
                : canvas.gui.widgets.FlightProfile.DRAW_MODE_DISTANCE;
            me._profileView.setDrawMode(mode);
        });

        return checkbox;
    },

    #
    # Start/stop play animation of fly.
    #
    # @return void
    #
    _togglePlay: func() {
        if (me._playTimer.isRunning) {
            me._playTimer.stop();
            me._btnPlay.setText("Play");
        }
        else {
            me._restartPlayInterval(me._mapView.getTrackPosition());
            me._playTimer.start();
            me._btnPlay.setText("Stop");
        }
    },

    #
    # Play animation update timer callback.
    #
    # @return void
    #
    _onPlayUpdate: func() {
        var position = me._mapView.getTrackPosition();
        if (position < me._mapView.getTrackLastIndex()) {
            me._goNextTrack();

            me._restartPlayInterval(position);
        }
        else {
            me._playTimer.stop();
            me._btnPlay.setText("Play");
        }
    },

    #
    # Calculate animation speed.
    #
    # @param  int  position
    # @return void
    #
    _restartPlayInterval: func(position) {
        if (position < me._mapView.getTrackLastIndex() - 1) {
            var nextPoint    = me._mapView.getTrackItemByPosition(position + 1);
            var currentPoint = me._mapView.getTrackItemByPosition(position);

            # Real speed animation:
            var interval = (nextPoint.timestamp - currentPoint.timestamp) * 3600;
            # Speed up interval:
            interval /= me._playSpeed;

            me._playTimer.restart(interval);
        }
    },
};
