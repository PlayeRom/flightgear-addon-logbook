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

io.include('framework/nasal/Application.nas');

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

    Config.useVersionCheck.byGitTag = true;

    Application
        .hookFilesExcludedFromLoading(func {
            var excluded = [
                # Framework files I don't use
                '/framework/Canvas/BaseDialogs/TransientDialog.nas',
                '/framework/Utils/Message.nas',
            ];

            if (g_FGVersion.greaterThanOrEqual('2024.1.1')) {
                return excluded ~ [
                    '/nasal/Storage/CSV/Storage.nas',
                    '/nasal/Storage/CSV/Recovery.nas',
                    '/nasal/Canvas/CSV/SettingsDialog.nas',
                ];
            }

            return excluded ~ [
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
        })
        .hookOnInit(func {
            g_Settings = Settings.new();
            g_Sound    = Sound.new();
        })
        .hookOnInitCanvas(func {
            g_Logbook = Logbook.new();
        })
        .hookExcludedMenuNamesForEnabled(func {
            return {
                'logbook-addon-main-dialog':,
                'logbook-addon-export-csv':, # <- this will be enabled only on FG version >= 2024
            };
        })
        .create(addon, 'logbookAddon');
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
    Log.print('unload');
    Application.unload();

    if (g_Logbook != nil) {
        g_Logbook.del();
    }

    if (g_Sound != nil) {
        g_Sound.del();
    }

    if (g_Settings != nil) {
        g_Settings.del();
    }
};
