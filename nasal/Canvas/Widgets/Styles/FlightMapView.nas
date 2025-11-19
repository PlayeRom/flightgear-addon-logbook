#
# FlightMap widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# FlightMap widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# FlightMap widget View
#
DefaultStyle.widgets["flight-map-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "flight-map-view");

        me._content = me._root.createChild("group", "clip-content")
            .set("clip-frame", Element.PARENT);

        me._textColor = me._style.getColor("fg_color");
        me._bgColor   = me._style.getColor("bg_color");

        me._numTiles         = { x:  6, y:  4 };
        me._centerTileOffset = { x:  0, y:  0 };
        me._lastTile         = { x: -1, y: -1 };

        me._tiles = [];

        # A variable to remember the extreme positions of the map tiles,
        # which we will use to not draw the flight path outside the map
        me._tileBoundaries = {
            min: { x: 0, y: 0 },
            max: { x: 0, y: 0 },
        };

        me._isEventsSet = 0;

        me._refPosition = 0;
        me._refZoom = gui.widgets.FlightMap.ZOOM_DEFAULT;

        me._lastSize = { w: nil, h: nil };

        me._zoomLabel = nil;

        me._isReDrew = 0;

        me._planeIcon  = PlaneIcon.new();
        me._windBarbs  = WindBarbs.new();
        me._flightPath = FlightPathMap.new();
        me._mapButtons = MapButtons.new();
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  FlightMap model
    # @param  int w, h  Width and height of widget
    # @return ghost
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
    # @param  ghost  model  FlightMap model
    # @return void
    #
    update: func(model) {
        me._content.set("clip", "rect(0, " ~ model._size[0] ~ ", " ~ model._size[1] ~ ", 0)");
    },

    #
    # @param  ghost  model  FlightMap model
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

        me._planeIcon.create(me._content, "Textures/plane-top.svg");

        me._flightPath.create(me._content);

        me._calculateNumTiles(model);

        me._centerTileOffset.x = (me._numTiles.x - 1) / 2;
        me._centerTileOffset.y = (me._numTiles.y - 1) / 2;

        # Reset values
        me._lastTile.x = -1;
        me._lastTile.y = -1;

        me._createTiles(model);

        me._windBarbs.create(me._content);
        me._mapButtons.create(model, me._content);

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
    # @param  ghost  model  FlightMap model
    # @return void
    #
    _addEvents: func(model) {
        if (me._isEventsSet) {
            # Events should be added only once, otherwise they will be called multiple times
            return;
        }

        me._isEventsSet = 1;

        me._content.addEventListener("click", func(e) {
            # Find the path point closest to the click
            var minDistance = nil;
            var position = nil;
            var distance = 0;

            foreach (var point; me._flightPath.getPointsToDraw()) {
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
    # Calculate how many tiles you need in width and height depending on the widget size.
    #
    # @param  ghost  model  FlightMap model
    # @return  void
    #
    _calculateNumTiles: func(model) {
        me._numTiles.x = math.ceil(model._size[0] / gui.widgets.FlightMap.TILE_SIZE) + 1;
        me._numTiles.y = math.ceil(model._size[1] / gui.widgets.FlightMap.TILE_SIZE) + 1;
    },

    #
    # Initialize the map by setting up a grid of raster images.
    #
    # @param  ghost  model  FlightMap model
    # @return void
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
    _createText: func(
        x,
        y,
        label,
        alignment = "left-baseline",
        fontSize = 12,
        font = "LiberationFonts/LiberationMono-Regular.ttf",
        color = nil,
    ) {
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
    # @param  ghost  model  FlightMap model
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

        me._planeIcon.draw(
            x     : gui.widgets.FlightMap.TILE_SIZE * me._centerTileOffset.x,
            y     : gui.widgets.FlightMap.TILE_SIZE * me._centerTileOffset.y,
            rotate: track.heading_true
        );
        me._windBarbs.draw(model, track.wind_heading, track.wind_speed);

        me._resetTileBoundaries();

        # Get current position
        var lat = track.lat;
        var lon = track.lon;

        var scale = math.pow(2, model._zoom);

        var latRad = lat * math.pi / 180;
        var mercatorY = math.ln(math.tan(latRad) + 1 / math.cos(latRad));

        var offset = {
            x: scale * ((lon + 180) / 360) - me._centerTileOffset.x,
            y: (1 - mercatorY / math.pi) / 2 * scale - me._centerTileOffset.y,
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
                    x: int((ox + x) * gui.widgets.FlightMap.TILE_SIZE + 0.5),
                    y: int((oy + y) * gui.widgets.FlightMap.TILE_SIZE + 0.5),
                };

                me._tiles[x][y].setTranslation(trans.x, trans.y);

                me._setTileBoundaries(trans);

                # Update tiles if needed
                if (   tileIndex.x != me._lastTile.x
                    or tileIndex.y != me._lastTile.y
                    or forceSetTile
                ) {
                    me._updateSingleTile(model, x, y, offset);
                }
            }
        }

        me._lastTile.x = tileIndex.x;
        me._lastTile.y = tileIndex.y;

        me._flightPath.draw(model, me._centerTileOffset, me._tileBoundaries);
    },

    #
    # Reset values of tile boundaries
    #
    # @return void
    #
    _resetTileBoundaries: func {
        me._tileBoundaries.min.x = 0;
        me._tileBoundaries.min.y = 0;
        me._tileBoundaries.max.x = 0;
        me._tileBoundaries.max.y = 0;
    },

    #
    # Remember the extreme positions of map tiles
    #
    # @param  hash  trans  Translation vector of tile
    # @return void
    #
    _setTileBoundaries: func(trans) {
        if (trans.x > me._tileBoundaries.max.x) {
            me._tileBoundaries.max.x = trans.x;
        }

        if (trans.x < me._tileBoundaries.min.x) {
            me._tileBoundaries.min.x = trans.x;
        }

        if (trans.y > me._tileBoundaries.max.y) {
            me._tileBoundaries.max.y = trans.y;
        }

        if (trans.y < me._tileBoundaries.min.y) {
            me._tileBoundaries.min.y = trans.y;
        }
    },

    #
    # Update single map tile
    #
    # @param  ghost  model  FlightMap model object
    # @param  int  x, y
    # @param  hash  offset
    # @return void
    #
    _updateSingleTile: func(model, x, y, offset) {
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

                http.save(imgUrl, imgPath)
                    .done(func {
                        tile.set("src", imgPath);
                    })
                    .fail(func(response) {
                        logprint(LOG_ALERT, 'FlightMap Widget - failed to get image ', imgPath, ' ', response.status, ': ', response.reason);
                    });
            }
            else { # cached image found, reusing
                tile.set("src", imgPath);
            }
        })();
    },

    #
    # Draw an invisible line to get the padding. It is needed when FlightMap is drawn inside ScrollArea.
    #
    # @param  ghost  model  FlightMap model
    # @return void
    #
    _drawPaddingKeeper: func(model) {
        me._content.createChild("path", "padding-keeper")
            .moveTo(0, 0)
            .horiz(model._size[0])
            .setColor(0, 0, 0, 0)
            .setStrokeLineWidth(1);
    },
};
