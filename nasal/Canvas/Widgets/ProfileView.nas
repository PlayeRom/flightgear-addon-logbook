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
# ProfileView widget Model
#
gui.widgets.ProfileView = {
    #
    # Constructor
    #
    # @param  hash  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.ProfileView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "profile-view", me._cfg));

        # Items from `trackers` table
        me._tractItems = [];

        # Maximum flight altitude or elevation
        me._maxAlt = 0;

        # Current index of me._tractItems
        me._position = 0;

        return me;
    },

    #
    # Set track items and max alt
    #
    # @param  vector|nil  rows  Vector of records from `trackers` table
    # @param  double maxAlt  Maximum flight altitude or elevation
    # @return me
    #
    setData: func(rows, maxAlt) {
        me._position = 0;

        me._tractItems = rows;
        me._maxAlt = maxAlt;

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

        var lastRowsIndex = me.getTrackLastIndex();
        if (me._position > lastRowsIndex) {
            me._position = lastRowsIndex;
        }

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

        if (me._position < 0) {
            me._position = 0;
        }

        me._view.updateAircraftPosition(me);

        return me;
    },

    #
    # Get current index position
    #
    # @return int  Index position of me_tractItems vector
    #
    getPosition: func() {
        return me._position;
    },
};
