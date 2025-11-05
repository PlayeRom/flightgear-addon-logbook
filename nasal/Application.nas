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

io.include('Utils/FGVersion.nas');

#
# Global object for check FG version.
#
var g_FGVersion = FGVersion.new();

#
# For older versions of FlightGear, add the `true` and `false` aliases as values ​​1 and 0.
#
if (g_FGVersion.lowerThan('2024.1.1')) {
    io.include('Boolean.nas');
}

io.include('Config.nas');
io.include('Loader.nas');
io.include('Dev/DevMode.nas');

#
# Global object of addons.Addon ghost.
#
var g_Addon = nil;

#
# Main add-on class for load and run all submodules.
#
var Application = {
    #
    # Set hook function which return list of files excluded from loading.
    #
    # @param  func  callback
    # @return hash
    #
    hookFilesExcludedFromLoading: func (callback) {
        me.filesExcludedFromLoading = callback;
        return me;
    },

    #
    # Set hook function which will be called by the framework upon initialization. Here, should be objects instantiate
    # but not those related to Canvas. This could be, for example, some logic in your add-on.
    #
    # @param  func  callback
    # @return hash
    #
    hookOnInit: func(callback) {
        me.onInit = callback;
        return me;
    },

    #
    # Set hook function which will be called by the framework when it's time to initialize the Canvas objects ─ this
    # will happen 3 seconds after onInit(). Here windows can be instantiated in Canvas.
    #
    # @param  func  callback
    # @return hash
    #
    hookOnInitCanvas: func(callback) {
        me.onInitCanvas = callback;
        return me;
    },

    #
    # Set hook function for exclude menu names for enabled after onInitCanvas().
    #
    # @param  func  callback
    # @return hash
    #
    hookExcludedMenuNamesForEnabled: func(callback) {
        me.excludedMenuNamesForEnabled = callback;
        return me;
    },

    #
    # Main load function.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @param  string|nil  aliasNamespace  Globally unique alias to the add-on namespace
    #                                     for easier reference e.g. in addon-menubar-items.xml.
    # @return void
    #
    create: func(addon, aliasNamespace = nil) {
        g_Addon = addon;

        DevMode.init();

        var namespace = me._getNamespace(aliasNamespace);

        Loader.new().load(g_Addon.basePath, namespace);

        Bootstrap.init();
    },

    #
    # Unload add-on.
    #
    # @return void
    #
    unload: func {
        Bootstrap.uninit();
    },

    #
    # Call hook function by name.
    #
    # @param  string  name
    # @param  mixed  default  Default value returned if name is not found.
    # @return mixed
    #
    callHook: func(name, default = nil) {
        if (me._isHook(name)) {
            return me[name]();
        }

        return default;
    },

    #
    # Get namespace name of add-on and create alias for this namespace if specified.
    # This is the same namespace which is created by FlightGear based on add-on ID.
    #
    # @param  string|nil  aliasNamespace
    # @return string
    #
    _getNamespace: func(aliasNamespace = nil) {
        var namespace = globals.addons.getNamespaceName(g_Addon);

        if (aliasNamespace != nil) {
            # Create an alias to the add-on namespace for easier reference e.g. in addon-menubar-items.xml:
            globals[aliasNamespace] = globals[namespace];
        }

        return namespace;
    },

    #
    # A helper function that checks if the Application has implemented a given hook.
    #
    # @param  string  name  Function name in Application object.
    # @return bool
    #
    _isHook: func(name) {
        return contains(me, name)
            and isfunc(me[name]);
    },
};
