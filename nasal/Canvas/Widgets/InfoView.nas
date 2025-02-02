#
# InfoView widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# InfoView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# InfoView widget Model
#
gui.widgets.InfoView = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.InfoView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "info-view", me._cfg));

        return me;
    },

    #
    # @param  double  lat
    # @param  double  lon
    # @return me
    #
    setLatLon: func(lat, lon) {
        me._view.setLatLon(lat, lon);
        return me;
    },

    #
    # @param  double  msl  In feet
    # @param  double  agl  In feet
    # @return me
    #
    setAltitudes: func(msl, agl) {
        me._view.setAltitudes(msl, agl);
        return me;
    },

    #
    # @param  double  hdgTrue
    # @param  double  hdgMag
    # @return me
    #
    setHeadings: func(hdgTrue, hdgMag) {
        me._view.setHeadings(hdgTrue, hdgMag);
        return me;
    },

    #
    # @param  double  airspeed  In knots
    # @param  double  groundspeed  In knots
    # @return me
    #
    setSpeeds: func(airspeed, groundspeed) {
        me._view.setSpeeds(airspeed, groundspeed);
        return me;
    },

    #
    # @param  double  heading
    # @param  double  speed  In knots
    # @return me
    #
    setWind: func(heading, speed) {
        me._view.setWind(heading, speed);
        return me;
    },

    #
    # @param  string  timestamp
    # @return me
    #
    setTimestamp: func(timestamp) {
        me._view.setTimestamp(timestamp);
        return me;
    },

    #
    # @param  double  distance  In nautical miles
    # @return me
    #
    setDistance: func(distance) {
        me._view.setDistance(distance);
        return me;
    },
};
