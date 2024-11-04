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
    WINDOW_WIDTH  : 1360, # max width
    WINDOW_HEIGHT : 680,
    MAX_DATA_ITEMS: 20,
    FONT_NAME     : "LiberationFonts/LiberationSans-Bold.ttf",
    FONT_SIZE     : 12,

    #
    # Constructor
    #
    # @param  hash  storage  Storage object
    # @param  hash  filters  Filters object
    # @param  hash  columns  Columns object
    # @return me
    #
    new: func(storage, filters, columns) {
        var windowWidth = columns.getSumWidth() + (canvas.DefaultStyle.widgets["list-view"].PADDING * 2);
        if (windowWidth > LogbookDialog.WINDOW_WIDTH) {
            windowWidth = LogbookDialog.WINDOW_WIDTH;
        }

        var me = {
            parents : [
                LogbookDialog,
                Dialog.new(
                    windowWidth,
                    LogbookDialog.WINDOW_HEIGHT,
                    "Logbook"
                ),
            ],
            _storage : storage,
            _filters : filters,
            _columns : columns,
        };

        me._addonNodePath = g_Addon.node.getPath();

        me.setPositionOnCenter();

        # Override window del method for close FilterSelector
        var self = me;
        me.window.del = func() {
            call(LogbookDialog.hide, [], self);
        };

        me._startIndex      = 0;
        me._data            = [];
        me._headersContent  = nil;
        me.selectedRecordId = nil;

        me.canvas.set("background", me.style.CANVAS_BG);

        me._detailsDialog  = DetailsDialog.new(storage, columns);
        me._filterSelector = FilterSelector.new(columns);
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
            .setColumnsWidth(me._columns.getWidths())
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

                var index      = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-index");
                var columnName = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-column-name");
                var value      = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-value");

                if (me._storage.editData(index, columnName, value)) {
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
        foreach (var columnItem; me._columns.getAll()) {
            if (!columnItem.visible) {
                continue;
            }

            var rowGroup = me._headersContent.createChild("group");
            rowGroup.setTranslation(x, 0);
            var rect = rowGroup.rect(0, 0, columnItem.width, canvas.DefaultStyle.widgets["list-view"].ITEM_HEIGHT);
            rect.setColorFill([0.0, 0.0, 0.0, 0.0]);

            me._drawText(rowGroup, 0, 20, me._getReplaceHeaderText(columnItem.name, columnItem.header));

            me._setMouseHoverHeadersListener(
                rowGroup,
                rect,
                me._filters.getFilterItemsByColumnName(columnItem.name),
                columnItem.header ~ " filter",
                columnItem.name
            );

            x += columnItem.width;
        }
    },

    #
    # @param  hash  rowGroup  Canvas group
    # @param  hash  rect  Rectangle canvas object
    # @param  vector|nil  items  Items for FilterSelector
    # @param  string|nil  title  FilterSelector title dialog
    # @param  string  columnName  Column name
    # @return void
    #
    _setMouseHoverHeadersListener: func(rowGroup, rect, items, title, columnName) {
        if (items == nil or title == nil or columnName == nil) {
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
                    .setColumnName(columnName)
                    .setPosition(event.screenX, event.screenY)
                    .setTitle(title)
                    .setCallback(me, me._filterSelectorCallback)
                    .show();
            }
        });
    },

    #
    # @param  string  columName
    # @param  string  value
    # @return void
    #
    _filterSelectorCallback: func(columName, value) {
        me._detailsDialog.hide();
        me.reloadData(true, FilterData.new(columName, value));
    },

    #
    # Replace some too long header text or set "filtered" marker
    #
    # @param  string  columnName
    # @param  string  text
    # @return string
    #
    _getReplaceHeaderText: func(columnName, text) {
        if (columnName == Columns.DATE
            or columnName == Columns.SIM_UTC_DATE
            or columnName == Columns.SIM_LOC_DATE
        ) {
            text = "Date";
        }
        else if (columnName == Columns.TIME
            or columnName == Columns.SIM_UTC_TIME
            or columnName == Columns.SIM_LOC_TIME
        ) {
            text = "Time";
        }
        else if (columnName == Columns.LANDING) {
            text = "Land.";
        }

        if (me._filters.isApplied(columnName)) {
            return text ~ " (!)";
        }

        if (columnName == Columns.INSTRUMENT) {
            return "Instr.";
        }

        if (columnName == Columns.MULTIPLAYER) {
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
    # @param  hash  filter  FilterData object as {"columnName": name, "value": "text"}
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
    # @param  vector  data  Vector of hashes {"id": index, "data": vector}
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
            or me._data[highlightedIndex].id != me.selectedRecordId
        ) {
            me._listView.removeHighlightingRow();
        }

        # Check that the selected row is among the data.
        if (me._detailsDialog.isWindowVisible()) {
            forindex (var index; me._data) {
                var id = me._data[index].id;
                if (id == me.selectedRecordId) {
                    me._setHighlightingRow(id, index);
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
    # @param  int  index
    # @return void
    #
    _listViewCallback: func(index) {
        if (!g_isThreadPending) {
            g_Sound.play('paper');

            var hash = me._data[index]; # = hash {"id": index, "data": vector}

            me._setHighlightingRow(hash.id, index);

            me._filterSelector.hide();

            me._detailsDialog.show(me, hash.id);
        }
    },

    #
    # @param  int  id  Record ID from SQLite or index of row in whole CSV file
    # @param  int  index  Index of row in list view (among displayed rows)
    # @return void
    #
    _setHighlightingRow: func(id, index) {
        me.selectedRecordId = id;
        me._listView.removeHighlightingRow();
        me._listView.setHighlightingRow(index, me.style.SELECTED_BAR);
    },
};
