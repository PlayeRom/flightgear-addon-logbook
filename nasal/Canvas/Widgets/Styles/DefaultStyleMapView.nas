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
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "map-view");

        me._textColor = me._style.getColor("fg_color");

        # Variables for map
        me._mapsBase = getprop("/sim/fg-home") ~ '/cache/maps';
        me._makeUrl = string.compileTemplate('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
        me._makePath = string.compileTemplate(me._mapsBase ~ '/osm-cache/{z}/{x}/{y}.png');

        me._numTiles = [6, 4];

        me._centerTileOffset = [
            (me._numTiles[0] - 1) / 2,
            (me._numTiles[1] - 1) / 2,
        ];

        me._lastTile = [-1, -1];

        me._flightPathGroup = nil;
        me._tiles = [];

        # A variable to remember the extreme positions of the map tiles,
        # which we will use to not draw the flight path outside the map
        me._minTileX = 0;
        me._maxTileX = 0;
        me._minTileY = 0;
        me._maxTileY = 0;
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  MapView model
    # @param  int w, h  Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        # me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  MapView model
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  MapView model
    # @return void
    #
    reDrawContent: func(model) {
        me._root.removeAllChildren();

        if (model._tractItems == nil or size(model._tractItems) == 0) {
            me._drawPaddingKeeper(model);

            me._createText(
                int(model._size[0] / 2),
                int(model._size[1] / 2),
                "This log doesn't contain flight data.",
                "center-center"
            );
        }
        else {
            me._flightPathGroup = me._root.createChild("group")
                .set("z-index", 1);

            me._createTiles();

            me._drawAircraft();

            me.updateTiles(model);
        }
    },

    #
    # Initialize the map by setting up a grid of raster images
    #
    _createTiles: func() {
        me._tiles = setsize([], me._numTiles[0]);

        for (var x = 0; x < me._numTiles[0]; x += 1) {
            me._tiles[x] = setsize([], me._numTiles[1]);

            for (var y = 0; y < me._numTiles[1]; y += 1) {
                me._tiles[x][y] = me._root.createChild("image", "map-tile");
            }
        }
    },

    #
    # Simple aircraft icon at current position/center of the map
    #
    _drawAircraft: func() {
        me._root.createChild("path")
            .moveTo(
                DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset[0] - 10,
                DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset[1]
            )
            .horiz(20)
            .move(-10, -10)
            .vert(20)
            .set("stroke", "red")
            .set("stroke-width", 3)
            .set("z-index", 2);
    },

    #
    # @param  int  x, y
    # @param  string  text
    # @param  string  alignment
    # @return ghost  Text element
    #
    _createText: func(x, y, text, alignment = "left-baseline") {
        return me._root.createChild("text")
            .setFont("LiberationFonts/LiberationMono-Regular.ttf")
            .setFontSize(12)
            .setAlignment(alignment)
            .setTranslation(x, y)
            .setColor(me._textColor)
            .setText(text);
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
    # Convert given lan, lot to pixel position on the window
    #
    # @param  double  lat  Latitude to convert to pixel
    # @param  double  lon  Longitude to convert to pixel
    # @param  double  centerLat  Latitude of current aircraft position
    # @param  double  centerLon  Longitude of current aircraft position
    # @param  int  zoom  Current zoom level of map
    # @return hash  Hash as pixel position with x and y
    #
    _convertLatLonToPixel: func(lat, lon, centerLat, centerLon, zoom) {
        var x = me._lonToX(lon, zoom);
        var y = me._latToY(lat, zoom);

        var centerX = me._lonToX(centerLon, zoom);
        var centerY = me._latToY(centerLat, zoom);

        # Offset from the center of the map
        var pixelX = x - centerX + DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset[0];
        var pixelY = y - centerY + DefaultStyle.widgets["map-view"].TILE_SIZE * me._centerTileOffset[1];

        return { x: pixelX, y: pixelY };
    },

    #
    # Redraw flight path. We have to redraw if zoom was changed
    #
    # @param  ghost  model  MapView model
    # @return ghost  Path element
    #
    _drawFlightPath: func(model) {
        me._flightPathGroup.removeAllChildren();

        var pointsToDraw = [];

        var isBreak = false;

        # The first loop is to build an array of points that are within the map
        forindex (var index; model._tractItems) {
            var row = model._tractItems[index];

            var pos = me._convertLatLonToPixel(
                row.lat,
                row.lon,
                model._tractItems[model._position].lat,
                model._tractItems[model._position].lon,
                model._zoom
            );

            if (   pos.x > me._maxTileX + DefaultStyle.widgets["map-view"].TILE_SIZE
                or pos.x < me._minTileX
                or pos.y > me._maxTileY + DefaultStyle.widgets["map-view"].TILE_SIZE
                or pos.y < me._minTileY
            ) {
                # The path point is out of map tiles, so ship it
                isBreak = true;
            }
            else {
                # When there was a discontinuity, we need to start drawing with the moveTo function,
                # so we set the moveTo flag which will tell us that
                pos["moveTo"] = isBreak ? true : false;
                isBreak = false;
                append(pointsToDraw, pos);
            }
        }

        # Draw points only those within the map
        var flightPath = me._flightPathGroup.createChild("path", "flight")
            .setColor(0.5, 0.5, 1)
            .setStrokeLineWidth(2)
            .set("z-index", 1);

        forindex (var index; pointsToDraw) {
            var point = pointsToDraw[index];

            if (index == 0 or point.moveTo) {
                flightPath.moveTo(point.x, point.y);
            }
            else {
                flightPath.lineTo(point.x, point.y);
            }
        }

        return flightPath;
    },

    #
    # This is the callback that will be regularly called by the timer to update the map
    #
    # @param  ghost  model  MapView model
    # @return void
    #
    updateTiles: func(model) {
        if (model._tractItems == nil or size(model._tractItems) == 0) {
            return;
        }

        me._minTileX = 0;
        me._maxTileX = 0;
        me._minTileY = 0;
        me._maxTileY = 0;

        # get current position
        # var lat = getprop('/position/latitude-deg');
        # var lon = getprop('/position/longitude-deg');

        var lat = model._tractItems[model._position].lat;
        var lon = model._tractItems[model._position].lon;

        var n = math.pow(2, model._zoom);
        var offset = [
            n * ((lon + 180) / 360) - me._centerTileOffset[0],
            (1 - math.ln(math.tan(lat * math.pi / 180) + 1 / math.cos(lat * math.pi / 180)) / math.pi) / 2 * n - me._centerTileOffset[1],
        ];
        var tileIndex = [int(offset[0]), int(offset[1])];

        var ox = tileIndex[0] - offset[0];
        var oy = tileIndex[1] - offset[1];

        for (var x = 0; x < me._numTiles[0]; x += 1) {
            for (var y = 0; y < me._numTiles[1]; y += 1) {
                var transX = int((ox + x) * DefaultStyle.widgets["map-view"].TILE_SIZE + 0.5);
                var transY = int((oy + y) * DefaultStyle.widgets["map-view"].TILE_SIZE + 0.5);

                me._tiles[x][y].setTranslation(transX, transY);

                # Remember the extreme positions of map tiles
                if (transX > me._maxTileX) {
                    me._maxTileX = transX;
                }

                if (transX < me._minTileX) {
                    me._minTileX = transX;
                }

                if (transY > me._maxTileY) {
                    me._maxTileY = transY;
                }

                if (transY < me._minTileY) {
                    me._minTileY = transY;
                }
            }
        }

        if (   tileIndex[0] != me._lastTile[0]
            or tileIndex[1] != me._lastTile[1]
        ) {
            for (var x = 0; x < me._numTiles[0]; x += 1) {
                for (var y = 0; y < me._numTiles[1]; y += 1) {
                    var pos = {
                        z: model._zoom,
                        x: int(offset[0] + x),
                        y: int(offset[1] + y),
                    };

                    (func {
                        var imgPath = me._makePath(pos);
                        var tile = me._tiles[x][y];

                        if (io.stat(imgPath) == nil) {
                            # image not found, save in $FG_HOME
                            var imgUrl = me._makeUrl(pos);

                            logprint(LOG_INFO, 'Logbook Add-on - requesting ', imgUrl);

                            http.save(imgUrl, imgPath)
                                .done(func {
                                    logprint(LOG_INFO, 'Logbook Add-on - received image ', imgPath);
                                    tile.set("src", imgPath);
                                })
                                .fail(func (response) {
                                    logprint(LOG_ALERT, 'Logbook Add-on - failed to get image ', imgPath, ' ', response.status, ': ', response.reason);
                                });
                        }
                        else { # cached image found, reusing
                            logprint(LOG_INFO, 'Logbook Add-on - loading ', imgPath);
                            tile.set("src", imgPath);
                        }
                    })();
                }
            }

            me._lastTile = tileIndex;
        }

        me._drawFlightPath(model);
    },

    #
    # Draw an invisible line to get the padding
    #
    # @param  ghost  model  MapView model
    # @return ghost  Path element
    #
    _drawPaddingKeeper: func(model) {
        me._root.createChild("path", "padding-keeper")
            .moveTo(0, 0)
            .horiz(model._size[0])
            .setColor(0, 0, 0, 0)
            .setStrokeLineWidth(1);
    },
};

