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
    WINDOW_HEIGHT : 600,
    FONT_NAME     : "LiberationFonts/LiberationMono-Bold.ttf",
    FONT_SIZE     : 16,
    COLUMNS_WIDTH : [
        120, # header
        450, # data
    ],

    #
    # Constructor
    #
    # hash file - File object
    #
    new: func(file) {
        var me = { parents: [
            DetailsDialog,
            Dialog.new(DetailsDialog.WINDOW_WIDTH, DetailsDialog.WINDOW_HEIGHT, "Logbook Details"),
        ] };

        me.dataRow = nil;
        me.file    = file;

        me.canvas.set("background", me.style.CANVAS_BG);

        me.listView = ListView.new(
            me.group,
            me.vbox,
            ListView.SHIFT_Y * 19,
            DetailsDialog.WINDOW_WIDTH,
            DetailsDialog.COLUMNS_WIDTH,
            ListView.LAYOUT_V
        );
        me.listView.setStyle(me.style);
        me.listView.setFont(DetailsDialog.FONT_NAME, DetailsDialog.FONT_SIZE);

        var buttonBox = me.drawBottomBar();

        me.vbox.addItem(buttonBox);

        return me;
    },

    #
    # Destructor
    #
    del: func() {
        me.parents[1].del();
    },

    #
    # Draw grid with logbook details
    #
    reDrawDataContent: func() {
        me.listView.reDrawDataContent();
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
        me.listView.setStyle(style);

        me.reDrawDataContent();
    },

    #
    # Show canvas dialog
    #
    # vector dataRows
    #
    show: func(dataRows) {
        me.listView.setDataToDraw(dataRows, me.file.getHeadersData());
        me.reDrawDataContent();

        me.parents[1].show();
    },
};
