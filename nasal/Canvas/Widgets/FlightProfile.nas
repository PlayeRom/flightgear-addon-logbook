#
# FlightProfile widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# FlightProfile widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# FlightProfile widget Model
#
gui.widgets.FlightProfile = {
    #
    # Constants
    #
    DRAW_MODE_TIMESTAMP : 'timestamp',
    DRAW_MODE_DISTANCE  : 'distance',

    # Max zoom cannot be too large, because there may be a lack of points for individual fractions,
    # especially if the user has used the time acceleration during the flight
    ZOOM_MIN    : 1,
    ZOOM_MAX    : 16,
    ZOOM_DEFAULT: 1,

    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash|nil  style
    # @param  hash|nil  cfg
    # @return ghost
    #
    new: func(parent, style = nil, cfg = nil) {
        if (style == nil) {
            style = canvas.style;
        }

        cfg = Config.new(cfg);
        var obj = gui.Widget.new(gui.widgets.FlightProfile, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "flight-profile-view", cfg));

        # Vector of hashes with flight data
        obj._trackItems = [];
        obj._trackItemsSize = 0;

        # Maximum flight altitude or elevation from all obj._trackItems provided
        obj._maxAlt = 0;

        # Current index of obj._trackItems (current aircraft position)
        obj._position = 0;

        # Callback function called when this widget changes the aircraft's position
        obj._callbackPos = nil;
        obj._objCallbackPos = nil; # object as owner of callback function

        # Callback function called when this widget changes the profile zoom
        obj._callbackZoom    = nil;
        obj._objCallbackZoom = nil;

        # Defines whether the X-axis should be drawn based on time or distance traveled.
        # When based on time, the graph will be evenly and linearly distributed, even when the aircraft is stationary
        # or hovering because time is always moving forward. So the graph won't show where the flight was faster or
        # slower, but you will avoid overlapping points.
        # When based on distance, the points will be drawn close to each other or overlapping when the aircraft is
        # stationary or flying slowly, but they will be more spread out when flying fast, making it possible to
        # recognize places where the flight was performed at higher speeds and where at lower ones.
        obj._drawMode = gui.widgets.FlightProfile.DRAW_MODE_DISTANCE;

        # Graph zoom level
        obj._zoom = gui.widgets.FlightProfile.ZOOM_DEFAULT;

        # A mode where new track points are added live.
        # In this mode, the ability to change the zoom level is disabled.
        obj._isLiveUpdateMode = 0;

        return obj;
    },

    #
    # Set track items and max altitude
    #
    # @param  vector  trackItems  Vector of hashes with flight data:
    #     [
    #          {
    #               timestamp   : double,
    #               alt_m       : double,
    #               elevation_m : double,
    #               distance    : double,
    #               pitch       : double,
    #          },
    #          ... etc.
    #     ]
    # @param  double|nil  maxAlt  Maximum flight altitude or elevation.
    #     If not given then it will be obtained from rows (slow performance).
    # @param  bool  withResetPosition
    # @return ghost
    #
    setTrackItems: func(trackItems, maxAlt = nil, withResetPosition = 1) {
        if (withResetPosition) {
            me._zoom = gui.widgets.FlightProfile.ZOOM_DEFAULT;
            me._position = 0;
        }

        if (maxAlt == nil and trackItems != nil) {
            foreach (var item; trackItems) {
                if (maxAlt == nil) {
                    maxAlt = math.max(item.alt_m, item.elevation_m);
                    continue;
                }

                if (item.alt_m > maxAlt) {
                    maxAlt = item.alt_m;
                }

                if (item.elevation_m > maxAlt) {
                    maxAlt = item.elevation_m;
                }
            }
        }

        me._trackItems     = trackItems[:]; # copy vector instead of reference
        me._trackItemsSize = size(me._trackItems);

        me._maxAlt = maxAlt;

        # Rebuild structure of zoom fractions
        me._view.setZoomFractionToRecreate();

        return me;
    },

    #
    # Append one track item and max altitude
    #
    # @param  hash  trackItem  Hash with flight data:
    #     {
    #          timestamp   : double,
    #          alt_m       : double,
    #          elevation_m : double,
    #          distance    : double,
    #          pitch       : double,
    #     },
    # @param  double|nil  maxAlt  Optional maximum flight altitude or altitude from all data provided.
    # @return ghost
    #
    appendTrackItem: func(trackItem, maxAlt = nil) {
        append(me._trackItems, trackItem);
        me._trackItemsSize = size(me._trackItems);

        if (maxAlt == nil) {
            if (me._maxAlt < trackItem.alt_m) {
                me._maxAlt = trackItem.alt_m;
            }

            if (me._maxAlt < trackItem.elevation_m) {
                me._maxAlt = trackItem.elevation_m;
            }
        }
        else {
            me._maxAlt = maxAlt;
        }

        # Rebuild structure of zoom fractions
        me._view.setZoomFractionToRecreate();

        return me;
    },

    #
    # Hard redraw needed when graph has been changed
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
    # Move aircraft position to the first point and redraw aircraft position
    #
    # @return ghost
    #
    goStartTrack: func() {
        me._position = 0;

        me._view.updateAircraftPosition(me);

        return me;
    },

    #
    # Move aircraft position to the last point and redraw aircraft position
    #
    # @return ghost
    #
    goEndTrack: func() {
        me._position = me.getTrackLastIndex();

        me._view.updateAircraftPosition(me);

        return me;
    },

    #
    # Move the aircraft position forward by the specified interval and redraw aircraft position
    #
    # @param  int  interval
    # @return ghost
    #
    goNextTrack: func(interval = 1) {
        me._position += interval;

        me._protectMaxPosition();

        me._view.updateAircraftPosition(me);

        return me;
    },

    #
    # Move the aircraft position backward by the specified interval and redraw aircraft position
    #
    # @param  int  interval
    # @return ghost
    #
    goPrevTrack: func(interval = 1) {
        me._position -= interval;

        me._protectMinPosition();

        me._view.updateAircraftPosition(me);

        return me;
    },

    #
    # Set new position of track
    #
    # @param  int  position
    # @return ghost
    #
    setTrackPosition: func(position) {
        me._position = position;

        me._protectMinPosition();
        me._protectMaxPosition();

        me._view.updateAircraftPosition(me);

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
    # @param  func|nil  callback  Callback function, if nil then callback will be disabled
    # @param  hash|nil  objCallback  Class as owner of callback function,
    #     if nil then reference for callback will not be used
    # @return ghost
    #
    setUpdatePositionCallback: func(callback, objCallback) {
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
    # @param  string  mode  As DRAW_MODE_TIMESTAMP or DRAW_MODE_DISTANCE
    # @return void
    #
    setDrawMode: func(mode) {
        me._drawMode = mode;

        me._view.reDrawContent(me);
    },

    #
    # @return bool  Return true if draw mode is "time"
    #
    isDrawModeTime: func() {
        return me._drawMode == gui.widgets.FlightProfile.DRAW_MODE_TIMESTAMP;
    },

    #
    # @return bool  Return true if draw mode is "distance"
    #
    isDrawModeDistance: func() {
        return me._drawMode == gui.widgets.FlightProfile.DRAW_MODE_DISTANCE;
    },

    #
    # Zoom in the profile view and redrew it
    #
    # @return ghost
    #
    zoomIn: func() {
        if (me._changeZoom(direction: 1)) {
            me._view.reDrawContent(me);
        }

        return me;
    },

    #
    # Zoom out the profile view and redrew it
    #
    # @return ghost
    #
    zoomOut: func() {
        if (me._changeZoom(direction: -1)) {
            me._view.reDrawContent(me);
        }

        return me;
    },

    #
    # Set value of zoom level within certain limits
    #
    # @param  int  direction  If 0 then without changing, -1 for zoom out or +1 for zoom in
    # @return bool  Return true if zoom has been changed
    #
    _changeZoom: func(direction) {
        if (direction == 1 and me._zoom < me.getMaxZoomLevel()) {
            me._zoom *= 2;
            return true;
        }

        if (direction == -1 and me._zoom > gui.widgets.FlightProfile.ZOOM_MIN) {
            me._zoom /= 2;
            return true;
        }

        return false;
    },

    #
    # Get current zool level
    #
    # @return int  Profile zoom level
    #
    getZoomLevel: func() {
        return me._zoom;
    },

    #
    # Get max zool level
    #
    # @return int  Max zoom level
    #
    getMaxZoomLevel: func() {
        return me._view.getMaxZoomLevel();
    },

     #
    # Set callback function for zoom update
    #
    # @param  func|nil  callback  Callback function, if nil then callback will be disabled
    # @param  hash|nil  objCallback  Class as owner of callback function, if nil then reference for callback will not be used
    # @return ghost
    #
    setUpdateZoomCallback: func(callback, objCallback = nil) {
        me._callbackZoom = callback;
        me._objCallbackZoom = objCallback;

        return me;
    },

    #
    # Call the callback that the widget itself updated the zoom of profile
    #
    # @return void
    #
    _updateZoom: func() {
        if (me._callbackZoom != nil) {
            call(me._callbackZoom, [], me._objCallbackZoom);
        }
    },
};
