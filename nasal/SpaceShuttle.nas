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
    new: func {
        var obj = { parents: [SpaceShuttle] };

        obj._propDestroyed     = props.globals.getNode("/fdm/jsbsim/systems/failures/shuttle-destroyed");
        obj._propGearNoseCond  = props.globals.getNode("/fdm/jsbsim/systems/failures/gear/gearstrut-nose-condition");
        obj._propGearLeftCond  = props.globals.getNode("/fdm/jsbsim/systems/failures/gear/gearstrut-left-condition");
        obj._propGearRightCond = props.globals.getNode("/fdm/jsbsim/systems/failures/gear/gearstrut-right-condition");
        obj._propPreLaunch     = props.globals.getNode("/sim/config/shuttle/prelaunch-flag");

        obj._ignition = false;
        obj._launched = false;

        obj._listeners = Listeners.new();
        obj._setListeners();

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func {
        me._listeners.del();
    },

    #
    # Set listeners.
    #
    # @return void
    #
    _setListeners: func {
        if (me.isPreLaunch()) {
            Log.print("SpaceShuttle preLaunch = ", me._propPreLaunch.getBoolValue());
            me._listeners.add(
                node: me._propPreLaunch,
                code: func(node) {
                    if (!node.getBoolValue()) {
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
    isPreLaunch: func {
        return me._propPreLaunch != nil and me._propPreLaunch.getBoolValue();
    },

    #
    # @return bool
    #
    isLiftOff: func {
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
    isLaunched: func {
        return me._launched;
    },

    #
    # Return true if the Shuttle crashed or any gear is broken.
    #
    # @return bool
    #
    isCrashed: func {
        return me._isDestroyed() or me._isGearBroken();
    },

    #
    # Return true if the Shuttle crashed.
    #
    # @return bool
    #
    _isDestroyed: func {
        return me._propDestroyed != nil and me._propDestroyed.getBoolValue();
    },

    #
    # Return true if any gear is broken.
    #
    # @return bool
    #
    _isGearBroken: func {
        return (me._propGearNoseCond  != nil and me._propGearNoseCond.getValue()  == 0)
            or (me._propGearLeftCond  != nil and me._propGearLeftCond.getValue()  == 0)
            or (me._propGearRightCond != nil and me._propGearRightCond.getValue() == 0);
    },
};
