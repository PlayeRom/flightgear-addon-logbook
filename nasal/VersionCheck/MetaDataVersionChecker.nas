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
# This class will execute an HTTP request to download the addon-metadata.xml
# file from the repository. This way, you can read the version entered there and
# compare it with the local addon's version.
#
var MetaDataVersionChecker = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [
                MetaDataVersionChecker,
                XmlVersionChecker.new(),
            ],
        };

        obj.setUrl(obj._getUrl());
        obj.setDownloadCallback(Callback.new(obj._downloadCallback, obj));

        return obj;
    },

    #
    # Get URL to addon-metadata.xml file in your repository.
    #
    # @return string|nil
    #
    _getUrl: func {
        var (domain, user, repo) = me.getUserAndRepoNames();

        if (domain == 'github.com')      return 'https://raw.githubusercontent.com/' ~ user ~ '/' ~ repo ~ '/HEAD/addon-metadata.xml';
        if (domain == 'gitlab.com')      return 'https://gitlab.com/' ~ user ~ '/' ~ repo ~ '/-/raw/HEAD/addon-metadata.xml';
        if (domain == 'sourceforge.net') return 'https://sourceforge.net/p/' ~ repo ~ '/addon-metadata.xml?format=raw';
        if (domain == 'fgaddon')         return 'https://sourceforge.net/p/flightgear/fgaddon/HEAD/tree/trunk/Addons/' ~ repo ~ '/addon-metadata.xml?format=raw';

        # TODO: add support for more repos if needed.

        return nil;
    },

    #
    # @param  ghost  downloadedResource  Downloaded props.Node for HTTP request.
    # @return void
    #
    _downloadCallback: func(downloadedResource) {
        var addonNode = downloadedResource.getChild('addon');
        if (addonNode == nil) {
            return;
        }

        var versionNode = addonNode.getChild('version');
        if (versionNode == nil) {
            return;
        }

        var strLatestVersion = versionNode.getValue();
        if (strLatestVersion == nil) {
            return;
        }

        me.checkVersion(strLatestVersion);
    },
};
