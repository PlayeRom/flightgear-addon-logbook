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
        me._fontSize = 14;
        me._itemElements = [];
        me._width = 0;
        me._textColor = me._style.getColor("fg_color");
        me._backgroundColor = me._style.getColor("bg_color");
        me._hoverBackgroundColor = [1.0, 1.0, 0.5, 1.0];
    },

    #
    # Callback called when user resized the window
    #
    # @param hash model
    # @param int w, h - Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        me._width = w;

        me.reDrawItems(model);

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

        if (me._titleElement != nil) {
            me._titleElement.setColor(color);
        }

        foreach (var hash; me._itemElements) {
            hash.text.setColor(color);
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

        if (me._titleElement != nil) {
            me._titleElement.setFontSize(fontSize);
        }

        foreach (var hash; me._itemElements) {
            hash.text.setFontSize(fontSize);
        }

        return me
    },

    #
    # @param hash model
    # @return void
    #
    reDrawItems: func(model) {
        me._deleteElements(); # TODO: <- is it really needed? Maybe removeAllChildren does the job?
        me._root.removeAllChildren();

        var x = DefaultStyle.widgets.ListView.PADDING;
        var y = 0;

        me._itemElements = [];

        if (model.title != nil) {
            var group = me._createBarGroup(y);
            me._titleElement = me._createText(group, x, model.title);

            y += int(DefaultStyle.widgets.ListView.ITEM_HEIGHT + DefaultStyle.widgets.ListView.ITEM_HEIGHT / 4);
        }

        var index = 0;
        foreach (var text; model.items) {
            var hash = me._createBar(y);
            hash.text = me._createText(hash.group, x, text);
            append(me._itemElements, hash);

            func () {
                var innerIndex = index;
                me._itemElements[innerIndex].group.addEventListener("mouseenter", func {
                    me._itemElements[innerIndex].rect.setColorFill(me._hoverBackgroundColor);
                });

                me._itemElements[innerIndex].group.addEventListener("mouseleave", func {
                    me._itemElements[innerIndex].rect.setColorFill(me._backgroundColor);
                });

                me._itemElements[index].group.addEventListener("click", func {
                    call(model.callback, [innerIndex], model.callbackContext);
                });
            }();

            y += DefaultStyle.widgets.ListView.ITEM_HEIGHT;
            index += 1;
        }

        model.setLayoutMinimumSize([50, y]);
        model.setLayoutSizeHint([me._width, y]);
    },

    #
    # @param int y
    # @return hash
    #
    _createBar: func(y) {
        var hash = {
            group : me._createBarGroup(y),
            rect  : nil,
            text  : nil,
        };

        hash.rect = hash.group.rect(
                0,
                0,
                me._width - (DefaultStyle.widgets.ListView.PADDING * 2),
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
    # @param int x
    # @param string text
    # @return hash - Text element
    #
    _createText: func(context, x, text) {
        return context.createChild("text")
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setFontSize(me._fontSize)
            .setAlignment("left-baseline")
            .setTranslation(x, me._getTextYOffset())
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
        if (me._titleElement != nil) {
            me._titleElement.del();
            me._titleElement = nil;
        }

        foreach (var hash; me._itemElements) {
            hash.text.del();
            hash.rect.del();
            hash.group.del();
        }
        me._itemElements = [];

        return me;
    },
};
