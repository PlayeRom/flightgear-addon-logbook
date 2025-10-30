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
# A class to check if there is a new version of an add-on based on releases and
# git tags when the add-on is hosted on GitHub or GitLab.
# See description of VersionChecker class.
#
var GitTagVersionChecker = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [
                GitTagVersionChecker,
                JsonVersionChecker.new(),
            ],
        };

        obj.setUrl(obj._getUrl());
        obj.setDownloadCallback(Callback.new(obj._downloadCallback, obj));

        return obj;
    },

    #
    # Get URL to latest release of the project.
    #
    # @return string|nil
    #
    _getUrl: func {
        var (domain, user, repo) = me.getUserAndRepoNames();

        if (domain == 'github.com') {
            return 'https://api.github.com/repos/' ~ user ~ '/' ~ repo ~ '/releases/latest';
        } elsif (domain == 'gitlab.com') {
            var project = Utils.urlEncode(user ~ '/' ~ repo);
            return 'https://gitlab.com/api/v4/projects/' ~ project ~ '/releases/permalink/latest';
        }

        # TODO: add support for more repos if needed.

        return nil;
    },

    #
    # @param  string  downloadedResource  Downloaded text from HTTP request.
    # @return void
    #
    _downloadCallback: func(downloadedResource) {
        var json = me.parseJson(downloadedResource);
        if (json == nil or !ishash(json)) {
            return;
        }

        # GitHub returns a single object with the latest release, where we find the `tag_name` field.
        if (!contains(json, 'tag_name')) {
            Log.print("GitTagVersionChecker failed, the JSON doesn't contain `tag_name` key.");
            return;
        }

        var strLatestVersion = json['tag_name'];
        if (strLatestVersion == nil) {
            return;
        }

        me.checkVersion(strLatestVersion);
    },
};
