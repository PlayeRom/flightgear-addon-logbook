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
            Dialog.new(Dialog.ID_DETAILS, DetailsDialog.WINDOW_WIDTH, DetailsDialog.WINDOW_HEIGHT, "Logbook Details"),
        ] };

        me.dataRow         = nil;
        me.parentDataIndex = nil;
        me.file            = file;
        me.inputDialog     = InputDialog.new(file);
        me.deleteDialog    = ConfirmationDialog.new(file, "Delete entry log");
        me.deleteDialog.setLabel("Do you really want to delete this entry?");

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
        me.listView.setClickDialog(me.inputDialog);

        var buttonBox = me.drawBottomBar();

        me.vbox.addItem(buttonBox);

        me.setPositionOnCenter(DetailsDialog.WINDOW_WIDTH, DetailsDialog.WINDOW_HEIGHT);

        setlistener(me.addon.node.getPath() ~ "/addon-devel/redraw-details", func(node) {
            if (node.getValue()) {
                # Back to false
                setprop(node.getPath(), false);

                me.reload();
            }
        });

        return me;
    },

    #
    # Destructor
    #
    del: func() {
        me.inputDialog.del();
        me.deleteDialog.del();
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
            .setText("Delete")
            .setFixedSize(75, 26);

        btnClose.listen("clicked", func {
            me.deleteDialog.show(me.listView.parentDataIndex);
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
    # vector data
    #   data[0] = int - index of row in CSV file
    #   data[1] = vector of single row data
    # return void
    #
    show: func(data) {
        me.inputDialog.hide();

        me.parentDataIndex = data[0];
        me.listView.parentDataIndex = me.parentDataIndex;
        me.listView.setDataToDraw(data[1], 0, me.file.getHeadersData());

        me.reDrawDataContent();

        me.parents[1].show();
    },

    #
    # Reload current log
    #
    # return void
    #
    reload: func() {
        if (me.listView.parentDataIndex != nil) {
            var data = me.file.getLogData(me.listView.parentDataIndex);
            me.listView.setDataToDraw(data, 0, me.file.getHeadersData());
            me.reDrawDataContent();
        }
    },
};
