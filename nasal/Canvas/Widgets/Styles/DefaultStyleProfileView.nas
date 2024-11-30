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

        me._addEvents(model);

        me._createPlaneIcon();

        me._drawProfile(model);

        me.updateAircraftPosition(model);
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

            model.setTrackPosition(position);
            model._updatePosition();
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

        var lastRecord = model._trackItems[model._trackItemsSize - 1];
        me._maxValueX = model.isDrawModeTime()
            ? lastRecord.timestamp
            : lastRecord.distance;

        var maxXAxisLabelsCount = 15;
        var xAxisLabelsSeparation = math.ceil(model._trackItemsSize / maxXAxisLabelsCount);
        var lastLabelX = 0;
        var labelDistance = 35;

        forindex (var index; model._trackItems) {
            var item = model._trackItems[index];

            var valueX = model.isDrawModeTime()
                ? item.timestamp
                : item.distance;

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
        var item = model._trackItems[model._position];

        var valueX = model.isDrawModeTime()
            ? item.timestamp
            : item.distance;

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
