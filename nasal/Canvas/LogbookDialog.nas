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
    CLASS: "LogbookDialog",

    #
    # Constants
    #
    MAX_WINDOW_WIDTH : 1500,
    MIN_WINDOW_WIDTH : 540,

    MAX_WINDOW_HEIGHT: 680,
    MIN_WINDOW_HEIGHT: 260,

    #
    # Constructor
    #
    # @param  hash  storage  Storage object
    # @param  hash  filters  Filters object
    # @param  hash  columns  Columns object
    # @param  hash  logbook  Logbook object
    # @return hash
    #
    new: func(storage, filters, columns, logbook) {
        var windowWidth = columns.getSumWidth() + (canvas.DefaultStyle.widgets["logbook-list-view"].PADDING * 2);
        if (windowWidth < LogbookDialog.MIN_WINDOW_WIDTH) {
            windowWidth = LogbookDialog.MIN_WINDOW_WIDTH;
        }
        elsif (windowWidth > LogbookDialog.MAX_WINDOW_WIDTH) {
            windowWidth = LogbookDialog.MAX_WINDOW_WIDTH;
        }

        var windowHeight = (g_Settings.getLogItemsPerPage() + 2) * canvas.DefaultStyle.widgets["logbook-list-view"].ITEM_HEIGHT + 64; # +2 (headers row and Totals row), +64 (space bottom buttons)
        if (windowHeight < LogbookDialog.MIN_WINDOW_HEIGHT) {
            windowHeight = LogbookDialog.MIN_WINDOW_HEIGHT;
        }
        elsif (windowHeight > LogbookDialog.MAX_WINDOW_HEIGHT) {
            windowHeight = LogbookDialog.MAX_WINDOW_HEIGHT;
        }

        var me = {
            parents : [
                LogbookDialog,
                StylePersistentDialog.new(windowWidth, windowHeight, "Logbook"),
            ],
            _storage : storage,
            _filters : filters,
            _columns : columns,
            _logbook : logbook,
            _isUsingSQLite: Utils.isUsingSQLite(),
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, LogbookDialog); # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        if (me._isUsingSQLite) {
            me._storage.loadAllData();
        }

        me._itemsPerPage = g_Settings.getLogItemsPerPage();

        me._addonNodePath = g_Addon.node.getPath();

        me._startIndex      = 0;
        me._data            = [];
        me._headersContent  = nil;
        me.selectedRecordId = nil;

        me._canvas.set("background", me._style.CANVAS_BG);

        me._detailsDialog  = DetailsDialog.new(storage, columns);
        me._filterSelector = FilterSelector.new(columns);
        me.helpDialog      = HelpDialog.new();
        me.aboutDialog     = AboutDialog.new();

        me._drawHeaders();

        me._listView = canvas.gui.widgets.LogbookList.new(me._group, canvas.style, {})
            .setFontSizeSmall()
            .setTranslation( # Set translation for align LogbookList with headers row
                canvas.DefaultStyle.widgets["logbook-list-view"].PADDING,
                canvas.DefaultStyle.widgets["logbook-list-view"].ITEM_HEIGHT
            )
            .useOptimizeRow()
            .setClickCallback(me._listViewCallback, me);

        me._setListViewStyle();

        me._vbox.addItem(me._listView, 1); # 2nd param = stretch

        me._labelPaging = canvas.gui.widgets.Label.new(me._group, canvas.style, {});
        if (Utils.isFG2024Version()) {
            me._labelPaging.setColor(me._style.TEXT_COLOR);
        }

        me._btnFirst = canvas.gui.widgets.Button.new(me._group, canvas.style, {});
        me._btnPrev  = canvas.gui.widgets.Button.new(me._group, canvas.style, {});
        me._btnNext  = canvas.gui.widgets.Button.new(me._group, canvas.style, {});
        me._btnLast  = canvas.gui.widgets.Button.new(me._group, canvas.style, {});

        me._btnStyle    = canvas.gui.widgets.Button.new(me._group, canvas.style, {});
        me._drawBottomBar();

        me._listeners = Listeners.new();
        me._setListeners();

        return me;
    },

    #
    # Set listeners.
    #
    # @return void
    #
    _setListeners: func() {
        # User clicked delete entry
        me._listeners.add(
            node: me._addonNodePath ~ "/addon-devel/action-delete-entry",
            code: func(node) {
                if (node.getBoolValue()) {
                    # Back to false
                    setprop(node.getPath(), false);

                    var index = getprop(me._addonNodePath ~ "/addon-devel/action-delete-entry-index");
                    if (me._logbook.deleteLog(index)) {
                        me._listView.enableLoading();

                        if (me._isUsingSQLite) {
                            # Get signal to reload data
                            setprop(me._addonNodePath ~ "/addon-devel/logbook-entry-deleted", true);
                            setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
                        }
                    }
                }
            },
        );

        # User clicked edit
        me._listeners.add(
            node: me._addonNodePath ~ "/addon-devel/action-edit-entry",
            code: func(node) {
                if (node.getBoolValue()) {
                    # Back to false
                    setprop(node.getPath(), false);

                    var index      = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-index");
                    var columnName = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-column-name");
                    var value      = getprop(me._addonNodePath ~ "/addon-devel/action-edit-entry-value");

                    if (me._storage.editData(index, columnName, value)) {
                        me._listView.enableLoading();

                        if (me._isUsingSQLite) {
                            # Get signal to reload data
                            setprop(me._addonNodePath ~ "/addon-devel/reload-logbook", true);
                        }
                    }
                }
            },
        );

        # Reload data dialog after edit or delete file operation
        me._listeners.add(
            node: me._addonNodePath ~ "/addon-devel/reload-logbook",
            code: func(node) {
                if (node.getBoolValue()) {
                    # Back to false
                    setprop(node.getPath(), false);

                    me._reloadLogbookListenerCallback();
                }
            },
        );

        me._listeners.add(
            node: "/devices/status/mice/mouse/button",
            code: func(node) {
                if (node.getBoolValue()) {
                    # Mouse was clicked somewhere in the sim, close my popups dialogs
                    me._filterSelector.hide();
                    me._detailsDialog.getInputDialog().getFilterSelector().hide();
                }
            },
        );
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
            var pages = math.ceil(me._storage.getTotalLines() / me._itemsPerPage);
            var newIndex = (pages * me._itemsPerPage) - me._itemsPerPage;
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
    # @override StylePersistentDialog
    #
    del: func() {
        me._listeners.del();
        me._detailsDialog.del();
        me._filterSelector.del();
        me.helpDialog.del();
        me.aboutDialog.del();

        me._parentDialog.del();
    },

    #
    # Show canvas dialog
    #
    # @return void
    # @override StylePersistentDialog
    #
    show: func() {
        if (g_isThreadPending) {
            return;
        }

        g_Sound.play('paper');

        # We need to redraw the headers too, because when the window was created,
        # the data had not yet been loaded (they load in a separate thread), so nothing was drawn.
        me.reloadData(withHeaders: true);

        me._parentDialog.show();
    },

    #
    # Hide canvas dialog
    #
    # @return void
    # @override StylePersistentDialog
    #
    hide: func() {
        me._filterSelector.hide();
        me._detailsDialog.hide();

        me._parentDialog.hide();
    },

    #
    # @return ghost  LogbookList widget
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
        me._headersContent = me._group.createChild("group");
        me._headersContent.setTranslation(0, 0);
        me._headersContent
            .set("font", "LiberationFonts/LiberationMono-Bold.ttf")
            .set("character-size", 12)
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

        var x = canvas.DefaultStyle.widgets["logbook-list-view"].PADDING * 2;
        foreach (var columnItem; me._columns.getAll()) {
            if (!columnItem.visible) {
                continue;
            }

            var rowGroup = me._headersContent.createChild("group");
            rowGroup.setTranslation(x, 0);
            var rect = rowGroup.rect(0, 0, columnItem.width, canvas.DefaultStyle.widgets["logbook-list-view"].ITEM_HEIGHT);
            rect.setColorFill([0.0, 0.0, 0.0, 0.0]);

            me._drawText(
                context: rowGroup,
                x: 0,
                y: 20,
                label: me._getReplaceHeaderText(columnItem.name, columnItem.header)
            );

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
    # @param  ghost  rowGroup  Canvas group
    # @param  ghost  rect  Rectangle canvas object
    # @param  vector|nil  items  Items for FilterSelector
    # @param  string  title  FilterSelector title dialog
    # @param  string  columnName  Column name
    # @return void
    #
    _setMouseHoverHeadersListener: func(rowGroup, rect, items, title, columnName) {
        if (items == nil) {
            # No filters for this column, skip it
            return;
        }

        rowGroup.addEventListener("mouseenter", func {
            if (!g_isThreadPending) {
                rect.setColorFill(me._style.HOVER_BG);
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
                    .setCallback(Callback.new(me._filterSelectorCallback, me))
                    .show();
            }
        });
    },

    #
    # @param  string  columnName
    # @param  string  value
    # @return void
    #
    _filterSelectorCallback: func(columnName, value) {
        me._detailsDialog.hide();
        me.reloadData(withHeaders: true, filter: FilterData.new(columnName, value));
    },

    #
    # Replace some too long header text or set "filtered" marker
    #
    # @param  string  columnName
    # @param  string  text
    # @return string
    #
    _getReplaceHeaderText: func(columnName, text) {
        if (   columnName == Columns.DATE
            or columnName == Columns.SIM_UTC_DATE
            or columnName == Columns.SIM_LOC_DATE
        ) {
            text = "Date";
        }
        elsif (columnName == Columns.TIME
            or columnName == Columns.SIM_UTC_TIME
            or columnName == Columns.SIM_LOC_TIME
        ) {
            text = "Time";
        }
        elsif (columnName == Columns.LANDING) {
            text = "Land.";
        }

        if (me._filters.isApplied(columnName)) {
            return text ~ "*";
        }

        if (columnName == Columns.INSTRUMENT) {
            return "Instr.";
        }

        if (columnName == Columns.MULTIPLAYER) {
            return "Multip.";
        }

        if (columnName == Columns.MAX_GS_KT) {
            return "Max GS";
        }

        return text;
    },

    #
    # Draw text
    #
    # @param  ghost  context  Parent canvas group
    # @param  int  x, y  Position of text
    # @param  string  label  Text to draw
    # @return ghost  Text canvas element
    #
    _drawText: func(context, x, y, label) {
        return context.createChild("text")
            .setTranslation(x, y)
            .setColor(me._style.TEXT_COLOR)
            .setText(label);
    },

    #
    # Draw bottom bar with buttons
    #
    # @return void
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        me._btnFirst
            .setText("|<<")
            .setFixedSize(65, 26)
            .listen("clicked", func { me._first(); });

        me._btnPrev
            .setText("<")
            .setFixedSize(65, 26)
            .listen("clicked", func { me._prev(); });

        me._setPaging();

        me._btnNext
            .setText(">")
            .setFixedSize(65, 26)
            .listen("clicked", func { me._next(); });

        me._btnLast
            .setText(">>|")
            .setFixedSize(65, 26)
            .listen("clicked", func { me._last(); });

        me._btnStyle
            .setText(me._getOppositeStyleName())
            .setFixedSize(65, 26)
            .listen("clicked", func { me._toggleStyle(); });

        var btnSettings = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("≡")
            .setFixedSize(26, 26)
            .listen("clicked", func { me._logbook.showSettingDialog(); });

        var btnHelp = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("?")
            .setFixedSize(26, 26)
            .listen("clicked", func { me.helpDialog.show(); });

        buttonBox.addStretch(4);
        buttonBox.addItem(me._btnFirst);
        buttonBox.addItem(me._btnPrev);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._labelPaging);
        buttonBox.addStretch(1);
        buttonBox.addItem(me._btnNext);
        buttonBox.addItem(me._btnLast);
        buttonBox.addStretch(2);
        buttonBox.addItem(me._btnStyle);
        buttonBox.addItem(btnSettings);
        buttonBox.addItem(btnHelp);
        buttonBox.addStretch(1);

        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(canvas.DefaultStyle.widgets["logbook-list-view"].PADDING);
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

        me._style = me._style.NAME == "dark"
            ? me.getStyle().light
            : me.getStyle().dark;

        g_Settings.setDarkMode(me._style.NAME == "dark");

        me.toggleBgImage();

        me._canvas.set("background", me._style.CANVAS_BG);
        me._btnStyle.setText(me._getOppositeStyleName());
        me._setListViewStyle();
        me._filterSelector.setStyle(me._style);

        if (Utils.isFG2024Version()) {
            me._labelPaging.setColor(me._style.TEXT_COLOR);
        }

        me.reloadData();

        me._detailsDialog.setStyle(me._style);
    },

    #
    # @return void
    #
    _setListViewStyle: func() {
        me._listView
            .setColorText(me._style.TEXT_COLOR)
            .setColorBackground(me._style.LIST_BG)
            .setColorHoverBackground(me._style.HOVER_BG);
    },

    #
    # @return string
    #
    _getOppositeStyleName: func() {
        return me._style.NAME == "dark"
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
            me.reloadData(withHeaders: false);
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

        if (me._startIndex - me._itemsPerPage >= 0) {
            g_Sound.play('paper');

            me._startIndex -= me._itemsPerPage;
            me._filterSelector.hide();
            me._detailsDialog.hide();
            me.reloadData(withHeaders: false);
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

        if (me._startIndex + me._itemsPerPage < me._storage.getTotalLines()) {
            g_Sound.play('paper');

            me._startIndex += me._itemsPerPage;
            me._filterSelector.hide();
            me._detailsDialog.hide();
            me.reloadData(withHeaders: false);
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
        var pages = math.ceil(me._storage.getTotalLines() / me._itemsPerPage);
        me._startIndex = (pages * me._itemsPerPage) - me._itemsPerPage;

        if (old != me._startIndex) {
            g_Sound.play('paper');

            me._filterSelector.hide();
            me._detailsDialog.hide();
            me.reloadData(withHeaders: false);
        }
    },

    #
    # Reload logbook data
    #
    # @param  bool  withHeaders  Set true when headers/filters must be change too.
    # @param  hash|nil  filter  FilterData object as {"columnName": name, "value": "text"}
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

        me._storage.loadDataRange(
            Callback.new(me._reloadDataCallback, me),
            me._startIndex,
            me._itemsPerPage,
            withHeaders,
        );
    },

    #
    # This function is call when loadDataRange thread finish its job and give as a results.
    #
    # @param  vector  data  Vector of hashes {"id": index, "columns": vector}
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
        var curPage = (me._startIndex / me._itemsPerPage) + 1;
        var maxPages = math.ceil(me._storage.getTotalLines() / me._itemsPerPage) or 1;
        me._labelPaging.setText(sprintf("%d / %d (%d items)", curPage, maxPages, me._storage.getTotalLines()));

        me._btnFirst.setEnabled(curPage > 1);
        me._btnPrev.setEnabled(curPage > 1);
        me._btnNext.setEnabled(curPage < maxPages);
        me._btnLast.setEnabled(curPage < maxPages);
    },

    #
    # The click callback on the LogbookList widget. Open the details window.
    #
    # @param  int  index
    # @return void
    #
    _listViewCallback: func(index) {
        if (!g_isThreadPending) {
            g_Sound.play('paper');

            var hash = me._data[index]; # = hash {"id": index, "columns": vector}

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
        me._listView.setHighlightingRow(index, me._style.SELECTED_BAR);
    },
};
