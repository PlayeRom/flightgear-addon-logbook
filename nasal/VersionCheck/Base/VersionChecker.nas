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
# Base class to check latest version from repository.
#
var VersionChecker = {
    #
    # Static method to get version checker object according to config.
    #
    # @return hash
    #
    make: func {
        if (Config.useVersionCheck.byMetaData) return MetaDataVersionChecker.new();
        if (Config.useVersionCheck.byGitTag)   return GitTagVersionChecker.new();

        # If version checking is disabled, the base class is returned to avoid
        # having to check whether `g_VersionChecker` is set.
        return VersionChecker.new();
    },

    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [
                VersionChecker,
            ],
        };

        # Variables that must be set by the child's class by `setUrl` and `setDownloadCallback` methods:
        obj._url = nil;
        obj._downloadCallback = nil;

        # Variable that the child class must set in the `checkLastVersion` method when it retrieves the resource:
        obj._downloadResource = nil;

        obj._callbacks = std.Vector.new();
        obj._newVersion = nil;

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func {
        me._callbacks.clear();
    },

    #
    # Set URL for download resource.
    #
    # @param  string  url
    # @return void
    #
    setUrl: func(url) {
        me._url = url;
    },

    #
    # Set download callback. This callback will be called after download resource.
    # The resource will be pass as parameter.
    #
    # @param  hash  callback  The Callback object.
    # @return void
    #
    setDownloadCallback: func(callback) {
        me._downloadCallback = callback;
    },

    #
    # Register callback, called when a new version is available.
    # The callback will receive a string with the new version as a parameter.
    #
    # @param  hash  callback  The Callback object.
    # @return void
    #
    registerCallback: func(callback) {
        me._callbacks.append(callback);
    },

    #
    # This is main method to download resource and should be override by child class,
    # which will implement a specific way of downloading a resource.
    #
    # @return void
    #
    checkLastVersion: func {
        Log.warning('VersionChecker.checkLastVersion - version checking is disabled.');
    },

    #
    # Return new version as string or nil id new version is not available.
    #
    # @return string|nil
    #
    getNewVersion: func {
        return me._newVersion;
    },

    #
    # Return true if new version is available.
    #
    # @return bool
    #
    isNewVersion: func {
        return me.getNewVersion() == nil ? false : true;
    },

    #
    # Get repo domain, user and repository name from repository URL.
    # For it to work correctly, the URL must end with /user-name/repo-name, e.g.:
    # https://gitlab.com/user-name/repo-name
    #
    # @param  string|nil  repositoryUrl  If not provided then addons.Addon.codeRepositoryUrl will be used.
    # @return vector  Repository domain, user and repository names or empty strings when failed.
    #
    getUserAndRepoNames: func(repositoryUrl = nil) {
        # remove '/' on the end if exists
        var repoUrl = string.trim(repositoryUrl or g_Addon.codeRepositoryUrl, 1, func(c) c == `/`);

        # remove 'https://' on the front
        if (string.imatch(repoUrl, 'https://*')) {
            repoUrl = substr(repoUrl, 8, size(repoUrl) - 8);
        }

        var parts = split('/', repoUrl);
        if (size(parts) < 3) {
            return ['', '', ''];
        }

        var domain = parts[0];
        var user = '';
        var repo = '';

        if (domain == 'sourceforge.net') {
            if (me._isFgAddonRepo(repositoryUrl)) {
                # Example: https://sourceforge.net/p/flightgear/fgaddon/HEAD/tree/trunk/Addons/Framework
                domain = 'fgaddon'; # Special marker
                repo = parts[-1];   # Last element is a dir name.
            } else {
                # Own hosted project, example:
                # https://sourceforge.net/p/framework/code/ci/HEAD/tree
                #         ^               ^ ^
                #         0               1 2

                repo = string.join('/', parts[2:]); # Start with 2 because we are omitting the domain and 'p' element.
            }
        } else {
            # Examples: https://gitlab.com/user-name/project/repo-name
            #           https://github.com/user-name/repo-name
            user = parts[1];
            repo = string.join('/', parts[2:]); # Repo can have subdirectories
        }

        return [domain, user, repo];
    },

    #
    # Return true if given repo URL it's FGAddon repo on SourceForge.
    #
    # @return bool
    #
    _isFgAddonRepo: func(repoUrl) {
        return string.imatch(repoUrl, '*/p/flightgear/fgaddon/*');
    },

    #
    # Invoke a callback function with the downloaded resource.
    #
    # @return void
    #
    _invokeDownloadCallback: func {
        if (me._downloadCallback != nil) {
            me._downloadCallback.invoke(me._downloadResource);
        }
    },

    #
    # Compare the local version of the add-on with the one passed in the parameter.
    # If the passed version is greater than the local version, then invoke all
    # registered callbacks, passing them a string with the new version.
    #
    # @param  string  strLatestVersion
    # @return bool  Return true if new version is available.
    #
    checkVersion: func(strLatestVersion) {
        Log.print('The latest version found in the repository = ', strLatestVersion);

        var latestVersion = me._getLatestVersion(strLatestVersion);
        if (latestVersion == nil) {
            return false;
        }

        if (latestVersion.lowerThanOrEqual(g_Addon.version)) {
            return false;
        }

        me._newVersion = latestVersion.str();
        Log.alertWarning('New version ', me._newVersion, ' is available');

        # Inform registered callbacks about the new version:
        foreach (var callback; me._callbacks.vector) {
            callback.invoke(me._newVersion);
        }

        return true;
    },

    #
    # Convert string with version to the addons.AddonVersion object.
    #
    # @param  string  strVersion
    # @return ghost|nil  The addons.AddonVersion object or nil if failed.
    #
    _getLatestVersion: func(strVersion) {
        var strVersion = me._removeVPrefix(strVersion);

        var errors = [];
        var version = call(func addons.AddonVersion.new(strVersion), [], errors);

        if (size(errors)) {
            foreach (var error; errors) {
                Log.error(error);
            }

            return nil;
        }

        return version;
    },

    #
    # If string starts with "v", or "v.", remove this prefix.
    #
    # @param  string  strVersion
    # @return string  Version without "v." prefix.
    #
    _removeVPrefix: func(strVersion) {
        strVersion = string.trim(strVersion, -1, func(c) c == `v` or c == `V`);
        return string.trim(strVersion, -1, func(c) c == `.`);
    },
};
