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
# ListView widget
#
var ListView = {
    #
    # Constants
    #
    SHIFT_Y  : 28,
    PADDING  : 10,
    LAYOUT_H : "horizontal",
    LAYOUT_V : "vertical",

    #
    # Constructor
    #
    # hash cGroup - Parent canvas group
    # hash vBox - Layout object
    # int vBoxSpacing - The value of the space by how much to move down the vbox
    # int windowWidth
    # vector columnsWidth - Array with widths of each column
    # string layout - Layout of ListView, it can be "horizontal" or "vertical"
    # return me
    #
    new: func(cGroup, vBox, vBoxSpacing, windowWidth, columnsWidth, layout = "horizontal") {
        var me = { parents: [ListView] };

        me.windowWidth    = windowWidth;
        me.font           = "LiberationFonts/LiberationSans-Bold.ttf";
        me.fontSize       = 12;
        me.columnsWidth   = columnsWidth;
        me.layout         = layout;
        me.style          = nil;
        me.clickDialog    = nil;
        me.dataRows       = [];
        me.headers        = nil;

        # If ListView is using in DetailsDialog
        me.parentDataIndex = nil;

        me.dataContent = cGroup.createChild("group");
        me.dataContent
            .set("font", me.font)
            .set("character-size", me.fontSize)
            .set("alignment", "left-baseline");

        # Add space for buttons drawn below the list view content
        vBox.addSpacing(vBoxSpacing);

        return me;
    },

    #
    # Destructor
    #
    # return void
    #
    del: func() {
    },

    #
    # string font
    # int fontSize
    # return void
    #
    setFont: func(font, fontSize) {
        me.font     = font;
        me.fontSize = fontSize;

        me.dataContent
            .set("font", me.font)
            .set("character-size", me.fontSize);
    },

    #
    # int x, y
    # return void
    #
    setTranslation: func(x, y) {
        me.dataContent.setTranslation(x, y);
    },

    #
    # Set dialog object which will be opened after click on the row
    #
    # hash dialog
    # return void
    #
    setClickDialog: func(dialog) {
        me.clickDialog = dialog;
    },

    #
    # vector|hash dataRows - If called from LogbookDialog it's vector of hashes {"allDataIndex": index, "data": row data}
    #                        If called from DetailsDialog it's single hash {"allDataIndex": index, "data": row data}
    # vector|nil headers - required for LAYOUT_V
    # return void
    #
    setDataToDraw: func(dataRows, headers = nil) {
        me.dataRows = dataRows;
        me.headers = headers;
    },

    #
    # hash style
    # return void
    #
    setStyle: func(style) {
        me.style = style;
    },

    #
    # Get width of column for given index
    #
    # int index
    # return int
    #
    getX: func(index) {
        return me.columnsWidth[index];
    },

    #
    # int y
    # vector|nil dataToPass - data to pass to MouseHover
    # return hash - canvas group
    #
    drawHoverBox: func(y, dataToPass = nil) {
        var rowGroup = me.dataContent.createChild("group");
        rowGroup.setTranslation(ListView.PADDING, y - ListView.SHIFT_Y + 11);

        # Create rect because setColorFill on rowGroup doesn't work
        var rect = rowGroup.rect(0, 0, me.windowWidth - (ListView.PADDING * 2), ListView.SHIFT_Y);

        if (me.isDetailsWindowOpenForSelectedRow(dataToPass)) {
            # This row was cliced and details window is opened
            rect.setColorFill(me.style.SELECTED_BAR);
        }
        else {
            rect.setColorFill([0.0, 0.0, 0.0, 0.0]);
        }

        var mouseHover = MouseHover.new(me.clickDialog, me.style, rowGroup, rect, dataToPass);
        mouseHover.addEvents();

        return rowGroup;
    },

    #
    # vector|nil dataToPass
    # return bool
    #
    isDetailsWindowOpenForSelectedRow: func(dataToPass) {
        return me.clickDialog != nil and
            dataToPass != nil and
            me.clickDialog.getDialogId() == Dialog.ID_DETAILS and
            me.clickDialog.isWindowVisible() and
            me.clickDialog.parentDataIndex == dataToPass[0];
    },

    #
    # hash cGroup - Parent canvas group
    # int x
    # string text
    # int|nil maxWidth
    # return hash - canvas text object
    #
    drawText: func(cGroup, x, text, maxWidth = nil) {
        var text = cGroup.createChild("text")
            .setTranslation(x, me.getTextYOffset())
            .setColor(me.style.TEXT_COLOR)
            # .setAlignment("left-top")
            .setText(text);

        if (maxWidth != nil) {
            text.setMaxWidth(maxWidth);
        }

        return text;
    },

    #
    # return int
    #
    getTextYOffset: func() {
        if (me.fontSize == 12) {
            return 16;
        }
        else if (me.fontSize == 16) {
            return 18;
        }

        return 0;
    },

    #
    # Draw list view
    #
    # return int - Y offset
    #
    reDrawDataContent: func() {
        me.dataContent.removeAllChildren();

        var y = 0;

        if (me.layout == ListView.LAYOUT_V) {
            y = me.reDrawVertical(me.dataRows, me.headers);
        }
        else {
            y = me.reDrawHorizontal(me.dataRows);
        }

        return y;
    },

    #
    # vector dataRows - vector of hashes {"allDataIndex": index, "data": vector}
    # return int - Y offset
    #
    reDrawHorizontal: func(dataRows) {
        var y = ListView.PADDING * 3;
        var index = 0;
        foreach (var dataRowHash; dataRows) {
            var x = ListView.PADDING * 2;
            var column = 0;

            var rowGroup = me.drawHoverBox(y, [dataRowHash["allDataIndex"], dataRowHash]);

            foreach (var text; dataRowHash["data"]) {
                if (column == size(dataRowHash["data"]) - 1) {
                    # Don't show Note column
                    break;
                }
                me.drawText(rowGroup, x, text);

                x += me.getX(column);
                column += 1;
            }

            y += ListView.SHIFT_Y;
            index += 1;
        }

        return y;
    },

    #
    # hash dataRows - {"allDataIndex": index, "data": vector}
    # vector headers
    # return int - Y offset
    #
    reDrawVertical: func(dataRows, headers) {
        var y = ListView.PADDING * 3;
        var index = 0;
        if (me.parentDataIndex != nil) {
            foreach (var dataText; dataRows["data"]) {
                var x = ListView.PADDING * 2;
                var column = 0;

                var rowGroup = me.drawHoverBox(y, [index, me.parentDataIndex, headers[index], dataText]);

                # column 1 - header
                me.drawText(rowGroup, x, sprintf("%10s:\n", headers[index]));

                # column 2 - data
                x += me.getX(column);
                column += 1;

                var text = dataText == "" ? "-" : dataText;
                text = sprintf("%s %s\n", text, me.getExtraText(index, dataText));
                var maxWidth = index == File.INDEX_NOTE ? me.getX(column) : nil;
                me.drawText(rowGroup, x, text, maxWidth);

                y += ListView.SHIFT_Y;
                index += 1;
            }
        }

        return y;
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
    # int column
    # string data
    # return string
    #
    getExtraText: func(column, data) {
        if ((column == File.INDEX_FROM or column == File.INDEX_TO) and data != "") { # From and To
            var airport = airportinfo(data);
            if (airport != nil) {
                return "(" ~ airport.name ~ ")";
            }
        }
        else if (column >= File.INDEX_DAY and column <= File.INDEX_DURATION) {
            return "hours";
        }
        else if (column == File.INDEX_DISTANCE) {
            return sprintf("nm (%.02f km)", data * globals.NM2M / 1000);
        }
        else if (column == File.INDEX_FUEL) {
            return sprintf("US gallons (%.02f l)", data * globals.GAL2L);
        }
        else if (column == File.INDEX_MAX_ALT) {
            return "ft MSL"
        }

        return "";
    },
};
