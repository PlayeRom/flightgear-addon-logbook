#
# ProfileView widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# ProfileView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# ProfileView widget Model
#
gui.widgets.ProfileView = {
    #
    # Constants
    #
    DRAW_MODE_TIMESTAMP : 'timestamp',
    DRAW_MODE_DISTANCE  : 'distance',

    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.ProfileView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "profile-view", me._cfg));

        # Vector of hashes with flight data
        me._trackItems = [];
        me._trackItemsSize = 0;

        # Maximum flight altitude or elevation from all me._trackItems provided
        me._maxAlt = 0;

        # Current index of me._trackItems (current aircraft position)
        me._position = 0;

        # Callback function called when this widget changes the aircraft's position
        me._callback = nil;
        me._objCallback = nil; # object as owner of callback function

        # Defines whether the X-axis should be drawn based on time or distance traveled.
        # When based on time, the graph will be evenly and linearly distributed, even when the aircraft is stationary
        # or hovering because time is always moving forward. So the graph won't show where the flight was faster or
        # slower, but you will avoid overlapping points.
        # When based on distance, the points will be drawn close to each other or overlapping when the aircraft is
        # stationary or flying slowly, but they will be more spread out when flying fast, making it possible to
        # recognize places where the flight was performed at higher speeds and where at lower ones.
        me._drawMode = gui.widgets.ProfileView.DRAW_MODE_DISTANCE;

        return me;
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
    # @return me
    #
    setTrackItems: func(trackItems, maxAlt = nil, withResetPosition = 1) {
        if (withResetPosition) {
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

        me._trackItems     = trackItems;
        me._trackItemsSize = size(me._trackItems);

        me._maxAlt = maxAlt;

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
    # @return me
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
    # @return me
    #
    goStartTrack: func() {
        me._position = 0;

        me._view.updateAircraftPosition(me);

        return me;
    },

    #
    # Move aircraft position to the last point and redraw aircraft position
    #
    # @return me
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
    # @return me
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
    # @return me
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
    # @return me
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
    # @return me
    #
    setUpdateCallback: func(callback, objCallback) {
        me._callback = callback;
        me._objCallback = objCallback;

        return me;
    },

    #
    # Call the callback that the widget itself updated the aircraft's position
    #
    # @return void
    #
    _updatePosition: func() {
        if (me._callback != nil) {
            call(me._callback, [me._position], me._objCallback);
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
        return me._drawMode == gui.widgets.ProfileView.DRAW_MODE_TIMESTAMP;
    },

    #
    # @return bool  Return true if draw mode is "distance"
    #
    isDrawModeDistance: func() {
        return me._drawMode == gui.widgets.ProfileView.DRAW_MODE_DISTANCE;
    },
};
