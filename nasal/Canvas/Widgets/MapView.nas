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
    # @param  hash  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.MapView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "map-view", me._cfg));

        # Items from `trackers` table
        me._tractItems = [];

        me._zoom = gui.widgets.MapView.ZOOM_DEFAULT;

        # Current index of me._tractItems
        me._position = 0;

        return me;
    },

    #
    # Set track items
    #
    # @param  vector|nil  rows  Vector of records from `trackers` table
    # @return me
    #
    setTrackItems: func(rows) {
        me._zoom = gui.widgets.MapView.ZOOM_DEFAULT;
        me._position = 0;

        me._tractItems = rows;

        me._view.reDrawContent(me);

        return me;
    },

    #
    # Get last index of me._tractItems vector
    #
    # @return int
    #
    getTrackLastIndex: func() {
        return size(me._tractItems) - 1;
    },

    #
    # Zoom in the map and redrew it
    #
    # @return me
    #
    zoomIn: func() {
        me._changeZoom(1);

        me._view.updateTiles(me);

        return me;
    },

    #
    # Zoom out the map and redrew it
    #
    # @return me
    #
    zoomOut: func() {
        me._changeZoom(-1);

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
    setTrack: func(position) {
        me._position = position;

        me._protectMinPosition();
        me._protectMaxPosition();

        me._view.updateTiles(me);

        return me;
    },

    #
    # Prevents exceeding the minimum value of the position
    #
    _protectMinPosition: func() {
        if (me._position < 0) {
            me._position = 0;
        }
    },

    #
    # Prevents exceeding the maximum value of the position
    #
    _protectMaxPosition: func() {
        var lastRowsIndex = me.getTrackLastIndex();
        if (me._position > lastRowsIndex) {
            me._position = lastRowsIndex;
        }
    },

    #
    # Get current max zool level
    #
    # @return int  Map zoom level
    #
    getZoomLevel: func() {
        return me._zoom;
    },

    #
    # Get current index position
    #
    # @return int  Index position of me_tractItems vector
    #
    getPosition: func() {
        return me._position;
    },

    #
    # @param  func  callback  Callback function
    # @param  hash  objCallback  Class as owner of callback function
    # @return me
    #
    setUpdateCallback: func(callback, objCallback) {
        me._callback = callback;
        me._objCallback = objCallback;

        return me;
    },

    #
    # The widget itself updated the aircraft's position
    #
    # @param  int  position  New position
    # @return void
    #
    _updatePosition: func(position) {
        me._position = position;

        if (me._objCallback != nil and me._callback != nil) {
            call(me._callback, [position], me._objCallback);
        }
    },
};
