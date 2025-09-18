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
# InfoView widget View
#
DefaultStyle.widgets["info-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "info-view");

        me._content = me._root.createChild("group", "clip-content")
            .set("clip-frame", Element.PARENT);

        me._textColor = me._style.getColor("fg_color");
        me._bgColor   = me._style.getColor("bg_color");

        var y = 0;
        var small = 20;
        var big   = 30;

        me._labelLatLon         = me._createTextLabel(0, y += 20,    "Latitude, Longitude");
        me._labelLatLonValue    = me._createTextValue(0, y += small, "");
        me._labelAlt            = me._createTextLabel(0, y += big,   "Altitude MSL / AGL");
        me._labelAltValue       = me._createTextValue(0, y += small, "");
        me._labelHdg            = me._createTextLabel(0, y += big,   "Heading true / mag");
        me._labelHdgValue       = me._createTextValue(0, y += small, "");
        me._labelSpeeds         = me._createTextLabel(0, y += big,   "Air / Groundspeed");
        me._labelSpeedsValue    = me._createTextValue(0, y += small, "");
        me._labelWind           = me._createTextLabel(0, y += big,   "Wind");
        me._labelWindValue      = me._createTextValue(0, y += small, "");
        me._labelTimestamp      = me._createTextLabel(0, y += big,   "Flight Duration");
        me._labelTimestampValue = me._createTextValue(0, y += small, "");
        me._labelDistance       = me._createTextLabel(0, y += big,   "Distance");
        me._labelDistanceValue  = me._createTextValue(0, y += small, "");

        me.setLatLon(0, 0);
        me.setAltitudes(0, 0);
        me.setHeadings(0, 0);
        me.setSpeeds(0, 0);
        me.setWind(0, 0);
        me.setTimestamp("0:00:00");
        me.setDistance(0);
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  InfoView model
    # @param  int  w, h  Width and height of widget
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  InfoView model
    # @return void
    #
    update: func(model) {
        me._content.set("clip", "rect(0, " ~ model._size[0] ~ ", " ~ model._size[1] ~ ", 0)");
    },

    #
    # @param  int  x, y
    # @param  string  label
    # @param  string  alignment
    # @return ghost  Text element
    #
    _createTextLabel: func(x, y, label = "", alignment = "left-baseline") {
        return me._content.createChild("text")
            .setTranslation(x, y)
            .setText(label)
            .setAlignment(alignment)
            .setFontSize(12)
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setColor(me._textColor)
            .setColorFill(me._bgColor);
    },

    #
    # @param  int  x, y
    # @param  string  label
    # @param  string  alignment
    # @return ghost  Text element
    #
    _createTextValue: func(x, y, label = "", alignment = "left-baseline") {
        return me._content.createChild("text")
            .setTranslation(x, y)
            .setText(label)
            .setAlignment(alignment)
            .setFontSize(16)
            .setFont("LiberationFonts/LiberationSans-Bold.ttf")
            .setColor(me._textColor)
            .setColorFill(me._bgColor);
    },

    #
    # @param  ghost  model  InfoView model
    # @return void
    #
    reDrawContent: func(model) {
        #
    },

    #
    # @param  double  lat
    # @param  double  lon
    # @return void
    #
    setLatLon: func(lat, lon) {
        me._labelLatLonValue.setText(sprintf("%.03f, %.03f", lat, lon));
    },

    #
    # @param  double  msl  In feet
    # @param  double  agl  In feet
    # @return void
    #
    setAltitudes: func(msl, agl) {
        me._labelAltValue.setText(sprintf("%.0f ft / %.0f ft", msl, agl));
    },

    #
    # @param  double  hdgTrue
    # @param  double  hdgMag
    # @return void
    #
    setHeadings: func(hdgTrue, hdgMag) {
        me._labelHdgValue.setText(sprintf("%.0f° / %.0f°", hdgTrue, hdgMag));
    },

    #
    # @param  double  airspeed  In knots
    # @param  double  groundspeed  In knots
    # @return void
    #
    setSpeeds: func(airspeed, groundspeed) {
        me._labelSpeedsValue.setText(sprintf("%.0f kt / %.0f kt", airspeed, groundspeed));
    },

    #
    # @param  double  heading
    # @param  double  speed  In knots
    # @return void
    #
    setWind: func(heading, speed) {
        me._labelWindValue.setText(sprintf("%.0f°, %.0f kt", heading, speed));
    },

    #
    # @param  string  timestamp
    # @return void
    #
    setTimestamp: func(timestamp) {
        me._labelTimestampValue.setText(timestamp);
    },

    #
    # @param  double  distance  In nautical miles
    # @return void
    #
    setDistance: func(distance) {
        me._labelDistanceValue.setText(sprintf("%.02f NM", distance));
    },
};
