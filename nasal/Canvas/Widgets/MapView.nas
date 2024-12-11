#
# MapView widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# MapView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# MapView widget Model
#
gui.widgets.MapView = {
    #
    # Constants
    #
    ZOOM_MIN    : 3,
    ZOOM_MAX    : 14,
    ZOOM_DEFAULT: 10,

    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.MapView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "map-view", me._cfg));

        # Variables for map
        me._mapsBase = getprop("/sim/fg-home") ~ '/cache/maps';
        me._makeUrl  = nil;
        me._makePath = nil;

        # The background color of the map, where the alpha channel makes the map more faded
        me._colorFill = [1.0, 1.0, 1.0, 1.0];

        me.setOpenStreetMap();

        # Vector of hashes with flight data
        me._trackItems = [];
        me._trackItemsSize = 0;

        me._zoom = gui.widgets.MapView.ZOOM_DEFAULT;

        # Current index of me._trackItems
        me._position = 0;

        # Callback function called when this widget changes the aircraft's position
        me._callbackPos     = nil;
        me._objCallbackPos  = nil;

        # Callback function called when this widget changes the map zoom
        me._callbackZoom    = nil;
        me._objCallbackZoom = nil;

        # A mode where new track points are added live.
        # In this mode, drawing the flight path is less optimal.
        me._isLiveUpdateMode = 0;

        return me;
    },

    #
    # Use OpenStreetMap tiles
    #
    # @return void
    #
    setOpenStreetMap: func() {
        me._makeUrl  = string.compileTemplate('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
        me._makePath = string.compileTemplate(me._mapsBase ~ '/osm-cache/{z}/{x}/{y}.png');
        me._colorFill = [1.0, 1.0, 1.0, 0.7];
    },

    #
    # Use OpenTopoMap tiles
    # https://opentopomap.org/about
    #
    # @return void
    #
    setOpenTopoMap: func() {
        me._makeUrl  = string.compileTemplate('https://tile.opentopomap.org/{z}/{x}/{y}.png');
        me._makePath = string.compileTemplate(me._mapsBase ~ '/opentopomap-cache/{z}/{x}/{y}.png');
        me._colorFill = [1.0, 1.0, 1.0, 0.5];
    },

    #
    # Set track items
    #
    # @param  vector  trackItems  Vector of hashes with flight data:
    #     [
    #          {
    #               lat         : double,
    #               lon         : double,
    #               heading_true: double,
    #          },
    #          ... etc.
    #     ]
    # @param  bool  withResetPosition
    # @return me
    #
    setTrackItems: func(trackItems, withResetPosition = 1) {
        if (withResetPosition) {
            me._zoom = gui.widgets.MapView.ZOOM_DEFAULT;
            me._position = 0;
        }

        me._trackItems     = trackItems;
        me._trackItemsSize = size(me._trackItems);

        return me;
    },

    #
    # Append one track item
    #
    # @param  hash  trackItem  Hash with flight data:
    #     {
    #          lat         : double,
    #          lon         : double,
    #          heading_true: double,
    #     },
    # @return me
    #
    appendTrackItem: func(trackItem) {
        append(me._trackItems, trackItem);
        me._trackItemsSize = size(me._trackItems);

        return me;
    },

    #
    # Soft redraw tiles and path
    #
    # @param  bool  forceSetTile
    # @return void
    #
    softUpdateView: func(forceSetTile = 0) {
        me._view.updateTiles(me, forceSetTile);
    },

    #
    # Hard redraw whole widget
    #
    # @return void
    #
    hardUpdateView: func() {
        me._view.reDrawContent(me);
    },

    #
    # Set to true if the flight path should be updated live
    #
    # @param  bool  value
    # @return void
    #
    setLiveUpdateMode: func(value) {
        me._isLiveUpdateMode = value;
    },

    #
    # Get last index of me._trackItems vector
    #
    # @return int
    #
    getTrackLastIndex: func() {
        return me._trackItemsSize - 1;
    },

    #
    # @return int
    #
    getTrackItemsSize: func() {
        return me._trackItemsSize;
    },

    #
    # Get track item from current position
    #
    # @return hash
    #
    getCurrentTrackItem: func() {
        return me.getTrackItemByPosition(me._position);
    },

    #
    # Get track item from given position
    #
    # @return hash
    #
    getTrackItemByPosition: func(position) {
        return me._trackItems[position];
    },

    #
    # Zoom in the map and redrew it
    #
    # @return me
    #
    zoomIn: func() {
        me._changeZoom(direction: 1);

        me._view.updateTiles(me);

        return me;
    },

    #
    # Zoom out the map and redrew it
    #
    # @return me
    #
    zoomOut: func() {
        me._changeZoom(direction: -1);

        me._view.updateTiles(me);

        return me;
    },

    #
    # Sev value of zoom level within certain limits
    #
    # @param  int  direction  If 0 then without changing, -1 for zoom out or +1 for zoom in
    # @return int  Current zoom level
    #
    _changeZoom: func(direction) {
        var min = math.min(gui.widgets.MapView.ZOOM_MAX, me._zoom + direction);
        me._zoom = math.max(gui.widgets.MapView.ZOOM_MIN, min);

        return me._zoom;
    },

    #
    # Move aircraft position to the first point and redraw the map
    #
    # @return me
    #
    goStartTrack: func() {
        me._position = 0;

        me._view.updateTiles(me);

        return me;
    },

    #
    # Move aircraft position to the last point and redraw the map
    #
    # @return me
    #
    goEndTrack: func() {
        me._position = me.getTrackLastIndex();

        me._view.updateTiles(me);

        return me;
    },

    #
    # Move the aircraft position forward by the specified interval and redraw the map
    #
    # @param  int  interval
    # @return me
    #
    goNextTrack: func(interval = 1) {
        me._position += interval;

        me._protectMaxPosition();

        me._view.updateTiles(me);

        return me;
    },

    #
    # Move the aircraft position backward by the specified interval and redraw the map
    #
    # @param  int  interval
    # @return me
    #
    goPrevTrack: func(interval = 1) {
        me._position -= interval;

        me._protectMinPosition();

        me._view.updateTiles(me);

        return me;
    },

    #
    # Set new position of track
    #
    # @param  int  position
    # @return me
    #
    setTrackPosition: func(position) {
        me._position = position;

        me._protectMinPosition();
        me._protectMaxPosition();

        me._view.updateTiles(me);

        return me;
    },

    #
    # Get current index position
    #
    # @return int  Index position of me_tractItems vector
    #
    getTrackPosition: func() {
        return me._position;
    },

    #
    # Prevents exceeding the minimum value of the position
    #
    # @return void
    #
    _protectMinPosition: func() {
        if (me._position < 0) {
            me._position = 0;
        }
    },

    #
    # Prevents exceeding the maximum value of the position
    #
    # @return void
    #
    _protectMaxPosition: func() {
        var lastRowsIndex = me.getTrackLastIndex();
        if (me._position > lastRowsIndex) {
            me._position = lastRowsIndex;
        }
    },

    #
    # Get current zool level
    #
    # @return int  Map zoom level
    #
    getZoomLevel: func() {
        return me._zoom;
    },

    #
    # Set callback function for position update
    #
    # @param  func|nil  callback  Callback function, if nil then callback will be disabled
    # @param  hash|nil  objCallback  Class as owner of callback function if nil then reference for callback will not be used
    # @return me
    #
    setUpdatePositionCallback: func(callback, objCallback = nil) {
        me._callbackPos = callback;
        me._objCallbackPos = objCallback;

        return me;
    },

    #
    # Call the callback that the widget itself updated the aircraft's position
    #
    # @return void
    #
    _updatePosition: func() {
        if (me._callbackPos != nil) {
            call(me._callbackPos, [me._position], me._objCallbackPos);
        }
    },

    #
    # Set callback function for zoom update
    #
    # @param  func|nil  callback  Callback function, if nil then callback will be disabled
    # @param  hash|nil  objCallback  Class as owner of callback function, if nil then reference for callback will not be used
    # @return me
    #
    setUpdateZoomCallback: func(callback, objCallback = nil) {
        me._callbackZoom = callback;
        me._objCallbackZoom = objCallback;

        return me;
    },

    #
    # Call the callback that the widget itself updated the zoom of map
    #
    # @return void
    #
    _updateZoom: func() {
        if (me._callbackZoom != nil) {
            call(me._callbackZoom, [], me._objCallbackZoom);
        }
    },
};
