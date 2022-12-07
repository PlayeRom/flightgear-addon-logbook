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
    new: func () {
        var me = { parents: [SpaceShuttle] };

        me.preLaunch = getprop("/sim/config/shuttle/prelaunch-flag") or false;
        me.ignition = false;
        me.launched = false;

        if (me.preLaunch) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - SpaceShuttle preLaunch = ", me.preLaunch);
            setlistener("/sim/config/shuttle/prelaunch-flag", func(node) {
                me.preLaunch = node.getValue();
                if (!me.preLaunch) {
                    # ignition
                    me.ignition = true;
                    logprint(MY_LOG_LEVEL, "Logbook Add-on - SpaceShuttle ignition = ", me.ignition);
                }
            });
        }

        return me;
    },

    #
    # Is Shuttle on the lounch position
    #
    # return bool
    #
    isPreLaunch: func() {
        return me.preLaunch;
    },

    #
    # return bool
    #
    isLiftOff: func() {
        if (me.ignition) {
            me.ignition = false;
            me.launched = true; # mark that we launched shuttle
            return true;
        }

        return false;
    },

    #
    # return bool
    #
    isLaunched: func() {
        return me.launched;
    },

    #
    # return bool
    #
    isCrashed: func() {
        return (getprop("/fdm/jsbsim/systems/failures/shuttle-destroyed") or false) or
                me.isGearBroken();
    },

    #
    # Return true if any gear is broken.
    #
    # return bool
    #
    isGearBroken: func() {
        return getprop("/fdm/jsbsim/systems/failures/gear/gearstrut-nose-condition") == 0 or
               getprop("/fdm/jsbsim/systems/failures/gear/gearstrut-left-condition") == 0 or
               getprop("/fdm/jsbsim/systems/failures/gear/gearstrut-right-condition") == 0
    }
};
