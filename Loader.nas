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

        # List of files that should not be loaded.
        me._excluded = std.Hash.new({
            "/addon-main.nas":,
            "/Loader.nas":,
        });

        if (me._isFG2024Version()) {
            me._excluded.set("/Boolean.nas", nil);
            me._excluded.set("/nasal/Storage/CSV/Storage.nas", nil);
            me._excluded.set("/nasal/Storage/CSV/Recovery.nas", nil);
            me._excluded.set("/nasal/Canvas/CSV/SettingsDialog.nas", nil);
        } else {
            me._excluded.set("/nasal/Storage/SQLite/DB.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Migrations/MigrationBase.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Migrations/M2024_10_30_08_44_CreateMigrationsTable.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Migrations/M2024_10_30_13_01_CreateLogbooksTable.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Migrations/M2024_11_04_11_53_AddSimTimeColumns.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Migrations/M2024_11_06_22_42_AddSpeedColumns.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Migrations/M2024_11_06_22_50_CreateTrackersTable.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Migration.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Storage.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Recovery.nas", nil);
            me._excluded.set("/nasal/Storage/SQLite/Exporter.nas", nil);
            me._excluded.set("/nasal/Canvas/SQLite/SettingsDialog.nas", nil);
        }

        me._fullPath = os.path.new();

        return me;
    },

    #
    # Search for ".nas" files recursively and load them.
    #
    # @param  string  path  Starts as base absolute path of add-on.
    # @param  string  namespace  Namespace of add-on.
    # @param  int  level  Starts from 0, each subsequent subdirectory gets level + 1.
    # @param  string  relPath  Relative path to the add-on's root directory.
    # @return void
    #
    load: func(path, namespace, level = 0, relPath = "") {
        var entries = globals.directory(path);

        foreach (var entry; entries) {
            if (entry == "." or entry == "..") {
                continue;
            }

            var fullRelPath = relPath ~ "/" ~ entry;
            if (me._excluded.contains(fullRelPath)) {
                logprint(LOG_WARN, level, ". ", namespace, " excluded -> ", fullRelPath);
                continue;
            }

            me._fullPath.set(path);
            me._fullPath.append(entry);

            if (me._fullPath.isFile() and me._fullPath.lower_extension == "nas") {
                logprint(LOG_WARN, level, ". ", namespace, " -> ", me._fullPath.realpath);
                io.load_nasal(me._fullPath.realpath, namespace);
                continue;
            }

            if (level == 0 and !string.imatch(entry, "nasal")) {
                # At level 0 we are only interested in the "nasal" directory.
                continue;
            }

            if (!me._fullPath.isDir()) {
                continue;
            }

            if (me._isDirInPath("Widgets")) {
                me.load(me._fullPath.realpath, "canvas",  level + 1, fullRelPath);
            } else {
                me.load(me._fullPath.realpath, namespace, level + 1, fullRelPath);
            }
        }
    },

    #
    # Returns true if expectedDirName is the last part of the me._fullPath,
    # or if expectedDirName is contained in the current path.
    #
    # @param  string  expectedDirName  The expected directory name, which means the namespace should change.
    # @return bool
    #
    _isDirInPath: func(expectedDirName) {
        return string.imatch(me._fullPath.file, expectedDirName)
            or string.imatch(me._fullPath.realpath, me._addon.basePath ~ "/*/" ~ expectedDirName ~ "/*");
    },

    #
    # @return bool  Return true if running on FG version 2024.x and later
    #
    _isFG2024Version: func() {
        var fgVersion = getprop("/sim/version/flightgear");
        var (major, minor, patch) = globals.split(".", fgVersion);
        return major >= 2024;
    },
};
