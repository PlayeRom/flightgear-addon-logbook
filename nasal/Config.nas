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
# Framework configuration.
# Change the following options as needed in your `main` function in `/addon-main.nas` file
# before using Application class.
#
var Config = {
    #
    # Options related to checking for a newer version of the add-on. Only one flag should be set to `true`,
    # or none at all. For information on how version checking works, see "Version Checker" section in `README.md` file.
    # These settings also ensure that files from the `/nasal/VersionCheck/` directory that are not needed will
    # not be loaded when the simulator is started.
    # This also requires the URL to be provided in the `<code-repository>` tag in the `/addon-metadata.xml` file, e.g.:
    # `<code-repository type="string">https://github.com/PlayeRom/flightgear-addon-framework</code-repository>`.
    #
    # If you host your project on the official FGAddon repository on SourceForge, you provide the URL as e.g.:
    # https://sourceforge.net/p/flightgear/fgaddon/HEAD/tree/trunk/Addons/Framework (where your add-on directory
    # must be the last element of the URL).
    #
    # If you hosted your project on own SourceForge, then URL should be like:
    # https://sourceforge.net/p/framework/code/ci/HEAD/tree
    #
    useVersionCheck: {
        #
        # Set to `true` if you want to check for a newer version by downloading the `/addon-metadata.xml` file from the
        # repository. Only GitHub, GitLab and FGAddons are supported.
        # Example: Config.useVersionCheck.byMetaData = true;
        #
        byMetaData: false,

        #
        # Set to `true` if you want to check for a newer version by checking your repository's git tags, where tag
        # is the version number, e.g. "1.2.5" or "v1.2.5". Only GitHub and GitLab are supported.
        # Example: Config.useVersionCheck.byGitTag = true;
        #
        byGitTag: false,
    },

    #
    # Developer options.
    #
    dev: {
        #
        # Set the value to `true` to enable the add-on to use the `.env` file. This option can be safely left enabled
        # (`true`) even for end users, as long as the `.env` file remains only in your local copy.
        # Setting this flag to `false` will prevent files from the `/nasal/Dev/` directory from being loaded when
        # the simulator is started.
        #
        useEnvFile: true,
    },
};
