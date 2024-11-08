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
# VerticalProfileDialog class
#
var VerticalProfileDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 1360,
    WINDOW_HEIGHT : 350,
    PADDING       : 0,
    #
    # Aircraft icon:
    PIXEL_DIFF    : 9,  # The difference in height in pixels between adjacent flight profile points
    AC_ANGLE      : 20, # Angle in degrees to rotate the airplane icon up or down

    #
    # Constructor
    #
    # @param  hash  storage  Storage object
    # @return me
    #
    new: func(storage) {
        var me = {
            parents: [
                VerticalProfileDialog,
                Dialog.new(
                    VerticalProfileDialog.WINDOW_WIDTH,
                    VerticalProfileDialog.WINDOW_HEIGHT,
                    "Vertical Profile"
                ),
            ],
            _storage  : storage,
            _logbookId: nil,
        };

        me.bgImage.hide();

        me.setPositionOnCenter();

        me._vBoxLayout = nil;

        me._drawContent();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Show this canvas dialog
    #
    # @param  int  logbookId
    # @return void
    #
    show: func(logbookId) {
        g_Sound.play('paper');

        me._logbookId = logbookId;

        me._drawContent();

        call(Dialog.show, [], me);
    },

    #
    # Draw whole dialog content
    #
    # @return void
    #
    _drawContent: func() {
        me.vbox.clear();

        var margins = {
            left   : VerticalProfileDialog.PADDING,
            top    : VerticalProfileDialog.PADDING,
            right  : VerticalProfileDialog.PADDING,
            bottom : 0,
        };
        me._scrollData = me.createScrollArea(nil, margins);
        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch
        me._scrollDataContent = me.getScrollAreaContent(me._scrollData);

        me._drawScrollable();

        me._drawBottomBar();
    },

    #
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func() {
        var graphHeight = VerticalProfileDialog.WINDOW_HEIGHT - 100;

        me._scrollDataContent.createChild("path", "padding-keeper")
            .moveTo(0, 0)
            .lineTo(VerticalProfileDialog.WINDOW_WIDTH, 0)
            .setColor(0, 0, 0)
            .setStrokeLineWidth(1);

        var rows = me._storage.getLogbookTracker(me._logbookId);
        if (rows == nil or size(rows) == 0) {
            me._drawTextCenter("This log doesn't contain flight data.", VerticalProfileDialog.WINDOW_WIDTH / 2, graphHeight / 2);
            return;
        }

        var seaMeanLevel = (graphHeight / 6);
        var padding = 20;
        var xXAxis = 80;
        var yXAxis = graphHeight - seaMeanLevel; # horizontal position of the X axis in pixels
        var positiveYAxisLength = yXAxis - padding;

        var graphWidth = VerticalProfileDialog.WINDOW_WIDTH - padding - (VerticalProfileDialog.PADDING * 2);

        me._drawTextCenter("Time (hours) and Distance (NM)", VerticalProfileDialog.WINDOW_WIDTH / 2, graphHeight + 10);
        me._drawTextCenter("Altitude (feet)", 20, graphHeight / 2, -90);

        var maxAlt = me._storage.getLogbookTrackerMaxAlt(me._logbookId);

        # Draw max alt label and half alt label
        # me._drawTextRight(sprintf("%.0f", maxAlt * globals.M2FT),       xXAxis - 5, padding);
        # me._drawTextRight(sprintf("%.0f", (maxAlt / 2) * globals.M2FT), xXAxis - 5, padding + (positiveYAxisLength / 2));

        # Draw altitude grid

        var grid = me._scrollDataContent.createChild("path", "x-y-grid")
            .setColor(0.8, 0.8, 0.8)
            .setStrokeLineWidth(1);

        me._drawTextRight("0", xXAxis - 5, yXAxis); # 0 ft altitude

        var maxAltFt = maxAlt * globals.M2FT;
        var graduation = me._roundToNearestPowerOfTen(maxAltFt / 4);
        for (var i = 1; i <= 5; i += 1) {
            var altFt = graduation * i;
            var y = yXAxis - ((altFt / maxAltFt) * positiveYAxisLength);
            if (y < padding) {
                # There is no more space for another horizontal line, exit the loop
                break;
            }

            me._drawTextRight(sprintf("%.0f", altFt), xXAxis - 5, y);

            # Draw horizontal grid line
            grid.moveTo(xXAxis, y)
                .lineTo(graphWidth, y);
        }

        # Draw elevation and flight profile

        var elevationProfile = me._scrollDataContent.createChild("path", "elevation")
            .setColor(0.65, 0.16, 0.16)
            # .setColorFill(0.75, 0.26, 0.26)
            # .moveTo(xXAxis, graphHeight)
            .setStrokeLineWidth(2);

        var flightProfile = me._scrollDataContent.createChild("path", "flight")
            .setColor(0.5, 0.5, 1)
            .setStrokeLineWidth(2);

        var lastRecord = rows[size(rows) - 1];
        var maxTimestamp = lastRecord.timestamp;

        # Distance in pixels on graph between recorded points.
        # If the distance reaches a value above 100 px, then draw an airplane icon.
        var p1 = {};
        var p2 = {};
        var distance = 0;

        var maxXAxisLabelsCount = 15;
        var xAxisLabelsSeparation = math.ceil(size(rows) / maxXAxisLabelsCount);

        forindex (var index; rows) {
            var row = rows[index];

            var x = xXAxis + ((row.timestamp / maxTimestamp) * (graphWidth - xXAxis));
            var elevationY = yXAxis - ((row.elevation_m / maxAlt) * positiveYAxisLength);
            var flightY    = yXAxis - ((row.alt_m / maxAlt) * positiveYAxisLength);

            if (index == 0) {
                elevationProfile.moveTo(x, elevationY);
                flightProfile.moveTo(x, flightY);

                p1["x"] = x;
                p1["y"] = flightY;
            }
            else {
                elevationProfile.lineTo(x, elevationY);
                flightProfile.lineTo(x, flightY);

                if (index > 1) {
                    p1["x"] = p2.x;
                    p1["y"] = p2.y;
                }

                p2["x"] = x;
                p2["y"] = flightY;

                distance += me._getDistance(p1, p2);

                if (distance > 100) {
                    var rotate = 0;
                    if (p2.y > p1.y + VerticalProfileDialog.PIXEL_DIFF) {
                        rotate = VerticalProfileDialog.AC_ANGLE; # descent
                    }
                    else if (p2.y + VerticalProfileDialog.PIXEL_DIFF < p1.y) {
                        # We are climb compared with previous point, but for climb
                        # it is best to compare Y with the next point
                        if (index + 1 < size(rows)) {
                            var nextRow = rows[index + 1];
                            var nextFlightY = yXAxis - ((nextRow.alt_m / maxAlt) * positiveYAxisLength);

                            if (nextFlightY + VerticalProfileDialog.PIXEL_DIFF < p2.y) {
                                rotate = -VerticalProfileDialog.AC_ANGLE; # climb
                            }
                        }
                    }

                    me._drawPlaneSymbol(x, flightY, rotate);
                    distance = 0;
                }

                if (math.mod(index, xAxisLabelsSeparation) == 0) {
                    # Labels with hours on X axis
                    me._drawTextCenter(sprintf("%.2f", row.timestamp), x, yXAxis + 10);

                    # Labels with distance on X axis
                    me._drawTextCenter(sprintf("%.1f", row.distance), x, yXAxis + 30);

                    # Draw vertical grid line
                    grid.moveTo(x, padding)
                        .lineTo(x, yXAxis);
                }
            }
        }

        # elevationProfile.lineTo(x, graphHeight);

        var axis = me._scrollDataContent.createChild("path", "axis")
            .setColor(0, 0, 0)
            .setStrokeLineWidth(1);

        # Draw X Axis
        axis.moveTo(xXAxis, yXAxis)
            .lineTo(graphWidth, yXAxis);

        # Draw Y Axis
        axis.moveTo(xXAxis, padding)
            .lineTo(xXAxis, graphHeight);
    },

    #
    # Draw text center-center
    #
    # @param  string  text
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @return void
    #
    _drawTextCenter: func(text, x, y, rotate = 0) {
        me._drawText(text, x, y, rotate, "center-center");
    },

    #
    # Draw text right-center
    #
    # @param  string  text
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @return void
    #
    _drawTextRight: func(text, x, y, rotate = 0) {
        me._drawText(text, x, y, rotate, "right-center");
    },

    #
    # Draw text with given alignment
    #
    # @param  string  text
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @param  string  alignment
    # @return void
    #
    _drawText: func(text, x, y, rotate, alignment = "center-center") {
        me._scrollDataContent.createChild("text")
            .setColor(0, 0, 0)
            .setColorFill(0, 0, 0)
            .setAlignment(alignment)
            .setFont("LiberationFonts/LiberationMono-Regular.ttf")
            .setFontSize(12)
            .setTranslation(x, y)
            .setRotation(rotate * globals.D2R)
            .setText(text);
    },

    #
    # Calculate distance between 2 points
    #
    # @param  hash  p1
    # @param  hash  p2
    # @return double
    #
    _getDistance: func(p1, p2) {
        math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2));
    },

    #
    # Draw plane from SVG file
    #
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @return void
    #
    _drawPlaneSymbol: func(x, y, rotate = 0) {
        var svgPlane = me._scrollDataContent.createChild("group");
        canvas.parsesvg(svgPlane, "Textures/plane.svg");
        svgPlane.setScale(0.15);
        svgPlane.setTranslation(x - 12, y - 8);
        svgPlane.setRotation(rotate * globals.D2R);
    },

    #
    # Round given number to nearest power of ten, e.g. 185 => 100, 6486 => 6000, etc.
    #
    # @param  double  number
    # @return double
    #
    _roundToNearestPowerOfTen: func(number) {
        var magnitude = math.pow(10, math.floor(math.log10(number) / math.log10(10)));
        return math.floor(number / magnitude) * magnitude;
    },

    #
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnCancel = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Close")
            .setFixedSize(65, 26)
            .listen("clicked", func { me.window.hide(); });

        buttonBox.addStretch(1);
        buttonBox.addItem(btnCancel);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return buttonBox;
    },
};
