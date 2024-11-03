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
    WINDOW_HEIGHT : 660,
    FONT_NAME     : "LiberationFonts/LiberationMono-Bold.ttf",
    COLUMNS_WIDTH : [
        120, # header
        440, # data
    ],

    #
    # Constructor
    #
    # @param  hash  storage  Storage object
    # @param  hash  columns  Columns object
    # @return me
    #
    new: func(storage, columns) {
        var me = { parents: [
            DetailsDialog,
            Dialog.new(DetailsDialog.WINDOW_WIDTH, DetailsDialog.WINDOW_HEIGHT, "Logbook Details"),
        ] };

        # Override window del method for hide InputDialog and ConfirmationDialog
        var self = me;
        me.window.del = func() {
            call(DetailsDialog.hide, [], self);
        };

        me._parent          = nil; # LogbookDialog object
        me._dataRow         = nil;
        me._isTotals        = false;
        me._parentDataIndex = nil;
        me._storage         = storage;
        me._columns         = columns;
        me._btnDelete       = nil;
        me._inputDialog     = InputDialog.new(columns);
        me._deleteDialog    = ConfirmationDialog.new("Delete entry log");
        me._deleteDialog.setLabel("Do you really want to delete this entry?");

        me.canvas.set("background", me.style.CANVAS_BG);

        var margins = {
            left   : canvas.DefaultStyle.widgets["list-view"].PADDING,
            top    : canvas.DefaultStyle.widgets["list-view"].PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollData = me.createScrollArea(me.style.LIST_BG, margins);
        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch
        me._scrollDataContent = me.getScrollAreaContent(me._scrollData);

        var vBoxLayout = canvas.VBoxLayout.new();
        me._listView = canvas.gui.widgets.ListView.new(me._scrollDataContent, canvas.style, {})
            .setFontSizeLarge()
            .setFontName(DetailsDialog.FONT_NAME)
            .setColumnsWidth(DetailsDialog.COLUMNS_WIDTH)
            .setClickCallback(me._listViewCallback, me)
            .useTextMaxWidth()
            .setEmptyPlaceholder("-");

        me._setListViewStyle();

        vBoxLayout.addItem(me._listView);
        me._scrollData.setLayout(vBoxLayout);

        me._drawBottomBar();

        me.setPositionOnCenter();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._inputDialog.del();
        me._deleteDialog.del();
        call(Dialog.del, [], me);
    },

    #
    # @return ghost  ListView widget
    #
    getListView: func() {
        return me._listView;
    },

    #
    # @return ghost  InputDialog object
    #
    getInputDialog: func() {
        return me._inputDialog;
    },

    #
    # @return void
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Close")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                call(me.hide, [], me);
            }
        );

        me._btnDelete = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Delete")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                if (!g_isThreadPending) {
                    me._deleteDialog.show(me._parentDataIndex, me);
                }
            }
        );

        buttonBox.addStretch(3);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnDelete);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(canvas.DefaultStyle.widgets["list-view"].PADDING);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(canvas.DefaultStyle.widgets["list-view"].PADDING);
    },

    #
    # @param hash style
    # @return void
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me._scrollData.setColorBackground(me.style.LIST_BG);
        me._setListViewStyle();
        me.toggleBgImage();

        me._inputDialog.setStyle(style);
    },

    #
    # @return hash - ListView widget
    #
    _setListViewStyle: func() {
        return me._listView
            .setColorText(me.style.TEXT_COLOR)
            .setColorBackground(me.style.LIST_BG)
            .setColorHoverBackground(me.style.HOVER_BG);
    },

    #
    # Show canvas dialog
    #
    # @param  hash  parent  LogbookDialog object
    # @param  hash  data  {"allDataIndex": index, "data": vector}
    # @param  bool  isTotals
    # @return void
    #
    show: func(parent, data, isTotals) {
        me._parent = parent;
        me._dataRow = data;
        me._isTotals = isTotals;

        me._btnDelete.setEnabled(!me._isTotals);

        me._inputDialog.hide();
        me._deleteDialog.hide();

        me._parentDataIndex = me._dataRow.allDataIndex;

        me._listView.setItems(me._getListViewRows(me._dataRow.data));

        call(Dialog.show, [], me);
    },

    #
    # Hide details window with its sub windows
    #
    # @return void
    #
    hide: func() {
        if (me._parent != nil) {
            # Remove highlighted row in LogbookDialog
            me._parent.getListView().removeHighlightingRow();
            me._parent.allDataIndexSelected = nil;
        }

        me._parentDataIndex = nil;
        me._inputDialog.hide();
        me._deleteDialog.hide();
        call(Dialog.hide, [], me);
    },

    #
    # Prepare columns data for ListView
    #
    # @param vector data
    # @return vector
    #
    _getListViewRows: func(data) {
        var columns = me._columns.getAll();
        var rowsData = [];

        var start = 0;
        if (me._isTotals) {
            start = StorageCsv.INDEX_LANDING;
        }

        forindex (var index; columns[start:]) {
            var shiftIndex = index + start;
            if (me._isTotals and shiftIndex == StorageCsv.INDEX_NOTE) {
                break; # In total we do not show notes
            }

            append(rowsData, {
                data : [
                    sprintf("%10s:", columns[shiftIndex].header),
                    sprintf("%s %s",
                        me._addCommaSeparator(shiftIndex, data[shiftIndex]),
                        me._getExtraText(shiftIndex, data[shiftIndex])
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
        if (me._parentDataIndex != nil) {
            me._dataRow = me._storage.getLogData(me._parentDataIndex);
            if (me._dataRow == nil) {
                call(DetailsDialog.hide, [false], me);
                return;
            }

            me._listView.setItems(me._getListViewRows(me._dataRow.data));
        }
    },

    #
    # The click callback on the ListView widget. Open the inputDialog.
    #
    # @param int index
    # @return void
    #
    _listViewCallback: func(index) {
        if (!g_isThreadPending) {
            if (me._dataRow.allDataIndex > -1) { # -1 is using for Totals row
                g_Sound.play('paper');

                me._listView.removeHighlightingRow();
                me._listView.setHighlightingRow(index, me.style.SELECTED_BAR);

                me._inputDialog.getFilterSelector().hide();

                var columns = me._columns.getAll();
                me._inputDialog.show(me, me._dataRow.allDataIndex, columns[index].header, me._dataRow.data[index]);
            }
        }
    },

    #
    # @param int column
    # @param string value
    # @return string
    #
    _getExtraText: func(column, value) {
        if ((column == StorageCsv.INDEX_FROM or column == StorageCsv.INDEX_TO) and value != "") {
            var airport = airportinfo(value);
            if (airport != nil) {
                return "(" ~ airport.name ~ ")";
            }

            return "";
        }

        if (column >= StorageCsv.INDEX_DAY and column <= StorageCsv.INDEX_DURATION) {
            var digits = split(".", value);
            if (size(digits) < 2) {
                # something is wrong
                return "hours";
            }

            return sprintf("hours (%d:%02.0f)", digits[0], (digits[1] / 100) * 60);
        }

        if (column == StorageCsv.INDEX_DISTANCE) {
            var inMeters = value * globals.NM2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("nm (%s km)", me._getValueWithCommaSeparator(km));
            }

            return sprintf("nm (%.0f m)", inMeters);
        }

        if (column == StorageCsv.INDEX_FUEL) {
            var liters = sprintf("%.02f", value * globals.GAL2L);
            return sprintf("US gallons (%s l)", me._getValueWithCommaSeparator(liters));
        }

        if (column == StorageCsv.INDEX_MAX_ALT) {
            var inMeters = value * globals.FT2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("ft MSL (%s km)", me._getValueWithCommaSeparator(km));
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
    _addCommaSeparator: func(column, value) {
        if (   column == StorageCsv.INDEX_DISTANCE
            or column == StorageCsv.INDEX_FUEL
            or column == StorageCsv.INDEX_MAX_ALT
        ) {
            return me._getValueWithCommaSeparator(value);
        }

        return value;
    },

    #
    # @param string value
    # @return string
    #
    _getValueWithCommaSeparator: func(value) {
        var numberParts = split(".", value);
        var strToCheck  = numberParts[0];
        var newValue    = strToCheck;
        var length      = size(strToCheck);
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

        if (size(numberParts) == 2) {
            return newValue ~ "." ~ numberParts[1];
        }

        return newValue;
    },
};
