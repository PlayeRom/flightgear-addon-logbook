#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# SpaceShuttle class to handle Space Shuttle.
# ATTENTION! The shuttle always has the onground flag set to false,
# even if the --on-ground option is specified with launch position.
#
var SpaceShuttle = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [SpaceShuttle] };

        me._preLaunch = getprop("/sim/config/shuttle/prelaunch-flag") or false;
        me._ignition = false;
        me._launched = false;

        me._listeners = Listeners.new();
        me._setListeners();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._listeners.del();
    },

    #
    # Set listeners.
    #
    # @return void
    #
    _setListeners: func() {
        if (me._preLaunch) {
            Log.print("SpaceShuttle preLaunch = ", me._preLaunch);
            me._listeners.add(
                node: "/sim/config/shuttle/prelaunch-flag",
                code: func(node) {
                    me._preLaunch = node.getValue();
                    if (!me._preLaunch) {
                        # ignition
                        me._ignition = true;
                        Log.print("SpaceShuttle ignition = ", me._ignition);
                    }
                },
            );
        }
    },

    #
    # Is Shuttle on the launch position
    #
    # @return bool
    #
    isPreLaunch: func() {
        return me._preLaunch;
    },

    #
    # @return bool
    #
    isLiftOff: func() {
        if (me._ignition) {
            me._ignition = false;
            me._launched = true; # mark that we launched shuttle
            return true;
        }

        return false;
    },

    #
    # Return true if Shuttle lifted off
    #
    # @return bool
    #
    isLaunched: func() {
        return me._launched;
    },

    #
    # Return true if the Shuttle crashed or any gear is broken.
    #
    # @return bool
    #
    isCrashed: func() {
        return (getprop("/fdm/jsbsim/systems/failures/shuttle-destroyed") or false)
            or me._isGearBroken();
    },

    #
    # Return true if any gear is broken.
    #
    # @return bool
    #
    _isGearBroken: func() {
        return getprop("/fdm/jsbsim/systems/failures/gear/gearstrut-nose-condition") == 0
            or getprop("/fdm/jsbsim/systems/failures/gear/gearstrut-left-condition") == 0
            or getprop("/fdm/jsbsim/systems/failures/gear/gearstrut-right-condition") == 0
    },
};
