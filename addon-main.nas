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

# This is the main addon Nasal hook. It MUST contain a function
# called "main". The main function will be called upon init with
# the addons.Addon instance corresponding to the addon being loaded.
#
# This script will live in its own Nasal namespace that gets
# dynamically created from the global addon init script.
# It will be something like "__addon[ADDON_ID]__" where ADDON_ID is
# the addon identifier, such as "org.flightgear.addons.framework".
#
# See $FG_ROOT/Docs/README.add-ons for info about the addons.Addon
# object that is passed to main(), and much more. The latest version
# of this README.add-ons document is at:
#
#   https://sourceforge.net/p/flightgear/fgdata/ci/next/tree/Docs/README.add-ons
#

io.include('nasal/App.nas');

#
# Main add-on function.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var main = func(addon) {
    logprint(LOG_INFO, addon.name, ' Add-on initialized from path ', addon.basePath);

    Config.useVersionCheck.byMetaData = 1;

    App.load(addon);
};

#
# This function is for addon development only. It is called on addon
# reload. The addons system will replace setlistener() and maketimer() to
# track this resources automatically for you.
#
# Listeners created with setlistener() will be removed automatically for you.
# Timers created with maketimer() will have their stop() method called
# automatically for you. You should NOT use settimer anymore, see wiki at
# http://wiki.flightgear.org/Nasal_library#maketimer.28.29
#
# Other resources should be freed by adding the corresponding code here,
# e.g. myCanvas.del();
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var unload = func(addon) {
    App.unload();
};

#
# This class defines a set of callback functions that the framework will invoke
# at specific points during the add-on's lifecycle. Add-on authors implement
# these functions to provide custom behavior, but the framework itself handles
# when and how they are called.
#
# The Hooks object acts purely as a container for these functions. It does not
# implement any framework logic itself — it is the add-on's responsibility to
# provide meaningful implementations.
#
# All of these methods are optional and can be removed entirely from the code
# if they are not needed.
#
var Hooks = {
    #
    # Return vector of Nasal files excluded from loading. Files must be specified with a path relative to the add-on's
    # root directory and must start with `/` (where `/` represents the add-on's root directory).
    #
    # @return vector
    #
    filesExcludedFromLoading: func {
        return [];
    },

    #
    # Create non-Canvas objects here.
    #
    onInit: func {
        # TODO: crate objects here...
    },

    #
    # Create Canvas objects here.
    #
    onInitCanvas: func {
        # TODO: crate objects here...
    },

    #
    # Remove all objects here.
    #
    onUninit: func {
        # TODO: release objects here...
    },

    #
    # For the menu with 'name', which is disabled while the Canvas is loading,
    # you can specify here the names of the menu items that should not be enabled
    # automatically, but you can decide in your code when to enable them again,
    # using gui.menuEnable().
    #
    # @return hash  Key as menu name from addon-menubar-items.xml, value whatever.
    #
    excludedMenuNamesForEnabled: func {
        return {};
    },
};
