#
# ProfileView widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# ProfileView is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# ProfileView widget View
#
DefaultStyle.widgets["profile-view"] = {
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

        me._xXAxis = 0;
        me._yXAxis = 0;
        me._maxValueX = 0;
        me._graphWidth = 0;
        me._positiveYAxisLength = 0;

        me._pointsX = std.Vector.new();
        me._isClickEventSet = 0;

        me._svgPlane = nil;
        me._planeIconWidth  = 0;
        me._planeIconHeight = 0;

        me._trackItemsSize = 0;
        me._trackItems     = nil;

        # If zoom is used, in which fraction of the graph is the plane located
        me._fractionIndex = 0;
        me._firstValueX = 0;

        me._zoomFractions = {
            distance : std.Vector.new(),
            timestamp: std.Vector.new(),
        };
        me._isZoomFractionsBuilt = 0;
        me._firstFractionPosition = nil;
        me._isZoomBlocked = 0;
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  ProfileView model
    # @param  int  w, h  Width and height of widget
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

        if (model._trackItems == nil or model._trackItemsSize == 0) {
            me._drawTextCenter(
                "This log doesn't contain flight data.",
                int(model._size[0] / 2),
                int(model._size[1] / 2)
            );

            return;
        }

        me._buildZoomFractions(model);

        me._addEvents(model);

        me._createPlaneIcon();

        me._setRangeOfPointsToDraw(model);
        me._drawProfile(model);

        me.updateAircraftPosition(model);
    },

    #
    # @return int
    #
    _getFirstFractionPosition: func() {
        if (me._firstFractionPosition == nil) {
            return 0;
        }

        return me._firstFractionPosition;
    },

    #
    # Add mouse events to profile view
    #
    # @param  ghost  model  ProfileView model
    # @return void
    #
    _addEvents: func(model) {
        if (me._isClickEventSet) {
            # Events should be added only once, otherwise they will be called multiple times
            return;
        }

        me._isClickEventSet = 1;

        me._root.addEventListener("click", func(e) {
            var position = me._findClosestXBinary(e.localX, me._pointsX.vector);

            model.setTrackPosition(position + me._getFirstFractionPosition());
            model._updatePosition();
        });


        # Zoom by scroll wheel
        me._root.addEventListener("wheel", func(e) {
            if (model._isLiveUpdateMode or me._isZoomBlocked) {
                # Zoom is disabled for live update mode or if zoom is blocked
                return;
            }

            # e.deltaY = 1 or -1
            if (model._changeZoom(e.deltaY)) {
                model._updateZoom();

                me.reDrawContent(model);
            }
        });
    },

    #
    # Binary search for closest point to click
    #
    # @param  int  clickedX
    # @param  vector  points  Vector of hashes [{ x: double, position: int }, {...}, ...]
    # @return int  Aircraft position found
    #
    _findClosestXBinary: func(clickedX, points) {
        var left = 0;
        var right = size(points) - 1;
        var closestIndex = -1;

        while (left <= right) {
            var mid = math.floor((left + right) / 2);

            # The following doesn't make sense since points[mid].x is double and clickedX is integer
            # if (points[mid].x == clickedX) {
            #     return points[mid].position;
            # }

            if (points[mid].x < clickedX) {
                left = mid + 1;
            }
            else {
                right = mid - 1;
            }

            # Update nearest index if current point is closer
            if (closestIndex == -1 or math.abs(points[mid].x - clickedX) < math.abs(points[closestIndex].x - clickedX)) {
                closestIndex = mid;
            }
        }

        return points[closestIndex].position;
    },

    #
    # Build zoom fractions, once for model._trackItems data
    #
    # @param  ghost  model  ProfileView model
    # @return void
    #
    _buildZoomFractions: func(model) {
        if (me._isZoomFractionsBuilt or model._isLiveUpdateMode) {
            return;
        }

        me._isZoomFractionsBuilt = 1;

        me._zoomFractions.distance.clear();
        me._zoomFractions.timestamp.clear();

        var lastIndex = model._trackItemsSize - 1;
        var lastItem  = model._trackItems[lastIndex];

        var distFraction = lastItem.distance  / gui.widgets.ProfileView.ZOOM_MAX;
        var timeFraction = lastItem.timestamp / gui.widgets.ProfileView.ZOOM_MAX;

        var nextDistValue = distFraction;
        var nextTimeValue = timeFraction;

        var distObj = {
            firstPosition: nil,
            lastPosition : nil,
            items        : [],
            itemsSize    : 0,
        };

        var timeObj = {
            firstPosition: nil,
            lastPosition : nil,
            items        : [],
            itemsSize    : 0,
        };

        var distCounter = 0;
        var timeCounter = 0;

        me._isZoomBlocked = 0;

        forindex (var index; model._trackItems) {
            var item = model._trackItems[index];

            var isLast = index == lastIndex;

            (nextDistValue, distObj, distCounter) = me._buildZoomFraction(index, item, "distance",  nextDistValue, distFraction, distObj, isLast, distCounter);
            (nextTimeValue, timeObj, timeCounter) = me._buildZoomFraction(index, item, "timestamp", nextTimeValue, timeFraction, timeObj, isLast, timeCounter);
        }

        if (me._isZoomBlocked) {
            if (model.setDefaultZoom()) {
                model._updateZoom();
            }
        }
    },

    #
    # Build zoom fraction for distance or timestamp
    #
    # @param  int  index  Current index of model._trackItems
    # @param  hash  item  Current item of model._trackItems
    # @param  string  key  "distance" or "timestamp"
    # @param  double  nextValue  Limit value for current faction
    # @param  double  fractionValue  A fractional part of a time or distance value
    # @param  hash  fractionObj  Fraction object with min and max positions, vector of points and size of vector
    # @param  bool  isLast  True if it's last index of model._trackItems vector
    # @param  int  counter
    # @return vector  New value of nextValue and fractionObj
    #
    _buildZoomFraction: func(index, item, key, nextValue, fractionValue, fractionObj, isLast, counter) {
        if (item[key] <= nextValue or isLast) {
            if (fractionObj.firstPosition == nil) {
                fractionObj.firstPosition = index;
            }

            fractionObj.lastPosition = index;
            fractionObj.itemsSize += 1;

            append(fractionObj.items, item);
            counter += 1;
        }

        if (item[key] > nextValue or isLast) {
            if (counter < 2) {
                # Block change zoom level when zoom fraction hasn't min 2 points
                me._isZoomBlocked = 1;
            }

            counter = 0;

            me._zoomFractions[key].append(fractionObj);

            if (!isLast) {
                fractionObj = {
                    firstPosition: index,
                    lastPosition : index,
                    items        : [],
                    itemsSize    : 1,
                };

                append(fractionObj.items, item);

                nextValue += fractionValue;
            }
        }

        return [nextValue, fractionObj, counter];
    },

    #
    # Set range of points to draw according to zoom level
    #
    # @param  ghost  model  ProfileView model
    # @return void
    #
    _setRangeOfPointsToDraw: func(model) {
        if (model._isLiveUpdateMode) {
            # For live mode the zoom is disabled
            me._trackItems     = model._trackItems;
            me._trackItemsSize = model._trackItemsSize;
            return;
        }

        var fractions = me._getZoomFractions(model);

        var indexAllFractions = me._getCurrentFractionIndex(model);
        var invert = math.min(fractions.size(), gui.widgets.ProfileView.ZOOM_MAX) / model._zoom;
        var firstIndex = (math.floor(indexAllFractions / invert)) * invert;

        me._trackItems = [];
        me._trackItemsSize = 0;
        me._firstFractionPosition = nil;

        foreach (var item; fractions.vector[firstIndex:(firstIndex + invert - 1)]) {
            me._trackItems ~= item.items; # merge vectors
            me._trackItemsSize += item.itemsSize;
            if (me._firstFractionPosition == nil) {
                me._firstFractionPosition = item.firstPosition;
            }
        }

        me._fractionIndex = me._getIndexMergedFractions(model, indexAllFractions);
    },

    #
    # Return the index of the part of the graph where the aircraft is currently located.
    # For example, if zoom level is 8, it can be index from 0 do 7.
    #
    # @param  ghost  model  ProfileView model
    # @return int
    #
    _getCurrentFractionIndex: func(model) {
        var vector = me._getZoomFractions(model).vector;
        forindex (var index; vector) {
            var item = vector[index];

            if (item.firstPosition == nil) {
                return 0;
            }

            if (    model._position >= item.firstPosition
                and model._position <= item.lastPosition
            ) {
                return index;
            }
        }

        return 0;
    },

    #
    # Get vector of zoom fractions depend of draw mode
    #
    # @param  ghost  model  ProfileView model
    # @return std.Vector
    #
    _getZoomFractions: func(model) {
        return model.isDrawModeTime()
            ? me._zoomFractions.timestamp
            : me._zoomFractions.distance;
    },

    #
    # Returned index value depend of zoom level. The fractions vectors have been merged according to zoom level
    # e.g. when zoom = 2, then ZOOM_MAX vectors will be merged to 2 vectors, then this function will return 0 or 1.
    #
    # @param  ghost model  ProfileView mode
    # @param  int  indexAllFractions
    # @return int
    #
    _getIndexMergedFractions: func(model, indexAllFractions) {
        return math.floor(indexAllFractions / (gui.widgets.ProfileView.ZOOM_MAX / model._zoom));
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

        var seaMeanLevel = (graphHeight / 6);
        me._xXAxis = 60 + paddingLeft;
        me._yXAxis = graphHeight - seaMeanLevel; # horizontal position of the X axis in pixels
        me._positiveYAxisLength = me._yXAxis - paddingTop;

        me._graphWidth = model._size[0] - me._xXAxis - paddingRight - (me._planeIconWidth / 2);

        me._drawText("Time (hours) and Distance (NM)", model._size[0] / 2, model._size[1], "center-bottom");
        me._drawText("Altitude (feet)", paddingLeft, graphHeight / 2, "center-top", -90);

        var maxAlt = model._maxAlt;

        # Draw altitude grid

        var grid = me._root.createChild("path", "x-y-grid")
            .setColor(0.8, 0.8, 0.8)
            .setStrokeLineWidth(1);

        me._drawTextRight("0", me._xXAxis - 5, me._yXAxis); # 0 ft altitude

        var maxAltFt = maxAlt * globals.M2FT;
        var graduation = me._roundToHundreds(maxAltFt / 4);
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

        # Shift X according to zoom level
        me._firstValueX = model.isDrawModeTime()
            ? me._trackItems[0].timestamp
            : me._trackItems[0].distance;

        var lastRecord = me._trackItems[me._trackItemsSize - 1];
        me._maxValueX = model.isDrawModeTime()
            ? lastRecord.timestamp
            : lastRecord.distance;

        me._maxValueX -= me._firstValueX;

        var maxXAxisLabelsCount = 15;
        var xAxisLabelsSeparation = math.ceil(me._trackItemsSize / maxXAxisLabelsCount);
        var lastLabelX = 0;
        var labelDistance = 35;

        forindex (var index; me._trackItems) {
            var item = me._trackItems[index];

            var valueX = model.isDrawModeTime()
                ? item.timestamp
                : item.distance;

            valueX -= me._firstValueX;

            var x = me._xXAxis + ((me._maxValueX == 0 ? 0 : valueX / me._maxValueX) * me._graphWidth);
            var elevationY = me._yXAxis - ((maxAlt == 0 ? 0 : item.elevation_m / maxAlt) * me._positiveYAxisLength);
            var flightY    = me._yXAxis - ((maxAlt == 0 ? 0 : item.alt_m / maxAlt) * me._positiveYAxisLength);

            me._pointsX.append({ x: x, position: index });

            if (index == 0) {
                elevationProfile.moveTo(x, elevationY);
                flightProfile.moveTo(x, flightY);
            }
            else {
                elevationProfile.lineTo(x, elevationY);
                flightProfile.lineTo(x, flightY);

                if (math.mod(index, xAxisLabelsSeparation) == 0
                    and math.abs(x - lastLabelX) > labelDistance # <- prevents overlapping of multiple labels in distance mode.
                ) {
                    # Labels with hours on X axis
                    me._drawTextCenter(sprintf("%.2f", item.timestamp), x, me._yXAxis + 10);

                    # Labels with distance on X axis
                    me._drawTextCenter(sprintf("%.1f", item.distance), x, me._yXAxis + 30);

                    # Draw vertical grid line
                    grid.moveTo(x, paddingTop)
                        .vert(me._yXAxis);

                    lastLabelX = x;
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
        if (model._trackItemsSize == 0) {
            return;
        }

        if (!model._isLiveUpdateMode) {
            var fractionIndex = me._getIndexMergedFractions(model, me._getCurrentFractionIndex(model));
            if (fractionIndex != me._fractionIndex) {
                # The aircraft is in a different fraction of the graph, so redraw the whole graph
                me.reDrawContent(model);
                return;
            }
        }

        var index = model._position - me._getFirstFractionPosition();
        var item = me._trackItems[index];

        var valueX = model.isDrawModeTime()
            ? item.timestamp
            : item.distance;

        valueX -= me._firstValueX;

        var x = me._xXAxis + ((me._maxValueX == 0 ? 0 : valueX / me._maxValueX) * me._graphWidth);
        var y = me._yXAxis - ((model._maxAlt == 0 ? 0 : item.alt_m / model._maxAlt) * me._positiveYAxisLength);

        return me._drawPlaneIcon(x, y, item.pitch);
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
        return math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2));
    },

    #
    # Create SVG plane image
    #
    # @return void
    #
    _createPlaneIcon: func() {
        me._svgPlane = me._root.createChild("group").set("z-index", 1);
        canvas.parsesvg(me._svgPlane, "Textures/plane-side.svg");

        (me._planeIconWidth, me._planeIconHeight) = me._svgPlane.getSize();
    },

    #
    # Draw plane from SVG file
    #
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @return void
    #
    _drawPlaneIcon: func(x, y, rotate = 0) {
        var angleInRadians = -rotate * globals.D2R;
        var offset = me._getRotationOffset(me._planeIconWidth, me._planeIconHeight, angleInRadians);

        me._svgPlane.setTranslation(
            x - (me._planeIconWidth  * 0.5) + offset.dx,
            y - (me._planeIconHeight * 0.8) + offset.dy
        );
        me._svgPlane.setRotation(angleInRadians);
    },

    #
    # Calculate offset for rotation because the image rotation point is in the upper left corner
    #
    # @param  int  width  Image width
    # @param  int  height  Image height
    # @param  double  angleInRadians
    # @return hash  Hash with delta X and delta Y
    #
    _getRotationOffset: func(width, height, angleInRadians) {
        var deltaX = -(width / 2) * (math.cos(angleInRadians) - 1) + (height / 2) *  math.sin(angleInRadians);
        var deltaY = -(width / 2) *  math.sin(angleInRadians)      - (height / 2) * (math.cos(angleInRadians) - 1);

        return { dx: deltaX, dy: deltaY };
    },

    #
    # Round the given number to hundreds, e.g. 185 => 100, 6486 => 6400, etc.
    #
    # @param  double  number
    # @return double
    #
    _roundToHundreds: func(number) {
        var magnitude = 100;
        return math.floor(number / magnitude) * magnitude;
    },
};
