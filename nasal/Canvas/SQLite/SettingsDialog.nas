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
# SettingsDialog class to display settings options for version with SQLite DB
#
var SettingsDialog = {
    CLASS: "SettingsDialog",

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
    # @return hash
    #
    new: func(columns, logbook) {
        var me = {
            parents: [
                SettingsDialog,
                Dialog.new(SettingsDialog.WINDOW_WIDTH, SettingsDialog.WINDOW_HEIGHT, "Logbook Settings"),
            ],
            _columns: columns,
            _logbook: logbook,
        };

        # Let the parent know who their child is.
        me.parents[1].setChild(me, SettingsDialog);

        me._dateTimeDisplay = g_Settings.getDateTimeDisplay();
        me._soundOption     = g_Settings.isSoundEnabled();
        me._logItemsPerPage = g_Settings.getLogItemsPerPage();
        me._mapProvider     = g_Settings.getMapProvider();
        me._columnsVisible  = {};
        me._loadColumnsVisible();

        me.bgImage.hide();

        me.setPositionOnCenter();

        me._checkboxReal         = nil;
        me._checkboxSimUtc       = nil;
        me._checkboxSimLocal     = nil;
        me._lineEditItemsPerPage = nil;
        me._columnCheckBoxes     = {};
        me._hBoxLayout           = nil;

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
        me._mapProvider     = g_Settings.getMapProvider();
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
        g_Settings.setMapProvider(me._mapProvider);

        me._columns.updateColumnsVisible();

        me._logbook.resetLogbookDialog();

        me.hide();
    },

    #
    # Draw whole dialog content
    #
    # @return void
    #
    _drawContent: func() {
        me._vbox.clear();

        var margins = {
            left   : SettingsDialog.PADDING,
            top    : SettingsDialog.PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollData = me.createScrollArea(margins: margins);

        me._vbox.addItem(me._scrollData, 1); # 2nd param = stretch

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
        me._drawFlightAnalysisOptions(vBoxLayout);
        me._drawMiscellaneousOptions(vBoxLayout);
        vBoxLayout.addStretch(1);

        me._hBoxLayout.addItem(vBoxLayout);
        me._hBoxLayout.addSpacing(30);
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
        vBoxLayout.addItem(me._getLabel("Date and time displayed\nin the Logbook view", { wordWrap: true }));
        vBoxLayout.addSpacing(10);

        var radio1 = me._getRadioButton("Real date & time (from your OS)")
            .setChecked(me._dateTimeDisplay == Settings.DATE_TIME_REAL);

        var radio2 = me._getRadioButton("UTC time in simulator",   { "parent-radio": radio1 })
            .setChecked(me._dateTimeDisplay == Settings.DATE_TIME_SIM_UTC);

        var radio3 = me._getRadioButton("Local time in simulator", { "parent-radio": radio1 })
            .setChecked(me._dateTimeDisplay == Settings.DATE_TIME_SIM_LOC);

        radio1.listen("group-checked-radio-changed", func(e) {
            var radioGroup = radio1.getRadioButtonsGroup();

            # In the dev version of the FG, the getCheckedRadio() method has been changed to getCheckedRadioButton().
            # TODO: Remove the check and only use getCheckedRadioButton when version 2024 becomes obsolete.
            var checkedRadio = Utils.tryCatch(func { typeof(radioGroup.getCheckedRadioButton) == "func"; }, [])
                ? radioGroup.getCheckedRadioButton()
                : radioGroup.getCheckedRadio();

            var getDateTimeDisplay = func(item) {
                if (item != nil) {
                       if (item._text == "UTC time in simulator")   return Settings.DATE_TIME_SIM_UTC;
                    elsif (item._text == "Local time in simulator") return Settings.DATE_TIME_SIM_LOC;
                }

                return Settings.DATE_TIME_REAL;
            };

            me._dateTimeDisplay = getDateTimeDisplay(checkedRadio);
        });

        vBoxLayout.addItem(radio1);
        vBoxLayout.addItem(radio2);
        vBoxLayout.addItem(radio3);

        return vBoxLayout;
    },

    #
    # Draw Flight Analysis Options
    #
    # @param  ghost  vBoxLayout  canvas.VBoxLayout
    # @return ghost  canvas.VBoxLayout
    #
    _drawFlightAnalysisOptions: func(vBoxLayout) {
        vBoxLayout.addSpacing(30);
        vBoxLayout.addItem(me._getLabel("Flight Analysis Options"));
        vBoxLayout.addItem(me._drawMapProvider());

        return vBoxLayout;
    },

    #
    # Draw Map Provider combo box
    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawMapProvider: func() {
        var hBoxLayout = canvas.HBoxLayout.new();

        hBoxLayout.addItem(me._getLabel("Map provider"));

        var comboBox = canvas.gui.widgets.ComboBox.new(me._scrollDataContent, canvas.style, {});
        if (Utils.tryCatch(func { typeof(comboBox.createItem) == "func"; }, [])) {
            # For next addMenuItem is deprecated
            comboBox.createItem("OpenStreetMap", "OpenStreetMap");
            comboBox.createItem("OpenTopoMap",   "OpenTopoMap");
        }
        else { # for 2024.1
            comboBox.addMenuItem("OpenStreetMap", "OpenStreetMap");
            comboBox.addMenuItem("OpenTopoMap",   "OpenTopoMap");
        }
        comboBox.setSelectedByValue(g_Settings.getMapProvider());
        comboBox.listen("selected-item-changed", func(e) {
            me._mapProvider = e.detail.value;
        });

        hBoxLayout.addItem(comboBox, 1);
        # hBoxLayout.addSpacing(20);

        # hBoxLayout.addStretch(1); # Decrease combo width

        return hBoxLayout;
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

        var checkboxSound = me._getCheckbox(text: "Click sound", isChecked: me._soundOption);
        checkboxSound.listen("toggled", func(e) {
            me._soundOption = e.detail.checked;
        });

        vBoxLayout.addItem(checkboxSound);

        vBoxLayout.addItem(me._drawLogItemsPerPage());

        vBoxLayout.addItem(
            me._getLabel(
                'The "Optimize database" button will defragment the database file, which will speed up database operations and reduce its size on the disk.',
                { wordWrap: true }
        ));
        var btnVacuum = canvas.gui.widgets.Button.new(me._scrollDataContent, canvas.style, {})
            .setText("Optimize database")
            .setFixedSize(150, 26)
            .listen("clicked", func {
                if (!g_isThreadPending) {
                    if (me._logbook.vacuumSQLite()) {
                        gui.popupTip("The database has been optimized");
                    }
                }
            }
        );

        vBoxLayout.addSpacing(20);
        vBoxLayout.addItem(btnVacuum);

        return vBoxLayout;
    },

    #
    # Draw Items per page option
    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawLogItemsPerPage: func() {
        var hBoxLayout = canvas.HBoxLayout.new();

        hBoxLayout.addItem(me._getLabel("Items per page"));

        var comboBox = canvas.gui.widgets.ComboBox.new(me._scrollDataContent, {});
        if (Utils.tryCatch(func { typeof(comboBox.createItem) == "func"; }, [])) {
            # For next addMenuItem is deprecated
            comboBox.createItem( "5",  5);
            comboBox.createItem("10", 10);
            comboBox.createItem("15", 15);
            comboBox.createItem("20", 20);
        }
        else { # for 2024.1
            comboBox.addMenuItem( "5",  5);
            comboBox.addMenuItem("10", 10);
            comboBox.addMenuItem("15", 15);
            comboBox.addMenuItem("20", 20);
        }
        comboBox.setSelectedByValue(g_Settings.getLogItemsPerPage());
        comboBox.listen("selected-item-changed", func(e) {
            me._logItemsPerPage = e.detail.value;
        });

        hBoxLayout.addItem(comboBox);

        hBoxLayout.addStretch(1); # Decrease combo width

        return hBoxLayout;
    },

    #
    # Draw column visibility options
    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawColumnsVisible: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        vBoxLayout.addItem(me._getLabel("Columns to display in the Logbook view", { wordWrap: true }));
        vBoxLayout.addSpacing(10);

        var checkboxDate = me._getCheckbox(text: "Date", isChecked: true, isEnabled: false);
        var checkboxTime = me._getCheckbox(text: "Time", isChecked: true, isEnabled: false);
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
    # @param  hash  cfg
    # @return ghost  Label widget
    #
    _getLabel: func(text, cfg = nil) {
        return canvas.gui.widgets.Label.new(me._scrollDataContent, canvas.style, cfg)
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
    # Get widgets.RadioButton
    #
    # @param  string  text  Label text
    # @param  hash|nil  cfg  Config hash or nil
    # @return ghost  widgets.RadioButton
    #
    _getRadioButton: func(text, cfg = nil) {
        return canvas.gui.widgets.RadioButton.new(me._scrollDataContent, canvas.style, cfg)
            .setText(text);
    },

    #
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnSave = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("OK")
            .setFixedSize(65, 26)
            .listen("clicked", func { me._save(); });

        var btnCancel = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText("Cancel")
            .setFixedSize(65, 26)
            .listen("clicked", func { me.hide(); });

        buttonBox.addStretch(1);
        buttonBox.addItem(btnSave);
        buttonBox.addItem(btnCancel);
        buttonBox.addStretch(1);

        me._vbox.addSpacing(10);
        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(10);

        return buttonBox;
    },
};
