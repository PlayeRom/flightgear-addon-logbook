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
#############################################################################################
# Simplest example of use:
#############################################################################################
# var window = canvas.Window.new([600, 480], "dialog").set("title", "ListView demo");
# var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
# var root = myCanvas.createGroup();
#
# var vbox = canvas.VBoxLayout.new();
# myCanvas.setLayout(vbox);
#
# var listView = canvas.gui.widgets.ListView.new(root, canvas.style, {});
# vbox.addItem(listView, 1);
#
# listView
#     .setClickCallback(func(index) {
#         gui.popupTip("Clicked on row " ~ index);
#     })
#     .setItems([
#         "Item text 1",
#         "Item text 2",
#         "Item text 3",
#         "Item text 4",
#         "Item text 5",
#     ]);
#
#############################################################################################
# The simplest use case with multiple columns:
#############################################################################################
# listView
#     .setClickCallback(func(index) {
#         gui.popupTip("Clicked on row " ~ index);
#     })
#     .setColumnsWidth([150, 150, 150])
#     .setItems([
#         {
#             data: [
#                 "Row 1 column 1",
#                 "Row 1 column 2",
#                 "Row 1 column 3",
#             ]
#         },
#         {
#             data: [
#                 "Row 2 column 1",
#                 "Row 2 column 2",
#                 "Row 2 column 3",
#             ]
#         },
#         {
#             data: [
#                 "Row 3 column 1",
#                 "Row 3 column 2",
#                 "Row 3 column 3",
#             ]
#         },
#     ]);
#############################################################################################
# The simplest use case with multiple columns and images in the columns:
#############################################################################################
# Notes for images:
# 1. All images will have the same height, default 64 px. To change this value, use setImageHeight().
# 2. All images must have the same aspect ratio, default 1.3333. To change this value, use setImageAspectRatio().
# 3. ListView doesn't care if the image goes beyond the column width or not. If the image goes beyond the column width,
#    just pass a larger value for the column by using setColumnsWidth() method.
#
# listView
#     .setClickCallback(func(index) {
#         gui.popupTip("Clicked on row " ~ index);
#     })
#     .setColumnsWidth([150, 150, 150])
#     .setItems([
#         {
#             types: [
#                 "string",
#                 "string",
#                 "image", # <- indicate that 3rd column is an image
#             ],
#             data: [
#                 "Row 1 column 1",
#                 "Row 1 column 2",
#                 "Textures/Splash1.png", # <- path to the image instead of text
#             ],
#         },
#         {
#             types: [
#                 "string",
#                 "image", # <- indicate that 2nd column is an image
#                 "string",
#             ],
#             data: [
#                 "Row 2 column 1",
#                 "Textures/Splash2.png", # <- path to the image instead of text
#                 "Row 2 column 3",
#             ],
#         },
#         {
#             # There is no need to include "types", since there is a string in all columns.
#             data: [
#                 "Row 3 column 1",
#                 "Row 3 column 2",
#                 "Row 3 column 3",
#             ],
#         },
#     ]);

