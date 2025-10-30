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
# This class inherits from VersionChecker and implements an HTTP request to
# retrieve the content of XMl file with FlightGear's PropertyList. The retrieved
# resource is converted to props.Node and then passed to the base class for
# further processing.
#
var XmlVersionChecker = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [
                XmlVersionChecker,
                VersionChecker.new(),
            ],
        };

        obj._listeners = Listeners.new();

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override VersionChecker
    #
    del: func {
        me._listeners.del();

        call(VersionChecker.del, [], me);
    },

    #
    # Check if there is a new version.
    #
    # @return void
    # @override VersionChecker
    #
    checkLastVersion: func {
        if (me._url == nil) {
            Log.print('XmlVersionChecker, URL is not set');
            return;
        }

        Log.print('XmlVersionChecker, URL = ', me._url);

        var addonNodePath = g_Addon.node.getPath();

        me._listeners.add(
            node: addonNodePath ~ '/version-check-response/completed',
            code: func {
                me._listeners.clear();

                me._downloadResource = props.globals.getNode(addonNodePath ~ '/version-check-response/resource');
                me._invokeDownloadCallback();
            },
        );

        fgcommand('xmlhttprequest', props.Node.new({
            url       : me._url,
            targetnode: addonNodePath ~ '/version-check-response/resource',
            complete  : addonNodePath ~ '/version-check-response/completed',
        }));
    },
};
