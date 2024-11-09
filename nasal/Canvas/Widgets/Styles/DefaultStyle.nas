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
# ListView widget View
#
DefaultStyle.widgets["list-view"] = {
    PADDING     : 10,
    ITEM_HEIGHT : 28,

    #
    # Constructor
    #
    # @param hash parent
    # @param hash cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "list-view");

        me._titleElement = nil;
        me._itemElements = [];
        me._loadingText = nil;
        me._columnsWidth = nil;

        me._fontSize = 14;
        me._fontName = "LiberationFonts/LiberationSans-Regular.ttf";

        me._textColor = me._style.getColor("fg_color");
        me._backgroundColor = me._style.getColor("bg_color");
        me._hoverBackgroundColor = [1.0, 1.0, 0.5, 1.0];
        me._highlightingRowColor = nil;

        me._xTranslation = nil;
        me._yTranslation = nil;
    },

    #
    # Callback called when user resized the window
    #
    # @param hash model
    # @param int w, h - Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param hash model
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param hash model
    # @param vector columnsWidth
    # @return me
    #
    setColumnsWidth: func(model, columnsWidth) {
        me._columnsWidth = columnsWidth;
        return me;
    },

    #
    # Set title as non clickable description text on the top
    #
    # @param hash model
    # @param string text
    # @return me
    #
    setTitle: func(model, text) {
        if (me._titleElement != nil) {
            me._titleElement.setText(text);
        }

        me.update(model);
        return me;
    },

    #
    # @param hash model
    # @param vector color
    # @return me
    #
    setColorText: func(model, color) {
        me._textColor = color;

        if (me._loadingText != nil) {
            me._loadingText.setColor(color);
        }

        if (me._titleElement != nil) {
            me._titleElement.setColor(color);
        }

        foreach (var hash; me._itemElements) {
            if (typeof(hash.elem) == "vector") {
                foreach (var elem; hash.elem) {
                    if (elem.getType() == "text") {
                        elem.setColor(color);
                    }
                }
            }
            else if (hash.elem.getType() == "text") {
                hash.elem.setColor(color);
            }
        }

        me.update(model);
        return me;
    },

    #
    # @param hash model
    # @param vector color
    # @return me
    #
    setColorBackground: func(model, color) {
        me._backgroundColor = color;

        foreach (var hash; me._itemElements) {
            if (hash.rect != nil) {
                hash.rect.setColorFill(color);
            }
        }

        me.update(model);
        return me;
    },

    #
    # @param hash model
    # @param vector color
    # @return me
    #
    setColorHoverBackground: func(model, color) {
        me._hoverBackgroundColor = color;

        me.update(model);
        return me;
    },

    #
    # @param hash model
    # @param int fontSize
    # @return me
    #
    setFontSize: func(model, fontSize) {
        me._fontSize = fontSize;

        if (me._loadingText != nil) {
            me._loadingText.setFontSize(fontSize);
        }

        if (me._titleElement != nil) {
            me._titleElement.setFontSize(fontSize);
        }

        foreach (var hash; me._itemElements) {
            if (typeof(hash.elem) == "vector") {
                foreach (var elem; hash.elem) {
                    if (elem.getType() == "text") {
                        elem.setFontSize(fontSize);
                    }
                }
            }
            else if (hash.elem.getType() == "text") {
                hash.elem.setFontSize(fontSize);
            }
        }

        return me
    },

    #
    # @param hash model
    # @param string font
    # @return me
    #
    setFontName: func(model, font) {
        me._fontName = font;

        if (me._loadingText != nil) {
            me._loadingText.setFont(font);
        }

        if (me._titleElement != nil) {
            me._titleElement.setFont(font);
        }

        foreach (var hash; me._itemElements) {
            if (typeof(hash.elem) == "vector") {
                foreach (var elem; hash.elem) {
                    if (elem.getType() == "text") {
                        elem.setFont(color);
                    }
                }
            }
            else if (hash.elem.getType() == "text") {
                hash.elem.setFont(font);
            }
        }

        return me;
    },

    #
    # @param hash model
    # @param int x, y
    # @return me
    #
    setTranslation: func(model, x, y) {
        me._xTranslation = x;
        me._yTranslation = y;
        return me;
    },

    #
    # @param hash model
    # @param vector color
    # @return me
    #
    setHighlightingRow: func(model, color) {
        if (model._highlightingRowIndex != nil) {
            me._highlightingRowColor = color;
            me._itemElements[model._highlightingRowIndex].rect.setColorFill(color);
        }
        return me;
    },

    #
    # @param hash model
    # @return me
    #
    removeHighlightingRow: func(model) {
        me._itemElements[model._highlightingRowIndex].rect.setColorFill(me._backgroundColor);
        return me;
    },

    #
    # @param hash model
    # @param vector boundingBox
    # @return me
    #
    setClipByBoundingBox: func(model, boundingBox) {
        me._root.setClipByBoundingBox(boundingBox);
        return me;
    },

    #
    # @param hash model
    # @return void
    #
    reDrawContent: func(model) {
        # me._deleteElements(); # TODO: <- is it really needed? Maybe removeAllChildren does the job?
        me._root.removeAllChildren();

        var y = model._isLoading
            ? me._drawContentLoading(model)
            : me._drawContentItems(model);

        model.setLayoutMinimumSize([50, DefaultStyle.widgets["list-view"].ITEM_HEIGHT]);
        model.setLayoutSizeHint([model._size[0], y]);
    },

    #
    # @param hash model
    # @return int - Height of content
    #
    _drawContentLoading: func(model) {
        me._loadingText = me._createText(
            model,
            me._root,
            int(model._size[0] / 2),
            int(model._size[1] / 2),
            "Loading...",
            "center-center"
        );

        return model._size[1];
    },

    #
    # @param hash model
    # @return int - Height of content
    #
    _drawContentItems: func(model) {
        if (me._xTranslation != nil and me._yTranslation != nil) {
            me._root.setTranslation(me._xTranslation, me._yTranslation);
        }

        var x = DefaultStyle.widgets["list-view"].PADDING;
        var y = 0;

        me._itemElements = [];

        if (model._title != nil) {
            var group = me._createBarGroup(y);
            me._titleElement = me._createText(model, group, x, me._getTextYOffset(), model._title);

            y += int(DefaultStyle.widgets["list-view"].ITEM_HEIGHT + DefaultStyle.widgets["list-view"].ITEM_HEIGHT / 4);
        }

        var index = 0;
        foreach (var item; model._items) {
            me._createRow(model, item, x, y);

            # TODO: event listeners should be move to model
            func() {
                var innerIndex = index;
                me._itemElements[innerIndex].group.addEventListener("mouseenter", func {
                    if (model._highlightingRowIndex != innerIndex) {
                        me._itemElements[innerIndex].rect.setColorFill(me._hoverBackgroundColor);
                    }
                });

                me._itemElements[innerIndex].group.addEventListener("mouseleave", func {
                    if (model._highlightingRowIndex != innerIndex) {
                        me._itemElements[innerIndex].rect.setColorFill(me._backgroundColor);
                    }
                });

                me._itemElements[index].group.addEventListener("click", func {
                    call(model._callback, [innerIndex], model._callbackContext);
                });
            }();

            # Since the text can wrap, you need to take the height of the last text and add it to the height of the content.
            var itemsCount = size(me._itemElements);
            height = me._itemElements[itemsCount - 1].maxHeight;

            y += height > DefaultStyle.widgets["list-view"].ITEM_HEIGHT
                ? (height + me._getHeightItemPadding(height))
                : DefaultStyle.widgets["list-view"].ITEM_HEIGHT;

            index += 1;
        }

        # Make sure that highlighted row is still highlighting
        me.setHighlightingRow(model, me._highlightingRowColor);

        return y;
    },

    #
    # Create row
    #
    # @param hash model
    # @param string|hash item
    # @param int x, y
    # @return void
    #
    _createRow: func(model, item, x, y) {
        if (model._isComplexItems) {
            # model._items is a vector of hash, each hash has "data" key with vector of strings
            me._createComplexRow(model, item, x, y);
            return;
        }

        # model._items is a vector of strings
        me._createSimpleRow(model, item, x, y);
    },

    #
    # Create simple row
    #
    # @param hash model
    # @param string|hash item
    # @param int x, y
    # @return void
    #
    _createSimpleRow: func(model, item, x, y) {
        var hash = me._createBar(y);

        # Create temporary text element for get his height
        # TODO: It would be nice to optimize here so as not to draw these temporary texts, but I need to first
        # draw a rectangle and know its height based on the text that will be there, and then draw the final text.
        var height = DefaultStyle.widgets["list-view"].ITEM_HEIGHT;
        if (model._isUseTextMaxWidth) {
            var tempText = me._createText(model, hash.group, x, me._getTextYOffset(), item)
                .setMaxWidth(me._columnsWidth[0]);

            height = tempText.getSize()[1];
            if (height > hash.maxHeight) {
                hash.maxHeight = height;
            }
            tempText.del();
        }

        hash.rect = me._createRectangle(model, hash.group, height + me._getHeightItemPadding(hash.maxHeight));

        hash.elem = me._createText(model, hash.group, x, me._getTextYOffset(), item);
        if (model._isUseTextMaxWidth) {
            hash.elem.setMaxWidth(me._columnsWidth[0]);
        }

        append(me._itemElements, hash);
    },

    #
    # Create complex row
    #
    # @param hash model
    # @param string|hash item
    # @param int x, y
    # @return void
    #
    _createComplexRow: func(model, item, x, y) {
        var hash = me._createBar(y);
        hash.elem = [];

        # Create temporary text elements to get their height
        # TODO: It would be nice to optimize here so as not to draw these temporary texts, but I need to first
        # draw a rectangle and know its height based on the text that will be there, and then draw the final text.
        if (model._isUseTextMaxWidth) {
            var tempText = me._createText(model, hash.group, x, me._getTextYOffset(), "temp");
            forindex (var columnIndex; me._columnsWidth) {
                if (item["types"] == nil or item.types[columnIndex] == "string") {
                    # If item has not declared "type" then assume that it's a string
                    tempText
                        .setText(item.data[columnIndex])
                        .setMaxWidth(me._getColumnWidth(columnIndex));

                    var height = tempText.getSize()[1];
                    if (height > hash.maxHeight) {
                        hash.maxHeight = height;
                    }
                }
            }
            tempText.del();
        }

        if (hash.maxHeight < model._imgHeight) {
            if (me._isImageInRow(item)) {
                hash.maxHeight = model._imgHeight;
            }
        }

        var rectHeight = hash.maxHeight == 0
            ? DefaultStyle.widgets["list-view"].ITEM_HEIGHT
            : hash.maxHeight + me._getHeightItemPadding(hash.maxHeight);
        hash.rect = me._createRectangle(model, hash.group, rectHeight);

        forindex (var columnIndex; me._columnsWidth) {
            var columnWidth = me._getColumnWidth(columnIndex);

            if (item["types"] == nil or item.types[columnIndex] == "string") {
                var text = me._createText(model, hash.group, x, me._getTextYOffset(), item.data[columnIndex]);
                if (model._isUseTextMaxWidth) {
                    text.setMaxWidth(columnWidth);
                }

                append(hash.elem, text);
            }
            else if (item.types[columnIndex] == "image") {
                var image = hash.group.createChild("image")
                    .setFile(item.data[columnIndex])
                    .setTranslation(x, me._getHeightItemPadding(hash.maxHeight) / 2)
                    .setSize(int(model._imgHeight * model._imgAspectRatio), model._imgHeight);

                append(hash.elem, image);
            }

            x += columnWidth;
        }

        append(me._itemElements, hash);
    },

    #
    # @param hash item
    # @return bool
    #
    _isImageInRow: func(item) {
        if (item["types"] != nil) {
            foreach (var type; item.types) {
                if (type == "image") {
                    return 1;
                }
            }
        }

        return 0;
    },

    #
    # Get width of column for given index
    #
    # @param int index
    # @return int
    #
    _getColumnWidth: func(index) {
        return me._columnsWidth[index];
    },

    #
    # @param int y
    # @return hash
    #
    _createBar: func(y) {
        var hash = {
            group     : me._createBarGroup(y),
            rect      : nil,
            elem      : nil, # vector of text/image element, or single text element
            maxHeight : 0,   # max text height in this row
        };

        return hash;
    },

    #
    # @param int y
    # @return hash - Group element
    #
    _createBarGroup: func(y) {
        return me._root.createChild("group").setTranslation(0, y);
    },

    #
    # @param hash model
    # @param hash context
    # @param int textHeight
    # @return hash - Path element
    #
    _createRectangle: func(model, context, textHeight) {
        return context.rect(
                0,
                0,
                model._size[0] - (me._xTranslation == nil ? 0 : (me._xTranslation * 2)),
                math.max(textHeight, DefaultStyle.widgets["list-view"].ITEM_HEIGHT)
            )
            .setColorFill(me._backgroundColor);
    },

    #
    # @param hash model
    # @param hash context - Parent element
    # @param int x, y
    # @param string text
    # @param string alignment
    # @return hash - Text element
    #
    _createText: func(model, context, x, y, text, alignment = "left-baseline") {
        if (model._placeholder != nil and string.trim(text) == "") {
            text = model._placeholder;
        }

        return context.createChild("text")
            .setFont(me._fontName)
            .setFontSize(me._fontSize)
            .setAlignment(alignment)
            .setTranslation(x, y)
            .setColor(me._textColor)
            .setText(text);
    },

    #
    # @return int
    #
    _getTextYOffset: func() {
             if (me._fontSize == 12) return 16;
        else if (me._fontSize == 14) return 17;
        else if (me._fontSize == 16) return 18;

        return 0;
    },

    #
    # @param int maxHeight - Max height of content
    # @return double
    #
    _getHeightItemPadding: func(maxHeight) {
        return maxHeight == 0
            ? 0 # we have single text line, no need add padding
            : me._fontSize;
    },

    #
    # @return me
    #
    _deleteElements: func() {
        if (me._loadingText != nil) {
            me._loadingText.del();
            me._loadingText = nil;
        }

        if (me._titleElement != nil) {
            me._titleElement.del();
            me._titleElement = nil;
        }

        foreach (var hash; me._itemElements) {
            if (typeof(hash.elem) == "vector") {
                foreach (var elem; hash.elem) {
                    elem.del();
                }
            }
            else {
                hash.elem.del();
            }

            hash.rect.del();
            hash.group.del();
        }
        me._itemElements = [];

        return me;
    },
};

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

        me._numTiles = [6, 3];

        me._centerTileOffset = [
            (me._numTiles[0] - 1) / 2,
            (me._numTiles[1] - 1) / 2,
        ];

        me._lastTile = [-1, -1];

        me._flightPathGroup = nil;
        me._tiles = [];
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

        var flightPath = me._flightPathGroup.createChild("path", "flight")
            .setColor(0.5, 0.5, 1)
            .setStrokeLineWidth(2)
            .set("z-index", 1);

        forindex (var index; model._tractItems) {
            var row = model._tractItems[index];

            var pos = me._convertLatLonToPixel(
                row.lat,
                row.lon,
                model._tractItems[model._position].lat,
                model._tractItems[model._position].lon,
                model._zoom
            );

            if (index == 0) {
                flightPath.moveTo(pos.x, pos.y);
            }
            else {
                flightPath.lineTo(pos.x, pos.y);
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

        # get current position
        # var lat = getprop('/position/latitude-deg');
        # var lon = getprop('/position/longitude-deg');

        me._drawFlightPath(model);

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

#
# ProfileView widget View
#
DefaultStyle.widgets["profile-view"] = {
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
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  ProfileView model
    # @param  int w, h  Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        # me.reDrawContent(model);

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
            me._drawPaddingKeeper(model);

            me._drawTextCenter(
                "This log doesn't contain flight data.",
                int(model._size[0] / 2),
                int(model._size[1] / 2)
            );
        }
        else {
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
        var graphHeight = model._size[1] - 100;

        me._drawPaddingKeeper(model);

        var rows = model._tractItems;

        var seaMeanLevel = (graphHeight / 6);
        var padding = 20;
        me._xXAxis = 80;
        me._yXAxis = graphHeight - seaMeanLevel; # horizontal position of the X axis in pixels
        me._positiveYAxisLength = me._yXAxis - padding;

        me._graphWidth = model._size[0] - padding;# - (VerticalProfileDialog.PADDING * 2);

        me._drawTextCenter("Time (hours) and Distance (NM)", model._size[0] / 2, graphHeight + 10);
        me._drawTextCenter("Altitude (feet)", 20, graphHeight / 2, -90);

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
            var y = me._yXAxis - ((altFt / maxAltFt) * me._positiveYAxisLength);
            if (y < padding) {
                # There is no more space for another horizontal line, exit the loop
                break;
            }

            me._drawTextRight(sprintf("%.0f", altFt), me._xXAxis - 5, y);

            # Draw horizontal grid line
            grid.moveTo(me._xXAxis, y)
                .horiz(me._graphWidth - me._xXAxis);
        }

        # Draw elevation and flight profile

        var elevationProfile = me._root.createChild("path", "elevation")
            .setColor(0.65, 0.16, 0.16)
            # .setColorFill(0.75, 0.26, 0.26)
            # .moveTo(me._xXAxis, graphHeight)
            .setStrokeLineWidth(2);

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

            var x = me._xXAxis + ((row.timestamp / me._maxTimestamp) * (me._graphWidth - me._xXAxis));
            var elevationY = me._yXAxis - ((row.elevation_m / maxAlt) * me._positiveYAxisLength);
            var flightY    = me._yXAxis - ((row.alt_m / maxAlt) * me._positiveYAxisLength);

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
                            var nextFlightY = me._yXAxis - ((nextRow.alt_m / maxAlt) * me._positiveYAxisLength);

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
                    grid.moveTo(x, padding)
                        .vert(me._yXAxis);
                }
            }
        }

        var axis = me._root.createChild("path", "axis")
            .setColor(0, 0, 0)
            .setStrokeLineWidth(1);

        # Draw X Axis
        axis.moveTo(me._xXAxis, me._yXAxis)
            .horiz(me._graphWidth - me._xXAxis);

        # Draw Y Axis
        axis.moveTo(me._xXAxis, padding)
            .vert(graphHeight);
    },

    #
    # Draw an invisible line to get the padding
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
        var x = me._xXAxis + ((row.timestamp / me._maxTimestamp) * (me._graphWidth - me._xXAxis));
        var y = me._yXAxis - ((row.alt_m / model._maxAlt) * me._positiveYAxisLength);

        return me._drawAircraft(x, y);
    },

    #
    # Simple aircraft icon at current position/center of the map
    #
    # @param  double  x
    # @param  double  y
    # @return ghost  Path element
    #
    _drawAircraft: func(x, y) {
        return me._aircraftPositionGroup.createChild("path")
            .moveTo(
                x - 10,
                y
            )
            .horiz(20)
            .move(-10, -10)
            .vert(20)
            .set("stroke", "red")
            .set("stroke-width", 3)
            .set("z-index", 2);
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
        return me._drawText(text, x, y, rotate, "center-center");
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
        return me._drawText(text, x, y, rotate, "right-center");
    },

    #
    # Draw text with given alignment
    #
    # @param  string  text
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @param  string  alignment
    # @return ghost  Text element
    #
    _drawText: func(text, x, y, rotate, alignment = "center-center") {
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
