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
    PADDING              : 10,
    TXT_WIDTH_MULTIPLIER : 8.5,
    MAX_DATA_ITEMS       : 20,
    SHIFT_Y              : 28,
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
                Dialog.new(LogbookDialog.WINDOW_WIDTH, LogbookDialog.WINDOW_HEIGHT, "Logbook", true),
            ],
        };

        me.startIndex = 0;

        me.file                = file;
        me.data                = me.file.loadData(me.startIndex, LogbookDialog.MAX_DATA_ITEMS);
        me.totals              = me.file.getTotalsData();
        me.rowTotal            = nil;
        me.groupHeadersContent = nil;
        me.scrollData          = nil;
        me.scrollDataContent   = nil;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.detailsDialog = DetailsDialog.new(file);
        me.helpDialog    = HelpDialog.new();
        me.aboutDialog   = AboutDialog.new();

        me.drawHeaders();
        me.drawData();

        me.labelPaging = canvas.gui.widgets.Label.new(me.group, canvas.style, {});
        me.btnStyle    = canvas.gui.widgets.Button.new(me.group, canvas.style, {});
        me.drawBottomBar();

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
        me.reloadData();
        me.parents[1].show();
    },

    #
    # Draw headers row
    #
    drawHeaders: func() {
        me.groupHeadersContent = me.group.createChild("group");
        me.groupHeadersContent
            .set("font", LogbookDialog.FONT_NAME)
            .set("character-size", LogbookDialog.FONT_SIZE)
            .set("alignment", "left-baseline");

        me.reDrawHeadersContent();
    },

    #
    # Draw headers row
    #
    reDrawHeadersContent: func() {
        me.groupHeadersContent.removeAllChildren();

        var y = LogbookDialog.PADDING * 3;
        var x = LogbookDialog.PADDING * 2 + 5;
        var column = 0;
        var headers = me.file.getHeadersData();
        foreach (var text; headers) {
            if (column == size(headers) - 1) {
                # Don't show Note column
                break;
            }

            me.drawText(me.groupHeadersContent, x, 20, me.getReplaceHeaderText(text));
            x += me.getX(column);
            column += 1;
        }
    },

    #
    # Draw scrollArea for logbook data
    #
    drawData: func() {
        me.scrollData = me.createScrollArea(me.style.CANVAS_BG, {"left": 5, "top": 0, "right": 0, "bottom": 0});

        me.vbox.addSpacing(30);
        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent(
            me.scrollData,
            LogbookDialog.FONT_NAME,
            LogbookDialog.FONT_SIZE,
            "left-baseline"
        );

        me.reDrawDataContent();
    },

    #
    # Draw grid with logbook data
    #
    reDrawDataContent: func() {
        me.scrollDataContent.removeAllChildren();

        var y = LogbookDialog.PADDING * 3;
        var index = 0;
        foreach (var row; me.data) {
            var x = LogbookDialog.PADDING * 2;
            var column = 0;

            var rowGroup = me.drawHoverBox(me.scrollDataContent, y, row);

            foreach (var text; row) {
                if (column == size(row) - 1) {
                    # Don't show Note column
                    break;
                }
                me.drawText(rowGroup, x, 16, text);

                x += me.getX(column);
                column += 1;
            }

            # Draw horizontal line
            # var hr = canvas.draw.rectangle(
            #     me.scrollDataContent,
            #     LogbookDialog.WINDOW_WIDTH - (LogbookDialog.PADDING * 2), # width
            #     1,                                          # height
            #     LogbookDialog.PADDING,                             # x
            #     y + 10                                      # y
            # );
            # hr.setColor(me.style.GROUP_BG);

            y += LogbookDialog.SHIFT_Y;
            index += 1;
        }

        me.rowTotal = me.drawHoverBox(me.scrollDataContent, y);
        me.drawTotalsRow(me.rowTotal);

        me.scrollDataContent.update();
    },

    #
    # hash cgroup - Parent canvas group
    # int y
    # vector|nil dataRow
    #
    drawHoverBox: func(cgroup, y, dataRow = nil) {
        var rowGroup = cgroup.createChild("group");
        rowGroup.setTranslation(LogbookDialog.PADDING, y - LogbookDialog.SHIFT_Y + 11);

        # Create rect because setColorFill on rowGroup doesn't work
        # TODO: Keep the rectangle not too wide, because then you get artifacts in drawing the sliders of ScrollArea.
        var rect = rowGroup.rect(0, 0, LogbookDialog.WINDOW_WIDTH - (LogbookDialog.PADDING * 3), LogbookDialog.SHIFT_Y);
        rect.setColorFill([0.0, 0.0, 0.0, 0.0]);

        var mouseHover = MouseHover.new(me.detailsDialog, me.style, rowGroup, rect, dataRow);
        mouseHover.addEvents();

        return rowGroup;
    },

    #
    # Draw row with totals summary
    #
    # hash cgroup - Parent canvas group
    #
    drawTotalsRow: func(cgroup) {
        var y = 16;
        var x = LogbookDialog.PADDING * 2 +  me.getX(0) + me.getX(1) + me.getX(2) + me.getX(3) + me.getX(4);
        me.drawText(cgroup, x, y, "Totals:");

        for (var i = 0; i < size(me.totals); i += 1) {
            var total = me.totals[i];
            x += me.getX(i + 5);
            me.drawText(cgroup, x, y, sprintf(LogbookDialog.TOTAL_FORMATS[i], total));
        }

        # Extra bottom margin
        y += LogbookDialog.SHIFT_Y;
        me.drawText(cgroup, x, y, " ");
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

        # me.vbox.addStretch(1);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);
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
    # Get width of column for given index
    #
    # int index
    # return int
    #
    getX: func(index) {
        return LogbookDialog.COLUMNS_WIDTH[index];
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
        me.scrollData.setColorBackground(me.style.CANVAS_BG);

        me.btnStyle.setText(me.getOppositeStyleName());

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
    # Draw text
    #
    # hash cgroup - Parent canvas group
    # int x, y - Position of text
    # string text - Text to draw
    #
    drawText: func(cgroup, x, y, text) {
        return cgroup.createChild("text")
            .setTranslation(x, y)
            .setColor(me.style.TEXT_COLOR)
            .setText(text);
    },

    #
    # Go to first logbook items
    #
    first: func() {
        if (me.startIndex != 0) {
            me.startIndex = 0;
            me.reloadData();
        }
    },

    #
    # Go to previous logbook items
    #
    prev: func() {
        if (me.startIndex - LogbookDialog.MAX_DATA_ITEMS >= 0) {
            me.startIndex -= LogbookDialog.MAX_DATA_ITEMS;
            me.reloadData();
        }
    },

    #
    # Go to next logbook items
    #
    next: func() {
        if (me.startIndex + LogbookDialog.MAX_DATA_ITEMS <= me.file.getTotalLines()) {
            me.startIndex += LogbookDialog.MAX_DATA_ITEMS;
            me.reloadData();
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
            me.reloadData();
        }
    },

    #
    # Reload logbook data
    #
    reloadData: func() {
        me.data   = me.file.loadData(me.startIndex, LogbookDialog.MAX_DATA_ITEMS);
        me.totals = me.file.getTotalsData();

        me.reDrawHeadersContent();
        me.reDrawDataContent();
        me.setPaging();
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
