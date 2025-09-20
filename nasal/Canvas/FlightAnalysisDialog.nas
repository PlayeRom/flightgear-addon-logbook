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
    FRACTION        : { labels: 2, map: 11 },
    #
    # Aircraft icon:
    #
    FAST_POS_CHANGE : 10,

    #
    # Constructor
    #
    # @param  string  title
    # @param  bool  liveUpdateMode
    # @return hash
    #
    new: func(title, liveUpdateMode = false) {
        var me = {
            parents: [
                FlightAnalysisDialog,
                Dialog.new(
                    width : FlightAnalysisDialog.WINDOW_WIDTH,
                    height: FlightAnalysisDialog.WINDOW_HEIGHT,
                    title : title,
                    resize: true,
                ),
            ],
            _liveUpdateMode : liveUpdateMode,
            _isFG2024Version: Utils.isFG2024Version(),
        };

        me.bgImage.hide();

        me.setPositionOnCenter();

        # Override window del method (X button on bar) for stop _playTimer
        var self = me;
        me._window.del = func() {
            call(FlightAnalysisDialog.hide, [], self);
        };

        me._playTimer = Timer.make(0.2, me, me._onPlayUpdate);
        me._playSpeed = 16;

        me._infoView = canvas.gui.widgets.InfoView.new(me._group, canvas.style, {});

        me._mapView = canvas.gui.widgets.MapView.new(me._group, canvas.style, {});
        me._mapView.setUpdatePositionCallback(me._mapViewUpdatePosition, me);
        me._mapView.setUpdateZoomCallback(me._mapViewUpdateZoom, me);
        me._mapView.setLiveUpdateMode(liveUpdateMode);

        me._profileView = canvas.gui.widgets.ProfileView.new(me._group, canvas.style, {});
        me._profileView.setUpdatePositionCallback(me._profileViewUpdatePosition, me);
        me._profileView.setUpdateZoomCallback(me._profileViewUpdateZoom, me);
        me._profileView.setLiveUpdateMode(liveUpdateMode);

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

        call(Dialog.del, [], me);
    },

    #
    # Show this canvas dialog
    #
    # @return void
    #
    show: func() {
        g_Sound.play('paper');

        me.setMapProvider(g_Settings.getMapProvider());
        me._mapView.softUpdateView(forceSetTile: true); # to change map provider

        me._updateAfterChangePosition();
        me._updateAfterZoom();
        me._btnPlay.setText("Play");

        call(Dialog.show, [], me);
    },

    #
    # Hide this canvas dialog
    #
    # @return void
    #
    hide: func() {
        me._playTimer.stop();

        call(Dialog.hide, [], me);
    },

    #
    # Set map provider by name
    #
    # @param  string  name  Map provider name: "OpenStreetMap" or "OpenTopoMap"
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
    # Set track data
    #
    # @param  vector  trackItems  Vector of hashes with all path points
    # @param  double  maxAlt  Max altitude of aircraft or terrain elevation
    # @param  bool  withResetPosition  If true then aircraft position will be set to 0
    # @return void
    #
    setData: func(trackItems, maxAlt, withResetPosition = 1) {
        # Put data to widgets
        me._mapView.setTrackItems(trackItems, withResetPosition);
        me._profileView.setTrackItems(trackItems, maxAlt, withResetPosition);
    },

    #
    # Add one hash point
    #
    # @param  hash  trackItem  Hash of one path point
    # @param  double  maxAlt  Max altitude of aircraft or terrain elevation
    # @return void
    #
    appendData: func(trackItem, maxAlt) {
        # Put data to widgets
        me._mapView.appendTrackItem(trackItem);
        me._profileView.appendTrackItem(trackItem, maxAlt);
    },

    #
    # Redraw hole widgets from strach
    #
    # @return void
    #
    hardUpdateView: func() {
        me._mapView.hardUpdateView();
        me._profileView.hardUpdateView();

        me._updateAfterChangePosition();
    },

    #
    # Soft redraw widgets, however profile must be always hard redraw
    #
    # @return void
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

        hBoxLayout.addSpacing(FlightAnalysisDialog.PADDING);
        hBoxLayout.addItem(me._infoView, FlightAnalysisDialog.FRACTION.labels); # 2nd param = stretch
        hBoxLayout.addItem(me._mapView, FlightAnalysisDialog.FRACTION.map); # 2nd param = stretch

        me._vbox.addItem(hBoxLayout, 2); # 2nd param = stretch

        var hBoxProfile = canvas.HBoxLayout.new();
        hBoxProfile.addSpacing(FlightAnalysisDialog.PADDING);
        hBoxProfile.addItem(me._profileView);
        hBoxProfile.addSpacing(FlightAnalysisDialog.PADDING);

        me._vbox.addSpacing(FlightAnalysisDialog.PADDING);
        me._vbox.addItem(hBoxProfile, 1); # 2nd param = stretch

        me._updateLabelValues();

        me._drawBottomBar();
    },

    #
    # Update values for all info labels
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
    # Zoom in the profile view
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
    # Zoom out the profile view
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
    # Update label and buttons according to current zoom level
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

        me._btnZoomMinus.setEnabled(zoom > canvas.gui.widgets.ProfileView.ZOOM_MIN);
        me._btnZoomPlus.setEnabled(zoom < me._profileView.getMaxZoomLevel());
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
        # nothing here
    },

    #
    # Callback function called from ProfileView when user change zoom by scroll
    #
    # @return void
    #
    _profileViewUpdateZoom: func() {
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

        me._labelZoom    = canvas.gui.widgets.Label.new(me._group, canvas.style, {})
            .setText("Zoom " ~ me._mapView.getZoomLevel());

        me._btnZoomMinus   = me._createButtonNarrow("-",   func { me._zoomOut(); });
        me._btnZoomPlus    = me._createButtonNarrow("+",   func { me._zoomIn(); });

        me._labelFrame     = canvas.gui.widgets.Label.new(me._group, canvas.style, {})
            .setText(sprintf("Frame %d/%d", 1, me._mapView.getTrackItemsSize()));

        me._btnStart       = me._createButtonNarrow("|<<", func { me._goStartTrack(); });
        me._btnBackFast    = me._createButtonNarrow("<<",  func { me._goPrevTrack(FlightAnalysisDialog.FAST_POS_CHANGE); });
        me._btnBack        = me._createButtonNarrow("<",   func { me._goPrevTrack(); });
        me._btnForward     = me._createButtonNarrow(">",   func { me._goNextTrack(); });
        me._btnForwardFast = me._createButtonNarrow(">>",  func { me._goNextTrack(FlightAnalysisDialog.FAST_POS_CHANGE); });
        me._btnEnd         = me._createButtonNarrow(">>|", func { me.goEndTrack(); });

        me._btnPlay        = me._createButtonWide("Play",  func { me._togglePlay(); });

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

        me._vbox.addSpacing(FlightAnalysisDialog.PADDING);
        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(FlightAnalysisDialog.PADDING);

        me._updateAfterChangePosition();

        return buttonBox;
    },

    #
    # Draw animation speed selection control
    #
    # @return ghost  Canvas object depend of FG version
    #
    _drawSpeedSelector: func() {
        if (me._isFG2024Version) {
            var buttonBox = canvas.HBoxLayout.new();

            var label = canvas.gui.widgets.Label.new(me._group, canvas.style, {})
                .setText("Speed");

            var comboBox = canvas.gui.widgets.ComboBox.new(me._group, {})
                .setFixedSize(70, 26);
            if (view.hasmember(comboBox, "createItem")) {
                # For next addMenuItem is deprecated
                comboBox.createItem( "1x",  1);
                comboBox.createItem( "2x",  2);
                comboBox.createItem( "4x",  4);
                comboBox.createItem( "8x",  8);
                comboBox.createItem("16x", 16);
                comboBox.createItem("32x", 32);
            }
            else { # for 2024.1
                comboBox.addMenuItem( "1x",  1);
                comboBox.addMenuItem( "2x",  2);
                comboBox.addMenuItem( "4x",  4);
                comboBox.addMenuItem( "8x",  8);
                comboBox.addMenuItem("16x", 16);
                comboBox.addMenuItem("32x", 32);
            }
            comboBox.setSelectedByValue(me._playSpeed);
            comboBox.listen("selected-item-changed", func(e) {
                me._playSpeed = e.detail.value;
            });

            buttonBox.addItem(label);
            buttonBox.addItem(comboBox);

            return buttonBox;
        }

        # Canvas in the FG 2020 version does not have a combobox, so we only have information about the speed
        return canvas.gui.widgets.Label.new(me._group, canvas.style, {})
            .setText("Speed " ~ me._playSpeed ~ "x");
    },

    #
    # Draw a profile mode selection control
    #
    # @return ghost  Canvas object depend of FG version
    #
    _drawProfileModeSelector: func() {
        if (me._isFG2024Version) {
            var buttonBox = canvas.HBoxLayout.new();

            var label = canvas.gui.widgets.Label.new(me._group, canvas.style, {})
                .setText("Profile mode");

            var comboBox = canvas.gui.widgets.ComboBox.new(me._group, {})
                .setFixedSize(100, 26);
            if (view.hasmember(comboBox, "createItem")) {
                # For next addMenuItem is deprecated
                comboBox.createItem("distance", canvas.gui.widgets.ProfileView.DRAW_MODE_DISTANCE);
                comboBox.createItem("time",     canvas.gui.widgets.ProfileView.DRAW_MODE_TIMESTAMP);
            }
            else { # for 2024.1
                comboBox.addMenuItem("distance", canvas.gui.widgets.ProfileView.DRAW_MODE_DISTANCE);
                comboBox.addMenuItem("time",     canvas.gui.widgets.ProfileView.DRAW_MODE_TIMESTAMP);
            }
            comboBox.setSelectedByValue(canvas.gui.widgets.ProfileView.DRAW_MODE_DISTANCE);
            comboBox.listen("selected-item-changed", func(e) {
                me._profileView.setDrawMode(e.detail.value);
            });

            buttonBox.addItem(label);
            buttonBox.addItem(comboBox);

            return buttonBox;
        }

        var checkbox = canvas.gui.widgets.CheckBox.new(me._group, canvas.style, { wordWrap: false })
            .setText("Profile mode as time")
            .setChecked(false)
            .setEnabled(true);

        checkbox.listen("toggled", func(e) {
            var mode = e.detail.checked
                ? canvas.gui.widgets.ProfileView.DRAW_MODE_TIMESTAMP
                : canvas.gui.widgets.ProfileView.DRAW_MODE_DISTANCE;
            me._profileView.setDrawMode(mode);
        });

        return checkbox;
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
        return canvas.gui.widgets.Button.new(me._group, canvas.style, {})
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
            me._btnPlay.setText("Play");
        }
        else {
            me._restartPlayInterval(me._mapView.getTrackPosition());
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
    # Calculate animation speed
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
