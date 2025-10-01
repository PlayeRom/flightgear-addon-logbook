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
    CLASS: "FilterSelector",

    #
    # Constants
    #
    WINDOW_WIDTH           : 250,
    WINDOW_HEIGHT          : 300,
    PADDING                : 10,
    BUTTON_HEIGHT          : 26,
    CLEAR_FILTER_VALUE     : "All",
    SEPARATOR_H_MULTIPLIER : 0.25,

    #
    # Constructor
    #
    # @param  hash  columns  Columns object
    # @return hash
    #
    new: func(columns) {
        var me = {
            parents: [
                FilterSelector,
                StylePersistentDialog.new(
                    FilterSelector.WINDOW_WIDTH,
                    FilterSelector.WINDOW_HEIGHT,
                    "Filter selector"
                ),
            ],
            _columns: columns,
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, FilterSelector); # Let the parent know who their child is.

        me._MAX_WINDOW_HEIGHT = LogbookDialog.MAX_WINDOW_HEIGHT - 50;

        me._font     = "LiberationFonts/LiberationSans-Bold.ttf";
        me._fontSize = 14;
        me._title    = "Filter";

        me._window.set("decoration-border", "0 0 0");

        me._bgImage.hide();

        me._canvas.set("background", me._style.CANVAS_BG);

        me._items = std.Vector.new();

        me._scrollArea = nil;
        me._scrollContent = nil;
        me._listView = nil;
        me._callback = nil;
        me._columnName = nil;

        me._drawContent();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    # @override StylePersistentDialog
    #
    del: func() {
        me._parentDialog.del();
    },

    #
    # Hide canvas window
    #
    # @return void
    # @override StylePersistentDialog
    #
    hide: func() {
        me._parentDialog.hide();
    },

    #
    # Show canvas window
    #
    # @return void
    # @override StylePersistentDialog
    #
    show: func() {
        me._recalculateWindowHeight();

        me._parentDialog.show();
    },

    #
    # @param  int  x, y
    # @return hash
    #
    setPosition: func(x, y) {
        me._window.setPosition(x, y);
        return me;
    },

    #
    # @param  string  title
    # @return hash
    #
    setTitle: func(title) {
        me._title = title;
        me._window.setTitle(title);

        if (me._listView != nil) {
            me._listView.setTitle(me._title);
        }

        return me;
    },

    #
    # @param  vector  items  Vector of strings
    # @param  bool  withDefaultAll
    # @return hash
    #
    setItems: func(items, withDefaultAll = 1) {
        me._items.clear();

        var columnWidth = FilterSelector.WINDOW_WIDTH - (FilterSelector.PADDING * 2);

        if (withDefaultAll) {
            me._items.append({
                columns: [{
                    width: columnWidth,
                    data : FilterSelector.CLEAR_FILTER_VALUE,
                }],
            });
        }

        foreach (var text; items) {
            me._items.append({
                columns: [{
                    width: columnWidth,
                    data : text,
                }],
            });
        }

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

        var windowHeight = int(count * canvas.DefaultStyle.widgets["logbook-list-view"].ITEM_HEIGHT);
        if (windowHeight > me._MAX_WINDOW_HEIGHT) {
            windowHeight = me._MAX_WINDOW_HEIGHT;
        }

        me._window.setSize(FilterSelector.WINDOW_WIDTH, windowHeight);

        # Check whether the selector window does not go outside the screen at the bottom, if so, move it up
        var posY = me.getPosY();
        var screenH = me.getScreenHeight();
        if (screenH - posY < windowHeight) {
            posY = screenH - windowHeight;
            me._window.setPosition(me.getPosX(), posY);
        }
    },

    #
    # Set column name
    #
    # @param  string  name  Column name
    # @return hash
    #
    setColumnName: func(name) {
        me._columnName = name;
        return me;
    },

    #
    # Set callback which will be call to apply filter.
    #
    # @param  hash  callback  Callback object.
    # @return hash
    #
    setCallback: func(callback) {
        me._callback = callback;
        return me;
    },

    #
    # @param  hash  style
    # @return hash
    #
    setStyle: func(style) {
        me._style = style;

        me._canvas.set("background", me._style.CANVAS_BG);
        if (me._scrollArea != nil) {
            me._scrollArea.setColorBackground(me._style.CANVAS_BG);
        }

        if (me._listView != nil) {
            me._listView
                .setColorText(me._style.TEXT_COLOR)
                .setColorBackground(me._style.CANVAS_BG)
                .setColorHoverBackground(me._style.HOVER_BG);
        }

        return me;
    },

    #
    # @return void
    #
    _drawContent: func() {
        me._vbox.clear();

        var margins = {
            left   : 0,
            top    : 0,
            right  : 0,
            bottom : 0,
        };
        me._scrollArea = ScrollAreaHelper.create(me._group, margins, me._style.CANVAS_BG);

        me._vbox.addItem(me._scrollArea, 1); # 2nd param = stretch

        me._scrollContent = ScrollAreaHelper.getContent(me._scrollArea, me._font, me._fontSize);

        me._drawScrollable();
    },

    #
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        me._listView = canvas.gui.widgets.LogbookList.new(me._scrollContent)
            .setTitle(me._title)
            .useTextMaxWidth()
            .setFontSizeMedium()
            .setColorText(me._style.TEXT_COLOR)
            .setColorBackground(me._style.CANVAS_BG)
            .setColorHoverBackground(me._style.HOVER_BG)
            .setClickCallback(me._listViewCallback, me)
            .setItems(me._items.vector);

        vBoxLayout.addItem(me._listView);
        me._scrollArea.setLayout(vBoxLayout);
    },

    #
    # The click callback on the LogbookList widget.
    # Call other callback passed by parent object by setCallback and hide this dialog.
    #
    # @param  int  index  Index of row
    # @return void
    #
    _listViewCallback: func(index) {
        g_Sound.play('paper');

        var text = me._items.vector[index].columns[0].data;

        me._callback.invoke(me._columnName, text);
        me.hide();
    },
};
