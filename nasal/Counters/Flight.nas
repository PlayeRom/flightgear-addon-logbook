#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Flight class for handle flight parameters like altitude, speed.
#
var Flight = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [
            Flight,
            BaseCounter.new(
                func()               { me._onResetCounters(); },
                func(diffElapsedSec) { me._onUpdate(diffElapsedSec); }
            ),
        ] };

        me._maxAlt  = 0.0;
        me._maxGSKt = 0.0;
        me._maxMach = 0.0;

        me._propAltFt = props.globals.getNode("/position/altitude-ft");
        me._propGSKt  = props.globals.getNode("/velocities/groundspeed-kt");
        me._propMach  = props.globals.getNode("/velocities/mach");

        return me;
    },

    #
    # Reset all counters
    #
    # @return void
    #
    _onResetCounters: func() {
        me._maxAlt  = 0.0;
        me._maxGSKt = 0.0;
        me._maxMach = 0.0;
    },

    #
    # Update all counters
    #
    # @param  double  diffElapsedSec
    # @return void
    #
    _onUpdate: func(diffElapsedSec) {
        var alt = me._propAltFt.getValue();
        if (alt > me._maxAlt) {
            me._maxAlt = alt;
        }

        var gs = me._propGSKt.getValue();
        if (gs > me._maxGSKt) {
            me._maxGSKt = gs;
        }

        var mach = me._propMach.getValue();
        if (mach > me._maxMach) {
            me._maxMach = mach;
        }
    },


    #
    # Get max altitude in ft
    #
    # @return double
    #
    getMaxAlt: func() {
        return me._maxAlt;
    },

    #
    # Get max groundspeed in knots
    #
    # @return double
    #
    getMaxGroundspeedKt: func() {
        return me._maxGSKt;
    },

    #
    # Get max speed in Mach number
    #
    # @return double
    #
    getMaxMach: func() {
        return me._maxMach;
    },
};
