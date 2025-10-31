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
var Loader = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [Loader],
        };

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
                logprint(LOG_WARN, 'Level: ', level, '. namespace: ', namespace, ' excluded -> ', fullRelPath);
                continue;
            }

            me._fullPath.set(path);
            me._fullPath.append(entry);

            if (me._fullPath.isFile() and me._fullPath.lower_extension == 'nas') {
                logprint(LOG_WARN, 'Level: ', level, '. namespace: ', namespace, ' -> ', fullRelPath);
                io.load_nasal(me._fullPath.realpath, namespace);
                continue;
            }

            if (level == 0 and !(
                       string.imatch(entry, 'nasal')
                    or string.imatch(entry, 'framework')
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
    # Files that must always be excluded from automatic loading, either because
    # FlightGear loads them or because they are loaded via io.include().
    #
    # @return void
    #
    _excludedPermanent: func {
        var excludedFiles = [
            '/addon-main.nas',
            '/nasal/Loader.nas',
            '/nasal/Config.nas',
            '/nasal/App.nas',
            '/nasal/Boolean.nas',
            '/nasal/Utils/FGVersion.nas',
        ];

        foreach (var file; excludedFiles) {
            me._addToExcluded(file);
        }
    },

    #
    # @return void
    #
    _excludedByConfig: func {
        var files = [];

        if (!Config.dev.useEnvFile) {
            files ~= [
                '/nasal/Dev/DevEnv.nas',
                '/nasal/Dev/DevReloadMenu.nas',
                '/nasal/Dev/DevReloadMultiKey.nas',
            ];
        }

        if (!Config.useVersionCheck.byGitTag) {
            files ~= [
                '/nasal/VersionCheck/GitTagVersionChecker.nas',
                '/nasal/VersionCheck/Base/JsonVersionChecker.nas',
            ];
        }

        if (!Config.useVersionCheck.byMetaData) {
            files ~= [
                '/nasal/VersionCheck/MetaDataVersionChecker.nas',
                '/nasal/VersionCheck/Base/XmlVersionChecker.nas',
            ];
        }

        foreach (var file; files) {
            me._addToExcluded(file);
        }

        if (isvec(Config.excludedFiles)) {
            foreach (var file; Config.excludedFiles) {
                me._excluded.set(file, nil);
            }
        }
    },

    #
    # @return void
    #
    _excludedByHookFunc: func {
        if (!g_isHook('filesExcludedFromLoading')) {
            return;
        }

        var excludedFiles = Hooks.filesExcludedFromLoading();

        if (isvec(excludedFiles)) {
            foreach (var file; excludedFiles) {
                obj._excluded.set(file, nil);
            }
        }
    },

    #
    # Add the file to the excluded list but twice, from the framework's perspective (default),
    # and from the perspective of the actual project using the framework.
    #
    # @param  string  file
    # @return void
    #
    _addToExcluded: func(file) {
        # From the framework's perspective:
        me._excluded.set(file, nil);

        # From the perspective of the project using the framework:
        me._excluded.set('/framework' ~ file, nil);
    },
};
