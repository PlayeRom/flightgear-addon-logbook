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
    WINDOW_WIDTH         : 1040,
    WINDOW_HEIGHT        : 680,
    TXT_WIDTH_MULTIPLIER : 8.5,
    MAX_DATA_ITEMS       : 20,
    COLUMNS_WIDTH        : [
         85, #  0 - date
         50, #  1 - time
        150, #  2 - aircraft
         80, #  3 - callsign
         55, #  4 - from
         55, #  5 - to
         50, #  6 - landings
         50, #  7 - crash
         50, #  8 - day
         50, #  9 - night
         50, # 10 - instrument
         65, # 11 - duration
         65, # 12 - distance
         80, # 13 - fuel
         70, # 14 - max alt
        100, # 15 - note
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
    FONT_NAME            : "LiberationFonts/LiberationSans-Bold.ttf",
    FONT_SIZE            : 12,

    #
    # Constructor
    #
    # hash file - File object
    #
    new: func(file) {
        var me = {
            parents: [
                LogbookDialog,
                Dialog.new(Dialog.ID_LOGBOOK, LogbookDialog.WINDOW_WIDTH, LogbookDialog.WINDOW_HEIGHT, "Logbook"),
            ],
        };

        me.startIndex = 0;

        file.loadAllData();

        me.file           = file;
        me.data           = [];
        me.totals         = me.file.getTotalsData();
        me.rowTotal       = nil;
        me.headersContent = nil;
        me.dataContent    = nil;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.detailsDialog = DetailsDialog.new(file);
        me.helpDialog    = HelpDialog.new();
        me.aboutDialog   = AboutDialog.new();

        me.listView = ListView.new(
            me.group,
            me.vbox,
            ListView.SHIFT_Y * 22, # 22 = 20 items + 1 headers + 1 totals
            LogbookDialog.WINDOW_WIDTH,
            LogbookDialog.COLUMNS_WIDTH,
            ListView.LAYOUT_H
        );
        me.listView.setTranslation(0, 20);
        me.listView.setClickDialog(me.detailsDialog);
        me.listView.setStyle(me.style);
        me.listView.setFont(LogbookDialog.FONT_NAME, LogbookDialog.FONT_SIZE);

        me.drawHeaders();

        me.labelPaging = canvas.gui.widgets.Label.new(me.group, canvas.style, {});
        me.btnStyle    = canvas.gui.widgets.Button.new(me.group, canvas.style, {});
        me.drawBottomBar();

        setlistener(me.addon.node.getPath() ~ "/addon-devel/reload-logbook", func(node) {
            if (node.getValue()) {
                # Back to false
                setprop(node.getPath(), false);

                if (getprop(me.addon.node.getPath() ~ "/addon-devel/logbook-entry-deleted") == true) {
                    setprop(me.addon.node.getPath() ~ "/addon-devel/logbook-entry-deleted", false);

                    # Check index of last page
                    var pages = math.ceil(me.file.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS);
                    var newIndex = (pages * LogbookDialog.MAX_DATA_ITEMS) - LogbookDialog.MAX_DATA_ITEMS;
                    if (me.startIndex > newIndex) {
                        # We exceed the maximum index, so set a new one
                        me.startIndex = newIndex;
                    }

                    me.reloadData(false);

                    # User deleted entry, hide details window
                    me.detailsDialog.hide();
                }
                else {
                    # For edit data
                    me.reloadData(false);
                    me.detailsDialog.reload();
                }
            }
        });

        setlistener(me.addon.node.getPath() ~ "/addon-devel/redraw-logbook", func(node) {
            if (node.getValue()) {
                # Back to false
                setprop(node.getPath(), false);

                me.redraw(false);
            }
        });

        return me;
    },

    #
    # Destructor
    #
    del: func() {
        me.parents[1].del();
        me.detailsDialog.del();
        me.helpDialog.del();
        me.aboutDialog.del();
    },

    #
    # Show canvas dialog
    #
    show: func() {
        me.reloadData(false);
        me.parents[1].show();
    },

    #
    # Draw headers row
    #
    drawHeaders: func() {
        me.headersContent = me.group.createChild("group");
        me.headersContent.setTranslation(0, 0);
        me.headersContent
            .set("font", LogbookDialog.FONT_NAME)
            .set("character-size", LogbookDialog.FONT_SIZE)
            .set("alignment", "left-baseline");

        me.reDrawHeadersContent();
    },

    #
    # Draw headers row
    #
    reDrawHeadersContent: func() {
        me.headersContent.removeAllChildren();

        var y = ListView.PADDING * 3;
        var x = ListView.PADDING * 3;
        var column = 0;
        var headers = me.file.getHeadersData();
        foreach (var text; headers) {
            if (column == size(headers) - 1) {
                # Don't show Note column
                break;
            }

            me.drawText(me.headersContent, x, 20, me.getReplaceHeaderText(text));
            x += me.listView.getX(column);
            column += 1;
        }
    },

    #
    # Replace some too long header text
    #
    # string text
    # return string
    #
    getReplaceHeaderText: func(text) {
        if (text == "Landings") {
            return "Land.";
        }

        if (text == "Instrument") {
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
    #
    drawText: func(cGroup, x, y, text) {
        return cGroup.createChild("text")
            .setTranslation(x, y)
            .setColor(me.style.TEXT_COLOR)
            .setText(text);
    },

    #
    # Draw grid with logbook data
    #
    reDrawDataContent: func() {
        var y = me.listView.reDrawDataContent();

        # Continue drawing totals row
        me.rowTotal = me.listView.drawHoverBox(y);
        me.drawTotalsRow(me.rowTotal);

        me.listView.dataContent.update();
    },

    #
    # Draw row with totals summary
    #
    # hash cGroup - Parent canvas group
    #
    drawTotalsRow: func(cGroup) {
        var x = ListView.PADDING * 2 +
            me.listView.getX(0) +
            me.listView.getX(1) +
            me.listView.getX(2) +
            me.listView.getX(3) +
            me.listView.getX(4);

        me.listView.drawText(cGroup, x, "Totals:");

        for (var i = 0; i < size(me.totals); i += 1) {
            var total = me.totals[i];
            x += me.listView.getX(i + 5);
            me.listView.drawText(cGroup, x, sprintf(LogbookDialog.TOTAL_FORMATS[i], total));
        }
    },

    #
    # Draw bottom bar with buttons
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
    toggleStyle: func() {
        me.style = me.style.NAME == "dark"
            ? me.getStyle().light
            : me.getStyle().dark;

        me.settings.setDarkMode(me.style.NAME == "dark");
        me.settings.save();

        me.canvas.set("background", me.style.CANVAS_BG);
        me.btnStyle.setText(me.getOppositeStyleName());
        me.listView.setStyle(me.style);

        me.reloadData();

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
    first: func() {
        if (me.startIndex != 0) {
            me.startIndex = 0;
            me.reloadData(false);
        }
    },

    #
    # Go to previous logbook items
    #
    prev: func() {
        if (me.startIndex - LogbookDialog.MAX_DATA_ITEMS >= 0) {
            me.startIndex -= LogbookDialog.MAX_DATA_ITEMS;
            me.reloadData(false);
        }
    },

    #
    # Go to next logbook items
    #
    next: func() {
        if (me.startIndex + LogbookDialog.MAX_DATA_ITEMS < me.file.getTotalLines()) {
            me.startIndex += LogbookDialog.MAX_DATA_ITEMS;
            me.reloadData(false);
        }
    },

    #
    # Go to last logbook items
    #
    last: func() {
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
    # bool withHeaders - Set true when color must be change too.
    # return void
    #
    reloadData: func(withHeaders = 1) {
        me.data   = me.file.loadDataRange(me.startIndex, LogbookDialog.MAX_DATA_ITEMS);
        me.totals = me.file.getTotalsData();

        me.listView.setDataToDraw(me.data, me.startIndex);

        me.redraw(withHeaders);
        me.setPaging();
    },

    #
    # Redraw windows
    #
    # bool withHeaders - Set true when color must be change too.
    # return void
    #
    redraw: func(withHeaders) {
        if (withHeaders) {
            me.reDrawHeadersContent();
        }
        me.reDrawDataContent();
    },

    #
    # Set paging information
    #
    setPaging: func() {
        var curPage = (me.startIndex / LogbookDialog.MAX_DATA_ITEMS) + 1;
        var maxPages = math.ceil(me.file.getTotalLines() / LogbookDialog.MAX_DATA_ITEMS) or 1;
        me.labelPaging.setText(sprintf("%d / %d (%d items)", curPage, maxPages, me.file.getTotalLines()));
    },
};
