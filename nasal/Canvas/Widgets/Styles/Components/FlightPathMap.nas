#
# FlightPathMap - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# FlightPathMap component is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Class for draw flight path on the FlightMap widget
#
var FlightPathMap = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func {
        return {
            parents              : [FlightPathMap],
            _FLIGHT_LINE_WIDTH   : 2,
            _isFlightPathRendered: 0,
            _flightPath          : nil,
            _pointsToDraw        : std.Vector.new(),
        };
    },

    #
    # Create path object
    #
    # @param  hash  context
    # @return void
    #
    create: func(context) {
        me._flightPath = context.createChild("path", "flight")
            .setColor(0.5, 0.5, 1)
            .setStrokeLineWidth(me._FLIGHT_LINE_WIDTH)
            .set("z-index", 1);

        me._isFlightPathRendered = 0;
    },

    #
    # Draw flight path
    #
    # @param  ghost  model  FlightMap model object
    # @param  hash  centerTileOffset
    # @param  hash  tileBoundaries
    # @return void
    #
    draw: func(model, centerTileOffset, tileBoundaries) {
        if (model._isLiveUpdateMode) {
            me._drawFlightPathInLiveMode(model, centerTileOffset, tileBoundaries);
        }
        else {
            # Render 7x faster with once-drawn and next path transformation
            me._isFlightPathRendered
                ? me._transformFlightPath(model, centerTileOffset, tileBoundaries)
                : me._drawFullFlightPath(model, centerTileOffset, tileBoundaries);
        }
    },

    #
    # Redraw flight path in live mode, for current flight analysis.
    #
    # @param  ghost  model  FlightMap model object
    # @param  hash  centerTileOffset
    # @param  hash  tileBoundaries
    # @return ghost  Path element
    #
    _drawFlightPathInLiveMode: func(model, centerTileOffset, tileBoundaries) {
        me._pointsToDraw.clear();
        me._flightPath.reset();

        var edgeTiles = me._getTileThresholds(model, tileBoundaries);

        # = true because the first point must start with moveTo method
        var discontinuity = 1;

        # The first loop is to build an array of points that are within the map
        forindex (var index; model._trackItems) {
            var pos = me._convertLatLonToPixel(model, index, centerTileOffset);

            if (    pos.x < edgeTiles.maxX
                and pos.y < edgeTiles.maxY
                and pos.x > edgeTiles.minX
                and pos.y > edgeTiles.minY
            ) {
                # The path point is on the map, add it to me._pointsToDraw vector to use for click action
                me._pointsToDraw.append(pos);

                # Draw points only those within the map
                discontinuity
                    ? me._flightPath.moveTo(pos.x, pos.y)
                    : me._flightPath.lineTo(pos.x, pos.y);

                # We have just drawn a point, so there is no discontinuity
                discontinuity = 0;
            }
            else {
                # The path point is out of map tiles, so ship it and mark discontinuity
                discontinuity = 1;
            }
        }
    },

    #
    # Redraw whole flight path and create vector of points visible on the map for click action.
    #
    # @param  ghost  model  FlightMap model object
    # @param  hash  centerTileOffset
    # @param  hash  tileBoundaries
    # @return void
    #
    _drawFullFlightPath: func(model, centerTileOffset, tileBoundaries) {
        # me._flightPath.reset();

        # Set the reference position and zoom to the values ​​we have during full drawing.
        # These values ​​will be needed to perform the flight path transformation.
        me._refPosition = model._position;
        me._refZoom     = model._zoom;

        var edgeTiles = me._getTileThresholds(model, tileBoundaries);

        # The loop to build an array of points that are within the map view and draw flight path
        me._pointsToDraw.clear();
        forindex (var index; model._trackItems) {
            var pos = me._convertLatLonToPixel(model, index, centerTileOffset);

            if (    pos.x < edgeTiles.maxX
                and pos.y < edgeTiles.maxY
                and pos.x > edgeTiles.minX
                and pos.y > edgeTiles.minY
            ) {
                # The path point is on the map, add it to me._pointsToDraw vector to use for click action
                me._pointsToDraw.append(pos);
            }

            # Draw all path point
            index == 0
                ? me._flightPath.moveTo(pos.x, pos.y)
                : me._flightPath.lineTo(pos.x, pos.y);
        }

        me._isFlightPathRendered = 1;
    },

    #
    # Path transformations by airplane icon offset and map zoom
    # and recreate vector of points visible on the map for click action.
    #
    # @param  ghost  model  FlightMap model object
    # @param  hash  centerTileOffset
    # @param  hash  tileBoundaries
    # @return void
    #
    _transformFlightPath: func(model, centerTileOffset, tileBoundaries) {
        me._pointsToDraw.clear();

        var edgeTiles = me._getTileThresholds(model, tileBoundaries);

        var refPos = nil;
        var currentPos = nil;

        # Generate a new vector with points visible on the map
        forindex (var index; model._trackItems) {
            var pos = me._convertLatLonToPixel(model, index, centerTileOffset);

            if (    pos.x < edgeTiles.maxX
                and pos.y < edgeTiles.maxY
                and pos.x > edgeTiles.minX
                and pos.y > edgeTiles.minY
            ) {
                # The path point is on the map, add it to me._pointsToDraw vector to use for click action
                me._pointsToDraw.append(pos);
            }

            if (index == me._refPosition) {
                # Take a reference point when drawing the full flight path
                refPos = pos;
            }

            if (index == model._position) {
                # Take current aircraft position point to calculate translation
                currentPos = pos;
            }
        }

        if (refPos != nil and currentPos != nil) {
            var scale = math.pow(2, model._zoom - me._refZoom);

            me._flightPath
                .setStrokeLineWidth(me._FLIGHT_LINE_WIDTH / scale)
                .setScale(scale)
                .setTranslation(
                    (refPos.x - currentPos.x) - (gui.widgets.FlightMap.TILE_SIZE * centerTileOffset.x * (scale - 1)),
                    (refPos.y - currentPos.y) - (gui.widgets.FlightMap.TILE_SIZE * centerTileOffset.y * (scale - 1)),
                );
        }
    },

    #
    # Get the maximum and minimum X and Y values ​​in pixels of the outermost tiles,
    # taking into account the buffer based on zoom
    #
    # @param  ghost  model  FlightMap model object
    # @param  hash  tileBoundaries
    # @return hash
    #
    _getTileThresholds: func(model, tileBoundaries) {
        var tileSizeBuffer = me._getTileSizeBuffer(model);

        return {
            maxX: tileBoundaries.max.x + tileSizeBuffer + gui.widgets.FlightMap.TILE_SIZE,
            maxY: tileBoundaries.max.y + tileSizeBuffer + gui.widgets.FlightMap.TILE_SIZE,
            minX: tileBoundaries.min.x - tileSizeBuffer,
            minY: tileBoundaries.min.y - tileSizeBuffer,
        };
    },

    #
    # Return an additional buffer to determine if the path point is in the field of view.
    # The buffer will cause the points that are not in the field of view to be added as well,
    # but it is good to drag the line to the edge of the view. And the larger the zoom,
    # the more buffer we need, because the points are more distant from each other.
    # TODO: for better adjustment it would be necessary to know the frequency with which waypoints were generated.
    #
    # @param  model  ghost  FlightMap model object
    # @return int
    #
    _getTileSizeBuffer: func(model) {
        return model._zoom >= 8
            ? 3 * math.pow(2, model._zoom - 8)
            : 0;
    },

    #
    # Convert given lan, lot to pixel position on the window
    #
    # @param  ghost  model  FlightMap model object
    # @param  int  index  Index of track item which lat, lon will be converted to pixel
    # @param  hash  centerTileOffset
    # @return hash  Hash as pixel position with x and y
    #
    _convertLatLonToPixel: func(model, index, centerTileOffset) {
        # Get lat, lon to convert to pixel
        var targetPoint = model._trackItems[index];

        # Get lat, lon of current aircraft position
        var centerPoint = model._trackItems[model._position];

        var x = me._lonToX(targetPoint.lon, model._zoom);
        var y = me._latToY(targetPoint.lat, model._zoom);

        var centerX = me._lonToX(centerPoint.lon, model._zoom);
        var centerY = me._latToY(centerPoint.lat, model._zoom);

        # Offset from the center of the map
        var pixelX = x - centerX + gui.widgets.FlightMap.TILE_SIZE * centerTileOffset.x;
        var pixelY = y - centerY + gui.widgets.FlightMap.TILE_SIZE * centerTileOffset.y;

        return {
            x: pixelX,
            y: pixelY,
            position: index,
        };
    },

    #
    # Convert given longitude to X position
    #
    # @param  double  lon  Longitude to convert to X position
    # @param  int  zoom  Current zoom level of map
    # @return double  The X position
    #
    _lonToX: func(lon, zoom) {
        var scale = gui.widgets.FlightMap.TILE_SIZE * math.pow(2, zoom);
        return (lon + 180) / 360 * scale;
    },

    #
    # Convert given latitude to Y position
    #
    # @param  double  lat  Latitude to convert to Y position
    # @param  int  zoom  Current zoom level of map
    # @return double  The Y position
    #
    _latToY: func(lat, zoom) {
        var scale = gui.widgets.FlightMap.TILE_SIZE * math.pow(2, zoom);
        var sinLat = math.sin(lat * globals.D2R);
        return (0.5 - math.ln((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    },

    #
    # @return vector
    #
    getPointsToDraw: func {
        return me._pointsToDraw.vector;
    },
};
