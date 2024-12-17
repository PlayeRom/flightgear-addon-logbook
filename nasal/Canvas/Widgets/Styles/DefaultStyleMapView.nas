#
# MapView widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# MapView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# MapView widget View
#
DefaultStyle.widgets["map-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "map-view");

        me._content = me._root.createChild("group", "clip-content")
            .set("clip-frame", Element.PARENT);

        me._textColor = me._style.getColor("fg_color");
        me._bgColor   = me._style.getColor("bg_color");

        # Variables for map
        me._TILE_SIZE = 256;

        me._numTiles         = { x:  6, y:  4 };
        me._centerTileOffset = { x:  0, y:  0 };
        me._lastTile         = { x: -1, y: -1 };

        me._FLIGHT_LINE_WIDTH = 2;
        me._isFlightPathRendered = 0;
        me._flightPath = nil;
        me._tiles = [];

        # A variable to remember the extreme positions of the map tiles,
        # which we will use to not draw the flight path outside the map
        me._minTile = { x: 0, y: 0 };
        me._maxTile = { x: 0, y: 0 };

        me._pointsToDraw = std.Vector.new();
        me._isClickEventSet = 0;

        me._refPosition = 0;
        me._refZoom = gui.widgets.MapView.ZOOM_DEFAULT;

        me._lastSize = { w: nil, h: nil };

        me._zoomLabel = nil;

        me._isReDrew = 0;

        me._planeIcon = PlaneIconMap.new();
        me._windBarbs = WindBarbs.new();
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  MapView model
    # @param  int w, h  Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        if (me._lastSize.w != w or me._lastSize.h != h) {
            me.reDrawContent(model);
        }

        me._lastSize.w = w;
        me._lastSize.h = h;

        return me;
    },

    #
    # @param  ghost  model  MapView model
    # @return void
    #
    update: func(model) {
        me._content.set("clip", "rect(0, " ~ model._size[0] ~ ", " ~ model._size[1] ~ ", 0)");
    },

    #
    # @param  ghost  model  MapView model
    # @return void
    #
    reDrawContent: func(model) {
        me._content.removeAllChildren();

        if (model._trackItems == nil or model._trackItemsSize == 0) {
            me._createText(
                x        : int(model._size[0] / 2),
                y        : int(model._size[1] / 2),
                label    : "This log doesn't contain flight data.",
                alignment: "center-center"
            );

            return;
        }

        me._isReDrew = 1;

        me._addEvents(model);

        me._planeIcon.create(me._content);

        me._flightPath = me._content.createChild("path", "flight")
            .setColor(0.5, 0.5, 1)
            .setStrokeLineWidth(me._FLIGHT_LINE_WIDTH)
            .set("z-index", 1);

        me._isFlightPathRendered = 0;

        me._calculateNumTiles(model);

        me._centerTileOffset.x = (me._numTiles.x - 1) / 2;
        me._centerTileOffset.y = (me._numTiles.y - 1) / 2;

        # Reset values
        me._lastTile.x = -1;
        me._lastTile.y = -1;

        me._createTiles(model);

        me._windBarbs.create(me._content);

        me._zoomLabel = me._createText(
            x       : 20,
            y       : 25,
            label   : "Zoom " ~ model._zoom,
            fontSize: 14,
            font    : "LiberationFonts/LiberationSans-Regular.ttf",
            color   : [0.0, 0.0, 0.0],
        );

        me.updateTiles(model);
    },

    #
    # Add mouse events to map view
    #
    # @param  ghost  model  MapView model
    # @return void
    #
    _addEvents: func(model) {
        if (me._isClickEventSet) {
            # Events should be added only once, otherwise they will be called multiple times
            return;
        }

        me._isClickEventSet = 1;

        me._content.addEventListener("click", func(e) {
            # Find the path point closest to the click
            var minDistance = nil;
            var position = nil;
            var distance = 0;
            foreach (var point; me._pointsToDraw.vector) {
                distance = me._getDistance({ x: e.localX, y: e.localY }, { x: point.x, y: point.y });

                if (distance < 50 # <- ignore points further than 50 px
                    and (minDistance == nil or distance < minDistance)
                ) {
                    minDistance = distance;
                    position = point.position;
                }
            }

            if (position != nil) {
                model.setTrackPosition(position);
                model._updatePosition();
            }
        });

        # Zoom map by scroll wheel
        me._content.addEventListener("wheel", func(e) {
            # e.deltaY = 1 or -1
            model._changeZoom(e.deltaY);
            model._updateZoom();

            me.updateTiles(model);
        });
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
    # Calculate how many tiles you need in width and height depending on the widget size
    #
    _calculateNumTiles: func(model) {
        me._numTiles.x = math.ceil(model._size[0] / me._TILE_SIZE) + 1;
        me._numTiles.y = math.ceil(model._size[1] / me._TILE_SIZE) + 1;
    },

    #
    # Initialize the map by setting up a grid of raster images
    #
    _createTiles: func(model) {
        me._tiles = setsize([], me._numTiles.x);

        for (var x = 0; x < me._numTiles.x; x += 1) {
            me._tiles[x] = setsize([], me._numTiles.y);

            for (var y = 0; y < me._numTiles.y; y += 1) {
                me._tiles[x][y] = me._content.createChild("image", "map-tile")
                    .setColorFill(model._colorFill);
            }
        }
    },

    #
    # @param  int  x, y
    # @param  string  label
    # @param  string  alignment
    # @param  int  fontSize
    # @param  string  font  Font file name
    # @param  vector|nil  color  Text color
    # @return ghost  Text element
    #
    _createText: func(x, y, label, alignment = "left-baseline", fontSize = 12, font = "LiberationFonts/LiberationMono-Regular.ttf", color = nil) {
        return me._content.createChild("text")
            .setTranslation(x, y)
            .setText(label)
            .setAlignment(alignment)
            .setFontSize(fontSize)
            .setFont(font)
            .setColor(color == nil ? me._textColor : color)
            .setColorFill(me._bgColor);
    },

    #
    # This is the callback that will be regularly called by the timer to update the map
    #
    # @param  ghost  model  MapView model
    # @param  bool  forceSetTile
    # @return void
    #
    updateTiles: func(model, forceSetTile = 0) {
        if (model._trackItems == nil or model._trackItemsSize == 0) {
            return;
        }

        if (!me._isReDrew) {
            # First must be call reDrawContent for create objects to draw
            me.reDrawContent(model);
            return;
        }

        me._zoomLabel.setText("Zoom " ~ model._zoom);

        var track = model._trackItems[model._position];

        me._planeIcon.draw(track.heading_true, me._TILE_SIZE, me._centerTileOffset);
        me._windBarbs.draw(model, track.wind_heading, track.wind_speed);

        me._minTile.x = 0;
        me._minTile.y = 0;
        me._maxTile.x = 0;
        me._maxTile.y = 0;

        # Get current position
        var lat = track.lat;
        var lon = track.lon;

        var scale = math.pow(2, model._zoom);
        var offset = {
            x: scale * ((lon + 180) / 360) - me._centerTileOffset.x,
            y: (1 - math.ln(math.tan(lat * math.pi / 180) + 1 / math.cos(lat * math.pi / 180)) / math.pi) / 2 * scale - me._centerTileOffset.y,
        };

        var tileIndex = {
            x: int(offset.x),
            y: int(offset.y),
        };

        var ox = tileIndex.x - offset.x;
        var oy = tileIndex.y - offset.y;

        for (var x = 0; x < me._numTiles.x; x += 1) {
            for (var y = 0; y < me._numTiles.y; y += 1) {
                var trans = {
                    x: int((ox + x) * me._TILE_SIZE + 0.5),
                    y: int((oy + y) * me._TILE_SIZE + 0.5),
                };

                me._tiles[x][y].setTranslation(trans.x, trans.y);

                # Remember the extreme positions of map tiles
                if (trans.x > me._maxTile.x) {
                    me._maxTile.x = trans.x;
                }

                if (trans.x < me._minTile.x) {
                    me._minTile.x = trans.x;
                }

                if (trans.y > me._maxTile.y) {
                    me._maxTile.y = trans.y;
                }

                if (trans.y < me._minTile.y) {
                    me._minTile.y = trans.y;
                }

                # Update tiles if needed
                if (   tileIndex.x != me._lastTile.x
                    or tileIndex.y != me._lastTile.y
                    or forceSetTile
                ) {
                    var pos = {
                        z: model._zoom,
                        x: int(offset.x + x),
                        y: int(offset.y + y),
                    };

                    (func {
                        var imgPath = model._makePath(pos);
                        var tile = me._tiles[x][y];

                        if (io.stat(imgPath) == nil) {
                            # image not found in cache, save in $FG_HOME
                            var imgUrl = model._makeUrl(pos);

                            # logprint(LOG_INFO, 'MapView Widget - requesting ', imgUrl);

                            http.save(imgUrl, imgPath)
                                .done(func {
                                    # logprint(LOG_INFO, 'MapView Widget - received image ', imgPath);
                                    tile.set("src", imgPath);
                                })
                                .fail(func(response) {
                                    logprint(LOG_ALERT, 'MapView Widget - failed to get image ', imgPath, ' ', response.status, ': ', response.reason);
                                });
                        }
                        else { # cached image found, reusing
                            # logprint(LOG_INFO, 'MapView Widget - loading ', imgPath);
                            tile.set("src", imgPath);
                        }
                    })();
                }
            }
        }

        me._lastTile.x = tileIndex.x;
        me._lastTile.y = tileIndex.y;

        if (model._isLiveUpdateMode) {
            me._drawFlightPathInLiveMode(model);
        }
        else {
            # Render 7x faster with once-drawn and next path transformation
            me._isFlightPathRendered
                ? me._transformFlightPath(model)
                : me._drawFullFlightPath(model);
        }
    },

    #
    # Redraw flight path in live mode, for current flight analysis.
    #
    # @param  ghost  model  MapView model
    # @return ghost  Path element
    #
    _drawFlightPathInLiveMode: func(model) {
        me._pointsToDraw.clear();
        me._flightPath.reset();

        var edgeTiles = me._getTileThresholds(model);

        # = true because the first point must start with moveTo method
        var discontinuity = 1;

        # The first loop is to build an array of points that are within the map
        forindex (var index; model._trackItems) {
            var pos = me._convertLatLonToPixel(model, index);

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
    # @param  ghost  model  MapView model
    # @return ghost  Path element
    #
    _drawFullFlightPath: func(model) {
        # me._flightPath.reset();

        # Set the reference position and zoom to the values ​​we have during full drawing.
        # These values ​​will be needed to perform the flight path transformation.
        me._refPosition = model._position;
        me._refZoom     = model._zoom;

        var edgeTiles = me._getTileThresholds(model);

        # The loop to build an array of points that are within the map view and draw flight path
        me._pointsToDraw.clear();
        forindex (var index; model._trackItems) {
            var pos = me._convertLatLonToPixel(model, index);

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
    # @param  ghost  model
    # @return void
    #
    _transformFlightPath: func(model) {
        me._pointsToDraw.clear();

        var edgeTiles = me._getTileThresholds(model);

        var refPos = nil;
        var currentPos = nil;

        # Generate a new vector with points visible on the map
        forindex (var index; model._trackItems) {
            var pos = me._convertLatLonToPixel(model, index);

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
                    (refPos.x - currentPos.x) - (me._TILE_SIZE * me._centerTileOffset.x * (scale - 1)),
                    (refPos.y - currentPos.y) - (me._TILE_SIZE * me._centerTileOffset.y * (scale - 1)),
                );
        }
    },

    #
    # Get the maximum and minimum X and Y values ​​in pixels of the outermost tiles,
    # taking into account the buffer based on zoom
    #
    # @param  ghost  model
    # @return hash
    #
    _getTileThresholds: func(model) {
        var tileSizeBuffer = me._getTileSizeBuffer(model);

        return {
            maxX: me._maxTile.x + tileSizeBuffer + me._TILE_SIZE,
            maxY: me._maxTile.y + tileSizeBuffer + me._TILE_SIZE,
            minX: me._minTile.x - tileSizeBuffer,
            minY: me._minTile.y - tileSizeBuffer,
        };
    },

    #
    # Return an additional buffer to determine if the path point is in the field of view.
    # The buffer will cause the points that are not in the field of view to be added as well,
    # but it is good to drag the line to the edge of the view. And the larger the zoom,
    # the more buffer we need, because the points are more distant from each other.
    # TODO: for better adjustment it would be necessary to know the frequency with which waypoints were generated.
    #
    # @param  model  ghost  MapView model object
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
    # @param  ghost  model  MapView model
    # @param  int  index  Index of track item which lat, lon will be converted to pixel
    # @return hash  Hash as pixel position with x and y
    #
    _convertLatLonToPixel: func(model, index) {
        # Get lat, lon to convert to pixel
        var targetPoint = model._trackItems[index];

        # Get lat, lon of current aircraft position
        var centerPoint = model._trackItems[model._position];

        var x = me._lonToX(targetPoint.lon, model._zoom);
        var y = me._latToY(targetPoint.lat, model._zoom);

        var centerX = me._lonToX(centerPoint.lon, model._zoom);
        var centerY = me._latToY(centerPoint.lat, model._zoom);

        # Offset from the center of the map
        var pixelX = x - centerX + me._TILE_SIZE * me._centerTileOffset.x;
        var pixelY = y - centerY + me._TILE_SIZE * me._centerTileOffset.y;

        return { x: pixelX, y: pixelY, position: index };
    },

    #
    # Convert given longitude to X position
    #
    # @param  double  lon  Longitude to convert to X position
    # @param  int  zoom  Current zoom level of map
    # @return double  The X position
    #
    _lonToX: func(lon, zoom) {
        var scale = me._TILE_SIZE * math.pow(2, zoom);
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
        var scale = me._TILE_SIZE * math.pow(2, zoom);
        var sinLat = math.sin(lat * math.pi / 180);
        return (0.5 - math.ln((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    },

    #
    # Draw an invisible line to get the padding. It is needed when MapView is drawn inside ScrollArea.
    #
    # @param  ghost  model  MapView model
    # @return ghost  Path element
    #
    _drawPaddingKeeper: func(model) {
        me._content.createChild("path", "padding-keeper")
            .moveTo(0, 0)
            .horiz(model._size[0])
            .setColor(0, 0, 0, 0)
            .setStrokeLineWidth(1);
    },
};

#
# Class for drawing a plane icon
#
var PlaneIconMap = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        return {
            parents: [PlaneIconMap],
            _svgImg: nil,
            _width : 0,
            _height: 0,
        };
    },

    #
    # Create SVG plane image
    #
    # @param  ghost  context
    # @return void
    #
    create: func(context) {
        me._svgImg = context.createChild("group").set("z-index", 2);
        canvas.parsesvg(me._svgImg, "Textures/plane-top.svg");

        (me._width, me._height) = me._svgImg.getSize();
    },

    #
    # Draw plane from SVG file at center of the map
    #
    # @param  double  heading
    # @param  int  tileSize
    # @param  hash  centerTileOffset
    # @return void
    #
    draw: func(heading, tileSize, centerTileOffset) {
        var headingInRad = heading * globals.D2R;
        var offset = me._getRotationOffset(me._width, me._height, headingInRad);

        me._svgImg.setRotation(headingInRad);
        me._svgImg.setTranslation(
            tileSize * centerTileOffset.x - (me._width  / 2) + offset.dx,
            tileSize * centerTileOffset.y - (me._height / 2) + offset.dy
        );
    },

    #
    # Calculate offset for rotation because the image rotation point is in the upper left corner
    #
    # @param  double  width  Image width
    # @param  double  height  Image height
    # @param  double  angleInRadians
    # @return hash  Hash with delta X and delta Y
    #
    _getRotationOffset: func(width, height, angleInRadians) {
        var deltaX = -(width / 2) * (math.cos(angleInRadians) - 1) + (height / 2) *  math.sin(angleInRadians);
        var deltaY = -(width / 2) *  math.sin(angleInRadians)      - (height / 2) * (math.cos(angleInRadians) - 1);

        return { dx: deltaX, dy: deltaY };
    },
};

#
# Class for drawing a wind indicator
#
var WindBarbs = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [WindBarbs] };

        me._LENGTH          = 50;
        me._MARGIN          = 10;
        me._WIND_LINE_WIDTH = 2;

        me._windPath = nil;

        me._windBarbRules = me._createBarbRules();

        return me;
    },

    #
    # Return barbs at a given speed
    # Barbs are marked by three numbers 5 (short barb), 10 (long barb), 50 (flag).
    #
    # @return vector
    #
    _createBarbRules: func() {
        return [
            { speed:   1, barbs: [] },                       #  1-2  kt: no barb
            { speed:   2, barbs: [5] },                      #  2-7  kt: 1 short
            { speed:   7, barbs: [10] },                     #  7-12 kt: 1 long
            { speed:  12, barbs: [10, 5] },                  # 12-17 kt: 1 long + short
            { speed:  17, barbs: [10, 10] },                 # 17-22 kt: 2 long
            { speed:  22, barbs: [10, 10, 5] },              # 22-27 kt: 2 long + short
            { speed:  27, barbs: [10, 10, 10] },             # 27-32 kt: 3 long
            { speed:  32, barbs: [10, 10, 10, 5] },          # 32-37 kt: 3 long + short
            { speed:  37, barbs: [10, 10, 10, 10] },         # 37-42 kt: 4 long
            { speed:  42, barbs: [10, 10, 10, 10, 5] },      # 42-47 kt: 4 long + short
            { speed:  47, barbs: [50] },                     # 47-52 kt: 1 flag
            { speed:  52, barbs: [50, 5] },                  # 52-57 kt: 1 flag + short
            { speed:  57, barbs: [50, 10] },                 # 57-62 kt: 1 flag + long
            { speed:  62, barbs: [50, 10, 5] },              # 62-67 kt: 1 flag + long + short
            { speed:  67, barbs: [50, 10, 10] },             # 67-72 kt: 1 flag + 2 long
            { speed:  72, barbs: [50, 10, 10, 5] },          # etc.
            { speed:  77, barbs: [50, 10, 10, 10] },
            { speed:  82, barbs: [50, 10, 10, 10, 5] },
            { speed:  87, barbs: [50, 10, 10, 10, 10] },
            { speed:  92, barbs: [50, 10, 10, 10, 10, 5] },
            { speed:  97, barbs: [50, 50] },
            { speed: 102, barbs: [50, 50, 5] },
            { speed: 107, barbs: [50, 50, 10] },
            { speed: 112, barbs: [50, 50, 10, 5] },
            { speed: 117, barbs: [50, 50, 10, 10] },
            { speed: 122, barbs: [50, 50, 10, 10, 5] },
            { speed: 127, barbs: [50, 50, 10, 10, 10] },
            { speed: 132, barbs: [50, 50, 10, 10, 10, 5] },
            { speed: 137, barbs: [50, 50, 10, 10, 10, 10] },
            { speed: 142, barbs: [50, 50, 10, 10, 10, 10, 5] },
            { speed: 147, barbs: [50, 50, 50] },
        ];
    },

    #
    # @param  ghost  context
    # @return void
    #
    create: func(context) {
        me._windPath = context.createChild("path", "wind")
            .setColor(0.0, 0.0, 0.0)
            .setStrokeLineWidth(me._WIND_LINE_WIDTH);
    },

    #
    # @param  ghost  model  MapView model
    # @param  double  windHeading
    # @param  double  windSpeed
    # @return void
    #
    draw: func(model, windHeading, windSpeed) {
        me._windPath.reset();

        var (width, height) = model._size;

        var center = {
            x: width - (me._LENGTH + me._MARGIN),
            y:          me._LENGTH + me._MARGIN,
        };

        if (windSpeed < 1) { # calm (draw circles)
            # TODO: We don't want a fill color here and it would be best to turn it off,
            # but alpha 0.0 works like 1.0, so I set it to the lowest possible
            me._windPath.setColorFill(1.0, 1.0, 1.0, 0.0022);

            me._windPath.circle( 7);
            me._windPath.circle(10);
        }
        else { # draw vector of wind
            # Set fill color for flag barb
            me._windPath.setColorFill(0.0, 0.0, 0.0, 1.0);

            var halfLength = me._LENGTH / 2;

            # We draw a vertical line in the local coordinate system (directly relative to the center)
            me._windPath.moveTo(0,  halfLength);
            me._windPath.lineTo(0, -halfLength); # draw vertical line to up

            var barbRule = me._findWindBarbRule(windSpeed);
            if (barbRule != nil) {
                var y = -halfLength; # Set y to end of wind vector
                foreach (var barb; barbRule) {
                    if (barb == 5) {
                        if (y == -halfLength) {
                            # This is first short which need offset
                            y += 5;
                        }

                        me._shortBarb(y);
                        y += 5;
                    }
                    else if (barb == 10) {
                        me._longBarb(y);
                        y += 5;
                    }
                    else if (barb == 50) {
                        me._flagBarb(y);
                        y += 10;
                    }
                };
            }

            # We set the path rotation relative to the center (0,0) - local coordinates
            me._windPath.setRotation(windHeading * globals.D2R);
        }

        # We move the path to the global center
        me._windPath.setTranslation(center.x, center.y);
    },

    #
    # Return vector with barbs according to given wind speed in knots
    #
    # @param  double  windSpeed
    # @return vector|nil
    #
    _findWindBarbRule: func(windSpeed) {
        for (var i = size(me._windBarbRules) - 1; i >= 0; i -= 1) {
            if (windSpeed >= me._windBarbRules[i].speed) {
                return me._windBarbRules[i].barbs;
            }
        }

        return nil;
    },

    #
    # Draw short (5 kt) wind barb line
    #
    # @param  int  y
    # @return void
    #
    _shortBarb: func(y) {
        me._windPath.moveTo(0, y);
        me._windPath.lineTo(5, y); # 5 px length of short barb
    },

    #
    # Draw long (10 kt) wind barb line
    #
    # @param  int  y
    # @return void
    #
    _longBarb: func(y) {
        me._windPath.moveTo( 0, y);
        me._windPath.lineTo(10, y);  # 10 px length of long barb
    },

    #
    # Draw flag (50 kt) wind barb
    #
    # @param  int  y
    # @return void
    #
    _flagBarb: func(y) {
        me._windPath.moveTo( 0, y);
        me._windPath.lineTo(10, y + 3.5); # 10 px height of flag
        me._windPath.lineTo( 0, y + 7);
    },
};
