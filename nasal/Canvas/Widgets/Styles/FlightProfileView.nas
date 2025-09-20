#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# FlightProfile is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# FlightProfile widget View
#
DefaultStyle.widgets["flight-profile-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "flight-profile-view");

        me._textColor = me._style.getColor("fg_color");

        me._xXAxis = 0;
        me._yXAxis = 0;
        me._maxValueX = 0;
        me._graphWidth = 0;
        me._positiveYAxisLength = 0;
        me._firstValueX = 0;

        me._pointsX = std.Vector.new();
        me._isEventsSet = 0;

        me._trackItems     = nil;
        me._trackItemsSize = 0;

        me._zoomFractions = ZoomFractions.new();
        me._planeIcon = PlaneIcon.new();
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  FlightProfile model
    # @param  int  w, h  Width and height of widget
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  FlightProfile model
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  FlightProfile model
    # @return void
    #
    reDrawContent: func(model) {
        me._root.removeAllChildren();

        if (model._trackItems == nil or model._trackItemsSize == 0) {
            me._drawTextCenter(
                x: int(model._size[0] / 2),
                y: int(model._size[1] / 2),
                label: "This log doesn't contain flight data."
            );

            return;
        }

        me._zoomFractions.create(model);

        me._addEvents(model);

        me._planeIcon.create(me._root, "Textures/plane-side.svg");

        me._zoomFractions.setRangeOfPointsToDraw(model, me);
        me._drawProfile(model);

        me.updateAircraftPosition(model);
    },

    #
    # Add mouse events to profile view
    #
    # @param  ghost  model  FlightProfile model
    # @return void
    #
    _addEvents: func(model) {
        if (me._isEventsSet) {
            # Events should be added only once, otherwise they will be called multiple times
            return;
        }

        me._isEventsSet = 1;

        me._root.addEventListener("click", func(e) {
            var position = me._findClosestXBinary(e.localX, me._pointsX.vector);

            model.setTrackPosition(position + me._zoomFractions.getFirstFractionPosition());
            model._updatePosition();
        });


        # Zoom by scroll wheel
        me._root.addEventListener("wheel", func(e) {
            if (model._isLiveUpdateMode) {
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
    # Draw flight vertical profile
    #
    # @param  ghost  model  FlightProfile model
    # @return void
    #
    _drawProfile: func(model) {
        var paddingTop    = 0;
        var paddingRight  = 0;
        var paddingBottom = 40; # <- to make space for the X-axis caption "Time (hours) and Distance (NM)"
        var paddingLeft   = 0;

        var graphHeight = model._size[1] - paddingBottom;

        var seaMeanLevel = (graphHeight / 6);
        me._xXAxis = 60 + paddingLeft;
        me._yXAxis = graphHeight - seaMeanLevel; # horizontal position of the X axis in pixels
        me._positiveYAxisLength = me._yXAxis - paddingTop;

        me._graphWidth = model._size[0] - me._xXAxis - paddingRight - (me._planeIcon.getWidth() / 2);

        me._drawText(
            x: model._size[0] / 2,
            y: model._size[1],
            label: "Time (hours) and Distance (NM)",
            alignment: "center-bottom",
        );

        me._drawText(
            x: paddingLeft,
            y: graphHeight / 2,
            label: "Altitude (feet)",
            alignment: "center-top",
            rotate: -90
        );

        var maxAlt = model._maxAlt;

        # Draw altitude grid

        var grid = me._root.createChild("path", "x-y-grid")
            .setColor(0.8, 0.8, 0.8)
            .setStrokeLineWidth(1);

        me._drawTextRight(
            x: me._xXAxis - 5,
            y: me._yXAxis,
            label: "0", # 0 ft altitude
        );

        var maxAltFt = maxAlt * globals.M2FT;
        var graduation = me._roundAltitude(maxAltFt / 4);
        for (var i = 1; i <= 5; i += 1) {
            var altFt = graduation * i;
            var y = me._yXAxis - ((maxAltFt == 0 ? 0 : altFt / maxAltFt) * me._positiveYAxisLength);
            if (y < paddingTop) {
                # There is no more space for another horizontal line, exit the loop
                break;
            }

            me._drawTextRight(
                x: me._xXAxis - 5,
                y: y,
                label: sprintf("%.0f", altFt),
            );

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
                    me._drawTextCenter(
                        x: x,
                        y: me._yXAxis + 10,
                        label: sprintf("%.2f", item.timestamp),
                    );

                    # Labels with distance on X axis
                    me._drawTextCenter(
                        x: x,
                        y: me._yXAxis + 30,
                        label: sprintf("%.1f", item.distance),
                    );

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
    # Draw an invisible line to get the padding. This was needed when FlightProfile was drawn inside ScrollArea.
    #
    # @param  ghost  model  FlightProfile model
    # @return void
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
    # @param  ghost  model  FlightProfile model
    # @return ghost  Path element
    #
    updateAircraftPosition: func(model) {
        if (model._trackItemsSize == 0) {
            return;
        }

        if (!model._isLiveUpdateMode) {
            var currentFractionIndex = me._zoomFractions.getCurrentFractionIndex(model);
            var fractionIndex        = me._zoomFractions.getIndexMergedFractions(model, currentFractionIndex);
            if (fractionIndex != me._zoomFractions.getFractionIndex()) {
                # The aircraft is in a different fraction of the graph, so redraw the whole graph
                me.reDrawContent(model);
                return;
            }
        }

        var index = model._position - me._zoomFractions.getFirstFractionPosition();
        var item = me._trackItems[index];

        var valueX = model.isDrawModeTime()
            ? item.timestamp
            : item.distance;

        valueX -= me._firstValueX;

        var x = me._xXAxis + ((me._maxValueX == 0 ? 0 : valueX / me._maxValueX) * me._graphWidth);
        var y = me._yXAxis - ((model._maxAlt == 0 ? 0 : item.alt_m / model._maxAlt) * me._positiveYAxisLength);

        return me._planeIcon.draw(x, y, -item.pitch, 0.8);
    },

    #
    # Draw text center-center
    #
    # @param  double  x
    # @param  double  y
    # @param  string  label
    # @param  double  rotate
    # @return ghost  Text element
    #
    _drawTextCenter: func(x, y, label, rotate = 0) {
        return me._drawText(x, y, label, "center-center", rotate);
    },

    #
    # Draw text right-center
    #
    # @param  double  x
    # @param  double  y
    # @param  string  label
    # @param  double  rotate
    # @return ghost  Text element
    #
    _drawTextRight: func(x, y, label, rotate = 0) {
        return me._drawText(x, y, label, "right-center", rotate);
    },

    #
    # Draw text with given alignment
    #
    # @param  double  x
    # @param  double  y
    # @param  string  label
    # @param  string  alignment
    # @param  double  rotate
    # @return ghost  Text element
    #
    _drawText: func(x, y, label, alignment = "center-center", rotate = 0) {
        return me._root.createChild("text")
            .setColor(me._textColor)
            .setAlignment(alignment)
            .setFont("LiberationFonts/LiberationMono-Regular.ttf")
            .setFontSize(12)
            .setTranslation(x, y)
            .setRotation(rotate * globals.D2R)
            .setText(label);
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
    # Round the given number to hundreds, e.g. 185 => 100, 6486 => 6400, etc.
    #
    # @param  double  number  Max alt in feet divided by 4
    # @return double
    #
    _roundAltitude: func(number) {
        var magnitude = me._getAltMagnitude(number);

        return math.floor(number / magnitude) * magnitude;
    },

    #
    # Get magnitude to alt
    #
    # @param  double  number  Max alt in feet divided by 4
    # @return double
    #
    _getAltMagnitude: func(number) {
        if (number <= 250) {
            return 10;
        }

        if (number <= 2000) {
            return 100;
        }

        return 1000;
    },

    #
    # @return int
    #
    getMaxZoomLevel: func() {
        return me._zoomFractions.getMaxZoomLevel();
    },

    #
    # Set fractions of zoom to recreate
    #
    # @return void
    #
    setZoomFractionToRecreate: func() {
        me._zoomFractions.setToRecreate();
    },
};
