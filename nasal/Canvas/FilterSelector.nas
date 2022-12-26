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
    # @param hash settings - Settings object
    # @return me
    #
    new: func (settings) {
        var me = { parents: [
            FilterSelector,
            Dialog.new(
                settings,
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

        me.items = std.Vector.new();

        me.scrollData = nil;
        me.scrollDataContent = nil;
        me.listView = nil;
        me.callback = nil;
        me.objCallback = nil;
        me.columnIndex = nil;

        me.drawContent();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Hide canvas window
    #
    # @return void
    #
    hide: func() {
        call(Dialog.hide, [], me);
    },

    #
    # Show canvas window
    #
    # @return void
    #
    show: func() {
        me.recalculateWindowHeight();

        call(Dialog.show, [], me);
    },

    #
    # @param int x, y
    # @return me
    #
    setPosition: func(x, y) {
        me.window.setPosition(x, y);
        return me;
    },

    #
    # @param string title
    # @return me
    #
    setTitle: func(title) {
        me.title = title;
        me.window.setTitle(title);

        if (me.listView != nil) {
            me.listView.setTitle(me.title);
        }

        return me;
    },

    #
    # @param vector items
    # @param bool withDefaultAll
    # @return me
    #
    setItems: func(items, withDefaultAll = 1) {
        me.items.clear();

        if (withDefaultAll) {
            me.items.append(FilterSelector.CLEAR_FILTER_VALUE);
        }

        me.items.extend(items);

        if (me.listView != nil) {
            me.listView.setItems(me.items.vector);
        }

        return me;
    },

    #
    # @return void
    #
    recalculateWindowHeight: func() {
        var paddingMultiplier = 2;
        var count = me.items.size() + 1 + FilterSelector.SEPARATOR_H_MULTIPLIER; # +1 for title bar

        var windowHeight = int(count * canvas.DefaultStyle.widgets.ListView.ITEM_HEIGHT + (FilterSelector.PADDING * paddingMultiplier));
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
    # @param int index - Column index as File.INDEX_[...] of column
    # @return me
    #
    setColumnIndex: func(index) {
        me.columnIndex = index;
        return me;
    },

    #
    # Set callback function (with object) which will be call to apply filter
    #
    # @param hash objCallback - The class object which contains the callback function
    # @param func callback
    # @return me
    #
    setCallback: func(objCallback, callback) {
        me.objCallback = objCallback;
        me.callback = callback;
        return me;
    },

    #
    # @param hash style
    # @return me
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        if (me.scrollData != nil) {
            me.scrollData.setColorBackground(me.style.CANVAS_BG);
        }

        if (me.listView != nil) {
            me.listView
                .setColorText(me.style.TEXT_COLOR)
                .setColorBackground(me.style.CANVAS_BG)
                .setColorHoverBackground(me.style.HOVER_BG);
        }

        return me;
    },

    #
    # @return void
    #
    drawContent: func() {
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
    # @return void
    #
    drawScrollable: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        me.listView = canvas.gui.widgets.ListView.new(me.scrollDataContent, canvas.style, {})
            .setTitle(me.title)
            .useTextMaxWidth()
            .setColumnsWidth([FilterSelector.WINDOW_WIDTH - (FilterSelector.PADDING * 2)])
            .setFontSizeLarge()
            .setColorText(me.style.TEXT_COLOR)
            .setColorBackground(me.style.CANVAS_BG)
            .setColorHoverBackground(me.style.HOVER_BG)
            .setClickCallback(me.listViewCallback, me)
            .setItems(me.items.vector);

        vBoxLayout.addItem(me.listView);
        me.scrollData.setLayout(vBoxLayout);
    },

    #
    # The click callback on the ListView widget.
    # Call other callback passed by parent object by setCallback and hide this dialog.
    #
    # @param int index
    # @return void
    #
    listViewCallback: func(index) {
        var text = me.items.vector[index];

        call(me.callback, [me.columnIndex, text], me.objCallback);
        me.hide();
    },
};
