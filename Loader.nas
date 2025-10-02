#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# A class for automatically loading Nasal files.
#
var Loader = {
    #
    # Constructor.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @return hash
    #
    new: func(addon) {
        var me = {
            parents: [Loader],
            _addon: addon,
        };

        return me;
    },

    #
    # Search for ".nas" files recursively and load them.
    #
    # @param  string  path  Starts as base path of add-on.
    # @param  string  namespace  Namespace of add-on.
    # @return void
    #
    load: func(path, namespace) {
        var modules = [
            "nasal/Utils/Dev/DevEnv",
            "nasal/Utils/Dev/DevReloadMenu",
            "nasal/Utils/Dev/DevReloadMultiKey",
            "nasal/Utils/Callback",
            "nasal/Utils/Listeners",
            "nasal/Utils/Log",
            "nasal/Utils/Profiler",
            "nasal/Utils/Thread",
            "nasal/Utils/Timer",
            "nasal/Utils/Utils",

            "nasal/Storage/CSV/MigrationCsv", # <- this file is using also for SQLite version

            "nasal/Canvas/BaseDialogs/Dialog",
            "nasal/Canvas/BaseDialogs/PersistentDialog",
            "nasal/Canvas/BaseDialogs/StylePersistentDialog",
            "nasal/Canvas/ScrollAreaHelper",
            "nasal/Canvas/InputDialog",
            "nasal/Canvas/ConfirmationDialog",
            "nasal/Canvas/AboutDialog",
            "nasal/Canvas/DetailsDialog",
            "nasal/Canvas/HelpDialog",
            "nasal/Canvas/FlightAnalysisDialog",
            "nasal/Canvas/LogbookDialog",
            "nasal/Canvas/FilterSelector",

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
            "nasal/Settings",
            "nasal/SpaceShuttle",
            "nasal/Sound",
            "nasal/Bootstrap",
        ];

        if (me._isFG2024Version()) {
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

        # Add widgets to "canvas" namespace
        var widgets = [
            "nasal/Canvas/Widgets/FlightInfo",
            "nasal/Canvas/Widgets/FlightMap",
            "nasal/Canvas/Widgets/FlightProfile",
            "nasal/Canvas/Widgets/LogbookList",

            "nasal/Canvas/Widgets/Styles/FlightInfoView",
            "nasal/Canvas/Widgets/Styles/FlightMapView",
            "nasal/Canvas/Widgets/Styles/FlightProfileView",
            "nasal/Canvas/Widgets/Styles/LogbookListView",

            "nasal/Canvas/Widgets/Styles/Components/WindBarbs",
            "nasal/Canvas/Widgets/Styles/Components/FlightPathMap",
            "nasal/Canvas/Widgets/Styles/Components/ZoomFractions",
            "nasal/Canvas/Widgets/Styles/Components/PlaneIcon",
            "nasal/Canvas/Widgets/Styles/Components/MapButtons",
        ];

        me._loadVectorOfModules(path, modules, namespace);
        me._loadVectorOfModules(path, widgets, "canvas");
    },

    #
    # @return bool  Return true if running on FG version 2024.x and later
    #
    _isFG2024Version: func() {
        var fgVersion = getprop("/sim/version/flightgear");
        var (major, minor, patch) = globals.split(".", fgVersion);
        return major >= 2024;
    },

    #
    # Load given array of Nasal files to given namespace.
    #
    # @param  string  path  Base path of add-on.
    # @param  vector  files
    # @param  string  namespace
    # @return void
    #
    _loadVectorOfModules: func(path, files, namespace) {
        foreach (var file; files) {
            var fullFileName = path ~ "/" ~ file ~ ".nas";

            io.load_nasal(fullFileName, namespace);
        }
    },
};
