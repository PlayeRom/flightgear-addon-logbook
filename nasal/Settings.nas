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
    SAVE_FILE    : "settings-v%s.xml",
    FILE_VERSION : "1.0.1",
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
    TRACKER_INTERVAL_SEC: 20,

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [Settings] };

        me._file = g_Addon.storagePath ~ "/" ~ sprintf(Settings.SAVE_FILE, Settings.FILE_VERSION);
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
    # Get log items per page
    #
    # @return int
    #
    getLogItemsPerPage: func() {
        var value = getprop(me._propToSave ~ "/settings/log-items-per-page") or Settings.MAX_LOG_ITEMS;
        return me._logItemsValidate(value);
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
    # @param  int|string|nil  value
    # @return int
    #
    _logItemsValidate: func(value) {
        value = int(value);
        if (value == nil) {
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
        return getprop(me._propToSave ~ "/settings/dark-style") or false;
    },

    #
    # @param  bool  value
    # @return void
    #
    setDarkMode: func(value) {
        setprop(me._propToSave ~ "/settings/dark-style", value);
    },

    #
    # If true then time spent in flight is always real time, i.e. speeding up or
    # slowing down the simulation time will not affect Duration.
    #
    # @return bool
    #
    isRealTimeDuration: func() {
        var isRealTimeDuration = getprop(me._propToSave ~ "/settings/real-time-duration");
        if (isRealTimeDuration == nil) {
            return true;
        }

        return isRealTimeDuration;
    },

    #
    # @return bool
    #
    isSoundEnabled: func() {
        var isSoundEnabled = getprop(me._propToSave ~ "/settings/sound-enabled");
        if (isSoundEnabled == nil) {
            return true;
        }

        return isSoundEnabled;
    },

    #
    # @param  bool  value
    # @return void
    #
    setSoundEnabled: func(value) {
        setprop(me._propToSave ~ "/settings/sound-enabled", value);
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
    # Get the options which date and time should be displayed in LogbookDialog
    #
    # @return string
    #
    getDateTimeDisplay: func() {
        var value = getprop(me._propToSave ~ "/settings/date-time-display");

        if (!me._isDateTimeDisplayValid(value)) {
            return Settings.DATE_TIME_REAL;
        }

        return value;
    },

    #
    # @param  string  value
    # @return void
    #
    setDateTimeDisplay: func(value) {
        if (!me._isDateTimeDisplayValid(value)) {
            logprint(LOG_ALERT, "Incorrect value for settings/date-time-display = ", value);
            return;
        }

        setprop(me._propToSave ~ "/settings/date-time-display", value);
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
    # Get number of seconds as data recording interval during flight
    #
    # @return int
    #
    getTrackerIntervalSec: func() {
        var value = getprop(me._propToSave ~ "/settings/tracker-interval-sec");

        if (value == nil or value == "") {
            return Settings.TRACKER_INTERVAL_SEC;
        }

        return value;
    },
};
