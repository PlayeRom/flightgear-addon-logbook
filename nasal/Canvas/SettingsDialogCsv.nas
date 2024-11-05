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
# SettingsDialogCsv class to display settings options for version with CSV file
#
var SettingsDialogCsv = {
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
    # @return me
    #
    new: func(columns, logbook) {
        var me = {
            parents: [
                SettingsDialogCsv,
                Dialog.new(SettingsDialogCsv.WINDOW_WIDTH, SettingsDialogCsv.WINDOW_HEIGHT, "Logbook Settings"),
            ],
            _columns: columns,
            _logbook: logbook,
        };

        me._soundOption     = g_Settings.isSoundEnabled();

        me.bgImage.hide();

        me.setPositionOnCenter();

        me._lineEditItemsPerPage = nil;
        me._hBoxLayout = nil;

        me._drawContent();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Show this canvas dialog
    #
    # @return void
    #
    show: func() {
        g_Sound.play('paper');

        me._soundOption     = g_Settings.isSoundEnabled();

        me._drawContent();

        call(Dialog.show, [], me);
    },

    #
    # Save settings to XML file and close the Settings dialog
    #
    # @return void
    #
    _save: func() {
        # Set values to Settings object
        g_Settings.setSoundEnabled(me._soundOption);
        g_Settings.setLogItemsPerPage(me._lineEditItemsPerPage.text());

        g_Settings.save();

        me._logbook.resetLogbookDialog();

        me.window.hide();
    },

    #
    # Draw whole dialog content
    #
    # @return void
    #
    _drawContent: func() {
        me.vbox.clear();

        var margins = {
            left   : SettingsDialogCsv.PADDING,
            top    : SettingsDialogCsv.PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollData = me.createScrollArea(nil, margins);

        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch

        me._scrollDataContent = me.getScrollAreaContent(me._scrollData);

        me._drawScrollable();

        me._drawBottomBar();
    },

    #
    # Draw content for scrollable area
    #
    # @return void
    #
    _drawScrollable: func() {
        me._hBoxLayout = canvas.HBoxLayout.new();

        var vBoxLayout = canvas.VBoxLayout.new();
        me._drawMiscellaneousOptions(vBoxLayout);
        vBoxLayout.addStretch(1);
        me._hBoxLayout.addItem(vBoxLayout);

        me._scrollData.setLayout(me._hBoxLayout);
    },

    #
    # Draw Miscellaneous Options
    #
    # @param  ghost  vBoxLayout  canvas.VBoxLayout
    # @return ghost  canvas.VBoxLayout
    #
    _drawMiscellaneousOptions: func(vBoxLayout) {
        vBoxLayout.addItem(me._getLabel("Miscellaneous Options"));

        var checkboxSound = me._getCheckbox("Click sound", me._soundOption);
        checkboxSound.listen("toggled", func(e) {
            me._soundOption = e.detail.checked;
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
        vBoxLayout.addItem(me._getLabel("Items per page (min 5, max 20)"));

        var hBoxLayout = canvas.HBoxLayout.new();

        me._lineEditItemsPerPage = canvas.gui.widgets.LineEdit.new(me._scrollDataContent, canvas.style, {})
            .setText(sprintf("%d", g_Settings.getLogItemsPerPage()));

        hBoxLayout.addItem(me._lineEditItemsPerPage);
        hBoxLayout.addStretch(1); # Decrease LineEdit width

        vBoxLayout.addItem(hBoxLayout);

        return vBoxLayout;
    },

    #
    # Get widgets.Label
    #
    # @param  string  text  Label text
    # @return ghost  Label widget
    #
    _getLabel: func(text) {
        return canvas.gui.widgets.Label.new(me._scrollDataContent, canvas.style, {})
            .setText(text);
    },

    #
    # Get widgets.CheckBox
    #
    # @param  string  text  Label text
    # @param  bool  isChecked
    # @param  bool  isEnabled
    # @return ghost  widgets.CheckBox
    #
    _getCheckbox: func(text, isChecked, isEnabled = 1) {
        var checkbox = canvas.gui.widgets.CheckBox.new(me._scrollDataContent, canvas.style, { wordWrap: false })
            .setText(text)
            .setChecked(isChecked)
            .setEnabled(isEnabled);

        return checkbox;
    },

    #
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnSave = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Save")
            .setFixedSize(65, 26)
            .listen("clicked", func { me._save(); });

        var btnCancel = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText("Cancel")
            .setFixedSize(65, 26)
            .listen("clicked", func { me.window.hide(); });

        buttonBox.addStretch(1);
        buttonBox.addItem(btnSave);
        buttonBox.addItem(btnCancel);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return buttonBox;
    },
};
