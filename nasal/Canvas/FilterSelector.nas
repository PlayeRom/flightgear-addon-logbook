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
# FilterSelector class
#
var FilterSelector = {
    #
    # Constants
    #
    WINDOW_WIDTH           : 250,
    WINDOW_HEIGHT          : 300,
    MAX_WINDOW_HEIGHT      : LogbookDialog.WINDOW_HEIGHT - 50,
    PADDING                : 10,
    BUTTON_HEIGHT          : 26,
    CLEAR_FILTER_VALUE     : "All",
    SEPARATOR_H_MULTIPLIER : 0.25,

    #
    # Constructor
    #
    # hash settings - Settings object
    # return me
    #
    new: func (settings) {
        var me = { parents: [
            FilterSelector,
            Dialog.new(
                settings,
                Dialog.ID_FILTER_SELECTOR,
                FilterSelector.WINDOW_WIDTH,
                FilterSelector.WINDOW_HEIGHT,
                "Logbook About"
            ),
        ] };

        me.font     = "LiberationFonts/LiberationSans-Bold.ttf";
        me.fontSize = 16;
        me.title    = "Filter";

        me.window.set("decoration-border", "0 0 0");

        me.bgImage.hide();

        me.canvas.set("background", me.style.CANVAS_BG);

        me.items = [];
        me.withDefaultAll = true;

        me.scrollData = nil;
        me.scrollDataContent = nil;
        me.callback = nil;
        me.objCallback = nil;
        me.columnIndex = nil;

        return me;
    },

    #
    # Destructor
    #
    # return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Hide canvas window
    #
    # return void
    #
    hide: func() {
        call(Dialog.hide, [], me);
    },

    #
    # Show canvas window
    #
    # return void
    #
    show: func() {
        me.recalculateWindowHeight();
        me.reDrawContent();

        call(Dialog.show, [], me);
    },

    #
    # int x, y
    # return me
    #
    setPosition: func(x, y) {
        me.window.setPosition(x, y);

        return me;
    },

    #
    # string title
    # return me
    #
    setTitle: func(title) {
        me.title = title;
        me.window.setTitle(title);

        return me;
    },

    #
    # vector items
    # bool withDefaultAll
    # return me
    #
    setItems: func(items, withDefaultAll = 1) {
        me.items = items;
        me.withDefaultAll = withDefaultAll;

        return me;
    },

    #
    # return void
    #
    recalculateWindowHeight: func() {
        var paddingMultiplier = 2;
        var count = size(me.items) + 1 + FilterSelector.SEPARATOR_H_MULTIPLIER; # +1 for title bar

        if (me.withDefaultAll) {
            count += 1;  # +1 for "Default All"
            paddingMultiplier += 1;
        }

        var windowHeight = int(count * ListView.SHIFT_Y + (FilterSelector.PADDING * paddingMultiplier));
        if (windowHeight > FilterSelector.MAX_WINDOW_HEIGHT) {
            windowHeight = FilterSelector.MAX_WINDOW_HEIGHT;
        }

        me.window.setSize(FilterSelector.WINDOW_WIDTH, windowHeight);

        # Check whether the selector window does not go outside the screen at the bottom, if so, move it up
        var posY = me.getPosY();
        var screenH = me.getScreenHeight();
        if (screenH - posY < windowHeight) {
            posY = screenH - windowHeight;
            me.window.setPosition(me.getPosX(), posY);
        }
    },

    #
    # Set column index of filter as File.INDEX_[...]
    #
    # int index - Column index as File.INDEX_[...] of column
    # return me
    #
    setColumnIndex: func(index) {
        me.columnIndex = index;
        return me;
    },

    #
    # Set callback function (with object) which will be call to apply filter
    #
    # hash objCallback - The class object which contains the callback function
    # func callback
    # return me
    #
    setCallback: func(objCallback, callback) {
        me.objCallback = objCallback;
        me.callback = callback;
        return me;
    },

    #
    # hash style
    # return me
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        if (me.scrollData != nil) {
            me.scrollData.setColorBackground(me.style.CANVAS_BG);
        }

        return me;
    },

    #
    # return void
    #
    reDrawContent: func() {
        me.vbox.clear();

        var margins = {
            "left"   : FilterSelector.PADDING,
            "top"    : FilterSelector.PADDING,
            "right"  : 0,
            "bottom" : FilterSelector.PADDING,
        };
        me.scrollData = me.createScrollArea(me.style.CANVAS_BG, margins);

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent(me.scrollData, me.font, me.fontSize);

        me.drawScrollable();
    },

    #
    # Draw content for scrollable area
    #
    # return void
    #
    drawScrollable: func() {
        me.scrollDataContent.removeAllChildren();

        var x = FilterSelector.PADDING * 2;
        var y = 0;
        y = me.drawHoverBoxTitle(x, y);
        y = me.drawHoverBoxSeparator(y);

        if (me.withDefaultAll) {
            rowGroup = me.drawHoverBox(
                y,
                [me.columnIndex, FilterSelector.CLEAR_FILTER_VALUE],
                me.style.CANVAS_BG
            );
            me.drawText(rowGroup, x, "Default All");
            y += ListView.SHIFT_Y;
        }

        foreach (var text; me.items) {
            var label = text == "" ? "<empty>" : text;
            var rowGroup = me.drawHoverBox(y, [me.columnIndex, text], me.style.CANVAS_BG);
            me.drawText(rowGroup, x, label);

            y += ListView.SHIFT_Y;
        }

        # Scrollable content must be updated for set paddings
        me.scrollDataContent.update();
    },

    #
    # int x, y
    # return int - Y pos
    #
    drawHoverBoxTitle: func(x, y) {
        var group = me.drawHoverBox(y, nil, me.style.CANVAS_BG, false);
        me.drawText(group, x, me.title);
        y += ListView.SHIFT_Y;
        return y;
    },

    #
    # int y
    # return int - Y pos
    #
    drawHoverBoxSeparator: func(y) {
        return y + ListView.SHIFT_Y * FilterSelector.SEPARATOR_H_MULTIPLIER;
    },

    #
    # int y
    # vector|nil dataToPass - data to pass to MouseHover
    # return hash - canvas group
    #
    drawHoverBoxItems: func(y, dataToPass = nil) {
        return me.drawHoverBox(y, dataToPass, me.style.CANVAS_BG);
    },

    #
    # int y
    # vector|nil dataToPass - data to pass to MouseHover
    # vector bgColor
    # bool isMouseHover
    # return hash - canvas group
    #
    drawHoverBox: func(y, dataToPass, bgColor, isMouseHover = 1) {
        var rowGroup = me.scrollDataContent.createChild("group")
            .setTranslation(0, y);

        # Create rect because setColorFill on rowGroup doesn't work
        var rect = rowGroup.rect(0, 0, FilterSelector.WINDOW_WIDTH - (ListView.PADDING * 3), ListView.SHIFT_Y)
            .setColorFill(bgColor);

        if (isMouseHover) {
            rowGroup.addEventListener("mouseenter", func {
                rect.setColorFill(me.style.HOVER_BG);
            });

            rowGroup.addEventListener("mouseleave", func {
                rect.setColorFill(me.style.CANVAS_BG);
            });

            if (dataToPass != nil) {
                rowGroup.addEventListener("click", func {
                    call(me.callback, dataToPass, me.objCallback);
                    me.hide();
                });
            }
        }

        return rowGroup;
    },

    #
    # hash cGroup - Parent canvas group
    # int x
    # string text
    # int|nil maxWidth
    # return hash - canvas text object
    #
    drawText: func(cGroup, x, text, maxWidth = nil) {
        var text = cGroup.createChild("text")
            .setTranslation(x, me.getTextYOffset())
            .setColor(me.style.TEXT_COLOR)
            .setText(text);

        if (maxWidth != nil) {
            text.setMaxWidth(maxWidth);
        }

        return text;
    },

    #
    # return int
    #
    getTextYOffset: func() {
        if (me.fontSize == 12) {
            return 16;
        }

        if (me.fontSize == 16) {
            return 18;
        }

        return 0;
    },
};
