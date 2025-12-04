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

        obj._dateTimeDisplay = g_Settings.getDateTimeDisplay();
        obj._soundOption     = g_Settings.isSoundEnabled();
        obj._logItemsPerPage = g_Settings.getLogItemsPerPage();
        obj._mapProvider     = g_Settings.getMapProvider();
        obj._columnsVisible  = {};
        obj._loadColumnsVisible();

        obj._checkboxReal         = nil;
        obj._checkboxSimUtc       = nil;
        obj._checkboxSimLocal     = nil;
        obj._lineEditItemsPerPage = nil;
        obj._columnCheckBoxes     = {};
        obj._hBoxLayout           = nil;

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

        me._dateTimeDisplay = g_Settings.getDateTimeDisplay();
        me._soundOption     = g_Settings.isSoundEnabled();
        me._logItemsPerPage = g_Settings.getLogItemsPerPage();
        me._mapProvider     = g_Settings.getMapProvider();
        me._loadColumnsVisible();

        me._drawContent();

        call(PersistentDialog.show, [], me);
    },

    #
    # Load visibility option from columns to settings dialog memory
    #
    # @return void
    #
    _loadColumnsVisible: func {
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
    _save: func {
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
        me._hBoxLayout = canvas.HBoxLayout.new();

        var vBoxLayout = canvas.VBoxLayout.new();
        me._drawDateTimeOptions(vBoxLayout);
        me._drawFlightAnalysisOptions(vBoxLayout);
        me._drawMiscellaneousOptions(vBoxLayout);
        vBoxLayout.addStretch(1);

        me._hBoxLayout.addItem(vBoxLayout);
        me._hBoxLayout.addSpacing(30);
        me._hBoxLayout.addItem(me._drawColumnsVisible());

        me._scrollArea.setLayout(me._hBoxLayout);
    },

    #
    # Draw options for date & time
    #
    # @param  ghost  vBoxLayout  canvas.VBoxLayout
    # @return ghost  canvas.VBoxLayout
    #
    _drawDateTimeOptions: func(vBoxLayout) {
        vBoxLayout.addItem(me._widgetScroll.getLabel("Date and time displayed\nin the Logbook view", true));
        vBoxLayout.addSpacing(10);

        var radio1 = me._widgetScroll.getRadioButton("Real date & time (from your OS)")
            .setChecked(me._dateTimeDisplay == Settings.DATE_TIME_REAL);

        var radio2 = me._widgetScroll.getRadioButton("UTC time in simulator", radio1)
            .setChecked(me._dateTimeDisplay == Settings.DATE_TIME_SIM_UTC);

        var radio3 = me._widgetScroll.getRadioButton("Local time in simulator", radio1)
            .setChecked(me._dateTimeDisplay == Settings.DATE_TIME_SIM_LOC);

        radio1.listen("group-checked-radio-changed", func(e) {
            var radioGroup = radio1.getRadioButtonsGroup();

            # In the dev version of the FG, the getCheckedRadio() method has been changed to getCheckedRadioButton().
            # TODO: Remove the check and only use getCheckedRadioButton when version 2024 becomes obsolete.
            var checkedRadio = Utils.tryCatch(func typeof(radioGroup.getCheckedRadioButton), [])
                ? radioGroup.getCheckedRadioButton()
                : radioGroup.getCheckedRadio();

            var getDateTimeDisplay = func(item) {
                if (item != nil) {
                    if (item._text == "UTC time in simulator")   return Settings.DATE_TIME_SIM_UTC;
                    if (item._text == "Local time in simulator") return Settings.DATE_TIME_SIM_LOC;
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
        vBoxLayout.addItem(me._widgetScroll.getLabel("Flight Analysis Options"));
        vBoxLayout.addItem(me._drawMapProvider());

        return vBoxLayout;
    },

    #
    # Draw Map Provider combo box
    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawMapProvider: func {
        var hBoxLayout = canvas.HBoxLayout.new();

        hBoxLayout.addItem(me._widgetScroll.getLabel("Map provider"));

        var items = [
            { label: "OpenStreetMap", value: "OpenStreetMap" },
            { label: "OpenTopoMap",   value: "OpenTopoMap" },
        ];

        var comboBox = ComboBoxHelper.create(me._scrollContent, items);
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
        vBoxLayout.addItem(me._widgetScroll.getLabel("Miscellaneous Options"));

        var checkboxSound = me._widgetScroll.getCheckBox("Click sound", me._soundOption, func(e) {
            me._soundOption = e.detail.checked ? true : false;
        });

        vBoxLayout.addItem(checkboxSound);

        vBoxLayout.addItem(me._drawLogItemsPerPage());

        vBoxLayout.addItem(me._widgetScroll.getLabel(
            'The "Optimize database" button will defragment the database file, '
            'which will speed up database operations and reduce its size on the disk.',
            true,
        ));

        var btnVacuum = me._widgetScroll.getButton("Optimize database", 150, func {
            if (!g_isThreadPending) {
                if (me._logbook.vacuumSQLite()) {
                    gui.popupTip("The database has been optimized");
                }
            }
        });

        vBoxLayout.addSpacing(20);
        vBoxLayout.addItem(btnVacuum);

        return vBoxLayout;
    },

    #
    # Draw Items per page option
    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawLogItemsPerPage: func {
        var items = [
            { label:  "5", value:  5 },
            { label: "10", value: 10 },
            { label: "15", value: 15 },
            { label: "20", value: 20 },
        ];

        var comboBox = ComboBoxHelper.create(me._scrollContent, items);
        comboBox.setSelectedByValue(g_Settings.getLogItemsPerPage());
        comboBox.listen("selected-item-changed", func(e) {
            me._logItemsPerPage = e.detail.value;
        });

        var hBoxLayout = canvas.HBoxLayout.new();
        hBoxLayout.addItem(me._widgetScroll.getLabel("Items per page"));
        hBoxLayout.addItem(comboBox);
        hBoxLayout.addStretch(1); # Decrease combo width

        return hBoxLayout;
    },

    #
    # Draw column visibility options
    #
    # @return ghost  canvas.VBoxLayout
    #
    _drawColumnsVisible: func {
        var vBoxLayout = canvas.VBoxLayout.new();

        vBoxLayout.addItem(me._widgetScroll.getLabel("Columns to display in the Logbook view", true));
        vBoxLayout.addSpacing(10);

        var checkboxDate = me._widgetScroll.getCheckBox("Date", true).setEnabled(false);
        var checkboxTime = me._widgetScroll.getCheckBox("Time", true).setEnabled(false);
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

            var checkbox = me._widgetScroll.getCheckBox(columnItem.header, isChecked)
                .setEnabled(!isDisabled);

            if (!isDisabled) {
                func {
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
