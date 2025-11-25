#
# Framework Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# A class for automatically loading Nasal files.
#
var AutoLoader = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [AutoLoader],
        };

        obj._frameworkDir = obj._getFrameworkSubDir();
        obj._subDir = obj._frameworkDir;
        if (obj._subDir != '') {
            obj._subDir = '/' ~ obj._subDir;
        }

        # List of files that should not be loaded.
        obj._excluded = std.Hash.new();

        obj._excludedPermanent();
        obj._excludedByConfig();
        obj._excludedByHookFunc();

        obj._fullPath = os.path.new();

        return obj;
    },

    #
    # Search for '.nas' files recursively and load them.
    #
    # @param  string  path  Starts as base absolute path of add-on.
    # @param  string  namespace  Namespace of add-on.
    # @param  int  level  Starts from 0, each subsequent subdirectory gets level + 1.
    # @param  string  relPath  Relative path to the add-on's root directory.
    # @return void
    #
    load: func(path, namespace, level = 0, relPath = '') {
        var entries = directory(path);

        foreach (var entry; entries) {
            if (entry == '.' or entry == '..') {
                continue;
            }

            var fullRelPath = relPath ~ '/' ~ entry;
            if (me._excluded.contains(fullRelPath)) {
                Log.warning('AutoLoader excluded - level: ', level, '. namespace: ', namespace, ' -> ', fullRelPath);
                continue;
            }

            me._fullPath.set(path);
            me._fullPath.append(entry);

            if (me._fullPath.isFile() and me._fullPath.lower_extension == 'nas') {
                if (io.load_nasal(me._fullPath.realpath, namespace)) {
                    Log.success('AutoLoader loaded   - level: ', level, '. namespace: ', namespace, ' -> ', fullRelPath);
                }
                continue;
            }

            if (level == 0
                and !(
                       string.imatch(entry, 'nasal')
                    or string.imatch(entry, me._frameworkDir)
                )
            ) {
                # At level 0 we are only interested in the 'nasal' and 'framework/nasal' directories.
                continue;
            }

            if (!me._fullPath.isDir()) {
                continue;
            }

            me.load(me._fullPath.realpath, me._getNamespace(namespace), level + 1, fullRelPath);
        }
    },

    #
    # Get namespace for load new directory.
    #
    # @param  string  currentNamespace
    # @return string
    #
    _getNamespace: func(currentNamespace) {
        return me._isDirInPath('Widgets')
            ? 'canvas'
            : currentNamespace;
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
            or string.imatch(me._fullPath.realpath, g_Addon.basePath ~ '/*/' ~ expectedDirName ~ '/*');
    },

    #
    # Return `framework` dir if Framework is located inside `/framework`,
    # which means it is used by a specific add-on and not the Framework itself.
    # If the launch is from the Framework itself, it returns an empty string.
    #
    # @return string
    #
    _getFrameworkSubDir: func {
        var path = caller(0)[2];

        path = substr(path, size(g_Addon.basePath) + 1); # +1 for skip `/`
        # Now a path = 'framework/nasal/AutoLoader.nas' or 'nasal/AutoLoader.nas'

        var parts = split('/', path);
        if (size(parts) >= 3) {
            return parts[0];
        }

        return '';
    },

    #
    # Files that must always be excluded from automatic loading, either because
    # FlightGear loads them or because they are loaded via io.include().
    #
    # @return void
    #
    _excludedPermanent: func {
        var excludedFiles = [
            '/addon-main.nas',
            me._subDir ~ '/addon-main.nas', # It may repeat, but it doesn't matter, it will be there once in the hash
            me._subDir ~ '/nasal/Application.nas',        # Included in addon-main.nas
            me._subDir ~ '/nasal/AutoLoader.nas',         # Included in Application.nas
            me._subDir ~ '/nasal/Boolean.nas',            # Included in Application.nas
            me._subDir ~ '/nasal/Config.nas',             # Included in Application.nas
            me._subDir ~ '/nasal/Dev/DevMode.nas',        # Included in Application.nas
            me._subDir ~ '/nasal/Dev/DevEnv.nas',         # Included in DevMode.nas if needed
            me._subDir ~ '/nasal/Dev/DevMultiKeyCmd.nas', # Included in DevMode.nas if needed
            me._subDir ~ '/nasal/Dev/DevReloadMenu.nas',  # Included in DevMode.nas if needed
            me._subDir ~ '/nasal/Dev/Log.nas',            # Included in DevMode.nas
            me._subDir ~ '/nasal/Utils/FGVersion.nas',    # Included in Application.nas
        ];

        foreach (var file; excludedFiles) {
            me._excluded.set(file, nil);
        }
    },

    #
    # @return void
    #
    _excludedByConfig: func {
        var files = [];

        if (!Config.useVersionCheck.byGitTag) {
            files ~= [
                me._subDir ~ '/nasal/VersionCheck/GitTagVersionChecker.nas',
                me._subDir ~ '/nasal/VersionCheck/Base/JsonVersionChecker.nas',
            ];
        }

        if (!Config.useVersionCheck.byMetaData) {
            files ~= [
                me._subDir ~ '/nasal/VersionCheck/MetaDataVersionChecker.nas',
                me._subDir ~ '/nasal/VersionCheck/Base/XmlVersionChecker.nas',
            ];
        }

        foreach (var file; files) {
            me._excluded.set(file, nil);
        }
    },

    #
    # @return void
    #
    _excludedByHookFunc: func {
        var excludedFiles = Application.callHook('filesExcludedFromLoading', []);

        if (isvec(excludedFiles)) {
            foreach (var file; excludedFiles) {
                me._excluded.set(file, nil);
            }
        }
    },
};
