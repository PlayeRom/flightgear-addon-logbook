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
    WINDOW_HEIGHT : 360,
    PADDING       : 10,

    #
    # Constructor
    #
    # hash file - File object
    #
    new: func(file) {
        var me = { parents: [
            DetailsDialog,
            Dialog.new(DetailsDialog.WINDOW_WIDTH, DetailsDialog.WINDOW_HEIGHT, "Logbook Details", true),
        ] };

        me.file = file;

        me.canvas.set("background", me.style.CANVAS_BG);

        var margins = {"left": DetailsDialog.PADDING, "top": DetailsDialog.PADDING, "right": 0, "bottom": 0};
        me.scrollData = me.createScrollArea(me.style.CANVAS_BG, margins);

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent(
            me.scrollData,
            "LiberationFonts/LiberationMono-Bold.ttf",
            16,
            "left-baseline"
        );

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
    # Destructor
    #
    del: func() {
        me.parents[1].del();
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

        me.parents[1].show();
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
    },
};
