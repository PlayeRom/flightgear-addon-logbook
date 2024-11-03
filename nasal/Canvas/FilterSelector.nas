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
    # @param  hash  columns  Columns object
    # @return me
    #
    new: func(columns) {
        var me = {
            parents: [
                FilterSelector,
                Dialog.new(
                    FilterSelector.WINDOW_WIDTH,
                    FilterSelector.WINDOW_HEIGHT,
                    "Filter selector"
                ),
            ],
            _columns: columns,
        };

        me._font     = "LiberationFonts/LiberationSans-Bold.ttf";
        me._fontSize = 16;
        me._title    = "Filter";

        me.window.set("decoration-border", "0 0 0");

        me.bgImage.hide();

        me.canvas.set("background", me.style.CANVAS_BG);

        me._items = std.Vector.new();

        me._scrollData = nil;
        me._scrollDataContent = nil;
        me._listView = nil;
        me._callback = nil;
        me._objCallback = nil;
        me._columnIndex = nil;

        me._drawContent();

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
        me._recalculateWindowHeight();

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
        me._title = title;
        me.window.setTitle(title);

        if (me._listView != nil) {
            me._listView.setTitle(me._title);
        }

        return me;
    },

    #
    # @param vector items
    # @param bool withDefaultAll
    # @return me
    #
    setItems: func(items, withDefaultAll = 1) {
        me._items.clear();

        if (withDefaultAll) {
            me._items.append(FilterSelector.CLEAR_FILTER_VALUE);
        }

        me._items.extend(items);

        if (me._listView != nil) {
            me._listView.setItems(me._items.vector);
        }

        return me;
    },

    #
    # @return void
    #
    _recalculateWindowHeight: func() {
        var count = me._items.size() + 1 + FilterSelector.SEPARATOR_H_MULTIPLIER; # +1 for title bar

        var windowHeight = int(count * canvas.DefaultStyle.widgets["list-view"].ITEM_HEIGHT);
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
    # Set column index of filter as StorageCsv.INDEX_[...]
    #
    # @param int index - Column index as StorageCsv.INDEX_[...] of column
    # @return me
    #
    setColumnIndex: func(index) {
        me._columnIndex = index;
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
        me._objCallback = objCallback;
        me._callback = callback;
        return me;
    },

    #
    # @param hash style
    # @return me
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        if (me._scrollData != nil) {
            me._scrollData.setColorBackground(me.style.CANVAS_BG);
        }

        if (me._listView != nil) {
            me._listView
                .setColorText(me.style.TEXT_COLOR)
                .setColorBackground(me.style.CANVAS_BG)
                .setColorHoverBackground(me.style.HOVER_BG);
        }

        return me;
    },

    #
    # @return void
    #
    _drawContent: func() {
        me.vbox.clear();

        var margins = {
            left   : 0,
            top    : 0,
            right  : 0,
            bottom : 0,
        };
        me._scrollData = me.createScrollArea(me.style.CANVAS_BG, margins);

        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch

        me._scrollDataContent = me.getScrollAreaContent(me._scrollData, me._font, me._fontSize);

        me._drawScrollable();
    },

    #
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        me._listView = canvas.gui.widgets.ListView.new(me._scrollDataContent, canvas.style, {})
            .setTitle(me._title)
            .useTextMaxWidth()
            .setColumnsWidth([FilterSelector.WINDOW_WIDTH - (FilterSelector.PADDING * 2)])
            .setFontSizeLarge()
            .setColorText(me.style.TEXT_COLOR)
            .setColorBackground(me.style.CANVAS_BG)
            .setColorHoverBackground(me.style.HOVER_BG)
            .setClickCallback(me._listViewCallback, me)
            .setItems(me._items.vector);

        vBoxLayout.addItem(me._listView);
        me._scrollData.setLayout(vBoxLayout);
    },

    #
    # The click callback on the ListView widget.
    # Call other callback passed by parent object by setCallback and hide this dialog.
    #
    # @param int index
    # @return void
    #
    _listViewCallback: func(index) {
        g_Sound.play('paper');

        var text = me._items.vector[index];

        var dbColumnName = me._columns.getColumnNameByIndex(me._columnIndex);

        call(me._callback, [me._columnIndex, dbColumnName, text], me._objCallback);
        me.hide();
    },
};
