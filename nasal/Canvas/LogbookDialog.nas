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
    WINDOW_WIDTH         : 1280,
    WINDOW_HEIGHT        : 680,
    TXT_WIDTH_MULTIPLIER : 8.5,
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
         55, #  8 - landings
         55, #  9 - crash
         50, # 10 - day
         50, # 11 - night
         50, # 12 - instrument
         65, # 13 - duration
         65, # 14 - distance
         80, # 15 - fuel
         70, # 16 - max alt
    ],
    TOTAL_FORMATS        : [
        "%d",   # landings
        "%d",   # crash
        "%.2f", # day
        "%.2f", # night
        "%.2f", # instrument
        "%.2f", # duration
        "%.2f", # distance
        "%.0f", # fuel
        "%.0f", # max alt
    ],
    TOTALS_COLUMNS_SHIFT : File.INDEX_TO,
    FONT_NAME            : "LiberationFonts/LiberationSans-Bold.ttf",
    FONT_SIZE            : 12,

    #
    # Constructor
    #
    # hash settings - Settings object
    # hash file - File object
    # hash filters - Filters object
    # return me
    #
    new: func(settings, file, filters) {
        var me = {
            parents : [
                LogbookDialog,
                Dialog.new(
                    settings,
                    LogbookDialog.WINDOW_WIDTH,
                    LogbookDialog.WINDOW_HEIGHT,
                    "Logbook"
                ),
            ],
            file    : file,
            filters : filters,
        };

        me.addonNodePath = me.addon.node.getPath();

        me.setPositionOnCenter();

        # Override window del method for close FilterSelector
        var self = me;
        me.window.del = func() {
            call(LogbookDialog.hide, [], self);
        };

        me.startIndex = 0;

        me.data           = [];
        me.rowTotal       = nil;
        me.headersContent = nil;
        me.dataContent    = nil;

        me.canvas.set("background", me.style.CANVAS_BG);

        me.detailsDialog  = DetailsDialog.new(settings, file);
        me.helpDialog     = HelpDialog.new(settings);
        me.aboutDialog    = AboutDialog.new(settings);
        me.filterSelector = FilterSelector.new(settings);

        me.drawHeaders();

        me.listView = canvas.gui.widgets.ListView.new(me.group, canvas.style, {})
            .setFontSizeSmall()
            .setMaxRows(21) # 20 items + 1 totals
            # Set transaltion for align with headers row:
            .setTranslation(canvas.DefaultStyle.widgets.ListView.PADDING, canvas.DefaultStyle.widgets.ListView.ITEM_HEIGHT)
            .setFontName(LogbookDialog.FONT_NAME)
            .setColumnsWidth(LogbookDialog.COLUMNS_WIDTH)
            .setTextColor(me.style.TEXT_COLOR)
            # .setBackgroundColor(me.style.CANVAS_BG)
            # Set a transparent background so that the background texture image of the window remains visible
            .setBackgroundColor([0.0, 0.0, 0.0, 0.0])
            .setHoverBackgroundColor(me.style.HOVER_BG)
            .setClickCallback(me, me.listViewCallback);

        me.vbox.addItem(me.listView);

        # It's still little tricky that we have to set spacing after ListView
        # content for set the bottom buttons in one place:
        me.vbox.addSpacing(me.listView.getContentHeight());

        me.labelPaging = canvas.gui.widgets.Label.new(me.group, canvas.style, {});
        me.btnStyle    = canvas.gui.widgets.Button.new(me.group, canvas.style, {});
        me.drawBottomBar();

        me.listeners = std.Vector.new();

        # User clicked delete entry
        me.listeners.append(setlistener(me.addonNodePath ~ "/addon-devel/action-delete-entry", func(node) {
            if (node.getBoolValue()) {
                # Back to false
                setprop(node.getPath(), false);

                var index = getprop(me.addonNodePath ~ "/addon-devel/action-delete-entry-index");
                if (me.file.deleteLog(index)) {
                    me.listView.enableLoading();
                }
            }
        }));

        # User clicked edit
        me.listeners.append(setlistener(me.addonNodePath ~ "/addon-devel/action-edit-entry", func(node) {
            if (node.getBoolValue()) {
                # Back to false
                setprop(node.getPath(), false);

                var index  = getprop(me.addonNodePath ~ "/addon-devel/action-edit-entry-index");
                var header = getprop(me.addonNodePath ~ "/addon-devel/action-edit-entry-header");
                var value  = getprop(me.addonNodePath ~ "/addon-devel/action-edit-entry-value");

                if (me.file.editData(index, header, value)) {
                    me.listView.enableLoading();
                }
            }
        }));

        # Reload data dialog after edit or delete file operation
        me.listeners.append(setlistener(me.addonNodePath ~ "/addon-devel/reload-logbook", func(node) {
            if (node.getBoolValue()) {
                # Back to false
                setprop(node.getPath(), false);

                me.reloadLogbookListenerCallback(node);
            }
        }));

        return me;
    },

    #
    # Callback from "/addons/by-id/org.flightgear.addons.logbook/addon-devel/reload-logbook" listener
    #
    # return void
    #
    reloadLogbookListenerCallback: func() {
        if (getprop(me.addonNodePath ~ "/addon-devel/logbook-entry-deleted") == true) {
            setprop(me.addonNodePath ~ "/addon-devel/logbook-entry-deleted", false);

            # Check index of last page
            var pages = math.ceil(me.file.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS);
            var newIndex = (pages * LogbookDialog.MAX_DATA_ITEMS) - LogbookDialog.MAX_DATA_ITEMS;
            if (me.startIndex > newIndex) {
                # We exceed the maximum index, so set a new one
                me.startIndex = newIndex;
            }

            # User deleted entry, hide details window, it MUST be before me.reloadData();
            me.detailsDialog.hide();

            me.reloadData();
        }
        else {
            # Reload after edit data
            me.reloadData();
        }
    },

    #
    # Destructor
    #
    # return void
    #
    del: func() {
        foreach (var listener; me.listeners.vector) {
            removelistener(listener);
        }

        me.detailsDialog.del();
        me.helpDialog.del();
        me.aboutDialog.del();
        me.filterSelector.del();
        call(Dialog.del, [], me);
    },

    #
    # Show canvas dialog
    #
    # return void
    #
    show: func() {
        if (g_isThreadPending) {
            return;
        }

        # We need to redraw the headers too, because when the window was created,
        # the data had not yet been loaded (they load in a separate thread), so nothing was drawn.
        me.reloadData(true);

        call(Dialog.show, [], me);
    },

    #
    # Hide canvas dialog
    #
    # return void
    #
    hide: func() {
        me.filterSelector.hide();
        me.detailsDialog.hide();
        call(Dialog.hide, [], me);
    },

    #
    # Draw headers row
    #
    # return void
    #
    drawHeaders: func() {
        me.headersContent = me.group.createChild("group");
        me.headersContent.setTranslation(0, 0);
        me.headersContent
            .set("font", LogbookDialog.FONT_NAME)
            .set("character-size", LogbookDialog.FONT_SIZE)
            .set("alignment", "left-baseline");

        # There is no need to re-draw headers here because the data loads in a separate thread so we may not have them
        # me.reDrawHeadersContent();
    },

    #
    # Draw headers row
    #
    # return void
    #
    reDrawHeadersContent: func() {
        me.headersContent.removeAllChildren();

        var x = canvas.DefaultStyle.widgets.ListView.PADDING * 2;
        var column = 0;
        var headers = me.file.getHeadersData();
        foreach (var text; headers) {
            if (column == size(headers) - 1) {
                # Don't show Note column
                break;
            }

            var rowGroup = me.headersContent.createChild("group");
            rowGroup.setTranslation(x, 0);
            var rect = rowGroup.rect(0, 0, me.getColumnWidth(column), canvas.DefaultStyle.widgets.ListView.ITEM_HEIGHT);
            rect.setColorFill([0.0, 0.0, 0.0, 0.0]);

            me.drawText(rowGroup, 0, 20, me.getReplaceHeaderText(column, text));

            me.setMouseHoverHeadersListener(
                rowGroup,
                rect,
                me.filters.getFilterItemsByColumnIndex(column),
                me.filters.getFilterTitleByColumnIndex(column),
                column
            );

            x += me.getColumnWidth(column);
            column += 1;
        }
    },

    #
    # Get width of column for given index
    #
    # int index
    # return int
    #
    getColumnWidth: func(index) {
        return LogbookDialog.COLUMNS_WIDTH[index];
    },

    #
    # hash rowGroup - canvas group
    # hash rect - rectangle canvas object
    # vector items|nil - Items for FilterSelector
    # string title|nil - FilterSelector title dialog
    # int index|nil - Column index as File.INDEX_[...]
    # return void
    #
    setMouseHoverHeadersListener: func(rowGroup, rect, items, title, index) {
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
                me.filterSelector
                    .setItems(items)
                    .setColumnIndex(index)
                    .setPosition(event.screenX, event.screenY)
                    .setTitle(title)
                    .setCallback(me, me.filterSelectorCallback)
                    .show();
            }
        });
    },

    #
    # int filterId
    # string value
    # return void
    #
    filterSelectorCallback: func(filterId, value) {
        me.detailsDialog.hide();
        me.reloadData(true, FilterData.new(filterId, value));
    },

    #
    # Replace some too long header text or set "filtered" marker
    #
    # index column
    # string text
    # return string
    #
    getReplaceHeaderText: func(column, text) {
        if (column == File.INDEX_LANDINGS) {
            text = "Land.";
        }

        if (me.filters.isApplied(column)) {
            return text ~ " (!)";
        }

        if (column == File.INDEX_INSTRUMENT) {
            return "Instr.";
        }

        return text;
    },

    #
    # Draw text
    #
    # hash cGroup - Parent canvas group
    # int x, y - Position of text
    # string text - Text to draw
    # return void
    #
    drawText: func(cGroup, x, y, text) {
        return cGroup.createChild("text")
            .setTranslation(x, y)
            .setColor(me.style.TEXT_COLOR)
            .setText(text);
    },

    #
    # Draw bottom bar with buttons
    #
    # return void
    #
    drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnFirst = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("|<<")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.first(); });

        var btnPrev = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("<")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.prev(); });

        me.setPaging();

        var btnNext = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(">")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.next(); });

        var btnLast = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(">>|")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.last(); });

        me.btnStyle
            .setText(me.getOppositeStyleName())
            .setFixedSize(75, 26)
            .listen("clicked", func { me.toggleStyle(); });

        var btnHelp = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("?")
            .setFixedSize(26, 26)
            .listen("clicked", func { me.helpDialog.show(); });

        buttonBox.addStretch(4);
        buttonBox.addItem(btnFirst);
        buttonBox.addItem(btnPrev);
        buttonBox.addStretch(1);
        buttonBox.addItem(me.labelPaging);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnNext);
        buttonBox.addItem(btnLast);
        buttonBox.addStretch(2);
        buttonBox.addItem(me.btnStyle);
        buttonBox.addItem(btnHelp);
        buttonBox.addStretch(1);

        me.vbox.addItem(buttonBox);
    },

    #
    # Toggle style from light to dark and vice versa.
    #
    # return void
    #
    toggleStyle: func() {
        if (g_isThreadPending) {
            return;
        }

        me.style = me.style.NAME == "dark"
            ? me.getStyle().light
            : me.getStyle().dark;

        me.settings.setDarkMode(me.style.NAME == "dark");
        me.settings.save();

        me.toggleBgImage();

        me.canvas.set("background", me.style.CANVAS_BG);
        me.btnStyle.setText(me.getOppositeStyleName());
        me.listView
            .setTextColor(me.style.TEXT_COLOR)
            # .setBackgroundColor(me.style.CANVAS_BG)
            # Set a transparent background so that the background texture image of the window remains visible
            .setBackgroundColor([0.0, 0.0, 0.0, 0.0])
            .setHoverBackgroundColor(me.style.HOVER_BG);
        me.filterSelector.setStyle(me.style);

        me.reloadData();

        # TODO: Additional data setting due to crash "non-numeric string in numeric context: 'data'"
        # by dataRows["data"] in ListView, but is it really needed? Will the index still be up to date?
        # if (me.detailsDialog.parentDataIndex != nil) {
        #     me.detailsDialog.listView.setDataToDraw(
        #         me.file.getLogData(me.detailsDialog.parentDataIndex),
        #         me.file.getHeadersData()
        #     );
        # }

        me.detailsDialog.setStyle(me.style);
        me.helpDialog.setStyle(me.style);
    },

    #
    # return string
    #
    getOppositeStyleName: func() {
        return me.style.NAME == "dark"
            ? me.getStyle().light.NAME
            : me.getStyle().dark.NAME;
    },

    #
    # Go to first logbook items
    #
    # return void
    #
    first: func() {
        if (g_isThreadPending) {
            return;
        }

        if (me.startIndex != 0) {
            me.startIndex = 0;
            me.reloadData(false);
        }
    },

    #
    # Go to previous logbook items
    #
    # return void
    #
    prev: func() {
        if (g_isThreadPending) {
            return;
        }

        if (me.startIndex - LogbookDialog.MAX_DATA_ITEMS >= 0) {
            me.startIndex -= LogbookDialog.MAX_DATA_ITEMS;
            me.reloadData(false);
        }
    },

    #
    # Go to next logbook items
    #
    # return void
    #
    next: func() {
        if (g_isThreadPending) {
            return;
        }

        if (me.startIndex + LogbookDialog.MAX_DATA_ITEMS < me.file.getTotalLines()) {
            me.startIndex += LogbookDialog.MAX_DATA_ITEMS;
            me.reloadData(false);
        }
    },

    #
    # Go to last logbook items
    #
    # return void
    #
    last: func() {
        if (g_isThreadPending) {
            return;
        }

        var old = me.startIndex;
        var pages = math.ceil(me.file.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS);
        me.startIndex = (pages * LogbookDialog.MAX_DATA_ITEMS) - LogbookDialog.MAX_DATA_ITEMS;

        if (old != me.startIndex) {
            me.reloadData(false);
        }
    },

    #
    # Reload logbook data
    #
    # bool withHeaders - Set true when headers/filters must be change too.
    # hash filter - FilterData object as {"index": column index, "value": "text"}
    # return void
    #
    reloadData: func(withHeaders = 1, filter = nil) {
        if (filter != nil) {
            if (!me.filters.applyFilter(filter)) {
                # The filter did not change anything, so there is nothing to reload
                return;
            }

            # Reset range
            me.startIndex = 0;
        }

        me.listView.enableLoading();

        me.file.loadDataRange(me, me.reloadDataCallback, me.startIndex, LogbookDialog.MAX_DATA_ITEMS, withHeaders);
    },

    #
    # This function is call when loadDataRange thread finish its job and give as a results.
    #
    # vector data - Vector of hashes {"allDataIndex": index, "data": vectorLogData}
    # vector totals
    # bool withHeaders
    # return void
    #
    reloadDataCallback: func(data, withHeaders) {
        me.data = data;

        me.listView.setItems(me.data);
        if (withHeaders) {
            me.reDrawHeadersContent();
        }
        me.setPaging();

        if (me.detailsDialog.isWindowVisible()) {
            me.detailsDialog.reload();
        }
    },

    #
    # Set paging information
    #
    # return void
    #
    setPaging: func() {
        var curPage = (me.startIndex / LogbookDialog.MAX_DATA_ITEMS) + 1;
        var maxPages = math.ceil(me.file.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS) or 1;
        me.labelPaging.setText(sprintf("%d / %d (%d items)", curPage, maxPages, me.file.getTotalLines()));
    },

    #
    # The click callback on the ListView widget. Open the details window.
    #
    # int index
    # return void
    #
    listViewCallback: func(index) {
        if (!g_isThreadPending) {
            var hash = me.data[index]; # = hash {"allDataIndex": index, "data": vector}
            if (hash.allDataIndex > -1) { # -1 is using for Totals row
                me.listView.removeHighlightingRow();
                me.listView.setHighlightingRow(index, me.style.SELECTED_BAR);
                me.detailsDialog.show(me, hash);
            }
        }
    },
};
