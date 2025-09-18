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
# Example of use:
#############################################################################################
# Notes for images:
# 1. All images will have the same height, default 64 px. To change this value, use setImageHeight().
# 2. All images must have the same aspect ratio, default 1.3333. To change this value, use setImageAspectRatio().
# 3. ListView doesn't care if the image goes beyond the column width or not. If the image goes beyond the column width,
#    just pass a larger value for the column by `width` field.
#
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
#         # First row:
#         {
#             columns: [
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       type   : "string",                                     # <- optional, default is string
#                       colspan: 1,                                            # <- optional, default is 1
#                       font   : "LiberationFonts/LiberationSans-Regular.ttf", # <- optional, set font for this cell
#                       data   : "Row 1 column 1",                             # <- required, text in cell
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       type   : "string",                                     # <- optional, default is string
#                       colspan: 1,                                            # <- optional, default is 1
#                       font   : "LiberationFonts/LiberationSans-Bold.ttf",    # <- optional, set font for this cell
#                       data   : "Row 1 column 2",                             # <- required, text in cell
#                  },
#             ],
#             font: "LiberationFonts/LiberationSans-Regular.ttf",              # <- optional, set font for whole row (profity has column font)
#         },
#         # Second row with image:
#         {
#             columns: [
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       type   : "image",                                      # <- indicate that data is path to image, not text to print
#                       colspan: 1,                                            # <- optional, default is 1
#                       data   : "Textures/Splash1.png",                       # <- path to the image instead of text
#                  },
#                  {
#                       width  : 150,
#                       type   : "string",                                     # <- optional, default is string
#                       colspan: 1,                                            # <- optional, default is 1
#                       font   : "LiberationFonts/LiberationSans-Bold.ttf",    # <- optional, set font for this cell
#                       data   : "Row 2 column 2",                             # <- required, text in cell
#                  },
#             ],
#             font: "LiberationFonts/LiberationSans-Regular.ttf",              # <- optional, set font for whole row (profity has column font)
#         }
#         # Third row with colspan:
#         {
#             columns: [
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       type   : "string",                                     # <- optional, default is string
#                       colspan: 2,                                            # <- this column will span to the next one,
#                       font   : "LiberationFonts/LiberationSans-Regular.ttf", # <- optional, set font for this cell
#                       data   : "Row 3 - some log text with span columns",    # <- required, text in cell
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 0,                                            # <- must be 0, if previous column has colspan > 1,
#                  },
#             ],
#             font: "LiberationFonts/LiberationSans-Regular.ttf",              # <- optional, set font for whole row (profity has column font)
#         }
#     ]);
#
#############################################################################################
# Example of use with useOptimizeRow():
#############################################################################################
# Notes: This is a more efficient method, where the entire row is rendered as a single text element (instead of
# creating a text element per cell). So if you have 20 rows, each with 30 columns, only 20 text elements are created,
# instead of 600!
#
# Limitations:
# 1. The font must be mono everywhere, because only then it's possible to align the columns.
# 2. You cannot use a different font for the cell, only for the entire row (still must be mono, but you can choose
#    regular or bold).
# 3. You cannot use images.
#
# Additional options:
# 1. For the cell, you can use the `align` field with the value "left" (default) or "right".
#
# listView
#     .useOptimizeRow()
#     .setClickCallback(func(index) {
#         gui.popupTip("Clicked on row " ~ index);
#     })
#     .setItems([
#         # First row:
#         {
#             columns: [
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 1,                                            # <- optional, default is 1
#                       align  : "left",                                       # <- optional, text align, default "left"
#                       data   : "Row 1 column 1",                             # <- required, text in cell
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 1,                                            # <- optional, default is 1
#                       align  : "left",                                       # <- optional, text align, default "left"
#                       data   : "Row 1 column 2",                             # <- required, text in cell
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 1,                                            # <- optional, default is 1
#                       align  : "left",                                       # <- optional, text align, default "left"
#                       data   : "Row 1 column 3",                             # <- required, text in cell
#                  },
#             ],
#             font: "LiberationFonts/LiberationMono-Regular.ttf",              # <- optional, set font for whole row
#         },
#         # Second row:
#         {
#             columns: [
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 1,                                            # <- optional, default is 1
#                       align  : "left",                                       # <- optional, text align, default "left"
#                       data   : "Row 2 column 1",                             # <- required, text in cell
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 1,                                            # <- optional, default is 1
#                       align  : "left",                                       # <- optional, text align, default "left"
#                       data   : "Row 2 column 2",                             # <- required, text in cell
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 1,                                            # <- optional, default is 1
#                       align  : "left",                                       # <- optional, text align, default "left"
#                       data   : "Row 2 column 3",                             # <- required, text in cell
#                  },
#             ],
#             font: "LiberationFonts/LiberationMono-Regular.ttf",              # <- optional, set font for whole row
#         },
#         # Third row:
#         {
#             columns: [
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 2,                                            # <- this column will span to the next one,
#                       align  : "right",                                      # <- align text to right
#                       data   : "Totals:",                                    # <- required, text in cell
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 0,                                            # <- must be 0, if previous column has colspan,
#                  },
#                  {
#                       width  : 150,                                          # <- required, column width in pixels
#                       colspan: 1,                                            # <- optional, default is 1
#                       align  : "left",                                       # <- optional, text align, default "left"
#                       data   : "Row 3 column 3",                             # <- required, text in cell
#                  },
#             ],
#             font: "LiberationFonts/LiberationMono-Bold.ttf",                 # <- optional, set font for whole row
#         }
#     ]);
#

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
    # @return ghost
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
    # @return ghost
    #
    setTranslation: func(x, y) {
        me._view.setTranslation(me, x, y);
        return me;
    },

    #
    # Set title as non clickable description text on the top
    #
    # @param  string  text
    # @return ghost
    #
    setTitle: func(text) {
        me._title = text;
        me._view.setTitle(me, text);
        return me;
    },

    #
    # @param  func  callback  The click callback with int parameter as clicked item index
    # @param  hash  callbackContext  The click callback context
    # @return ghost
    #
    setClickCallback: func(callback, callbackContext = nil) {
        me._callbackContext = callbackContext;
        me._callback = callback;
        return me;
    },

    #
    # @param  vector  color
    # @return ghost
    #
    setColorText: func(color) {
        me._view.setColorText(me, color);
        return me;
    },

    #
    # @param  vector  color
    # @return ghost
    #
    setColorBackground: func(color) {
        me._view.setColorBackground(me, color);
        return me;
    },

    #
    # @param  vector  color
    # @return ghost
    #
    setColorHoverBackground: func(color) {
        me._view.setColorHoverBackground(me, color);
        return me;
    },

    #
    # @return ghost
    #
    setFontSizeSmall: func() {
        me._view.setFontSize(model: me, fontSize: 12);
        return me;
    },

    #
    # @return ghost
    #
    setFontSizeMedium: func() {
        me._view.setFontSize(model: me, fontSize: 14);
        return me;
    },

    #
    # @return ghost
    #
    setFontSizeLarge: func() {
        me._view.setFontSize(model: me, fontSize: 16);
        return me;
    },

    #
    # @param  string  font
    # @return ghost
    #
    setFontName: func(font) {
        me._view.setFontName(me, font);
        return me;
    },

    #
    # Set vector of hashes as ListView data to display. Each hash in vector is a one row. Each row has `columns` key and
    # optional `font` (string as file font to apply to whole row).
    # Each `column` is another vector of hashes. Each hash represent a one column. Each column has following keys:
    # `width`   - width of column in pixels, it's required for all columns.
    # `type`    - type of column, can be "string" (default) or "image". Image in not supported with useOptimizeRow().
    # `colspan` - default 1. If more than 1, it means that the column will span the width of the next columns that
    #             follow it. Columns that will be absorbed by the previous span must have colspan set to 0. So if you
    #             set colspan to 2, then the next one column must have colspan 0. If you set colspan to 3, then the next
    #             two columns must have colspan 0, etc.
    # `font`    - font file name which will be applied to gibne column. Font in not supported with useOptimizeRow().
    # `data`    - text to display (if type is "string") or path to image file (if type is "image").
    # `align`   - text align, it can be "left" (default) or "right", only with useOptimizeRow().
    #
    # @param  vector  items
    # [
    #     {
    #         columns: [
    #              {
    #                   width  : 150,                                          # <- required, column width in pixels
    #                   type   : "string",                                     # <- optional, default is string
    #                   colspan: 1,                                            # <- optional, default is 1
    #                   font   : "LiberationFonts/LiberationSans-Regular.ttf", # <- optional, set font for this cell
    #                   data   : "Row 1 column 1",
    #              },
    #              {
    #                   width  : 150,                                          # <- required, column width in pixels
    #                   type   : "string",                                     # <- optional, default is string
    #                   colspan: 1,                                            # <- optional, default is 1
    #                   font   : "LiberationFonts/LiberationSans-Bold.ttf",    # <- optional, set font for this cell
    #                   data   : "Row 1 column 2",
    #              },
    #              ... next columns
    #         ],
    #         font: "LiberationFonts/LiberationSans-Regular.ttf",              # <- optional, set font for whole row (profity has column font)
    #     },
    #     ... next rows
    # ]
    # @param  bool  disableLoading
    # @return ghost
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
    # @param  int  index
    # @param  vector  color
    # @return ghost
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
    # @return ghost
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
    # @return ghost
    #
    enableLoading: func() {
        me._isLoading = 1;
        me._view.reDrawContent(me);
        return me;
    },

    #
    # Disable displaying "Loading..." text and redraw content for displaying list
    #
    # @return ghost
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
    # @return ghost
    #
    useTextMaxWidth: func() {
        me._isUseTextMaxWidth = 1;
        return me;
    },

    #
    # Use it for crate one text element per row instead of one text element per cell
    # NOTE: here the font has to be mono!
    #
    # @return ghost
    #
    useOptimizeRow: func() {
        me._isOptimizeRow = 1;
        return me;
    },

    #
    # @param  vector  boundingBox  [xmin, ymin, xmax, ymax]
    # @return ghost
    #
    setClipByBoundingBox: func(boundingBox) {
        me._view.setClipByBoundingBox(me, boundingBox);
        return me;
    },

    #
    # Set the placeholder text to use when a cell has an empty string value
    #
    # @param  string|nil  placeholder
    # @return ghost
    #
    setEmptyPlaceholder: func(placeholder) {
        me._placeholder = placeholder;
        return me;
    },

    #
    # Set height of images in pixels
    #
    # @param  int  height
    # @return ghost
    #
    setImageHeight: func(height) {
        me._imgHeight = height;
        return me;
    },

    #
    # Set aspect ratio of images. The width of the image will be = _imgHeight * _imgAspectRatio.
    #
    # @param  double  aspectRatio
    # @return ghost
    #
    setImageAspectRatio: func(aspectRatio) {
        me._imgAspectRatio = aspectRatio;
        return me;
    },
};
