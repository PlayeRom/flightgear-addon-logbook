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

io.include('framework/nasal/App.nas');

#
# Global object of Settings.
#
var g_Settings = nil;

#
# Global object of Sound.
#
var g_Sound = nil;

#
# Global object of Logbook.
#
var g_Logbook = nil;

#
# This flag indicates that a separate thread is running (for loading data) and
# other actions should be temporarily blocked.
#
var g_isThreadPending = false;

#
# Main add-on function.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var main = func(addon) {
    logprint(LOG_INFO, addon.name, ' Add-on initialized from path ', addon.basePath);

    # Create $FG_HOME/Export/Addons/org.flightgear.addons.logbook directory
    addon.createStorageDir();

    Config.excludedFiles = [
        # Framework files I don't use
        '/framework/Canvas/BaseDialogs/TransientDialog.nas',
        '/framework/Utils/Message.nas',
    ];

    if (g_FGVersion.greaterThanOrEqual('2024.1.1')) {
        Config.excludedFiles ~= [
            '/nasal/Storage/CSV/Storage.nas',
            '/nasal/Storage/CSV/Recovery.nas',
            '/nasal/Canvas/CSV/SettingsDialog.nas',
        ];
    } else {
        Config.excludedFiles ~= [
            '/nasal/Storage/SQLite/DB.nas',
            '/nasal/Storage/SQLite/Migrations/MigrationBase.nas',
            '/nasal/Storage/SQLite/Migrations/M2024_10_30_08_44_CreateMigrationsTable.nas',
            '/nasal/Storage/SQLite/Migrations/M2024_10_30_13_01_CreateLogbooksTable.nas',
            '/nasal/Storage/SQLite/Migrations/M2024_11_04_11_53_AddSimTimeColumns.nas',
            '/nasal/Storage/SQLite/Migrations/M2024_11_06_22_42_AddSpeedColumns.nas',
            '/nasal/Storage/SQLite/Migrations/M2024_11_06_22_50_CreateTrackersTable.nas',
            '/nasal/Storage/SQLite/Migration.nas',
            '/nasal/Storage/SQLite/Storage.nas',
            '/nasal/Storage/SQLite/Recovery.nas',
            '/nasal/Storage/SQLite/Exporter.nas',
            '/nasal/Canvas/SQLite/SettingsDialog.nas',
        ];
    }

    App.load(addon, 'logbookAddon');
};

#
# This function is for addon development only. It is called on addon
# reload. The addons system will replace setlistener() and maketimer() to
# track this resources automatically for you.
#
# Listeners created with setlistener() will be removed automatically for you.
# Timers created with maketimer() will have their stop() method called
# automatically for you. You should NOT use settimer anymore, see wiki at
# http://wiki.flightgear.org/Nasal_library#maketimer.28.29
#
# Other resources should be freed by adding the corresponding code here,
# e.g. myCanvas.del();
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var unload = func(addon) {
    App.unload();
};

#
# This class defines a set of callback functions that the framework will invoke
# at specific points during the add-on's lifecycle. Add-on authors implement
# these functions to provide custom behavior, but the framework itself handles
# when and how they are called.
#
# The Hooks object acts purely as a container for these functions. It does not
# implement any framework logic itself — it is the add-on's responsibility to
# provide meaningful implementations.
#
# All of these methods are optional and can be removed entirely from the code
# if they are not needed.
#
var Hooks = {
    #
    # Create non-Canvas objects here.
    #
    onInit: func {
        g_Settings = Settings.new();
        g_Sound    = Sound.new();
    },

    #
    # Create Canvas objects here.
    #
    onInitCanvas: func {
        g_Logbook = Logbook.new();
    },

    #
    # Remove all objects here.
    #
    onUninit: func {
        if (g_Logbook != nil) {
            g_Logbook.del();
        }

        if (g_Sound != nil) {
            g_Sound.del();
        }

        if (g_Settings != nil) {
            g_Settings.del();
        }
    },

    #
    # For the menu with 'name', which is disabled while the Canvas is loading,
    # you can specify here the names of the menu items that should not be enabled
    # automatically, but you can decide in your code when to enable them again,
    # using gui.menuEnable().
    #
    # @return hash  Key as menu name from addon-menubar-items.xml, value whatever.
    #
    excludedMenuNamesForEnabled: func {
        return {
            'logbook-addon-main-dialog':,
            'logbook-addon-export-csv':, # <- this will be enabled only on FG version >= 2024
        };
    },
};
