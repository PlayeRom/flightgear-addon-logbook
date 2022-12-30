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
# DetailsDialog class to display one row details
#
var DetailsDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 600,
    WINDOW_HEIGHT : 600,
    FONT_NAME     : "LiberationFonts/LiberationMono-Bold.ttf",
    COLUMNS_WIDTH : [
        120, # header
        440, # data
    ],

    #
    # Constructor
    #
    # @param hash settings - Settings object
    # @param hash file - File object
    # @return me
    #
    new: func(settings, file) {
        var me = { parents: [
            DetailsDialog,
            Dialog.new(settings, DetailsDialog.WINDOW_WIDTH, DetailsDialog.WINDOW_HEIGHT, "Logbook Details"),
        ] };

        # Override window del method for hide InputDialog and ConfirmationDialog
        var self = me;
        me.window.del = func() {
            call(DetailsDialog.hide, [], self);
        };

        me.parent          = nil;
        me.dataRow         = nil;
        me.isTotals        = false;
        me.parentDataIndex = nil;
        me.file            = file;
        me.inputDialog     = InputDialog.new(settings);
        me.deleteDialog    = ConfirmationDialog.new(settings, "Delete entry log");
        me.deleteDialog.setLabel("Do you really want to delete this entry?");

        me.canvas.set("background", me.style.CANVAS_BG);

        var margins = {
            "left"   : canvas.DefaultStyle.widgets.ListView.PADDING,
            "top"    : canvas.DefaultStyle.widgets.ListView.PADDING,
            "right"  : 0,
            "bottom" : 0,
        };
        me.scrollData = me.createScrollArea(me.style.LIST_BG, margins);
        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch
        me.scrollDataContent = me.getScrollAreaContent(me.scrollData);

        var vBoxLayout = canvas.VBoxLayout.new();
        me.listView = canvas.gui.widgets.ListView.new(me.scrollDataContent, canvas.style, {})
            .setFontSizeLarge()
            .setFontName(DetailsDialog.FONT_NAME)
            .setColumnsWidth(DetailsDialog.COLUMNS_WIDTH)
            .setClickCallback(me.listViewCallback, me)
            .useTextMaxWidth();

        me.setListViewStyle();

        vBoxLayout.addItem(me.listView);
        me.scrollData.setLayout(vBoxLayout);

        me.drawBottomBar();

        me.setPositionOnCenter();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.inputDialog.del();
        me.deleteDialog.del();
        call(Dialog.del, [], me);
    },

    #
    # @return void
    #
    drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Close")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                call(me.hide, [], me);
            }
        );

        var btnDelete = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Delete")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                if (!g_isThreadPending) {
                    me.deleteDialog.show(me.parentDataIndex, me);
                }
            }
        );

        buttonBox.addStretch(3);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnDelete);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(canvas.DefaultStyle.widgets.ListView.PADDING);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(canvas.DefaultStyle.widgets.ListView.PADDING);
    },

    #
    # @param hash style
    # @return void
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.scrollData.setColorBackground(me.style.LIST_BG);
        me.setListViewStyle();
        me.toggleBgImage();

        me.inputDialog.setStyle(style);
    },

    #
    # @return hash - ListView widget
    #
    setListViewStyle: func() {
        return me.listView
            .setColorText(me.style.TEXT_COLOR)
            .setColorBackground(me.style.LIST_BG)
            .setColorHoverBackground(me.style.HOVER_BG);
    },

    #
    # Show canvas dialog
    #
    # @param hash parent - LogbookDialog object
    # @param hash data - {"allDataIndex": index, "data": vector}
    # @param bool isTotals
    # @return void
    #
    show: func(parent, data, isTotals) {
        me.parent = parent;
        me.dataRow = data;
        me.isTotals = isTotals;

        me.inputDialog.hide();
        me.deleteDialog.hide();

        me.parentDataIndex = me.dataRow.allDataIndex;

        me.listView.setItems(me.getListViewRows(me.dataRow.data));

        call(Dialog.show, [], me);
    },

    #
    # Hide details window with its sub windows
    #
    # @return void
    #
    hide: func() {
        if (me.parent != nil) {
            # Remove highlighted row in LogbookDialog
            me.parent.listView.removeHighlightingRow();
            me.parent.allDataIndexSelected = nil;
        }

        me.parentDataIndex = nil;
        me.inputDialog.hide();
        me.deleteDialog.hide();
        call(Dialog.hide, [], me);
    },

    #
    # Perapre columns data for ListView
    #
    # @param vector data
    # @return vector
    #
    getListViewRows: func(data) {
        var headers = me.file.getHeadersData();
        var rowsData = [];

        var start = 0;
        if (me.isTotals) {
            start = File.INDEX_LANDING;
        }

        forindex (var index; headers[start:]) {
            var shiftIndex = index + start;
            if (me.isTotals and shiftIndex == File.INDEX_NOTE) {
                break;
            }

            append(rowsData, {
                data : [
                    sprintf("%10s:", headers[shiftIndex]),
                    sprintf("%s %s",
                        me.addCommaSeparator(shiftIndex, data[shiftIndex]),
                        me.getExtraText(shiftIndex, data[shiftIndex])
                    ),
                ],
            });
        }

        return rowsData;
    },

    #
    # Reload current log
    #
    # @return void
    #
    reload: func() {
        if (me.parentDataIndex != nil) {
            me.dataRow = me.file.getLogData(me.parentDataIndex);
            if (me.dataRow == nil) {
                call(DetailsDialog.hide, [false], me);
                return;
            }

            me.listView.setItems(me.getListViewRows(me.dataRow.data));
        }
    },

    #
    # The click callback on the ListView widget. Open the inputDialog.
    #
    # @param int index
    # @return void
    #
    listViewCallback: func(index) {
        if (!g_isThreadPending) {
            if (me.dataRow.allDataIndex > -1) { # -1 is using for Totals row
                me.listView.removeHighlightingRow();
                me.listView.setHighlightingRow(index, me.style.SELECTED_BAR);

                var headers = me.file.getHeadersData();
                me.inputDialog.show(me, me.dataRow.allDataIndex, headers[index], me.dataRow.data[index]);
            }
        }
    },

    #
    # @param int column
    # @param string value
    # @return string
    #
    getExtraText: func(column, value) {
        if ((column == File.INDEX_FROM or column == File.INDEX_TO) and value != "") {
            var airport = airportinfo(value);
            if (airport != nil) {
                return "(" ~ airport.name ~ ")";
            }

            return "";
        }

        if (column >= File.INDEX_DAY and column <= File.INDEX_DURATION) {
            var digits = split(".", value);
            if (size(digits) < 2) {
                # something is wrong
                return "hours";
            }

            return sprintf("hours (%d:%02.0f)", digits[0], (digits[1] / 100) * 60);
        }

        if (column == File.INDEX_DISTANCE) {
            var inMeters = value * globals.NM2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("nm (%s km)", me.getValueWithCommaSeparator(km));
            }

            return sprintf("nm (%.0f m)", inMeters);
        }

        if (column == File.INDEX_FUEL) {
            var liters = sprintf("%.02f", value * globals.GAL2L);
            return sprintf("US gallons (%s l)", me.getValueWithCommaSeparator(liters));
        }

        if (column == File.INDEX_MAX_ALT) {
            var inMeters = value * globals.FT2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("ft MSL (%s km)", me.getValueWithCommaSeparator(km));
            }

            return sprintf("ft MSL (%.0f m)", inMeters);
        }

        return "";
    },

    #
    # @param int column
    # @param string value
    # @return string
    #
    addCommaSeparator: func(column, value) {
        if (column == File.INDEX_DISTANCE or
            column == File.INDEX_FUEL or
            column == File.INDEX_MAX_ALT
        ) {
            return me.getValueWithCommaSeparator(value);
        }

        return value;
    },

    #
    # @param string value
    # @return string
    #
    getValueWithCommaSeparator: func(value) {
        var splitted   = split(".", value);
        var strToCheck = splitted[0];
        var newValue   = strToCheck;
        var length     = size(strToCheck);
        if (length > 3) {
            newValue = "";
            var modulo = math.mod(length, 3);
            if (modulo > 0) {
                newValue ~= substr(strToCheck, 0, modulo);
                newValue ~= ",";
            }

            for (var i = modulo; i < length; i += 3) {
                newValue ~= substr(strToCheck, i, 3);
                if (i + 3 < length) {
                    newValue ~= ",";
                }
            }
        }

        if (size(splitted) == 2) {
            return newValue ~ "." ~ splitted[1];
        }

        return newValue;
    },
};
