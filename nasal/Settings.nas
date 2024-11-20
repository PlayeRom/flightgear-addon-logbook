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
# Settings class to save/load settings to/from XML file
#
var Settings = {
    #
    # Constants
    #
    SAVE_FILE    : "settings.xml",
    #
    # Possible options for date and time display:
    #
    DATE_TIME_REAL   : "real",      # real time from OS
    DATE_TIME_SIM_UTC: "sim-utc",   # UTC time in simulator
    DATE_TIME_SIM_LOC: "sim-local", # local time in simulator
    #
    MIN_LOG_ITEMS : 5,
    MAX_LOG_ITEMS : 20,
    #
    TRACKER_INTERVAL_SEC: 5,

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [Settings] };

        me._file = g_Addon.storagePath ~ "/" ~ Settings.SAVE_FILE;
        me._propToSave = g_Addon.node.getPath() ~ "/addon-devel/save";
        me._saveNode = props.globals.getNode(me._propToSave); # node object with data to save/load

        # Name of columns that can be hidden/shown
        me._columnsVisible = [
            Columns.VARIANT,
            Columns.AC_TYPE,
            Columns.CALLSIGN,
            Columns.FROM,
            Columns.TO,
            Columns.LANDING,
            Columns.CRASH,
            Columns.DAY,
            Columns.NIGHT,
            Columns.INSTRUMENT,
            Columns.MULTIPLAYER,
            Columns.SWIFT,
            Columns.DURATION,
            Columns.DISTANCE,
            Columns.FUEL,
            Columns.MAX_ALT,
            Columns.MAX_GS_KT,
            Columns.MAX_MACH,
        ];

        me._itemsPerPageNode       = props.globals.getNode(me._propToSave ~ "/settings/log-items-per-page");
        me._darkModeNode           = props.globals.getNode(me._propToSave ~ "/settings/dark-style");
        me._realTimeNode           = props.globals.getNode(me._propToSave ~ "/settings/real-time-duration");
        me._isSoundNode            = props.globals.getNode(me._propToSave ~ "/settings/sound-enabled");
        me._dateTimeDisplayNode    = props.globals.getNode(me._propToSave ~ "/settings/date-time-display");
        me._trackerIntervalSecNode = props.globals.getNode(me._propToSave ~ "/settings/tracker-interval-sec");

        me._load();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.save();
    },

    #
    # Load settings properties tree
    #
    # @return void
    #
    _load: func() {
        if (io.read_properties(me._file, me._saveNode) == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - Load settings failed");
        }

        me._validateAllValues();
    },

    #
    # Save settings properties tree
    #
    # @return void
    #
    save: func() {
        if (io.write_properties(me._file, me._saveNode) == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - Save settings failed");
        }
    },

    #
    # Validate all properties and save with correct values ​​if they were incorrect
    #
    # @return void
    #
    _validateAllValues: func() {
        var isDirty = false;

        var value = me.getLogItemsPerPage();
        var validated = me._logItemsValidate(value);
        if (validated != value) {
            me.setLogItemsPerPage(validated);
            isDirty = true;
        }

        value = me.isDarkStyle();
        validated = me._booleanValidate(value, false);
        if (validated != value) {
            me.setDarkMode(validated);
            isDirty = true;
        }

        value = me.isRealTimeDuration();
        validated = me._booleanValidate(value, true);
        if (validated != value) {
            me.setRealTimeDuration(validated);
            isDirty = true;
        }

        value = me.isSoundEnabled();
        validated = me._booleanValidate(value, true);
        if (validated != value) {
            me.setSoundEnabled(validated);
            isDirty = true;
        }

        value = me.getDateTimeDisplay();
        if (!me._isDateTimeDisplayValid(value)) {
            me.setDateTimeDisplay(Settings.DATE_TIME_REAL);
            isDirty = true;
        }

        value = me.getTrackerIntervalSec();
        if (!me._isTrackerIntervalValid(value)) {
            me.setTrackerIntervalSec(Settings.TRACKER_INTERVAL_SEC);
            isDirty = true;
        }

        if (isDirty) {
            # Save to file correct values
            me.save();
        }
    },

    #
    # Get log items per page
    #
    # @return int
    #
    getLogItemsPerPage: func() {
        return me._itemsPerPageNode.getValue();
    },

    #
    # Set log items per page
    #
    # @param  int  value
    # @return void
    #
    setLogItemsPerPage: func(value) {
        setprop(me._propToSave ~ "/settings/log-items-per-page", me._logItemsValidate(value));
    },

    #
    # Validate log items per page
    #
    # @param  int|string|double|nil  value
    # @return int
    #
    _logItemsValidate: func(value) {
        value = int(value);
        if (value == nil or value == "") {
            return Settings.MAX_LOG_ITEMS;
        }
        else if (value < Settings.MIN_LOG_ITEMS) {
            return Settings.MIN_LOG_ITEMS;
        }
        else if (value > Settings.MAX_LOG_ITEMS) {
            return Settings.MAX_LOG_ITEMS;
        }

        return value;
    },

    #
    # @return bool
    #
    isDarkStyle: func() {
        return me._darkModeNode.getBoolValue();
    },

    #
    # @param  bool  value
    # @return void
    #
    setDarkMode: func(value) {
        setprop(me._propToSave ~ "/settings/dark-style", me._booleanValidate(value, false));
    },

    #
    # Validate boolean value
    #
    # @param  int|string|double|nil  value  Value to validate
    # @param  bool  default  Default value if param value is invalid
    # @return bool  Correct value
    #
    _booleanValidate: func(value, default) {
        if (value == true or value == false) {
            return value;
        }

        return default;
    },

    #
    # If true then time spent in flight is always real time, i.e. speeding up or
    # slowing down the simulation time will not affect Duration.
    #
    # @return bool
    #
    isRealTimeDuration: func() {
        return me._realTimeNode.getBoolValue();
    },

    #
    # Enable/disable real time duration
    #
    # @param  bool  value
    # @return void
    #
    setRealTimeDuration: func(value) {
        setprop(me._propToSave ~ "/settings/real-time-duration", me._booleanValidate(value, true));
    },

    #
    # @return bool
    #
    isSoundEnabled: func() {
        return me._isSoundNode.getBoolValue();
    },

    #
    # @param  bool  value
    # @return void
    #
    setSoundEnabled: func(value) {
        setprop(me._propToSave ~ "/settings/sound-enabled", me._booleanValidate(value, true));
    },

    #
    # Get the options which date and time should be displayed in LogbookDialog
    #
    # @return string
    #
    getDateTimeDisplay: func() {
        return me._dateTimeDisplayNode.getValue();
    },

    #
    # @param  string  value
    # @return void
    #
    setDateTimeDisplay: func(value) {
        if (!me._isDateTimeDisplayValid(value)) {
            value = Settings.DATE_TIME_REAL;
        }

        setprop(me._propToSave ~ "/settings/date-time-display", value);
    },

    #
    # @param  string|nil  value
    # @return bool  Return true if given parameter has valid value for date-time-display option
    #
    _isDateTimeDisplayValid: func(value) {
        return value == Settings.DATE_TIME_REAL
            or value == Settings.DATE_TIME_SIM_UTC
            or value == Settings.DATE_TIME_SIM_LOC;
    },

    #
    # @return hash
    #
    getColumnsVisible: func() {
        var columnsVisibleNode = me._saveNode.getNode("settings/columns-visible");

        var hash = {};

        foreach (var column; me._columnsVisible) {
            hash[column] = columnsVisibleNode.getChild(column).getBoolValue();
        }

        return hash;
    },

    #
    # @param  hash  columnsVisible  Column name with visible option { "name1:" true, "name2": false, ... }
    # @return void
    #
    setColumnsVisible: func(columnsVisible) {
        foreach (var columnName; me._columnsVisible) {
            setprop(me._propToSave ~ "/settings/columns-visible/" ~ columnName, columnsVisible[columnName]);
        }
    },

    #
    # Set number of seconds as data recording interval during flight
    #
    # @param  double  value
    # @return void
    #
    setTrackerIntervalSec: func(value) {
        if (!me._isTrackerIntervalValid(value)) {
            value = Settings.TRACKER_INTERVAL_SEC;
        }

        setprop(me._propToSave ~ "/settings/tracker-interval-sec", value);
    },

    #
    # Get number of seconds as data recording interval during flight
    #
    # @return double
    #
    getTrackerIntervalSec: func() {
        return me._trackerIntervalSecNode.getValue();
    },

    #
    # @param  int|string|double|nil  value
    # @return bool  Return true if given value is valid
    #
    _isTrackerIntervalValid: func(value) {
        return value != nil
            and value != ""
            and value > 0.1;
    },
};
