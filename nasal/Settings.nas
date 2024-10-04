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
    # @param hash addon - addons.Addon object
    # @return me
    #
    new: func(addon) {
        var me = { parents: [Settings] };

        me.file = addon.storagePath ~ "/" ~ sprintf(Settings.SAVE_FILE, Settings.FILE_VERSION);
        me.propToSave = addon.node.getPath() ~ "/addon-devel/save";

        me.load();

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
        return props.globals.getNode(me.propToSave);
    },

    #
    # Load settings properties tree
    #
    # @return void
    #
    load: func() {
        if (io.read_properties(me.file, me.getSaveNode()) == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - Load settings failed");
        }
    },

    #
    # Save settings properties tree
    #
    # @return void
    #
    save: func() {
        if (io.write_properties(me.file, me.getSaveNode()) == nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - Save settings failed");
        }
    },

    #
    # @return bool
    #
    isDarkStyle: func() {
        return getprop(me.propToSave ~ "/settings/dark-style") or false;
    },

    #
    # @param bool value
    # @return void
    #
    setDarkMode: func(value) {
        setprop(me.propToSave ~ "/settings/dark-style", value);
    },

    #
    # @return bool
    #
    isRealTimeDuration: func() {
        var isRealTimeDuration = getprop(me.propToSave ~ "/settings/real-time-duration");
        if (isRealTimeDuration == nil) {
            return true;
        }

        return isRealTimeDuration;
    },

    #
    # @return bool
    #
    isSoundEnabled: func() {
        var isSoundEnabled = getprop(me.propToSave ~ "/settings/sound-enabled");
        if (isSoundEnabled == nil) {
            return true;
        }

        return isSoundEnabled;
    },
};
