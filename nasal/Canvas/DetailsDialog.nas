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
    WINDOW_WIDTH  : 610,
    WINDOW_HEIGHT : 660,
    FONT_NAME     : "LiberationFonts/LiberationMono-Bold.ttf",
    COLUMNS_WIDTH : [
        170, # header
        400, # data
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

        me._isUsingSQLite        = Utils.isUsingSQLite();
        me._parent               = nil; # LogbookDialog object
        me._dataRow              = nil;
        me._isTotals             = false;
        me._logbookId            = nil;
        me._storage              = storage;
        me._columns              = columns;
        me._btnDelete            = nil;
        me._btnFlightAnalysis    = nil;
        me._inputDialog          = InputDialog.new(columns);
        me._flightAnalysisDialog = nil;
        me._deleteDialog         = ConfirmationDialog.new("Delete entry log");
        me._deleteDialog.setLabel("Do you really want to delete this entry?");

        me.canvas.set("background", me.style.CANVAS_BG);

        var margins = {
            left   : 0,
            top    : canvas.DefaultStyle.widgets["list-view"].PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollData = me.createScrollArea(me.style.LIST_BG, margins);
        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch
        me._scrollDataContent = me.getScrollAreaContent(me._scrollData);

        me._listView = canvas.gui.widgets.ListView.new(me._scrollDataContent, canvas.style, {})
            .setFontSizeLarge()
            .setFontName(DetailsDialog.FONT_NAME)
            .setColumnsWidth(DetailsDialog.COLUMNS_WIDTH)
            .setClickCallback(me._listViewCallback, me)
            .useTextMaxWidth()
            .setEmptyPlaceholder("-");

        me._setListViewStyle();

        var vBoxLayout = canvas.VBoxLayout.new();
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
        if (me._flightAnalysisDialog != nil) {
            me._flightAnalysisDialog.del();
            me._flightAnalysisDialog = nil;
        }

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
    # @return hash  InputDialog object
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

        me._btnFlightAnalysis = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Analysis")
            .setFixedSize(75, 26);

        if (me._isUsingSQLite) {
            me._btnFlightAnalysis.listen("clicked", func {
                var firstRun = me._flightAnalysisDialog == nil;
                if (firstRun) {
                    me._flightAnalysisDialog = FlightAnalysisDialog.new("Logbook Flight Analysis");
                }

                # Get data from SQLite
                var trackItems = me._storage.getLogbookTracker(me._logbookId);
                var maxAlt     = me._storage.getLogbookTrackerMaxAlt(me._logbookId);

                me._flightAnalysisDialog.setData(trackItems, maxAlt);

                if (!firstRun) {
                    me._flightAnalysisDialog.hardUpdateView();
                }

                me._flightAnalysisDialog.show();
            });
        }
        else {
            me._btnFlightAnalysis.setEnabled(false);
            me._btnFlightAnalysis.setVisible(false);
        }

        me._btnDelete = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Delete")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                if (!g_isThreadPending) {
                    me._deleteDialog.show(me._logbookId, me);
                }
            }
        );

        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnFlightAnalysis);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnDelete);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(canvas.DefaultStyle.widgets["list-view"].PADDING);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(canvas.DefaultStyle.widgets["list-view"].PADDING);
    },

    #
    # @param  hash  style
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
    # @return ghost  ListView widget
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
    # @param  int  logbookId  Logbook ID in DB or row index in CSV file, if -1 then it's total row
    # @return void
    #
    show: func(parent, logbookId) {
        me._parent = parent;
        me._isTotals = logbookId == Columns.TOTALS_ROW_ID;

        me.window.set("title", me._isTotals ? "Logbook Totals" : "Logbook Details");

        me._btnDelete.setEnabled(!me._isTotals);
        me._btnDelete.setVisible(!me._isTotals);
        if (me._isUsingSQLite) {
            me._btnFlightAnalysis.setEnabled(!me._isTotals);
            me._btnFlightAnalysis.setVisible(!me._isTotals);
        }

        me._inputDialog.hide();
        me._deleteDialog.hide();

        me._logbookId = logbookId;

        # Get data from storage
        me._dataRow = me._storage.getLogData(me._logbookId);

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
            me._parent.selectedRecordId = nil;
        }

        me._logbookId = nil;

        if (me._flightAnalysisDialog != nil) {
            me._flightAnalysisDialog.hide();
        }

        me._inputDialog.hide();
        me._deleteDialog.hide();
        call(Dialog.hide, [], me);
    },

    #
    # Prepare columns data for ListView
    #
    # @param  vector  data
    # @return vector
    #
    _getListViewRows: func(data) {
        var rowsData = [];
        var index = -1;

        foreach (var columnItem; me._columns.getAll()) {
            index += 1;

            if (me._isTotals and columnItem.totals == nil) {
                # We need to display totals, and the column is not a part of totals, so skip it
                continue;
            }

            append(rowsData, {
                data : [
                    sprintf("%16s:", columnItem.header),
                    sprintf("%s %s",
                        me._addCommaSeparator(columnItem.name, data[index]),
                        me._getExtraText(columnItem.name, data[index])
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
        if (me._logbookId != nil) {
            me._dataRow = me._storage.getLogData(me._logbookId);
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
    # @param  int  index
    # @return void
    #
    _listViewCallback: func(index) {
        if (g_isThreadPending or me._dataRow.id <= Columns.TOTALS_ROW_ID) {
            return;
        }

        var column = me._columns.getColumnByIndex(index);
        if (column.name == Columns.DURATION) {
            gui.popupTip("Please edit Day or Night instead");
            return;
        }

        g_Sound.play('paper');

        me._listView.removeHighlightingRow();
        me._listView.setHighlightingRow(index, me.style.SELECTED_BAR);

        me._inputDialog.getFilterSelector().hide();

        me._inputDialog.show(
            me,
            me._dataRow.id,
            me._dataRow.data[index],
            me._columns.getColumnByIndex(index)
        );
    },

    #
    # @param  string  columnName
    # @param  string  value
    # @return string
    #
    _getExtraText: func(columnName, value) {
        if ((columnName == Columns.FROM or columnName == Columns.TO) and value != "") {
            var airport = airportinfo(value);
            if (airport != nil) {
                return "(" ~ airport.name ~ ")";
            }

            return "";
        }

        if (   columnName == Columns.DAY
            or columnName == Columns.NIGHT
            or columnName == Columns.INSTRUMENT
            or columnName == Columns.MULTIPLAYER
            or columnName == Columns.SWIFT
            or columnName == Columns.DURATION
        ) {
            return sprintf("hours (%s)", Utils.decimalHoursToHuman(value));
        }

        if (columnName == Columns.DISTANCE) {
            var inMeters = value * globals.NM2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("NM (%s km)", me._getValueWithCommaSeparator(km));
            }

            return sprintf("NM (%.0f m)", inMeters);
        }

        if (columnName == Columns.FUEL) {
            var liters = sprintf("%.02f", value * globals.GAL2L);
            return sprintf("US gallons (%s l)", me._getValueWithCommaSeparator(liters));
        }

        if (columnName == Columns.MAX_ALT) {
            var inMeters = value * globals.FT2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("ft MSL (%s km)", me._getValueWithCommaSeparator(km));
            }

            return sprintf("ft MSL (%.0f m)", inMeters);
        }

        if (columnName == Columns.MAX_GS_KT) {
            var kmPerHour = value * 1.852;
            return sprintf("kt (%.0f km/h)", kmPerHour);
        }

        return "";
    },

    #
    # @param  string  columnName
    # @param  string  value
    # @return string
    #
    _addCommaSeparator: func(columnName, value) {
        if (   columnName == Columns.DISTANCE
            or columnName == Columns.FUEL
            or columnName == Columns.MAX_ALT
            or columnName == Columns.MAX_MACH
        ) {
            return me._getValueWithCommaSeparator(value);
        }

        return value;
    },

    #
    # @param  string  value
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
