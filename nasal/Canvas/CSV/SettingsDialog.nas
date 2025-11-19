#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# SettingsDialog class to display settings options for version with CSV file
#
var SettingsDialog = {
    CLASS: "SettingsDialog",

    #
    # Constants
    #
    WINDOW_WIDTH  : 250,
    WINDOW_HEIGHT : 250,
    PADDING       : 10,

    #
    # Constructor
    #
    # @param  hash  columns  Columns object
    # @param  hash  logbook  Logbook object
    # @return hash
    #
    new: func(columns, logbook) {
        var obj = {
            parents: [
                SettingsDialog,
                PersistentDialog.new(
                    SettingsDialog.WINDOW_WIDTH,
                    SettingsDialog.WINDOW_HEIGHT,
                    "Logbook Settings",
                ),
            ],
            _columns: columns,
            _logbook: logbook,
        };

        call(PersistentDialog.setChild, [obj, SettingsDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._widgetGroup  = WidgetHelper.new(obj._group);
        obj._widgetScroll = WidgetHelper.new();

        obj._soundOption = g_Settings.isSoundEnabled();

        obj._lineEditItemsPerPage = nil;
        obj._hBoxLayout = nil;

        obj._drawContent();

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    # @override PersistentDialog
    #
    del: func {
        call(PersistentDialog.del, [], me);
    },

    #
    # Show this canvas dialog
    #
    # @return void
    # @override PersistentDialog
    #
    show: func {
        g_Sound.play('paper');

        me._soundOption = g_Settings.isSoundEnabled();

        me._drawContent();

        call(PersistentDialog.show, [], me);
    },

    #
    # Save settings to XML file and close the Settings dialog
    #
    # @return void
    #
    _save: func {
        # Set values to Settings object
        g_Settings.setSoundEnabled(me._soundOption);
        g_Settings.setLogItemsPerPage(me._lineEditItemsPerPage.text());

        me._logbook.resetLogbookDialog();

        me.hide();
    },

    #
    # Draw whole dialog content
    #
    # @return void
    #
    _drawContent: func {
        me._vbox.clear();

        var margins = {
            left   : SettingsDialog.PADDING,
            top    : SettingsDialog.PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollArea = ScrollAreaHelper.create(me._group, margins);

        me._vbox.addItem(me._scrollArea, 1); # 2nd param = stretch

        me._scrollContent = ScrollAreaHelper.getContent(me._scrollArea);

        me._widgetScroll.setContext(me._scrollContent);

        me._drawScrollable();

        me._drawBottomBar();
    },

    #
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func {
        var vBoxLayout = canvas.VBoxLayout.new();
        me._drawMiscellaneousOptions(vBoxLayout);
        vBoxLayout.addStretch(1);

        me._hBoxLayout = canvas.HBoxLayout.new();
        me._hBoxLayout.addItem(vBoxLayout);

        me._scrollArea.setLayout(me._hBoxLayout);
    },

    #
    # Draw Miscellaneous Options
    #
    # @param  ghost  vBoxLayout  canvas.VBoxLayout
    # @return ghost  canvas.VBoxLayout
    #
    _drawMiscellaneousOptions: func(vBoxLayout) {
        vBoxLayout.addItem(me._widgetScroll.getLabel("Miscellaneous Options"));

        var checkboxSound = me._widgetScroll.getCheckBox("Click sound", me._soundOption, func(e) {
            me._soundOption = e.detail.checked ? true : false;
        });

        vBoxLayout.addItem(checkboxSound);

        me._drawLogItemsPerPage(vBoxLayout);

        return vBoxLayout;
    },

    #
    # Draw Items per page option
    #
    # @param  ghost  vBoxLayout  canvas.VBoxLayout
    # @return ghost  canvas.VBoxLayout
    #
    _drawLogItemsPerPage: func(vBoxLayout) {
        vBoxLayout.addItem(me._widgetScroll.getLabel("Items per page (min 5, max 20)"));

        me._lineEditItemsPerPage = me._widgetScroll.getLineEdit(sprintf("%d", g_Settings.getLogItemsPerPage()));

        var hBoxLayout = canvas.HBoxLayout.new();
        hBoxLayout.addItem(me._lineEditItemsPerPage);
        hBoxLayout.addStretch(1); # Decrease LineEdit width

        vBoxLayout.addItem(hBoxLayout);

        return vBoxLayout;
    },

    #
    # @return void
    #
    _drawBottomBar: func {
        var btnSave   = me._widgetGroup.getButton("OK", func me._save(), 65);
        var btnCancel = me._widgetGroup.getButton("Cancel", func me.hide(), 65);

        var buttonBox = canvas.HBoxLayout.new();
        buttonBox.addStretch(1);
        buttonBox.addItem(btnSave);
        buttonBox.addItem(btnCancel);
        buttonBox.addStretch(1);

        me._vbox.addSpacing(10);
        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(10);
    },
};
