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
# ListView widget Model
#
gui.widgets.ListView = {
    #
    # Constructor
    #
    # @param hash parent
    # @param hash style
    # @param hash cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.ListView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "ListView", me._cfg));

        me._maxRows = nil;
        me._title = nil;
        me._items = [];
        me._callbackContext = nil;
        me._callback = func;
        me._highlightingRowIndex = nil;
        me._isLoading = 0;

        return me;
    },

    #
    # @param int x, y
    # @return me
    #
    setTranslation: func(x, y) {
        me._view.setTranslation(me, x, y);
        return me;
    },

    #
    # Set title as non clickable description text on the top
    #
    # @param string text
    # @return me
    #
    setTitle: func(text) {
        me._title = text;
        me._view.setTitle(me, text);
        return me;
    },

    #
    # @param hash callbackContext - The click callback context
    # @param func callback - The click callback with int parameter as clicked item index
    # @return me
    #
    setClickCallback: func(callbackContext, callback) {
        me._callbackContext = callbackContext;
        me._callback = callback;

        return me;
    },

    #
    # @param vector color
    # @return me
    #
    setTextColor: func(color) {
        me._view.setTextColor(me, color);
        return me;
    },

    #
    # @param vector color
    # @return me
    #
    setBackgroundColor: func(color) {
        me._view.setBackgroundColor(me, color);
        return me;
    },

    #
    # @param vector color
    # @return me
    #
    setHoverBackgroundColor: func(color) {
        me._view.setHoverBackgroundColor(me, color);
        return me;
    },

    #
    # @return me
    #
    setFontSizeSmall: func() {
        me._view.setFontSize(me, 12);
        return me;
    },

    #
    # @return me
    #
    setFontSizeMedium: func() {
        me._view.setFontSize(me, 14);
        return me;
    },

    #
    # @return me
    #
    setFontSizeLarge: func() {
        me._view.setFontSize(me, 16);
        return me;
    },

    #
    # @param string font
    # @return me
    #
    setFontName: func(font) {
        me._view.setFontName(me, font);
        return me;
    },

    #
    # Set columns widths in pixels as a vector (each item as an int). It's needed if you have to draw many columns
    # with data. When you use it, then for setItems you have to pass vector of hashes.
    #
    # @param vector columnsWidth - e.g. [200, 300, 150, ...]
    # @return me
    #
    setColumnsWidth: func(columnsWidth) {
        me._view.setColumnsWidth(me, columnsWidth);
        return me;
    },

    #
    # If you didn't use setColumnsWidth then items is a vector of strings. Then each string will be a row. If you used
    # setColumnsWidth then items is a vector of hashes, where each hash must have "data" key with a vector of strings.
    # Then each hash will be a row and each string will be a column in its row. In this case, the size of the string
    # vector must be the same as the size of the vector given in setColumnsWidth.
    #
    # @param vector items - ["Item 1", "Item 2", ...] or
    #                       [{data: ["Row 1 Col 1", "Row 1 Col 2", ...]}, {data: ["Row 2 Col 1", "Row 2 col 2", ...]}, ...]
    # @param bool disableLoading
    # @return me
    #
    setItems: func(items, disableLoading = 1) {
        if (disableLoading) {
            me._isLoading = 0;
        }

        me._items = items;
        me._view.reDrawContent(me);

        return me;
    },

    #
    # Set permanently highlighting by given color, specific row given by index.
    # Mouse hover will not change this highlighting until removeHighlightingRow will be called.
    #
    # @param int index
    # @param vector color
    # @return me
    #
    setHighlightingRow: func(index, color) {
        me._highlightingRowIndex = index;
        me._view.setHighlightingRow(me, color);
        return me;
    },

    #
    # @return int
    #
    getHighlightingRow: func() {
        return me._highlightingRowIndex;
    },

    #
    # Remove row highlighting which was set by setHighlightingRow.
    #
    # @return me
    #
    removeHighlightingRow: func() {
        if (me._highlightingRowIndex != nil) {
            me._view.removeHighlightingRow(me);
            me._highlightingRowIndex = nil;
        }

        return me;
    },

    #
    # @param int maxRows
    # @return me
    #
    setMaxRows: func(maxRows) {
        me._maxRows = maxRows;
        return me;
    },

    #
    # @return int
    #
    getContentHeight: func() {
        return me._view.getContentHeight(me);
    },

    #
    # Enable disaplying "Loading..." text instead of list. For set the "Loading..." text on the center of list view
    # please call setMaxRows first.
    #
    enableLoading: func() {
        me._isLoading = 1;
        me._view.reDrawContent(me);
        return me;
    },

    #
    # Disable disaplying "Loading..." text and redraw content for displaying list
    #
    # @return me
    #
    disableLoading: func() {
        me._isLoading = 0;
        me._view.reDrawContent(me);
        return me;
    },

    #
    # @return bool
    #
    isLoading: func() {
        return me._isLoading;
    },
};