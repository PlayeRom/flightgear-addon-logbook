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
# SettingsDialogSQLite class to display settings options for version with SQLite DB
#
var SettingsDialogSQLite = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 500,
    WINDOW_HEIGHT : 680,
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
                SettingsDialogSQLite,
                Dialog.new(SettingsDialogSQLite.WINDOW_WIDTH, SettingsDialogSQLite.WINDOW_HEIGHT, "Logbook Settings"),
            ],
            _columns: columns,
            _logbook: logbook,
        };

        me._dateTimeDisplay = g_Settings.getDateTimeDisplay();
        me._soundOption     = g_Settings.isSoundEnabled();
        me._logItemsPerPage = g_Settings.getLogItemsPerPage();
        me._columnsVisible = {};
        me._loadColumnsVisible();

        me.bgImage.hide();

        me.setPositionOnCenter();

        me._checkboxReal     = nil;
        me._checkboxSimUtc   = nil;
        me._checkboxSimLocal = nil;
        me._lineEditItemsPerPage = nil;
        me._columnCheckBoxes = {};
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

        me._dateTimeDisplay = g_Settings.getDateTimeDisplay();
        me._soundOption     = g_Settings.isSoundEnabled();
        me._logItemsPerPage = g_Settings.getLogItemsPerPage();
        me._loadColumnsVisible();

        me._drawContent();

        call(Dialog.show, [], me);
    },

    #
    # Load visibility option from columns to settings dialog memory
    #
    # @return void
    #
    _loadColumnsVisible: func() {
        me._columnsVisible = {};

        foreach (var columnItem; me._columns.getAll()) {
            me._columnsVisible[columnItem.name] = columnItem.visible;
        }
    },

    #
    # Save settings to XML file and close the Settings dialog
    #
    # @return void
    #
    _save: func() {
        # Set values to Settings object
        g_Settings.setDateTimeDisplay(me._dateTimeDisplay);
        g_Settings.setSoundEnabled(me._soundOption);
        g_Settings.setColumnsVisible(me._columnsVisible);
        g_Settings.setLogItemsPerPage(me._logItemsPerPage);

        g_Settings.save();

        me._columns.updateColumnsVisible();

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
            left   : SettingsDialogSQLite.PADDING,
            top    : SettingsDialogSQLite.PADDING,
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
        me._drawDateTimeOptions(vBoxLayout);
        me._drawMiscellaneousOptions(vBoxLayout);
        vBoxLayout.addStretch(1);
        me._hBoxLayout.addItem(vBoxLayout);

        me._hBoxLayout.addItem(me._drawColumnsVisible());

        me._scrollData.setLayout(me._hBoxLayout);
    },

    #
    # Draw options for date & time
    #
    # @param  ghost  vBoxLayout  canvas.VBoxLayout
    # @return ghost  canvas.VBoxLayout
    #
    _drawDateTimeOptions: func(vBoxLayout) {
        vBoxLayout.addItem(me._getLabel("Date and time displayed\nin the Logbook view"));
        vBoxLayout.addSpacing(10);

        # TODO: for 2024.1. replace CheckBoxes to RadioButtons
        me._checkboxReal     = me._getCheckbox("Real date & time (from your OS)", me._dateTimeDisplay == Settings.DATE_TIME_REAL);
        me._checkboxSimUtc   = me._getCheckbox("UTC time in simulator", me._dateTimeDisplay == Settings.DATE_TIME_SIM_UTC);
        me._checkboxSimLocal = me._getCheckbox("Local time in simulator", me._dateTimeDisplay == Settings.DATE_TIME_SIM_LOC);

        me._checkboxReal.listen("toggled", func(e) {
            if (e.detail.checked) {
                me._dateTimeDisplay = Settings.DATE_TIME_REAL;
                me._checkboxSimUtc.setChecked(false);
                me._checkboxSimLocal.setChecked(false);
            }
            else if (me._dateTimeDisplay == Settings.DATE_TIME_REAL) {
                me._turnYourselfOn(me._checkboxReal);
            }
        });

        me._checkboxSimUtc.listen("toggled", func(e) {
            if (e.detail.checked) {
                me._dateTimeDisplay = Settings.DATE_TIME_SIM_UTC;
                me._checkboxReal.setChecked(false);
                me._checkboxSimLocal.setChecked(false);
            }
            else if (me._dateTimeDisplay == Settings.DATE_TIME_SIM_UTC) {
                me._turnYourselfOn(me._checkboxSimUtc);
            }
        });

        me._checkboxSimLocal.listen("toggled", func(e) {
            if (e.detail.checked) {
                me._dateTimeDisplay = Settings.DATE_TIME_SIM_LOC;
                me._checkboxReal.setChecked(false);
                me._checkboxSimUtc.setChecked(false);
            }
            else if (me._dateTimeDisplay == Settings.DATE_TIME_SIM_LOC) {
                me._turnYourselfOn(me._checkboxSimLocal);
            }
        });

        vBoxLayout.addItem(me._checkboxReal);
        vBoxLayout.addItem(me._checkboxSimUtc);
        vBoxLayout.addItem(me._checkboxSimLocal);

        return vBoxLayout;
    },

    #
    # For checkboxes imitating radio buttons, you can't uncheck a button that is
    # already checked. If that happens, we have to check the checkbox again.
    #
    # @param  canvas  checkBox
    # @return void
    #
    _turnYourselfOn: func(checkBox) {
        var timer = maketimer(0.2, func { checkBox.setChecked(true); });
        timer.singleShot = true;
        timer.start();
    },

    #
    # Draw Miscellaneous Options
    #
    # @param  ghost  vBoxLayout  canvas.VBoxLayout
    # @return ghost  canvas.VBoxLayout
    #
    _drawMiscellaneousOptions: func(vBoxLayout) {
        vBoxLayout.addSpacing(30);
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
        var hBoxLayout = canvas.HBoxLayout.new();

        hBoxLayout.addItem(me._getLabel("Items per page"));

        var comboBox = canvas.gui.widgets.ComboBox.new(me._scrollDataContent, {});
        comboBox.createItem("5", 5);
        comboBox.createItem("10", 10);
        comboBox.createItem("15", 15);
        comboBox.createItem("20", 20);
        comboBox.setSelectedByValue(g_Settings.getLogItemsPerPage());
        comboBox.listen("selected-item-changed", func(e) {
            me._logItemsPerPage = e.detail.value;
        });

        hBoxLayout.addItem(comboBox);

        hBoxLayout.addStretch(1); # Decrease LineEdit width

        vBoxLayout.addItem(hBoxLayout);

        return vBoxLayout;
    },

    #
    # Draw column visibility options
    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawColumnsVisible: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        vBoxLayout.addItem(me._getLabel("Columns to display in\nthe Logbook view"));
        vBoxLayout.addSpacing(10);

        var checkboxDate = me._getCheckbox("Date", true, false);
        var checkboxTime = me._getCheckbox("Time", true, false);
        vBoxLayout.addItem(checkboxDate);
        vBoxLayout.addItem(checkboxTime);

        me._columnCheckBoxes = {};

        foreach (var columnItem; me._columns.getAll()) {
            if (   columnItem.name == Columns.DATE
                or columnItem.name == Columns.TIME
                or columnItem.name == Columns.SIM_UTC_DATE
                or columnItem.name == Columns.SIM_UTC_TIME
                or columnItem.name == Columns.SIM_LOC_DATE
                or columnItem.name == Columns.SIM_LOC_TIME
            ) {
                continue;
            }

            var isDisabled = columnItem.name == Columns.AIRCRAFT
                or columnItem.name == Columns.NOTE;

            var isChecked = me._columnsVisible[columnItem.name];

            var checkbox = me._getCheckbox(columnItem.header, isChecked, !isDisabled);

            if (!isDisabled) {
                func() {
                    var columnName = columnItem.name;
                    checkbox.listen("toggled", func(e) {
                        me._columnsVisible[columnName] = e.detail.checked;
                    });
                }();
            }

            vBoxLayout.addItem(checkbox);
        }

        vBoxLayout.addStretch(1);

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
