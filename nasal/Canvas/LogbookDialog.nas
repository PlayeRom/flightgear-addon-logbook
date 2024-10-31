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
# LogbookDialog class to display logbook
#
var LogbookDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH         : 1360,
    WINDOW_HEIGHT        : 680,
    MAX_DATA_ITEMS       : 20,
    COLUMNS_WIDTH        : [
         85, #  0 - date
         50, #  1 - time
        150, #  2 - aircraft
        150, #  3 - variant
         80, #  4 - aircraft type
         80, #  5 - callsign
         55, #  6 - from
         55, #  7 - to
         50, #  8 - landing
         50, #  9 - crash
         50, # 10 - day
         50, # 11 - night
         50, # 12 - instrument
         50, # 13 - multiplayer
         50, # 14 - swift
         60, # 15 - duration
         60, # 16 - distance
         80, # 17 - fuel
         70, # 18 - max alt
    ],
    FONT_NAME            : "LiberationFonts/LiberationSans-Bold.ttf",
    FONT_SIZE            : 12,

    #
    # Constructor
    #
    # @param hash storage - Storage object
    # @param hash filters - Filters object
    # @return me
    #
    new: func(storage, filters) {
        var me = {
            parents : [
                LogbookDialog,
                Dialog.new(
                    LogbookDialog.WINDOW_WIDTH,
                    LogbookDialog.WINDOW_HEIGHT,
                    "Logbook"
                ),
            ],
            _storage : storage,
            _filters : filters,
        };

        me._addonNodePath = g_Addon.node.getPath();

        me.setPositionOnCenter();

        # Override window del method for close FilterSelector
        var self = me;
        me.window.del = func() {
            call(LogbookDialog.hide, [], self);
        };

        me._startIndex          = 0;
        me._data                = [];
        me._headersContent      = nil;
        me.allDataIndexSelected = nil;

        me.canvas.set("background", me.style.CANVAS_BG);

        me._detailsDialog  = DetailsDialog.new(storage);
        me._filterSelector = FilterSelector.new();
        me.helpDialog      = HelpDialog.new();
        me.aboutDialog     = AboutDialog.new();

        me._drawHeaders();

        me._listView = canvas.gui.widgets.ListView.new(me.group, canvas.style, {})
            .setFontSizeSmall()
            .setTranslation( # Set translation for align ListView with headers row
                canvas.DefaultStyle.widgets["list-view"].PADDING,
                canvas.DefaultStyle.widgets["list-view"].ITEM_HEIGHT
            )
            .setFontName(LogbookDialog.FONT_NAME)
            .setColumnsWidth(LogbookDialog.COLUMNS_WIDTH)
            .setClickCallback(me._listViewCallback, me);

        me._setListViewStyle();

        me.vbox.addItem(me._listView, 1); # 2nd param = stretch

        me._labelPaging = canvas.gui.widgets.Label.new(me.group, canvas.style, {});
        me._btnStyle    = canvas.gui.widgets.Button.new(me.group, canvas.style, {});
        me._drawBottomBar();

        me._listeners = std.Vector.new();

        # User clicked delete entry
        me._listeners.append(setlistener(me._addonNodePath ~ "/addon-devel/action-delete-entry", func(node) {
            if (node.getBoolValue()) {
                # Back to false
                setprop(node.getPath(), false);

                var index = getprop(me._addonNodePath ~ "/addon-devel/action-delete-entry-index");
                if (me._storage.deleteLog(index)) {
                    me._listView.enableLoading();

                    if (Utils.isUsingSQLite()) {
                        # Get signal to reload data
                        setprop(me._addonNodePath ~ "/addon-devel/logbook-entry-deleted", true);
                        setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
                    }
                }
            }
        }));

        # User clicked edit
        me._listeners.append(setlistener(me._addonNodePath ~ "/addon-devel/action-edit-entry", func(node) {
            if (node.getBoolValue()) {
                # Back to false
                setprop(node.getPath(), false);

                var index  = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-index");
                var header = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-header");
                var value  = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-value");

                if (me._storage.editData(index, header, value)) {
                    me._listView.enableLoading();

                    if (Utils.isUsingSQLite()) {
                        # Get signal to reload data
                        setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
                    }
                }
            }
        }));

        # Reload data dialog after edit or delete file operation
        me._listeners.append(setlistener(me._addonNodePath ~ "/addon-devel/reload-logbook", func(node) {
            if (node.getBoolValue()) {
                # Back to false
                setprop(node.getPath(), false);

                me._reloadLogbookListenerCallback();
            }
        }));

        me._listeners.append(setlistener("/devices/status/mice/mouse/button", func(node) {
            if (node.getBoolValue()) {
                # Mouse was clicked somewhere in the sim, close my popups dialogs
                me._filterSelector.hide();
                me._detailsDialog.getInputDialog().getFilterSelector().hide();
            }
        }));

        return me;
    },

    #
    # Callback from "/addons/by-id/org.flightgear.addons.logbook/addon-devel/reload-logbook" listener
    #
    # @return void
    #
    _reloadLogbookListenerCallback: func() {
        if (getprop(me._addonNodePath ~ "/addon-devel/logbook-entry-deleted")) {
            # User deleted entry

            # Back deleted flag to false value
            setprop(me._addonNodePath ~ "/addon-devel/logbook-entry-deleted", false);

            # Check index of last page
            var pages = math.ceil(me._storage.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS);
            var newIndex = (pages * LogbookDialog.MAX_DATA_ITEMS) - LogbookDialog.MAX_DATA_ITEMS;
            if (me._startIndex > newIndex) {
                # We exceed the maximum index, so set a new one
                me._startIndex = newIndex;
            }

            # Hide details window with deleted entry, it MUST be call before me.reloadData();
            me._detailsDialog.hide();
        }

        # Reload after edit/delete data
        me.reloadData();
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        foreach (var listener; me._listeners.vector) {
            removelistener(listener);
        }

        me._detailsDialog.del();
        me._filterSelector.del();
        me.helpDialog.del();
        me.aboutDialog.del();
        call(Dialog.del, [], me);
    },

    #
    # Show canvas dialog
    #
    # @return void
    #
    show: func() {
        if (g_isThreadPending) {
            return;
        }

        g_Sound.play('paper');

        # We need to redraw the headers too, because when the window was created,
        # the data had not yet been loaded (they load in a separate thread), so nothing was drawn.
        me.reloadData(true);

        call(Dialog.show, [], me);
    },

    #
    # Hide canvas dialog
    #
    # @return void
    #
    hide: func() {
        me._filterSelector.hide();
        me._detailsDialog.hide();
        call(Dialog.hide, [], me);
    },

    #
    # @return ghost  ListView widget
    #
    getListView: func() {
        return me._listView;
    },

    #
    # Draw headers row
    #
    # @return void
    #
    _drawHeaders: func() {
        me._headersContent = me.group.createChild("group");
        me._headersContent.setTranslation(0, 0);
        me._headersContent
            .set("font", LogbookDialog.FONT_NAME)
            .set("character-size", LogbookDialog.FONT_SIZE)
            .set("alignment", "left-baseline");

        # There is no need to re-draw headers here because the data loads in a separate thread so we may not have them
        # me._reDrawHeadersContent();
    },

    #
    # Draw headers row
    #
    # @return void
    #
    _reDrawHeadersContent: func() {
        me._headersContent.removeAllChildren();

        var x = canvas.DefaultStyle.widgets["list-view"].PADDING * 2;
        var column = -1;
        var headers = me._storage.getHeadersData();
        foreach (var text; headers) {
            column += 1;

            if (column == StorageCsv.INDEX_NOTE) {
                # Don't show Note column
                continue;
            }

            var rowGroup = me._headersContent.createChild("group");
            rowGroup.setTranslation(x, 0);
            var rect = rowGroup.rect(0, 0, me._getColumnWidth(column), canvas.DefaultStyle.widgets["list-view"].ITEM_HEIGHT);
            rect.setColorFill([0.0, 0.0, 0.0, 0.0]);

            me._drawText(rowGroup, 0, 20, me._getReplaceHeaderText(column, text));

            me._setMouseHoverHeadersListener(
                rowGroup,
                rect,
                me._filters.getFilterItemsByColumnIndex(column),
                me._filters.getFilterTitleByColumnIndex(column),
                column
            );

            x += me._getColumnWidth(column);
        }
    },

    #
    # Get width of column for given index
    #
    # @param int index
    # @return int
    #
    _getColumnWidth: func(index) {
        return LogbookDialog.COLUMNS_WIDTH[index];
    },

    #
    # @param  hash  rowGroup  Canvas group
    # @param  hash  rect  Rectangle canvas object
    # @param  vector|nil  items  Items for FilterSelector
    # @param  string|nil  title  FilterSelector title dialog
    # @param  int|nil  index  Column index as StorageCsv.INDEX_[...]
    # @return void
    #
    _setMouseHoverHeadersListener: func(rowGroup, rect, items, title, index) {
        if (items == nil or title == nil or index == nil) {
            # No filters for this column, skip it
            return;
        }

        rowGroup.addEventListener("mouseenter", func {
            if (!g_isThreadPending) {
                rect.setColorFill(me.style.HOVER_BG);
            }
        });

        rowGroup.addEventListener("mouseleave", func {
            if (!g_isThreadPending) {
                rect.setColorFill([0.0, 0.0, 0.0, 0.0]);
            }
        });

        rowGroup.addEventListener("click", func(event) {
            if (!g_isThreadPending) {
                g_Sound.play('paper');
                me._filterSelector
                    .setItems(items)
                    .setColumnIndex(index)
                    .setPosition(event.screenX, event.screenY)
                    .setTitle(title)
                    .setCallback(me, me._filterSelectorCallback)
                    .show();
            }
        });
    },

    #
    # @param  int  columnIndex
    # @param  string  dbColumnName
    # @param  string  value
    # @return void
    #
    _filterSelectorCallback: func(columnIndex, dbColumnName, value) {
        me._detailsDialog.hide();
        me.reloadData(true, FilterData.new(columnIndex, dbColumnName, value));
    },

    #
    # Replace some too long header text or set "filtered" marker
    #
    # @param int column
    # @param string text
    # @return string
    #
    _getReplaceHeaderText: func(column, text) {
        if (column == StorageCsv.INDEX_LANDING) {
            text = "Land.";
        }

        if (me._filters.isApplied(column)) {
            return text ~ " (!)";
        }

        if (column == StorageCsv.INDEX_INSTRUMENT) {
            return "Instr.";
        }

        if (column == StorageCsv.INDEX_MULTIPLAYER) {
            return "Multip.";
        }

        return text;
    },

    #
    # Draw text
    #
    # @param  hash  cGroup  Parent canvas group
    # @param  int  x, y  Position of text
    # @param  string  text  Text to draw
    # @return hash  Text canvas element
    #
    _drawText: func(cGroup, x, y, text) {
        return cGroup.createChild("text")
            .setTranslation(x, y)
            .setColor(me.style.TEXT_COLOR)
            .setText(text);
    },

    #
    # Draw bottom bar with buttons
    #
    # @return void
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnFirst = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("|<<")
            .setFixedSize(75, 26)
            .listen("clicked", func { me._first(); });

        var btnPrev = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("<")
            .setFixedSize(75, 26)
            .listen("clicked", func { me._prev(); });

        me._setPaging();

        var btnNext = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(">")
            .setFixedSize(75, 26)
            .listen("clicked", func { me._next(); });

        var btnLast = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(">>|")
            .setFixedSize(75, 26)
            .listen("clicked", func { me._last(); });

        me._btnStyle
            .setText(me._getOppositeStyleName())
            .setFixedSize(75, 26)
            .listen("clicked", func { me._toggleStyle(); });

        var btnHelp = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("?")
            .setFixedSize(26, 26)
            .listen("clicked", func { me.helpDialog.show(); });

        buttonBox.addStretch(4);
        buttonBox.addItem(btnFirst);
        buttonBox.addItem(btnPrev);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._labelPaging);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnNext);
        buttonBox.addItem(btnLast);
        buttonBox.addStretch(2);
        buttonBox.addItem(me._btnStyle);
        buttonBox.addItem(btnHelp);
        buttonBox.addStretch(1);

        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(canvas.DefaultStyle.widgets["list-view"].PADDING);
    },

    #
    # Toggle style from light to dark and vice versa.
    #
    # @return void
    #
    _toggleStyle: func() {
        if (g_isThreadPending) {
            return;
        }

        g_Sound.play('paper');

        me.style = me.style.NAME == "dark"
            ? me.getStyle().light
            : me.getStyle().dark;

        g_Settings.setDarkMode(me.style.NAME == "dark");
        g_Settings.save();

        me.toggleBgImage();

        me.canvas.set("background", me.style.CANVAS_BG);
        me._btnStyle.setText(me._getOppositeStyleName());
        me._setListViewStyle();
        me._filterSelector.setStyle(me.style);

        me.reloadData();

        me._detailsDialog.setStyle(me.style);
        me.helpDialog.setStyle(me.style);
    },

    #
    # @return void
    #
    _setListViewStyle: func() {
        me._listView
            .setColorText(me.style.TEXT_COLOR)
            .setColorBackground(me.style.LIST_BG)
            .setColorHoverBackground(me.style.HOVER_BG);
    },

    #
    # @return string
    #
    _getOppositeStyleName: func() {
        return me.style.NAME == "dark"
            ? me.getStyle().light.NAME
            : me.getStyle().dark.NAME;
    },

    #
    # Go to first logbook items
    #
    # @return void
    #
    _first: func() {
        if (g_isThreadPending) {
            return;
        }

        if (me._startIndex != 0) {
            g_Sound.play('paper');

            me._startIndex = 0;
            me._filterSelector.hide();
            me._detailsDialog.hide();
            me.reloadData(false);
        }
    },

    #
    # Go to previous logbook items
    #
    # @return void
    #
    _prev: func() {
        if (g_isThreadPending) {
            return;
        }

        if (me._startIndex - LogbookDialog.MAX_DATA_ITEMS >= 0) {
            g_Sound.play('paper');

            me._startIndex -= LogbookDialog.MAX_DATA_ITEMS;
            me._filterSelector.hide();
            me._detailsDialog.hide();
            me.reloadData(false);
        }
    },

    #
    # Go to next logbook items
    #
    # @return void
    #
    _next: func() {
        if (g_isThreadPending) {
            return;
        }

        if (me._startIndex + LogbookDialog.MAX_DATA_ITEMS < me._storage.getTotalLines()) {
            g_Sound.play('paper');

            me._startIndex += LogbookDialog.MAX_DATA_ITEMS;
            me._filterSelector.hide();
            me._detailsDialog.hide();
            me.reloadData(false);
        }
    },

    #
    # Go to last logbook items
    #
    # @return void
    #
    _last: func() {
        if (g_isThreadPending) {
            return;
        }

        var old = me._startIndex;
        var pages = math.ceil(me._storage.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS);
        me._startIndex = (pages * LogbookDialog.MAX_DATA_ITEMS) - LogbookDialog.MAX_DATA_ITEMS;

        if (old != me._startIndex) {
            g_Sound.play('paper');

            me._filterSelector.hide();
            me._detailsDialog.hide();
            me.reloadData(false);
        }
    },

    #
    # Reload logbook data
    #
    # @param  bool  withHeaders  Set true when headers/filters must be change too.
    # @param  hash  filter  FilterData object as {"index": column index, "value": "text"}
    # @return void
    #
    reloadData: func(withHeaders = 1, filter = nil) {
        if (filter != nil) {
            if (!me._filters.applyFilter(filter)) {
                # The filter did not change anything, so there is nothing to reload
                return;
            }

            # Reset range
            me._startIndex = 0;
        }

        me._listView.enableLoading();

        me._storage.loadDataRange(me, me._reloadDataCallback, me._startIndex, LogbookDialog.MAX_DATA_ITEMS, withHeaders);
    },

    #
    # This function is call when loadDataRange thread finish its job and give as a results.
    #
    # @param  vector  data  Vector of hashes {"allDataIndex": index, "data": vector}
    # @param  bool  withHeaders
    # @return void
    #
    _reloadDataCallback: func(data, withHeaders) {
        me._data = data;

        me._listView.setItems(me._data);
        if (withHeaders) {
            me._reDrawHeadersContent();
        }
        me._setPaging();

        if (me._detailsDialog.isWindowVisible()) {
            me._detailsDialog.reload();
        }

        me._handleSelectedRowAfterReloadData();
    },

    #
    # @return void
    #
    _handleSelectedRowAfterReloadData: func() {
        # Check if the selected row should still be selected.
        var highlightedIndex = me._listView.getHighlightingRow();
        if (   highlightedIndex == nil
            or highlightedIndex < 0
            or highlightedIndex >= size(me._data)
            or me._data[highlightedIndex].allDataIndex != me.allDataIndexSelected
        ) {
            me._listView.removeHighlightingRow();
        }

        # Check that the selected row is among the data.
        if (me._detailsDialog.isWindowVisible()) {
            forindex (var index; me._data) {
                var allDataIndex = me._data[index].allDataIndex;
                if (allDataIndex == me.allDataIndexSelected) {
                    me._setHighlightingRow(allDataIndex, index);
                    break;
                }
            }
        }
    },

    #
    # Set paging information
    #
    # @return void
    #
    _setPaging: func() {
        var curPage = (me._startIndex / LogbookDialog.MAX_DATA_ITEMS) + 1;
        var maxPages = math.ceil(me._storage.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS) or 1;
        me._labelPaging.setText(sprintf("%d / %d (%d items)", curPage, maxPages, me._storage.getTotalLines()));
    },

    #
    # The click callback on the ListView widget. Open the details window.
    #
    # @param int index
    # @return void
    #
    _listViewCallback: func(index) {
        if (!g_isThreadPending) {
            g_Sound.play('paper');

            var hash = me._data[index]; # = hash {"allDataIndex": index, "data": vector}

            me._setHighlightingRow(hash.allDataIndex, index);

            me._filterSelector.hide();

            var isTotals = hash.allDataIndex == -1;  # -1 is using for Totals row
            me._detailsDialog.show(me, hash, isTotals);
        }
    },

    #
    # @param int allDataIndex - index of row in whole CSV file
    # @param int index - index of row in list view (among displayed rows)
    # @return void
    #
    _setHighlightingRow: func(allDataIndex, index) {
        me.allDataIndexSelected = allDataIndex;
        me._listView.removeHighlightingRow();
        me._listView.setHighlightingRow(index, me.style.SELECTED_BAR);
    },
};
