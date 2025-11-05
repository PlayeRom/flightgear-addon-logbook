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

# This is the main addon Nasal hook. It MUST contain a function called "main". The main function will be called upon
# init with the addons.Addon instance corresponding to the addon being loaded.
#
# This script will live in its own Nasal namespace that gets dynamically created from the global addon init script.
# It will be something like "__addon[ADDON_ID]__" where ADDON_ID is the addon identifier, such as
# "org.flightgear.addons.framework".
#
# See $FG_ROOT/Docs/README.add-ons for info about the addons.Addon object that is passed to main(), and much more.
# The latest version of this README.add-ons document is at:
#
#   https://gitlab.com/flightgear/fgdata/-/blob/next/Docs/README.add-ons
#

io.include('nasal/Application.nas');

#
# Main add-on function.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var main = func(addon) {
    logprint(LOG_INFO, addon.name, ' Add-on initialized from path ', addon.basePath);

    # TODO: set config here if needed:
    # Config.dev.useEnvFile = false;
    # Config.useVersionCheck.byMetaData = true;
    # Config.useVersionCheck.byGitTag = true;

    Application
        .hookFilesExcludedFromLoading(func {
            return [
                # TODO: add list of Nasal files here if needed...
            ];
        })
        .hookOnInit(func {
            # TODO: create non-Canvas objects here if needed...
        })
        .hookOnInitCanvas(func {
            # TODO: create Canvas objects here if needed...
        })
        .hookExcludedMenuNamesForEnabled(func {
            return {
                # TODO: add list of names here if needed...
            };
        })
        .create(addon);
};

#
# This function is for addon development only. It is called on addon reload. The addons system will replace
# setlistener() and maketimer() to track this resources automatically for you.
#
# Listeners created with setlistener() will be removed automatically for you. Timers created with maketimer() will have
# their stop() method called automatically for you. You should NOT use settimer anymore, see wiki at
# https://wiki.flightgear.org/Nasal_library#maketimer()
#
# Other resources should be freed by adding the corresponding code here, e.g. `myCanvas.del();`.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var unload = func(addon) {
    Log.print('unload');
    Application.unload();

    # TODO: release all objects here...
};
