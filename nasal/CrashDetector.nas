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
# CrashDetector class
#
var CrashDetector = {
    #
    # Constructor
    #
    # @param hash spaceShuttle - SpaceShuttle object
    # @return me
    #
    new: func (spaceShuttle) {
        var me = { parents: [CrashDetector] };

        me.spaceShuttle = spaceShuttle;

        me.lastAircraftCoord = nil;
        me.lastAircraftAltAgl = nil;
        me.crashCounter = 0;

        return me;
    },

    #
    # Return true if testCrash positive within 3 seconds
    #
    # @param bool onGround
    # @return bool
    #
    isCrash: func(onGround) {
        if (me.testCrash(onGround)) {
            me.crashCounter += 1;
            logprint(MY_LOG_LEVEL, "Logbook Add-on - crash counter  = ", me.crashCounter);

            # testCrash detected per 3 sec, assume that it's true
            return me.crashCounter > 3;
        }

        return false;
    },

    #
    # Reutrn true if possible crash occured
    #
    # @param bool onGround
    # @return bool
    #
    testCrash: func(onGround) {
        if (me.spaceShuttle.isCrashed()) {
            return true;
        }

        if (onGround) {
            return false;
        }

        if (me.isC172PBrokenGear() or me.isC172PBrokenWing()) {
            return true;
        }

        var aircraftCoord = geo.aircraft_position();

        if (me.lastAircraftCoord != nil and
            me.lastAircraftAltAgl != nil and
            sprintf("%.5f", aircraftCoord.lat()) == sprintf("%.5f", me.lastAircraftCoord.lat()) and
            sprintf("%.5f", aircraftCoord.lon()) == sprintf("%.5f", me.lastAircraftCoord.lon()) and
            sprintf("%.2f", getprop("/position/altitude-agl-ft")) == sprintf("%.2f", me.lastAircraftAltAgl)
        ) {
            # The position and altitude relative to the ground is exactly the same,
            # I assume that even an outstanding helicopter pilot in hover makes a tiny difference :)
            return true;
        }

        # Update last position
        me.lastAircraftCoord = aircraftCoord;
        me.lastAircraftAltAgl = getprop("/position/altitude-agl-ft");
        me.crashCounter = 0;

        return false;
    },

    #
    # Return true if roll and pitch is less than 30 degrees
    #
    # @return bool
    #
    isOrientationOK: func() {
        return math.abs(getprop("/orientation/roll-deg"))  < 30 and
               math.abs(getprop("/orientation/pitch-deg")) < 30;
    },

    #
    # Return true if any gear is broken for Cessna 172P.
    #
    # @return bool
    #
    isC172PBrokenGear: func() {
        var node = props.globals.getNode("/fdm/jsbsim/gear");
        if (node != nil) {
            foreach (var gear; node.getChildren("unit")) {
                var broken = gear.getChild("broken");
                if (broken != nil and broken.getValue()) {
                    return true;
                }
            }
        }

        return false;
    },

    #
    # Return true if any wing is broken for Cessna 172P.
    #
    # @return bool
    #
    isC172PBrokenWing: func() {
        return
            (getprop("/fdm/jsbsim/wing-damage/left-wing")  or 0.0) >= 1.0 or
            (getprop("/fdm/jsbsim/wing-damage/right-wing") or 0.0) >= 1.0;
    },
};
