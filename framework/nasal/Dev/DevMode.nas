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

io.include('Log.nas');
io.include('DevEnv.nas');
io.include('DevMultiKeyCmd.nas');
io.include('DevReloadMenu.nas');

#
# Global flag to enable dev mode. You can use this flag to condition on heavier logging that shouldn't be  executed for
# the end user, but you want to keep it in your code for development purposes. This flag will be set to true
# automatically when you use an .env file with DEV_MODE=true.
#
var g_isDevMode = false;

#
# A class to initialize developer functions from an `.env` file.
#
var DevMode = {
    #
    # Initialize developer functions.
    #
    # @return void
    #
    init: func {
        if (!Config.dev.useEnvFile) {
            return;
        }

        var env = DevEnv.new();

        me._setMyLogLevel(env);

        g_isDevMode = env.getBoolValue('DEV_MODE');

        if (g_isDevMode) {
            me._setReloadMenu(env);
            me._setMultiKeyCommands(env);
        }
    },

    #
    # @param  hash  env  DevEnv object.
    # @return void
    #
    _setMyLogLevel: func(env) {
        var logLevel = env.getValue('MY_LOG_LEVEL');
        if (logLevel != nil) {
            MY_LOG_LEVEL = logLevel;
        }
    },

    #
    # @param  hash  env  DevEnv object.
    # @return void
    #
    _setReloadMenu: func(env) {
        var reloadMenu = DevReloadMenu.new();

        env.getBoolValue('RELOAD_MENU')
            ? reloadMenu.addMenu()
            : reloadMenu.removeMenu();
    },

    #
    # @param  hash  env  DevEnv object.
    # @return void
    #
    _setMultiKeyCommands: func(env) {
        DevMultiKeyCmd.new()
            .addReloadAddon(env.getValue('RELOAD_MULTIKEY_CMD'))
            .addRunTests(env.getValue('TEST_MULTIKEY_CMD'))
            .finish();
    },
};
