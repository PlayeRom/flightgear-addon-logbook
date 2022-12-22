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
DefaultStyle.widgets.ListView = {
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
        me._root = parent.createChild("group", "ListView");

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

        me._xTransaltion = nil;
        me._yTransaltion = nil;
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
    setTextColor: func(model, color) {
        me._textColor = color;

        if (me._loadingText != nil) {
            me._loadingText.setColor(color);
        }

        if (me._titleElement != nil) {
            me._titleElement.setColor(color);
        }

        foreach (var hash; me._itemElements) {
            if (typeof(hash.text) == "vector") {
                foreach (var text; hash.text) {
                    text.setColor(color);
                }
            }
            else {
                hash.text.setColor(color);
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
    setBackgroundColor: func(model, color) {
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
    setHoverBackgroundColor: func(model, color) {
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
            if (typeof(hash.text) == "vector") {
                foreach (var text; hash.text) {
                    text.setColor(color);
                }
            }
            else {
                hash.text.setFontSize(fontSize);
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
            if (typeof(hash.text) == "vector") {
                foreach (var text; hash.text) {
                    text.setFont(color);
                }
            }
            else {
                hash.text.setFont(font);
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
        me._xTransaltion = x;
        me._yTransaltion = y;
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
        me._deleteElements(); # TODO: <- is it really needed? Maybe removeAllChildren does the job?
        me._root.removeAllChildren();

        var y = model._isLoading
            ? me._drawContentLoading(model)
            : me._drawContentItems(model);

        model.setLayoutMinimumSize([50, DefaultStyle.widgets.ListView.ITEM_HEIGHT]);
        model.setLayoutSizeHint([model._size[0], y]);
    },

    #
    # @param hash model
    # @return int - Height of content
    #
    _drawContentLoading: func(model) {
        me._loadingText = me._createText(
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
        if (me._xTransaltion != nil and me._yTransaltion != nil) {
            me._root.setTranslation(me._xTransaltion, me._yTransaltion);
        }

        var x = DefaultStyle.widgets.ListView.PADDING;
        var y = 0;

        me._itemElements = [];

        if (model._title != nil) {
            var group = me._createBarGroup(y);
            me._titleElement = me._createText(group, x, me._getTextYOffset(), model._title);

            y += int(DefaultStyle.widgets.ListView.ITEM_HEIGHT + DefaultStyle.widgets.ListView.ITEM_HEIGHT / 4);
        }

        var index = 0;
        foreach (var item; model._items) {
            me._createRow(model, item, x, y);

            func () {
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
            if (model._isUseTextMaxWidth) {
                var itemsCount = size(me._itemElements);
                if (itemsCount > 0) {
                    var height = me._itemElements[itemsCount - 1].maxHeight;

                    y += (height > 18 ? height : 0); # 18 - font size threshold for 1 row (non-wraped text)
                }
            }

            y += DefaultStyle.widgets.ListView.ITEM_HEIGHT;
            index += 1;
        }

        # Make sure that highlighted row is still highlighting
        me.setHighlightingRow(model, me._highlightingRowColor);

        return y;
    },

    #
    # Get width of column for given index
    #
    # @param hash model
    # @param string|hash item
    # @param int x, y
    # @return void
    #
    _createRow: func(model, item, x, y) {
        if (me._columnsWidth == nil) {
            # model._items is a vactor of strings
            var hash = me._createBar(model, y);
            hash.text = me._createText(hash.group, x, me._getTextYOffset(), item);
            append(me._itemElements, hash);
            return;
        }

        # model._items is a vactor of hash, each hash has "data" key with vector of strings
        var hash = me._createBar(model, y);
        hash.text = [];

        forindex (var columnIndex; me._columnsWidth) {
            var text = me._createText(hash.group, x, me._getTextYOffset(), item.data[columnIndex]);
            if (model._isUseTextMaxWidth) {
                text.setMaxWidth(me._getColumnWidth(columnIndex));
                var height = text.getSize()[1];
                if (height > hash.maxHeight) {
                    hash.maxHeight = height;
                }
            }
            append(hash.text, text);

            x += me._getColumnWidth(columnIndex);
        }

        append(me._itemElements, hash);
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
    # @param hash model
    # @param int y
    # @return hash
    #
    _createBar: func(model, y) {
        var hash = {
            group     : me._createBarGroup(y),
            rect      : nil,
            text      : nil, # vector of text element, or single text element
            maxHeight : 0,   # max text height in this row
        };

        hash.rect = hash.group.rect(
                0,
                0,
                model._size[0] - (DefaultStyle.widgets.ListView.PADDING * 2) - (me._xTransaltion == nil ? 0 : me._xTransaltion),
                DefaultStyle.widgets.ListView.ITEM_HEIGHT
            )
            .setColorFill(me._backgroundColor);

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
    # @param hash context - Parent element
    # @param int x, y
    # @param string text
    # @param string alignment
    # @return hash - Text element
    #
    _createText: func(context, x, y, text, alignment = "left-baseline") {
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
        if (me._fontSize == 12) {
            return 16;
        }

        if (me._fontSize == 14) {
            return 17;
        }

        if (me._fontSize == 16) {
            return 18;
        }

        return 0;
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
            if (typeof(hash.text) == "vector") {
                foreach (var text; hash.text) {
                    text.del();
                }
            }
            else {
                hash.text.del();
            }

            hash.rect.del();
            hash.group.del();
        }
        me._itemElements = [];

        return me;
    },
};
