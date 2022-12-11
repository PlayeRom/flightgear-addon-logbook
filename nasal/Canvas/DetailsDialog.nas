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
    WINDOW_WIDTH         : 600,
    WINDOW_HEIGHT        : 360,
    PADDING              : 10,

    #
    # Constructor
    #
    # hash style
    # hash file - File object
    #
    new: func(style, file) {
        var me = { parents: [DetailsDialog] };

        me.style = style;
        me.file = file;

        me.window = me.createCanvasWindow();
        me.canvas = me.window.createCanvas().set("background", me.style.CANVAS_BG);
        me.group  = me.canvas.createGroup();

        me.vbox   = canvas.VBoxLayout.new();
        me.canvas.setLayout(me.vbox);

        me.scrollData = me.createScrollArea();

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent();

        me.textHeaders = me.drawText(0, 0);

        var offsetX = 110;
        me.textData = me.drawText(
            offsetX,
            0,
            DetailsDialog.WINDOW_WIDTH - (DetailsDialog.PADDING * 2) - offsetX
        );

        var buttonBox = me.drawBottomBar();

        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return me;
    },

    #
    # return hash
    #
    createCanvasWindow: func() {
        var window = canvas.Window.new([DetailsDialog.WINDOW_WIDTH, DetailsDialog.WINDOW_HEIGHT], "dialog")
            .set("title", "Logbook details")
            .setBool("resize", true);

        window.hide();

        window.del = func() {
            # This method will be call after click on (X) button in canvas top
            # bar and here we want hide the window only.
            # FG next version provide destroy_on_close, but for 2020.3.x it's
            # unavailable, so we are handling it manually by this trick.
            call(me.hide, [], me);
        };

        # Because window.del only hide the window, we have to add extra method
        # to really delete the window.
        window.destroy = func() {
            call(canvas.Window.del, [], me);
        };

        return window;
    },

    #
    # return hash - gui.widgets.ScrollArea object
    #
    createScrollArea: func() {
        var scrollData = canvas.gui.widgets.ScrollArea.new(me.group, canvas.style, {});
        scrollData.setColorBackground(me.style.CANVAS_BG);
        scrollData.setContentsMargins(DetailsDialog.PADDING, DetailsDialog.PADDING, 0, 0); # left, top, right, bottom

        return scrollData;
    },

    #
    # return hash - content group of ScrollArea
    #
    getScrollAreaContent: func() {
        var scrollDataContent = me.scrollData.getContent();
        scrollDataContent
            .set("font", "LiberationFonts/LiberationMono-Bold.ttf")
            .set("character-size", 16)
            .set("alignment", "left-baseline");

        return scrollDataContent;
    },

    #
    # int x
    # int y
    # int|nil maxWidth
    # return hash - canvas text object
    #
    drawText: func(x, y, maxWidth = nil) {
        var text = me.scrollDataContent.createChild("text")
            .setTranslation(x, y)
            .setColor(me.style.TEXT_COLOR)
            .setAlignment("left-top");

        if (maxWidth != nil) {
            text.setMaxWidth(maxWidth);
        }

        return text;
    },

    #
    # return hash - HBoxLayout object with button
    #
    drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Close")
            .setFixedSize(75, 26);

        btnClose.listen("clicked", func {
            me.window.hide();
        });

        buttonBox.addItem(btnClose);

        return buttonBox;
    },

    #
    # Destructor
    #
    del: func() {
        me.window.destroy();
    },

    #
    # hash style
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.scrollData.setColorBackground(me.style.CANVAS_BG);
        me.textHeaders.setColor(me.style.TEXT_COLOR);
        me.textData.setColor(me.style.TEXT_COLOR);
    },

    #
    # Show canvas dialog
    #
    # vector dataRow
    #
    show: func(dataRow) {
        me.textHeaders.setText(me.getTextHeaders(dataRow));
        me.textData.setText(me.getTextData(dataRow));
        me.window.raise();
        me.window.show();
    },

    #
    # Hide canvas dialog
    #
    hide: func() {
        me.window.hide();
    },

    #
    # vector dataRow
    # return string
    #
    getTextHeaders: func(dataRow) {
        var text = "";
        var headers = me.file.getHeadersData();
        for (var i = 0; i < size(headers); i += 1) {
            var header = headers[i];
            text ~= sprintf("%10s:\n", headers[i]);
        }

        return text;
    },

    #
    # vector dataRow
    # return string
    #
    getTextData: func(dataRow) {
        var text = "";
        var headers = me.file.getHeadersData();
        for (var i = 0; i < size(headers); i += 1) {
            if (i < size(dataRow)) {
                var data = dataRow[i] == "" ? "-" : dataRow[i];
                text ~= sprintf("%s %s\n", data, me.getExtraText(i, dataRow[i]));
            }
        }

        return text;
    },

    #
    # int column
    # string data
    # return string
    #
    getExtraText: func(column, data) {
        if ((column == 4 or column == 5) and data != "") { # From and To
            var airport = airportinfo(data);
            if (airport != nil) {
                return "(" ~ airport.name ~ ")";
            }
        }
        else if (column >= 8 and column <= 11) {
            return "hours";
        }
        else if (column == 12) {
            return "nm"
        }
        else if (column == 13) {
            return "US gallons"
        }
        else if (column == 14) {
            return "ft MSL"
        }

        return "";
    }
};
