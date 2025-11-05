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
# retrieve the content of any file (although the main assumption is that it will
# be a JSON file, which is most often used in various APIs). The retrieved
# resource content is then passed to the base class for further processing.
#
var JsonVersionChecker = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        return {
            parents: [
                JsonVersionChecker,
                VersionChecker.new(),
            ],
        };
    },

    #
    # Check if there is a new version.
    #
    # @return void
    # @override VersionChecker
    #
    checkLastVersion: func {
        if (me._url == nil) {
            Log.error('JsonVersionChecker, URL is not set');
            return;
        }

        Log.print('JsonVersionChecker, URL = ', me._url);

        http.load(me._url)
            .done(func(r) {
                # Be careful, because die() here will close the entire simulator (⊙_◎)

                if (r == nil) {
                    return;
                }

                me._downloadResource = r.response;

                # The done() method runs in a C++ context → uncaught errors kill
                # the entire simulator. Therefore, we call the timer to escape
                # to the Nasal context. There, crash or die() will not propagate
                # to C++, and the Nasal interpreter will handle it.
                Timer.singleShot(0.1, me, me._invokeDownloadCallback);
            });
    },

    #
    # Parse JSON string into a hash.
    #
    # @param  string  json
    # @return hash|nil
    #
    parseJson: func(json) {
        var compilationErrors = [];
        var jsonFunc = call(func compile(json), [], compilationErrors);

        if (size(compilationErrors)) {
            foreach (var error; compilationErrors) {
                Log.error(error);
            }
            return nil;
        }

        var runtimeErrors = [];
        var jsonHash = call(jsonFunc, [], runtimeErrors);

        if (size(runtimeErrors)) {
            foreach (var error; runtimeErrors) {
                Log.error(error);
            }
            return nil;
        }

        return jsonHash;
    },
};
