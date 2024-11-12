#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# ProfileView widget View
#
DefaultStyle.widgets["profile-view"] = {
    #
    # Constants
    #
    CROSS_ARM : 10,
    #
    # Constants aircraft icon:
    #
    PIXEL_DIFF:  9, # The difference in height in pixels between adjacent flight profile points
    AC_ANGLE  : 20, # Angle in degrees to rotate the airplane icon up or down

    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "profile-view");

        me._textColor = me._style.getColor("fg_color");

        me._aircraftPositionGroup = nil;

        me._xXAxis = 0;
        me._yXAxis = 0;
        me._maxTimestamp = 0;
        me._graphWidth = 0;
        me._positiveYAxisLength = 0;

        me._pointsX = std.Vector.new();
        me._isClickEventSet = false;
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  ProfileView model
    # @param  int w, h  Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  ProfileView model
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  ProfileView model
    # @return void
    #
    reDrawContent: func(model) {
        me._root.removeAllChildren();

        if (model._tractItems == nil or size(model._tractItems) == 0) {
            # me._drawPaddingKeeper(model);

            me._drawTextCenter(
                "This log doesn't contain flight data.",
                int(model._size[0] / 2),
                int(model._size[1] / 2)
            );
        }
        else {
            if (!me._isClickEventSet) {
                me._isClickEventSet = true;

                me._root.addEventListener("click", func(e) {
                    # Find nearest point on X axis
                    var minDiff = nil;
                    var lastDiff = nil;
                    var diff = 0;
                    var found = nil;
                    foreach (var item; me._pointsX.vector) {
                        diff = math.abs(item.x - e.localX);
                        if (minDiff == nil or diff < minDiff) {
                            minDiff = diff;
                            found = item;
                        }

                        if (lastDiff != nil and diff > lastDiff) {
                            break;
                        }

                        lastDiff = diff;
                    }

                    if (found != nil) {
                        model._updatePosition(found.position);

                        me.updateAircraftPosition(model);
                    }
                });
            }

            me._aircraftPositionGroup = me._root.createChild("group")
                .set("z-index", 1);

            me._drawProfile(model);

            me.updateAircraftPosition(model);
        }
    },

    #
    # Draw flight vertical profile
    #
    # @param  ghost  model  ProfileView model
    # @return void
    #
    _drawProfile: func(model) {
        var paddingTop    = 0;
        var paddingRight  = 0;
        var paddingBottom = 40; # <- to make space for the X-axis caption "Time (hours) and Distance (NM)"
        var paddingLeft   = 0;

        var graphHeight = model._size[1] - paddingBottom;

        # me._drawPaddingKeeper(model);

        var rows = model._tractItems;

        var seaMeanLevel = (graphHeight / 6);
        me._xXAxis = 60 + paddingLeft;
        me._yXAxis = graphHeight - seaMeanLevel; # horizontal position of the X axis in pixels
        me._positiveYAxisLength = me._yXAxis - paddingTop;

        me._graphWidth = model._size[0] - me._xXAxis - paddingRight - (DefaultStyle.widgets["profile-view"].CROSS_ARM);

        me._drawText("Time (hours) and Distance (NM)", model._size[0] / 2, model._size[1], "center-bottom");
        me._drawText("Altitude (feet)", paddingLeft, graphHeight / 2, "center-top", -90);

        var maxAlt = model._maxAlt; # me._storage.getLogbookTrackerMaxAlt(me._logbookId);

        # Draw altitude grid

        var grid = me._root.createChild("path", "x-y-grid")
            .setColor(0.8, 0.8, 0.8)
            .setStrokeLineWidth(1);

        me._drawTextRight("0", me._xXAxis - 5, me._yXAxis); # 0 ft altitude

        var maxAltFt = maxAlt * globals.M2FT;
        var graduation = me._roundToNearestPowerOfTen(maxAltFt / 4);
        for (var i = 1; i <= 5; i += 1) {
            var altFt = graduation * i;
            var y = me._yXAxis - ((maxAltFt == 0 ? 0 : altFt / maxAltFt) * me._positiveYAxisLength);
            if (y < paddingTop) {
                # There is no more space for another horizontal line, exit the loop
                break;
            }

            me._drawTextRight(sprintf("%.0f", altFt), me._xXAxis - 5, y);

            # Draw horizontal grid line
            grid.moveTo(me._xXAxis, y)
                .horiz(me._graphWidth);
        }

        # Draw elevation and flight profile

        var elevationProfile = me._root.createChild("path", "elevation")
            .setColor(0.65, 0.16, 0.16)
            # .setColorFill(0.75, 0.26, 0.26)
            # .moveTo(me._xXAxis, graphHeight)
            .setStrokeLineWidth(2);

        me._pointsX.clear();
        var flightProfile = me._root.createChild("path", "flight")
            .setColor(0.5, 0.5, 1)
            .setStrokeLineWidth(2);

        var lastRecord = rows[size(rows) - 1];
        me._maxTimestamp = lastRecord.timestamp;

        # Distance in pixels on graph between recorded points.
        # If the distance reaches a value above 100 px, then draw an airplane icon.
        var p1 = {};
        var p2 = {};
        var distance = 0;

        var maxXAxisLabelsCount = 15;
        var xAxisLabelsSeparation = math.ceil(size(rows) / maxXAxisLabelsCount);

        forindex (var index; rows) {
            var row = rows[index];

            var x = me._xXAxis + ((me._maxTimestamp == 0 ? 0 : row.timestamp / me._maxTimestamp) * me._graphWidth);
            var elevationY = me._yXAxis - ((maxAlt == 0 ? 0 : row.elevation_m / maxAlt) * me._positiveYAxisLength);
            var flightY    = me._yXAxis - ((maxAlt == 0 ? 0 : row.alt_m / maxAlt) * me._positiveYAxisLength);

            me._pointsX.append({ x: x, position: index });

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
                    if (p2.y > p1.y + DefaultStyle.widgets["profile-view"].PIXEL_DIFF) {
                        rotate = DefaultStyle.widgets["profile-view"].AC_ANGLE; # descent
                    }
                    else if (p2.y + DefaultStyle.widgets["profile-view"].PIXEL_DIFF < p1.y) {
                        # We are climb compared with previous point, but for climb
                        # it is best to compare Y with the next point
                        if (index + 1 < size(rows)) {
                            var nextRow = rows[index + 1];
                            var nextFlightY = me._yXAxis - ((maxAlt == 0 ? 0 : nextRow.alt_m / maxAlt) * me._positiveYAxisLength);

                            if (nextFlightY + DefaultStyle.widgets["profile-view"].PIXEL_DIFF < p2.y) {
                                rotate = -DefaultStyle.widgets["profile-view"].AC_ANGLE; # climb
                            }
                        }
                    }

                    me._drawPlaneSymbol(x, flightY, rotate);
                    distance = 0;
                }

                if (math.mod(index, xAxisLabelsSeparation) == 0) {
                    # Labels with hours on X axis
                    me._drawTextCenter(sprintf("%.2f", row.timestamp), x, me._yXAxis + 10);

                    # Labels with distance on X axis
                    me._drawTextCenter(sprintf("%.1f", row.distance), x, me._yXAxis + 30);

                    # Draw vertical grid line
                    grid.moveTo(x, paddingTop)
                        .vert(me._yXAxis);
                }
            }
        }

        var axis = me._root.createChild("path", "axis")
            .setColor(0, 0, 0)
            .setStrokeLineWidth(1);

        # Draw X Axis
        axis.moveTo(me._xXAxis, me._yXAxis)
            .horiz(me._graphWidth);

        # Draw Y Axis
        axis.moveTo(me._xXAxis, paddingTop)
            .vert(graphHeight);
    },

    #
    # Draw an invisible line to get the padding. This was needed when ProfileView was drawn inside ScrollArea.
    #
    # @param  ghost  model  ProfileView model
    # @return ghost  Path element
    #
    _drawPaddingKeeper: func(model) {
        me._root.createChild("path", "padding-keeper")
            .moveTo(0, 0)
            .horiz(model._size[0])
            .setColor(0, 0, 0, 0)
            .setStrokeLineWidth(1);
    },

    #
    # Redraw aircraft position
    #
    # @param  ghost  model  ProfileView model
    # @return ghost  Path element
    #
    updateAircraftPosition: func(model) {
        me._aircraftPositionGroup.removeAllChildren();

        var row = model._tractItems[model._position];
        var x = me._xXAxis + ((me._maxTimestamp == 0 ? 0 : row.timestamp / me._maxTimestamp) * me._graphWidth);
        var y = me._yXAxis - ((model._maxAlt == 0 ? 0 : row.alt_m / model._maxAlt) * me._positiveYAxisLength);

        return me._drawAircraft(model, x, y);
    },

    #
    # Simple aircraft icon at current position/center of the map
    #
    # @param  double  x
    # @param  double  y
    # @return ghost  Path element
    #
    _drawAircraft: func(model, x, y) {
        var arm = DefaultStyle.widgets["profile-view"].CROSS_ARM;

        return me._aircraftPositionGroup.createChild("path")
            .moveTo(x - arm, y)
            .horiz(arm * 2)
            .move(-arm, -arm)
            .vert(arm * 2)
            .set("stroke", "red")
            .set("stroke-width", 3)
            .set("z-index", 2);
            # .addEventListener("drag", func (e) {
            #     # var t = me._chart.getTranslation();
            #     # t[0] += e.deltaX;
            #     # t[1] += e.deltaY;
            #     # me._chart.setTranslation(t[0], t[1]);
            #     print("------------ e.deltaX = ", e.deltaX);
            #     if (e.deltaX > 5) {
            #         model._position += 1;
            #         var lastRowsIndex = model.getTrackLastIndex();
            #         if (model._position > lastRowsIndex) {
            #             model._position = lastRowsIndex;
            #         }

            #         me.updateAircraftPosition(model);
            #     }
            #     else if (e.deltaX < -5) {
            #         model._position -= 1;
            #         if (model._position < 0) {
            #             model._position = 0;
            #         }

            #         me.updateAircraftPosition(model);
            #     }
            # });
    },

    #
    # Draw text center-center
    #
    # @param  string  text
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @return ghost  Text element
    #
    _drawTextCenter: func(text, x, y, rotate = 0) {
        return me._drawText(text, x, y, "center-center", rotate);
    },

    #
    # Draw text right-center
    #
    # @param  string  text
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @return ghost  Text element
    #
    _drawTextRight: func(text, x, y, rotate = 0) {
        return me._drawText(text, x, y, "right-center", rotate);
    },

    #
    # Draw text with given alignment
    #
    # @param  string  text
    # @param  double  x
    # @param  double  y
    # @param  string  alignment
    # @param  double  rotate
    # @return ghost  Text element
    #
    _drawText: func(text, x, y, alignment = "center-center", rotate = 0) {
        return me._root.createChild("text")
            .setColor(me._textColor)
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
        var svgPlane = me._root.createChild("group");
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
};
