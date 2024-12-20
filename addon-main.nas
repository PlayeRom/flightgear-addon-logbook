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
# Main Nasal function
#
# @param  ghost  addon  addons.Addon object
# @return void
#
var main = func(addon) {
    logprint(LOG_INFO, "Logbook addon initialized from path ", addon.basePath);

    loadExtraNasalFiles(addon);

    # Create $FG_HOME/Export/Addons/org.flightgear.addons.logbook directory
    addon.createStorageDir();

    logbook.init(addon);
};

#
# Load extra Nasal files in main add-on directory
#
# @param  ghost  addon  addons.Addon object
# @return void
#
var loadExtraNasalFiles = func(addon) {
    var modules = [
        "nasal/Utils",
        "nasal/Storage/CSV/MigrationCsv", # <- this file is using also for SQLite version
        "nasal/Canvas/InputDialog",
        "nasal/Canvas/ConfirmationDialog",
        "nasal/Canvas/Dialog",
        "nasal/Canvas/AboutDialog",
        "nasal/Canvas/DetailsDialog",
        "nasal/Canvas/HelpDialog",
        "nasal/Canvas/FlightAnalysisDialog",
        "nasal/Canvas/LogbookDialog",
        "nasal/Canvas/FilterSelector", # Must be after LogbookDialog
        "nasal/Counters/BaseCounter",
        "nasal/Counters/Environment",
        "nasal/Counters/Multiplayer",
        "nasal/Counters/Flight",
        "nasal/Columns",
        "nasal/FlightAnalysis",
        "nasal/Aircraft",
        "nasal/AircraftType",
        "nasal/Airport",
        "nasal/CrashDetector",
        "nasal/FilterData",
        "nasal/Filters",
        "nasal/LandingGear",
        "nasal/LogData",
        "nasal/Logbook",
        "nasal/Settings", # Must be after FlightAnalysis
        "nasal/SpaceShuttle",
        "nasal/Thread",
        "nasal/Sound",
        "Logbook",
    ];

    if (isFG2024Version()) {
        modules = [
            "nasal/Storage/SQLite/DB",
            "nasal/Storage/SQLite/Migrations/MigrationBase",
            "nasal/Storage/SQLite/Migrations/M2024_10_30_08_44_CreateMigrationsTable",
            "nasal/Storage/SQLite/Migrations/M2024_10_30_13_01_CreateLogbooksTable",
            "nasal/Storage/SQLite/Migrations/M2024_11_04_11_53_AddSimTimeColumns",
            "nasal/Storage/SQLite/Migrations/M2024_11_06_22_42_AddSpeedColumns",
            "nasal/Storage/SQLite/Migrations/M2024_11_06_22_50_CreateTrackersTable",
            "nasal/Storage/SQLite/Migration",
            "nasal/Storage/SQLite/Storage",
            "nasal/Storage/SQLite/Recovery",
            "nasal/Storage/SQLite/Exporter",
            "nasal/Canvas/SQLite/SettingsDialog",
        ] ~ modules;
    }
    else {
        # Nasal in 2024.x version is support `true` and `false` keywords but previous FG versions not,
        # so for them add Boolean.nas file
        modules = [
            "Boolean",
            "nasal/Storage/CSV/Storage",
            "nasal/Storage/CSV/Recovery",
            "nasal/Canvas/CSV/SettingsDialog",
        ] ~ modules;
    }

    loadVectorOfModules(addon, modules, "logbook");

    # Add widgets to canvas namespace
    var widgets = [
        "nasal/Canvas/Widgets/ListView",
        "nasal/Canvas/Widgets/MapView",
        "nasal/Canvas/Widgets/ProfileView",
        "nasal/Canvas/Widgets/InfoView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleListView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleMapView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleProfileView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleInfoView",
        "nasal/Canvas/Widgets/Styles/Components/WindBarbs",
        "nasal/Canvas/Widgets/Styles/Components/FlightPathMap",
        "nasal/Canvas/Widgets/Styles/Components/ZoomFractions",
        "nasal/Canvas/Widgets/Styles/Components/PlaneIcon",
        "nasal/Canvas/Widgets/Styles/Components/MapButtons",
    ];

    loadVectorOfModules(addon, widgets, "canvas");
};

#
# @return bool  Return true if running on FG version 2024.x and later
#
var isFG2024Version = func() {
    var fgVersion = getprop("/sim/version/flightgear");
    var (major, minor, patch) = split(".", fgVersion);
    return major >= 2024;
}

#
# @param  ghost  addon  addons.Addon object
# @param  vector  modules
# @param  string  namespace
# @return void
#
var loadVectorOfModules = func(addon, modules, namespace) {
    foreach (var scriptName; modules) {
        var fileName = addon.basePath ~ "/" ~ scriptName ~ ".nas";

        if (!io.load_nasal(fileName, namespace)) {
            logprint(LOG_ALERT, "Logbook Add-on module \"", scriptName, "\" loading failed");
        }
    }
};

#
# This function is for addon development only. It is called on addon reload.
# The addons system will replace setlistener() and maketimer() to track this
# resources automatically for you.
#
# Listeners created with setlistener() will be removed automatically for you.
# Timers created with maketimer() will have their stop() method called
# automatically for you. You should NOT use settimer anymore, see wiki at
# http://wiki.flightgear.org/Nasal_library#maketimer.28.29
#
# Other resources should be freed by adding the corresponding code here,
# e.g. myCanvas.del();
#
# @param  ghost  addon  addons.Addon object
# @return void
#
var unload = func(addon) {
    logprint(LOG_INFO, "Logbook addon unload");
    logbook.uninit();
};
