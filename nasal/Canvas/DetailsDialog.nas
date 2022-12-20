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
    FONT_NAME     : "LiberationFonts/LiberationMono-Bold.ttf",
    FONT_SIZE     : 16,
    COLUMNS_WIDTH : [
        120, # header
        440, # data
    ],

    #
    # Constructor
    #
    # hash settings - Settings object
    # hash file - File object
    # return me
    #
    new: func(settings, file) {
        var VBOX_SPACING = ListView.SHIFT_Y * (File.INDEX_NOTE + 1 + 2); # File.INDEX_NOTE + 1 items + 2 for longer note text
        var WINDOW_HEIGHT = VBOX_SPACING + 68; # 68 = extra space for buttons and paddings

        var me = { parents: [
            DetailsDialog,
            Dialog.new(settings, Dialog.ID_DETAILS, DetailsDialog.WINDOW_WIDTH, WINDOW_HEIGHT, "Logbook Details"),
        ] };

        # Override window del method for hide InputDialog and ConfirmationDialog
        var self = me;
        me.window.del = func() {
            call(DetailsDialog.hide, [], self);
        };

        me.dataRow         = nil;
        me.parentDataIndex = nil;
        me.file            = file;
        me.inputDialog     = InputDialog.new(settings);
        me.deleteDialog    = ConfirmationDialog.new(settings, "Delete entry log");
        me.deleteDialog.setLabel("Do you really want to delete this entry?");

        me.canvas.set("background", me.style.CANVAS_BG);

        me.listView = ListView.new(
            me.group,
            me.vbox,
            VBOX_SPACING,
            DetailsDialog.WINDOW_WIDTH,
            DetailsDialog.COLUMNS_WIDTH,
            ListView.LAYOUT_V
        );
        me.listView.setStyle(me.style);
        me.listView.setFont(DetailsDialog.FONT_NAME, DetailsDialog.FONT_SIZE);
        me.listView.setClickDialog(me.inputDialog);

        # Since the long description text overlapped the buttons, we specify a clip box
        me.listView.dataContent.setClipByBoundingBox([0, 0, DetailsDialog.WINDOW_WIDTH, VBOX_SPACING]);

        var buttonBox = me.drawBottomBar();

        me.vbox.addItem(buttonBox);

        me.setPositionOnCenter();

        me.listeners = [];

        append(me.listeners, setlistener(me.addon.node.getPath() ~ "/addon-devel/redraw-details", func(node) {
            if (node.getBoolValue()) {
                # Back to false
                setprop(node.getPath(), false);

                me.reload();
            }
        }));

        return me;
    },

    #
    # Destructor
    #
    # return void
    #
    del: func() {
        foreach (var listener; me.listeners) {
            removelistener(listener);
        }

        me.inputDialog.del();
        me.deleteDialog.del();
        call(Dialog.del, [], me);
    },

    #
    # Draw grid with logbook details
    #
    # return void
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
            .setFixedSize(75, 26)
            .listen("clicked", func {
                call(me.hide, [], me);
            }
        );

        var btnDelete = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Delete")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                if (!g_isThreadPending) {
                    me.deleteDialog.show(me.listView.parentDataIndex, me);
                }
            }
        );

        buttonBox.addStretch(3);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnDelete);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # hash style
    # return void
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        me.listView.setStyle(style);

        me.reDrawDataContent();
        me.toggleBgImage();
    },

    #
    # Show canvas dialog
    #
    # vector data
    #   data[0] = int - index of row in CSV file
    #   data[1] = vector of hashes {"allDataIndex": index, "data": row data}
    # return void
    #
    show: func(data) {
        me.inputDialog.hide();
        me.deleteDialog.hide();

        me.parentDataIndex = data[1]["allDataIndex"];
        me.listView.parentDataIndex = me.parentDataIndex;
        me.listView.setDataToDraw(data[1], me.file.getHeadersData());

        me.reDrawDataContent();

        call(Dialog.show, [], me);
    },

    #
    # Hide details window with its sub windows
    #
    # return void
    #
    hide: func() {
        me.parentDataIndex = nil;
        me.listView.parentDataIndex = nil;
        me.inputDialog.hide();
        me.deleteDialog.hide();
        call(Dialog.hide, [], me);
    },

    #
    # Reload current log
    #
    # return void
    #
    reload: func() {
        if (me.listView.parentDataIndex != nil) {
            var data = me.file.getLogData(me.listView.parentDataIndex);
            if (data == nil) {
                call(DetailsDialog.hide, [false], me);
                return;
            }

            me.listView.setDataToDraw(data, me.file.getHeadersData());
            me.reDrawDataContent();
        }
    },
};
