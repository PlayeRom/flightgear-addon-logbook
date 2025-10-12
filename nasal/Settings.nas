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
# Settings class to set/get settings from property list.
# FlightGear will save them to the autosave.xml file automatically by using userarchive="y" in addon-config.xml file.
#
var Settings = {
    #
    # Constants:
    #
    # Possible options for date and time display:
    DATE_TIME_REAL   : "real",      # real time from OS
    DATE_TIME_SIM_UTC: "sim-utc",   # UTC time in simulator
    DATE_TIME_SIM_LOC: "sim-local", # local time in simulator

    MIN_LOG_ITEMS : 5,
    MAX_LOG_ITEMS : 20,

    TRACKER_INTERVAL_SEC: 0, # Default tracker interval sec, 0 means auto adjustment mode

    MAP_PROVIDER_OSM : 'OpenStreetMap',
    MAP_PROVIDER_TOPO: 'OpenTopoMap',

    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = { parents: [Settings] };

        obj._pathToSettingsProp = g_Addon.node.getPath() ~ "/addon-devel/settings";
        obj._settingsNode = props.globals.getNode(obj._pathToSettingsProp); # node object with data to save/load

        # Name of columns that can be hidden/shown
        obj._columnsVisible = [
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

        obj._itemsPerPageNode       = props.globals.getNode(obj._pathToSettingsProp ~ "/log-items-per-page");
        obj._darkModeNode           = props.globals.getNode(obj._pathToSettingsProp ~ "/dark-style");
        obj._realTimeNode           = props.globals.getNode(obj._pathToSettingsProp ~ "/real-time-duration");
        obj._soundEnabledNode       = props.globals.getNode(obj._pathToSettingsProp ~ "/sound-enabled");
        obj._dateTimeDisplayNode    = props.globals.getNode(obj._pathToSettingsProp ~ "/date-time-display");
        obj._trackerIntervalSecNode = props.globals.getNode(obj._pathToSettingsProp ~ "/tracker-interval-sec");
        obj._mapProviderNode        = props.globals.getNode(obj._pathToSettingsProp ~ "/map-provider");

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        #
    },

    #
    # Get log items per page.
    #
    # @return int
    #
    getLogItemsPerPage: func() {
        return me._itemsPerPageNode.getIntValue();
    },

    #
    # Set log items per page.
    #
    # @param  int  value
    # @return void
    #
    setLogItemsPerPage: func(value) {
        me._itemsPerPageNode.setIntValue(me._logItemsValidate(value));
    },

    #
    # Validate log items per page.
    #
    # @param  int|string|double|nil  value
    # @return int
    #
    _logItemsValidate: func(value) {
        value = int(value);

           if (value == nil or value == "")    return Settings.MAX_LOG_ITEMS;
        elsif (value < Settings.MIN_LOG_ITEMS) return Settings.MIN_LOG_ITEMS;
        elsif (value > Settings.MAX_LOG_ITEMS) return Settings.MAX_LOG_ITEMS;

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
        me._darkModeNode.setBoolValue(me._booleanValidate(value, false));
    },

    #
    # Validate boolean value.
    #
    # @param  int|string|double|nil  value  Value to validate
    # @param  bool  default  Default value if param value is invalid
    # @return bool  Correct value
    #
    _booleanValidate: func(value, default) {
        if (isscalar(value) and (value == true or value == false)) {
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
        me._realTimeNode.setBoolValue(me._booleanValidate(value, true));
    },

    #
    # @return bool
    #
    isSoundEnabled: func() {
        return me._soundEnabledNode.getBoolValue();
    },

    #
    # @param  bool  value
    # @return void
    #
    setSoundEnabled: func(value) {
        value = me._booleanValidate(value, true);
        # For some unknown reason, in this case I can't use setBoolValue, where I directly pass the value, I just need
        # to convert it to 1 or 0. Why? setprop works without the need to pass it to 1 or 0.
        # me._soundEnabledNode.setBoolValue(value ? 1 : 0);
        me._soundEnabledNode.setBoolValue(value ? 1 : 0);
        # setprop(me._pathToSettingsProp ~ "/sound-enabled", me._booleanValidate(value, true));
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

        me._dateTimeDisplayNode.setValue(value);
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
        var columnsVisibleNode = me._settingsNode.getNode("columns-visible");

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
            setprop(me._pathToSettingsProp ~ "/columns-visible/" ~ columnName, columnsVisible[columnName]);
        }
    },

    #
    # Get number of seconds as data recording interval during flight
    #
    # @return double
    #
    getTrackerIntervalSec: func() {
        return me._trackerIntervalSecNode.getDoubleValue();
    },

    #
    # Set number of seconds as data recording interval during flight.
    #
    # @param  double  value
    # @return void
    #
    setTrackerIntervalSec: func(value) {
        if (!me._isTrackerIntervalValid(value)) {
            value = Settings.TRACKER_INTERVAL_SEC;
        }

        me._trackerIntervalSecNode.setDoubleValue(value);
    },

    #
    # Validate tracker-interval-sec option.
    #
    # @param  int|string|double|nil  value
    # @return bool  Return true if given value is valid
    #
    _isTrackerIntervalValid: func(value) {
        return value != nil
            and value != ""
            and num(value) >= FlightAnalysis.INTERVAL_AUTO_THRESHOLD;
    },

    #
    # Get map provider name.
    #
    # @return string
    #
    getMapProvider: func() {
        return me._mapProviderNode.getValue();
    },

    #
    # Set map provider name.
    #
    # @param  string  name
    # @return void
    #
    setMapProvider: func(name) {
        if (!me._isMapProviderValid(name)) {
            name = Settings.MAP_PROVIDER_OSM;
        }

        me._mapProviderNode.setValue(name);
    },

    #
    # Validate map provider option.
    #
    # @param  string  name
    # @return bool
    #
    _isMapProviderValid: func(name) {
        return name == Settings.MAP_PROVIDER_OSM
            or name == Settings.MAP_PROVIDER_TOPO;
    },
};
