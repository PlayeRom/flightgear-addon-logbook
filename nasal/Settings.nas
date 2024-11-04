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
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [Settings] };

        me._file = g_Addon.storagePath ~ "/" ~ sprintf(Settings.SAVE_FILE, Settings.FILE_VERSION);
        me._propToSave = g_Addon.node.getPath() ~ "/addon-devel/save";
        me._saveNode = props.globals.getNode(me._propToSave); # node object with data to save/load

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
    # Get the options which date and time should be displayed in LogbookDialog
    #
    # @return string
    #
    getDateTimeDisplay: func() {
        var dateTimeDisplay = getprop(me._propToSave ~ "/settings/date-time-display");
        if (dateTimeDisplay == nil
            or (    dateTimeDisplay != Settings.DATE_TIME_REAL
                and dateTimeDisplay != Settings.DATE_TIME_SIM_UTC
                and dateTimeDisplay != Settings.DATE_TIME_SIM_LOC)
        ) {
            return Settings.DATE_TIME_REAL;
        }

        return dateTimeDisplay;
    },

    #
    # @return hash
    #
    getColumnsVisible: func() {
        var columnsVisibleNode = me._saveNode.getNode("settings/columns-visible");

        var columnOptions = [
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
        ];

        var hash = {};

        foreach (var column; columnOptions) {
            hash[column] = columnsVisibleNode.getChild(column).getBoolValue();
        }

        return hash;
    },
};
