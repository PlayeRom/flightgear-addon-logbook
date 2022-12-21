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
        me.vBoxSpacing    = vBoxSpacing;

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

        if (me.fontSize == 16) {
            return 18;
        }

        return 0;
    },

    #
    # Draw "Loading..." text (for LogbookDialog only)
    #
    # return void
    #
    drawLoading: func() {
        me.dataContent.removeAllChildren();

        me.dataContent.createChild("text")
            .setTranslation(int(LogbookDialog.WINDOW_WIDTH / 2), int(me.vBoxSpacing / 2))
            .setColor(me.style.TEXT_COLOR)
            .setAlignment("center-center")
            .setText("Loading...");
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
                text = sprintf("%s %s\n", me.addCommaSeparator(index, text), me.getExtraText(index, dataText));
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
    # string value
    # return string
    #
    getExtraText: func(column, value) {
        if ((column == File.INDEX_FROM or column == File.INDEX_TO) and value != "") {
            var airport = airportinfo(value);
            if (airport != nil) {
                return "(" ~ airport.name ~ ")";
            }

            return "";
        }

        if (column >= File.INDEX_DAY and column <= File.INDEX_DURATION) {
            var digits = split(".", value);
            if (size(digits) < 2) {
                # something is wrong
                return "hours";
            }

            return sprintf("hours (%d:%02.0f)", digits[0], (digits[1] / 100) * 60);
        }

        if (column == File.INDEX_DISTANCE) {
            var inMeters = value * globals.NM2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("nm (%s km)", me.getValueWithCommaSeparator(km));
            }

            return sprintf("nm (%.0f m)", inMeters);
        }

        if (column == File.INDEX_FUEL) {
            var liters = sprintf("%.02f", value * globals.GAL2L);
            return sprintf("US gallons (%s l)", me.getValueWithCommaSeparator(liters));
        }

        if (column == File.INDEX_MAX_ALT) {
            var inMeters = value * globals.FT2M;
            if (inMeters >= 1000) {
                var km = sprintf("%.02f", inMeters / 1000);
                return sprintf("ft MSL (%s km)", me.getValueWithCommaSeparator(km));
            }

            return sprintf("ft MSL (%.0f m)", inMeters);
        }

        return "";
    },

    #
    # int column
    # string value
    # return string
    #
    addCommaSeparator: func(column, value) {
        if (column == File.INDEX_DISTANCE or
            column == File.INDEX_FUEL or
            column == File.INDEX_MAX_ALT
        ) {
            return me.getValueWithCommaSeparator(value);
        }

        return value;
    },

    #
    # string value
    # return string
    #
    getValueWithCommaSeparator: func(value) {
        var splitted   = split(".", value);
        var strToCheck = splitted[0];
        var newValue   = strToCheck;
        var length     = size(strToCheck);
        if (length > 3) {
            newValue = "";
            var modulo = math.mod(length, 3);
            if (modulo > 0) {
                newValue ~= substr(strToCheck, 0, modulo);
                newValue ~= ",";
            }

            for (var i = modulo; i < length; i += 3) {
                newValue ~= substr(strToCheck, i, 3);
                if (i + 3 < length) {
                    newValue ~= ",";
                }
            }
        }

        if (size(splitted) == 2) {
            return newValue ~ "." ~ splitted[1];
        }

        return newValue;
    },
};
