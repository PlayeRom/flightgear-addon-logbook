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
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [Settings] };

        me._file = g_Addon.storagePath ~ "/" ~ sprintf(Settings.SAVE_FILE, Settings.FILE_VERSION);
        me._propToSave = g_Addon.node.getPath() ~ "/addon-devel/save";

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
    # @return hash - node object with data to save/load
    #
    getSaveNode: func() {
        return props.globals.getNode(me._propToSave);
    },

    #
    # Load settings properties tree
    #
    # @return void
    #
    _load: func() {
        if (io.read_properties(me._file, me.getSaveNode()) == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - Load settings failed");
        }
    },

    #
    # Save settings properties tree
    #
    # @return void
    #
    save: func() {
        if (io.write_properties(me._file, me.getSaveNode()) == nil) {
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
    # @param bool value
    # @return void
    #
    setDarkMode: func(value) {
        setprop(me._propToSave ~ "/settings/dark-style", value);
    },

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
};
