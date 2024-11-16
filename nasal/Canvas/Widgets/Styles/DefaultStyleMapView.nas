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
# MapView widget View
#
DefaultStyle.widgets["map-view"] = {
    #
    # Constants
    #
    TILE_SIZE: 256,
    #
    # If true, then the path drawing method has two steps. First, the first loop will check which path points are in
    # the map's field of view. The second loop will draw only those selected points.
    # Advantages: reduces the number of points to draw (the more zoomed out, the less it matters). Disadvantages: less
    # efficient path drawing because it has two loops (the more zoomed in, the less it matters).
    # If false, all route points will be drawn in one loop.
    # At first I used CULL_PATH = true because the MapView widget was embedded in ScrollArea, which caused the user to
    # scroll far the entire path outside the map. So to prevent this I culled the points that would be outside the map.
    # Now I use clip-frame, which clips the map, path and other elements to a rectangle defined by the size of the widget.
    # So using CULL_PATH loses its meaning.
    #
    CULL_PATH: false,

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

        # Variables for map
        var mapsBase = getprop("/sim/fg-home") ~ '/cache/maps';
        me._makeUrl  = string.compileTemplate('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
        me._makePath = string.compileTemplate(mapsBase ~ '/osm-cache/{z}/{x}/{y}.png');

        me._numTiles = { x: 6, y: 4 };
        me._centerTileOffset = { x: 0, y: 0 };
        me._lastTile = { x: -1, y: -1 };

        me._flightPath = nil;
        me._tiles = [];

        # A variable to remember the extreme positions of the map tiles,
        # which we will use to not draw the flight path outside the map
        me._minTile = { x: 0, y: 0 };
        me._maxTile = { x: 0, y: 0 };

        me._pointsToDraw = std.Vector.new();
        me._isClickEventSet = false;

        me._svgPlane = nil;
        me._planeIconWidth  = 0;
        me._planeIconHeight = 0;

        me._lastSize = { w: nil, h: nil };
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

        if (model._tractItems == nil or model._trackItemsSize == 0) {
            me._createText(
                int(model._size[0] / 2),
                int(model._size[1] / 2),
                "This log doesn't contain flight data.",
                "center-center"
            );

            return;
        }

        if (!me._isClickEventSet) {
            me._isClickEventSet = true;

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
        }

        me._createPlaneIcon();

        me._flightPath = me._content.createChild("path", "flight")
            .setColor(0.5, 0.5, 1)
            .setStrokeLineWidth(2)
            .set("z-index", 1);

        me._calculateNumTiles(model);

        me._centerTileOffset.x = (me._numTiles.x - 1) / 2;
        me._centerTileOffset.y = (me._numTiles.y - 1) / 2;

        # Reset values
        me._lastTile.x = -1;
        me._lastTile.y = -1;

        me._createTiles();

        me.updateTiles(model);
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
        me._numTiles.x = math.ceil(model._size[0] / DefaultStyle.widgets["map-view"].TILE_SIZE) + 1;
        me._numTiles.y = math.ceil(model._size[1] / DefaultStyle.widgets["map-view"].TILE_SIZE) + 1;
    },

    #
    # Initialize the map by setting up a grid of raster images
    #
    _createTiles: func() {
        me._tiles = setsize([], me._numTiles.x);

        for (var x = 0; x < me._numTiles.x; x += 1) {
            me._tiles[x] = setsize([], me._numTiles.y);

            for (var y = 0; y < me._numTiles.y; y += 1) {
                me._tiles[x][y] = me._content.createChild("image", "map-tile");
            }
        }
    },

    #
    # Create SVG plane image
    #
    _createPlaneIcon: func() {
        me._svgPlane = me._content.createChild("group").set("z-index", 2);
        canvas.parsesvg(me._svgPlane, "Textures/plane-top.svg");

        me._planeIconWidth  = me._svgPlane.getSize()[0];
        me._planeIconHeight = me._svgPlane.getSize()[1];
    },

    #
    # Draw plane from SVG file at center of the map
    #
    # @param  double  heading
    # @return void
    #
    _drawPlaneIcon: func(heading) {
        var headingInRad = heading * globals.D2R;
        var offset = me._getRotationOffset(me._planeIconWidth, me._planeIconHeight, headingInRad);

        me._svgPlane.setRotation(headingInRad);
        me._svgPlane.setTranslation(
            DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset.x - (me._planeIconWidth  / 2) + offset.dx,
            DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset.y - (me._planeIconHeight / 2) + offset.dy
        );
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
    # @param  int  x, y
    # @param  string  text
    # @param  string  alignment
    # @return ghost  Text element
    #
    _createText: func(x, y, text, alignment = "left-baseline") {
        return me._content.createChild("text")
            .setFont("LiberationFonts/LiberationMono-Regular.ttf")
            .setFontSize(12)
            .setAlignment(alignment)
            .setTranslation(x, y)
            .setColor(me._textColor)
            .setText(text);
    },

    #
    # This is the callback that will be regularly called by the timer to update the map
    #
    # @param  ghost  model  MapView model
    # @return void
    #
    updateTiles: func(model) {
        if (model._tractItems == nil or model._trackItemsSize == 0) {
            return;
        }

        var track = model._tractItems[model._position];

        me._drawPlaneIcon(track.heading_true);

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
                    x: int((ox + x) * DefaultStyle.widgets["map-view"].TILE_SIZE + 0.5),
                    y: int((oy + y) * DefaultStyle.widgets["map-view"].TILE_SIZE + 0.5),
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
                ) {
                    var pos = {
                        z: model._zoom,
                        x: int(offset.x + x),
                        y: int(offset.y + y),
                    };

                    (func {
                        var imgPath = me._makePath(pos);
                        var tile = me._tiles[x][y];

                        if (io.stat(imgPath) == nil) {
                            # image not found in cache, save in $FG_HOME
                            var imgUrl = me._makeUrl(pos);

                            # logprint(LOG_INFO, 'Logbook Add-on - requesting ', imgUrl);

                            http.save(imgUrl, imgPath)
                                .done(func {
                                    # logprint(LOG_INFO, 'Logbook Add-on - received image ', imgPath);
                                    tile.set("src", imgPath);
                                })
                                .fail(func(response) {
                                    logprint(LOG_ALERT, 'Logbook Add-on - failed to get image ', imgPath, ' ', response.status, ': ', response.reason);
                                });
                        }
                        else { # cached image found, reusing
                            # logprint(LOG_INFO, 'Logbook Add-on - loading ', imgPath);
                            tile.set("src", imgPath);
                        }
                    })();
                }
            }
        }

        me._lastTile.x = tileIndex.x;
        me._lastTile.y = tileIndex.y;

        me._drawFlightPath(model);
    },

    #
    # Redraw flight path. We have to redraw if zoom was changed
    #
    # @param  ghost  model  MapView model
    # @return ghost  Path element
    #
    _drawFlightPath: func(model) {
        if (DefaultStyle.widgets["map-view"].CULL_PATH) {
            me._pointsToDraw.clear();

            # = true because the first point must start with moveTo method
            var isBreak = true;

            # The first loop is to build an array of points that are within the map
            forindex (var index; model._tractItems) {
                var pos = me._convertLatLonToPixel(model, index);

                if (   pos.x > me._maxTile.x + DefaultStyle.widgets["map-view"].TILE_SIZE
                    or pos.y > me._maxTile.y + DefaultStyle.widgets["map-view"].TILE_SIZE
                    or pos.x < me._minTile.x
                    or pos.y < me._minTile.y
                ) {
                    # The path point is out of map tiles, so ship it
                    isBreak = true;
                }
                else {
                    # When there was a discontinuity, we need to start drawing with the moveTo function,
                    # so we set the moveTo flag which will tell us that
                    pos["moveTo"] = isBreak;
                    pos["position"] = index;
                    isBreak = false;
                    me._pointsToDraw.append(pos);
                }
            }

            # Draw points only those within the map
            me._flightPath.reset();

            foreach (var point; me._pointsToDraw.vector) {
                if (point.moveTo) {
                    me._flightPath.moveTo(point.x, point.y);
                }
                else {
                    me._flightPath.lineTo(point.x, point.y);
                }
            }
        }
        else {
            me._pointsToDraw.clear();
            me._flightPath.reset();

            forindex (var index; model._tractItems) {
                var pos = me._convertLatLonToPixel(model, index);

                if (    pos.x < me._maxTile.x + DefaultStyle.widgets["map-view"].TILE_SIZE
                    and pos.y < me._maxTile.y + DefaultStyle.widgets["map-view"].TILE_SIZE
                    and pos.x > me._minTile.x
                    and pos.y > me._minTile.y
                ) {
                    # The path point is on the map, add it to me._pointsToDraw vector to use for click action
                    me._pointsToDraw.append(pos);
                }

                index == 0
                    ? me._flightPath.moveTo(pos.x, pos.y)
                    : me._flightPath.lineTo(pos.x, pos.y);
            }
        }
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
        var targetPoint = model._tractItems[index];

        # Get lat, lon of current aircraft position
        var centerPoint = model._tractItems[model._position];

        var x = me._lonToX(targetPoint.lon, model._zoom);
        var y = me._latToY(targetPoint.lat, model._zoom);

        var centerX = me._lonToX(centerPoint.lon, model._zoom);
        var centerY = me._latToY(centerPoint.lat, model._zoom);

        # Offset from the center of the map
        var pixelX = x - centerX + DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset.x;
        var pixelY = y - centerY + DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset.y;

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
        var scale = DefaultStyle.widgets["map-view"].TILE_SIZE * math.pow(2, zoom);
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
        var scale = DefaultStyle.widgets["map-view"].TILE_SIZE * math.pow(2, zoom);
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

