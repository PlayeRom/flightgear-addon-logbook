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

io.include('Config.nas');
io.include('Loader.nas');
io.include('Utils/FGVersion.nas');

#
# Global object of addons.Addon.
#
var g_Addon = nil;

#
# Global object for check FG version.
#
var g_FGVersion = FGVersion.new();

#
# Global aliases for boolean types to distinguish the use of "int" from "bool".
# NOTE: unfortunately, it doesn't work as an assignment of a default value for a function parameter!
# FlightGear from version 2024.1.1 supports the `true` and `false` keywords natively.
#
if (g_FGVersion.lowerThan('2024.1.1')) {
    var true  = 1;
    var false = 0;
}

#
# A helper function that checks if the dev has implemented a given hook.
#
# @param  string  name  Function name in Hooks object.
# @return bool
#
var g_isHook = func(name) {
    return defined('Hooks')
        and contains(Hooks, name)
        and isfunc(Hooks[name]);
};

#
# Main Addon class for load and run all submodules.
#
var App = {
    #
    # Main load function.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @param  string|nil  aliasNamespace  Globally unique alias to the add-on namespace
    #                                     for easier reference e.g. in addon-menubar-items.xml.
    # @return void
    #
    load: func(addon, aliasNamespace = nil) {
        g_Addon = addon;

        var namespace = globals.addons.getNamespaceName(g_Addon);

        if (aliasNamespace != nil) {
            # Create an alias to the add-on namespace for easier reference e.g. in addon-menubar-items.xml:
            globals[aliasNamespace] = globals[namespace];
        }

        Loader.new().load(g_Addon.basePath, namespace);

        Bootstrap.init();
    },

    #
    # @return void
    #
    unload: func {
        Log.print('unload');
        Bootstrap.uninit();
    },
};
