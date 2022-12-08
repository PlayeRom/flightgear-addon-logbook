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
# Dialog class to display logbook
#
var Dialog = {
    #
    # Constants
    #
    WINDOW_WIDTH         : 1366,
    WINDOW_HEIGHT        : 670,
    PADDING              : 10,
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

    #
    # Constructor
    #
    # File file
    #
    new: func(file) {
        var me = { parents: [Dialog] };

        me.startIndex = 0;

        me.file   = file;
        me.data   = me.file.loadData(me.startIndex, Dialog.MAX_DATA_ITEMS);
        me.totals = me.file.getTotalsData();
        me.style  = me.getStyle().dark;
        me.canvasTexts = [];
        me.canvasTextsTotals = [];

        me.window = canvas.Window.new([Dialog.WINDOW_WIDTH, Dialog.WINDOW_HEIGHT], "dialog")
            .set("title", "Logbook")
            .set("resize", true);

        me.canvas = me.window.createCanvas().set("background", me.style.CANVAS_BG);
        me.group = me.canvas.createGroup();
        me.vbox = canvas.VBoxLayout.new();
        me.canvas.setLayout(me.vbox);
        me.scroll = canvas.gui.widgets.ScrollArea.new(me.group, canvas.style, {});
        me.scroll.setColorBackground(me.style.CANVAS_BG);
        me.scroll.setContentsMargins(5, 10, 0, 0); # left, top, right, bottom
        me.vbox.addItem(me.scroll, 1); # 2nd param = stretch
        me.scrollContent = me.scroll.getContent();
        me.scrollContent
            .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
            .set("character-size", 12)
            .set("alignment", "left-baseline");

        me.scrollContent.setColorFill(me.style.GROUP_BG); # color of canvas.draw.rectangle

        me.drawGrid();
        me.drawBottomBar();

        me.scrollContent.update();
        me.window.hide();

        me.window.del = func() {
            # Click on (X) button in canvas top bar, we only hide the window
            call(me.hide, [], me);
        };

        me.window.destroy = func() {
            call(canvas.Window.del, [], me);
        };

        return me;
    },

    #
    # Destructor
    #
    del: func() {
        me.window.destroy();
    },

    #
    # Show canvas dialog
    #
    show: func() {
        me.reloadData();
        me.window.show();
    },

    #
    # Hide canvas dialog
    #
    hide: func() {
        me.window.hide();
    },

    #
    # Draw grid with logbook
    #
    drawGrid: func() {
        var y = Dialog.PADDING * 3;
        var index = 0;
        foreach (var row; me.data) {
            var textCell = [];

            var x = Dialog.PADDING * 2;
            var column = 0;
            foreach (var text; row) {
                if (index == 0) {
                    text = me.getReplaceHeaderText(text);
                }

                append(textCell, me.drawText(x, y, text));

                # Draw horizontal line
                canvas.draw.rectangle(
                    me.scrollContent,
                    Dialog.WINDOW_WIDTH - (Dialog.PADDING * 2), # width
                    1,                                          # height
                    Dialog.PADDING,                             # x
                    y + 10                                      # y
                );

                x += me.getX(column);
                column += 1;
            }
            y += 28;

            append(me.canvasTexts, textCell);

            index += 1;
        }

        me.drawTotalsRow(y);
    },

    #
    # Draw row with totals summary
    #
    # int y - initial Y position of texts
    #
    drawTotalsRow: func(y) {
        var x = Dialog.PADDING * 2 +  me.getX(0) + me.getX(1) + me.getX(2) + me.getX(3) + me.getX(4);
        me.drawText(x, y, "Totals:");

        me.canvasTextsTotals = [];

        for (var i = 0; i < size(me.totals); i += 1) {
            var total = me.totals[i];
            x += me.getX(i + 5);
            append(me.canvasTextsTotals, me.drawText(x, y, sprintf(Dialog.TOTAL_FORMATS[i], total)));
        }

        # Extra bottom margin
        y += 28;
        me.drawText(x, y, " ");
    },

    #
    # Draw bottom bar with buttons
    #
    drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnFirst = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("<<")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.first(); });

        var btnPrev = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("<")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.prev(); });

        var btnNext = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(">")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.next(); });

        var btnLast = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(">>")
            .setFixedSize(75, 26)
            .listen("clicked", func { me.last(); });

        buttonBox.addStretch(1);
        buttonBox.addItem(btnFirst);
        buttonBox.addItem(btnPrev);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnNext);
        buttonBox.addItem(btnLast);
        buttonBox.addStretch(1);

        # me.vbox.addStretch(1);
        me.vbox.addItem(buttonBox);
    },

    #
    # Replace some too long header text
    #
    # string test
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
        return Dialog.COLUMNS_WIDTH[index];
    },

    #
    # Get hash with dialog styles
    #
    # return hash
    #
    getStyle: func() {
        return {
            "dark": {
                CANVAS_BG  : "#000000EE",
                GROUP_BG   : [0.3, 0.3, 0.3],
                TEXT_COLOR : [0.8, 0.8, 0.8],
            },
            "light": {
                CANVAS_BG  : canvas.style.getColor("bg_color"),
                GROUP_BG   : [0.7, 0.7, 0.7],
                TEXT_COLOR : [0.3, 0.3, 0.3],
            },
        };
    },

    #
    # Draw text
    #
    # int x, y - Position of text
    # string text - Text to draw
    #
    drawText: func(x, y, text) {
        return me.scrollContent.createChild("text")
            .setTranslation(x, y)
            .setColor(me.style.TEXT_COLOR)
            .setDrawMode(canvas.Text.TEXT)
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
        var old = me.startIndex;
        me.startIndex -= Dialog.MAX_DATA_ITEMS;
        if (me.startIndex < 0) {
            me.startIndex = 0;
        }

        if (old != me.startIndex) {
            me.reloadData();
        }
    },

    #
    # Go to next logbook items
    #
    next: func() {
        if (me.startIndex + Dialog.MAX_DATA_ITEMS <= me.file.getTotalLines()) {
            me.startIndex += Dialog.MAX_DATA_ITEMS;
            me.reloadData();
        }
    },

    #
    # Go to last logbook items
    #
    last: func() {
        var old = me.startIndex;
        for (var i = old; i < me.file.getTotalLines() - Dialog.MAX_DATA_ITEMS; i += Dialog.MAX_DATA_ITEMS) {
            me.startIndex += Dialog.MAX_DATA_ITEMS;
        }

        if (old != me.startIndex) {
            me.reloadData();
        }
    },

    #
    # Reload logbook data
    #
    reloadData: func() {
        me.clearData();

        me.data = me.file.loadData(me.startIndex, Dialog.MAX_DATA_ITEMS);
        for (var i = 0; i < size(me.data); i += 1) {
            var row = me.data[i];
            for (var j = 0; j < size(row); j += 1) {
                if (i == 0) {
                    row[j] = me.getReplaceHeaderText(row[j]);
                }

                me.canvasTexts[i][j].setText(row[j]);
            }
        }

        me.totals = me.file.getTotalsData();
        for (var i = 0; i < size(me.totals); i += 1) {
            var total = me.totals[i];
            me.canvasTextsTotals[i].setText(sprintf(Dialog.TOTAL_FORMATS[i], total));
        }

        me.scrollContent.update();
    },

    #
    # Clear logbook data from the window
    #
    clearData: func() {
        for (var i = 0; i < size(me.canvasTexts); i += 1) {
            var row = me.canvasTexts[i];
            for (var j = 0; j < size(row); j += 1) {
                me.canvasTexts[i][j].setText("");
            }
        }
    },
};