#
# ListView widget Model
#
gui.widgets.ListView = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.ListView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "list-view", me._cfg));

        # The items of the list
        me._items = [];

        # Optional non-clickable title at the top of the list
        me._title = nil;

        # The callback function which will be call on click action on row
        me._callback = func;

        # The object which is the owner of the _callback function
        me._callbackContext = nil;

        # Index of row with permanent special highlighting
        me._highlightingRowIndex = nil;

        # If it's set on true, then "Loading..." text is displaying instead of list
        me._isLoading = 0;

        # If it's set on true, long texts will be wrapped to the width of the column by setMaxWidth() method
        me._isUseTextMaxWidth = 0;

        # If it's set on true, then ListView widget was recognized items as a complex structure with multi-columns
        me._isComplexItems = 0;

        # If it's set on true, then the entire one row will be drawn on a single “text” element, which greater
        # performance. If false then each cell will be a separate “text” (or "image") element. Only when it is false
        # is it possible to draw pictures on the list.
        me._isOptimizeRow = 0;

        #  The placeholder text to use when a cell has an empty string value, default nil - without placeholder
        me._placeholder = nil;

        # Images height, default 64 px.
        me._imgHeight = 64;

        # Aspect ratio of image width. The image width will be = _imgHeight * _imgAspectRatio.
        me._imgAspectRatio = 1.3333;

        return me;
    },

    #
    # @param  int  x, y
    # @return me
    #
    setTranslation: func(x, y) {
        me._view.setTranslation(me, x, y);
        return me;
    },

    #
    # Set title as non clickable description text on the top
    #
    # @param  string  text
    # @return me
    #
    setTitle: func(text) {
        me._title = text;
        me._view.setTitle(me, text);
        return me;
    },

    #
    # @param  func  callback  The click callback with int parameter as clicked item index
    # @param  hash  callbackContext  The click callback context
    # @return me
    #
    setClickCallback: func(callback, callbackContext = nil) {
        me._callbackContext = callbackContext;
        me._callback = callback;
        return me;
    },

    #
    # @param  vector  color
    # @return me
    #
    setColorText: func(color) {
        me._view.setColorText(me, color);
        return me;
    },

    #
    # @param  vector  color
    # @return me
    #
    setColorBackground: func(color) {
        me._view.setColorBackground(me, color);
        return me;
    },

    #
    # @param  vector  color
    # @return me
    #
    setColorHoverBackground: func(color) {
        me._view.setColorHoverBackground(me, color);
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
    # @param  string  font
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
    # @param  vector  columnsWidth  e.g. [200, 300, 150, ...]
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
    # @param  vector  items  ["Item 1", "Item 2", ...] or
    #                        [{data: ["Row 1 Col 1", "Row 1 Col 2", ...]}, {data: ["Row 2 Col 1", "Row 2 col 2", ...]}, ...]
    # @param  bool  disableLoading
    # @return me
    #
    setItems: func(items, disableLoading = 1) {
        if (disableLoading) {
            me._isLoading = 0;
        }

        me._items = items;
        me._isComplexItems = size(me._items) > 0 ? typeof(me._items[0]) == "hash" : 0;
        me._view.reDrawContent(me);

        return me;
    },

    #
    # Set permanently highlighting by given color, specific row given by index.
    # Mouse hover will not change this highlighting until removeHighlightingRow will be called.
    #
    # @param  int  index
    # @param  vector  color
    # @return me
    #
    setHighlightingRow: func(index, color) {
        me._highlightingRowIndex = index;
        me._view.setHighlightingRow(me, color);
        return me;
    },

    #
    # @return int|nil
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
    # Enable displaying "Loading..." text instead of list. For set the "Loading..." text on the center of list view
    # please call setMaxRows first.
    #
    # @return me
    #
    enableLoading: func() {
        me._isLoading = 1;
        me._view.reDrawContent(me);
        return me;
    },

    #
    # Disable displaying "Loading..." text and redraw content for displaying list
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

    #
    # Use it for wrap text to next line. The max text width will be column
    # width so setColumnsWidth must be call too.
    #
    # @return me
    #
    useTextMaxWidth: func() {
        me._isUseTextMaxWidth = 1;
        return me;
    },

    #
    # Use it for crate one text element per row instead of one text element per cell
    #
    # @return me
    #
    useOptimizeRow: func() {
        me._isOptimizeRow = 1;
        return me;
    },

    #
    # @param  vector  boundingBox  [xmin, ymin, xmax, ymax]
    # @return me
    #
    setClipByBoundingBox: func(boundingBox) {
        me._view.setClipByBoundingBox(me, boundingBox);
        return me;
    },

    #
    # Set the placeholder text to use when a cell has an empty string value
    #
    # @param  string|nil  placeholder
    # @return me
    #
    setEmptyPlaceholder: func(placeholder) {
        me._placeholder = placeholder;
        return me;
    },

    #
    # Set height of images in pixels
    #
    # @param  int  height
    # @return me
    #
    setImageHeight: func(height) {
        me._imgHeight = height;
        return me;
    },

    #
    # Set aspect ratio of images. The width of the image will be = _imgHeight * _imgAspectRatio.
    #
    # @param  double  aspectRatio
    # @return me
    #
    setImageAspectRatio: func(aspectRatio) {
        me._imgAspectRatio = aspectRatio;
        return me;
    },
};
