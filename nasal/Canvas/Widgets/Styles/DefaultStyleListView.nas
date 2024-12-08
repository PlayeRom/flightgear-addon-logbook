#
# ListView widget - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# ListView widget is an Open Source project and it is licensed
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
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "list-view");

        me._titleElement = nil;
        me._itemElements = [];
        me._loadingText = nil;

        me._fontSize = 14;
        me._fontName = "LiberationFonts/LiberationMono-Regular.ttf";

        me._textColor = me._style.getColor("fg_color");
        me._backgroundColor = me._style.getColor("bg_color");
        me._hoverBackgroundColor = [1.0, 1.0, 0.5, 1.0];
        me._highlightingRowColor = nil;

        me._xTranslation = 0;
        me._yTranslation = 0;
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  ListView model
    # @param  int  w, h  Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  ListView model
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # Set title as non clickable description text on the top
    #
    # @param  ghost  model  ListView model
    # @param  string  text
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
    # @param  ghost  model  ListView model
    # @param  vector  color
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
    # @param  ghost  model  ListView model
    # @param  vector  color
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
    # @param  ghost  model  ListView model
    # @param  vector  color
    # @return me
    #
    setColorHoverBackground: func(model, color) {
        me._hoverBackgroundColor = color;

        me.update(model);
        return me;
    },

    #
    # @param  ghost  model  ListView model
    # @param  int  fontSize
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
    # @param  ghost  model  ListView model
    # @param  string  font
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
                        elem.setFont(font);
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
    # @param  ghost  model  ListView model
    # @param  int  x, y
    # @return me
    #
    setTranslation: func(model, x, y) {
        me._xTranslation = x;
        me._yTranslation = y;
        return me;
    },

    #
    # @param  ghost  model  ListView model
    # @param  vector  color
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
    # @param  ghost  model  ListView model
    # @return me
    #
    removeHighlightingRow: func(model) {
        me._itemElements[model._highlightingRowIndex].rect.setColorFill(me._backgroundColor);
        return me;
    },

    #
    # @param  ghost  model  ListView model
    # @param  vector  boundingBox  [xmin, ymin, xmax, ymax]
    # @return me
    #
    setClipByBoundingBox: func(model, boundingBox) {
        me._root.setClipByBoundingBox(boundingBox);
        return me;
    },

    #
    # @param  ghost  model  ListView model
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
    # @param  ghost  model  ListView model
    # @return int  Height of content
    #
    _drawContentLoading: func(model) {
        me._loadingText = me._createText(
            model    : model,
            context  : me._root,
            x        : int(model._size[0] / 2),
            y        : int(model._size[1] / 2),
            label    : "Loading...",
            alignment: "center-center"
        );

        return model._size[1];
    },

    #
    # @param  ghost  model  ListView model
    # @return int  Height of content
    #
    _drawContentItems: func(model) {
        var x = me._xTranslation + DefaultStyle.widgets["list-view"].PADDING;
        var y = me._yTranslation;

        me._itemElements = [];

        if (model._title != nil) {
            var group = me._createBarGroup(y);
            me._titleElement = me._createText(
                model  : model,
                context: group,
                x      : x,
                y      : me._getTextYOffset(),
                label  : model._title
            );

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
            height = me._itemElements[index].maxHeight;

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
    # @param  ghost  model  ListView model
    # @param  string|hash  item
    # @param  int  x, y
    # @return void
    #
    _createRow: func(model, item, x, y) {
        model._isOptimizeRow
            ? me._createComplexOptimizeRow(model, item, x, y)
            : me._createComplexRow(model, item, x, y);
    },

    #
    # Create complex row
    #
    # @param  ghost  model  ListView model
    # @param  string|hash  item
    # @param  int  x, y
    # @return void
    #
    _createComplexRow: func(model, item, x, y) {
        var hash = me._createBar(y);
        hash.elem = [];

        # Get row font
        var rowFont = contains(item, "font") ? item.font : nil;

        # Create temporary text elements to get their height
        # TODO: It would be nice to optimize here so as not to draw these temporary texts, but I need to first
        # draw a rectangle and know its height based on the text that will be there, and then draw the final text.
        if (model._isUseTextMaxWidth) {
            var tempText = me._createText(model, hash.group, x, me._getTextYOffset(), "temp");
            forindex (var columnIndex; item.columns) {
                var column = item.columns[columnIndex];

                # If item has not declared "type" then assume that it's a string
                if (me._isColTypeString(column)) {
                    var font = me._getCellFont(rowFont, column);

                    tempText
                        .setFont(font == nil ? me._fontName : font)
                        .setText(column.data)
                        .setMaxWidth(column.width);

                    var height = tempText.getSize()[1] + 1;
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

        forindex (var columnIndex; item.columns) {
            var column = item.columns[columnIndex];

            if (me._isColTypeString(column)) {
                var text = me._createText(
                    model    : model,
                    context  : hash.group,
                    x        : x,
                    y        : me._getTextYOffset(),
                    label    : column.data,
                    alignment: "left-baseline",
                    fontName : me._getCellFont(rowFont, column)
                );

                if (model._isUseTextMaxWidth) {
                    text.setMaxWidth(column.width);
                }

                append(hash.elem, text);
            }
            else if (me._isColTypeImage(column)) {
                var image = hash.group.createChild("image")
                    .setFile(column.data)
                    .setTranslation(x, me._getHeightItemPadding(hash.maxHeight) / 2)
                    .setSize(int(model._imgHeight * model._imgAspectRatio), model._imgHeight);

                append(hash.elem, image);
            }

            x += column.width;
        }

        append(me._itemElements, hash);
    },

    #
    # @param  hash  column
    # @return bool
    #
    _isColTypeString: func(column) {
        return !contains(column, "type") or column.type == "string";
    },

    #
    # @param  hash  column
    # @return bool
    #
    _isColTypeImage: func(column) {
        return contains(column, "type") and column.type == "image";
    },

    #
    # @param  ghost  model  ListView model
    # @return bool
    #
    _isImageInRow: func(item) {
        foreach (var column; item.columns) {
            if (me._isColTypeImage(column)) {
                return 1;
            }
        }

        return 0;
    },

    #
    # @param  string|nil  rowFont  Font file name passed for the row
    # @param  hash  column
    # @return string|nil  Font file name or nil
    #
    _getCellFont: func(rowFont, column) {
        # Get column font
        var columnFont = contains(column, "font") ? column.font : nil;

        # Column font has priority
        return columnFont != nil ? columnFont : rowFont;
    },

    #
    # Get character width according to font size for mono regular font
    #
    # @return double
    #
    _getMonoCharWidth: func() {
        # Unfortunately, the more characters, the more pixels per character, even though the font is mono.
        # The following calculations are for a string with 12 characters.
        #      if (me._fontSize == 12) return 7;   # 7.0625
        # else if (me._fontSize == 14) return 8.2; # 8.2395
        # else if (me._fontSize == 16) return 9.4; # 9.4166

        return 0.588525 * me._fontSize + 0.000183;
    },

    #
    # Create complex row but in an optimized way that there is only one text object per row,
    # ant images are not supported, only text.
    #
    # @param  ghost  model  ListView model
    # @param  hash  item
    # @param  int  x, y
    # @return void
    #
    _createComplexOptimizeRow: func(model, item, x, y) {
        var hash = me._createBar(y);
        hash.elem = [];

        var rectHeight = hash.maxHeight == 0
            ? DefaultStyle.widgets["list-view"].ITEM_HEIGHT
            : hash.maxHeight + me._getHeightItemPadding(hash.maxHeight);

        hash.rect = me._createRectangle(model, hash.group, rectHeight);

        var textStr = "";
        var charWidth = me._getMonoCharWidth();
        var columnsSize = size(item.columns);

        forindex (var columnIndex; item.columns) {
            var column = item.columns[columnIndex];

            var colspan = contains(column, "colspan") ? column.colspan : 1; # 1 as default value

            if (colspan == 0) {
                continue; # skip column with colspan 0
            }

            var columnWidth = column.width;

            # If colspan > 1, then add column width from next columns
            for (var i = 1; i < colspan; i += 1) {
                if (columnIndex + i < columnsSize) {
                    columnWidth += item.columns[columnIndex + 1].width;
                }
            }

            var originalTextSize = size(column.data);
            var maxChars = int(columnWidth / charWidth) - 1;

            var dots = originalTextSize > maxChars;
            if (dots) {
                # The text will be cut, add 3 dots ...
                maxChars -= 3;
            }

            var trimmedStr = substr(column.data, 0, maxChars);
            if (dots) {
                trimmedStr ~= "...";
            }

            var align = contains(column, "align") ? column.align : "left";

            var currChars = math.max(size(trimmedStr), originalTextSize);
            var spaces = "";
            for (var i = 0; i < maxChars - currChars; i += 1) {
                spaces ~= " ";
            }

            trimmedStr = align == "right"
                ? spaces ~ trimmedStr
                : trimmedStr ~ spaces;

            textStr ~= trimmedStr ~ " "; # it must be min 1 space to keep separation
        }

        var fontName = contains(item, "font")
            ? item.font
            : nil;

        var text = me._createText(
            model    : model,
            context  : hash.group,
            x        : x,
            y        : me._getTextYOffset(),
            label    : textStr,
            alignment: "left-baseline",
            fontName : fontName
        );

        append(hash.elem, text);

        append(me._itemElements, hash);
    },

    #
    # @param  int  y
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
    # @param  int  y
    # @return ghost  Group element
    #
    _createBarGroup: func(y) {
        return me._root.createChild("group").setTranslation(0, y);
    },

    #
    # @param  ghost  model  ListView model
    # @param  hash  context
    # @param  int  textHeight
    # @return ghost  Path element
    #
    _createRectangle: func(model, context, textHeight) {
        var height = int(math.max(textHeight, DefaultStyle.widgets["list-view"].ITEM_HEIGHT));
        return context.rect(0, 0, model._size[0], height)
            .setColorFill(me._backgroundColor);
    },

    #
    # @param  ghost  model  ListView model
    # @param  hash  context  Parent element
    # @param  int  x, y
    # @param  string  label
    # @param  string  alignment
    # @return ghost  Text element
    #
    _createText: func(model, context, x, y, label, alignment = "left-baseline", fontName = nil) {
        if (model._placeholder != nil and string.trim(label) == "") {
            label = model._placeholder;
        }

        if (fontName == nil) {
            fontName = me._fontName;
        }

        return context.createChild("text")
            .setFont(fontName)
            .setFontSize(me._fontSize)
            .setAlignment(alignment)
            .setTranslation(x, y)
            .setColor(me._textColor)
            .setText(label);
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
    # @param  int  maxHeight  Max height of content
    # @return int
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

