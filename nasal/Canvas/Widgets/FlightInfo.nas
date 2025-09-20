#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# FlightInfo widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# FlightInfo widget Model
#
gui.widgets.FlightInfo = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return ghost
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.FlightInfo);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "flight-info-view", me._cfg));

        return me;
    },

    #
    # @param  double  lat
    # @param  double  lon
    # @return ghost
    #
    setLatLon: func(lat, lon) {
        me._view.setLatLon(lat, lon);
        return me;
    },

    #
    # @param  double  msl  In feet
    # @param  double  agl  In feet
    # @return ghost
    #
    setAltitudes: func(msl, agl) {
        me._view.setAltitudes(msl, agl);
        return me;
    },

    #
    # @param  double  hdgTrue
    # @param  double  hdgMag
    # @return ghost
    #
    setHeadings: func(hdgTrue, hdgMag) {
        me._view.setHeadings(hdgTrue, hdgMag);
        return me;
    },

    #
    # @param  double  airspeed  In knots
    # @param  double  groundspeed  In knots
    # @return ghost
    #
    setSpeeds: func(airspeed, groundspeed) {
        me._view.setSpeeds(airspeed, groundspeed);
        return me;
    },

    #
    # @param  double  heading
    # @param  double  speed  In knots
    # @return ghost
    #
    setWind: func(heading, speed) {
        me._view.setWind(heading, speed);
        return me;
    },

    #
    # @param  string  timestamp
    # @return ghost
    #
    setTimestamp: func(timestamp) {
        me._view.setTimestamp(timestamp);
        return me;
    },

    #
    # @param  double  distance  In nautical miles
    # @return ghost
    #
    setDistance: func(distance) {
        me._view.setDistance(distance);
        return me;
    },
};
