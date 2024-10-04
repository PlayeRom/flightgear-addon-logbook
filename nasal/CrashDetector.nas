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
    # Constants
    #
    GFORCE_INTERVAL : 0.2,

    #
    # Constructor
    #
    # @param hash spaceShuttle - SpaceShuttle object
    # @return me
    #
    new: func(spaceShuttle) {
        var me = { parents: [CrashDetector] };

        me.spaceShuttle = spaceShuttle;

        me.lastAircraftCoord = nil;
        me.lastAircraftAltAgl = nil;
        me.crashCounter = 0;

        me.propWingLeft  = props.globals.getNode("/fdm/jsbsim/wing-damage/left-wing");
        me.propWingRight = props.globals.getNode("/fdm/jsbsim/wing-damage/right-wing");

        me.propGForce = props.globals.getNode("/accelerations/pilot-gdamped");
        me.lastGForces = std.Vector.new();

        me.timerGForce = maketimer(CrashDetector.GFORCE_INTERVAL, me, me.gForceCallback);

        me.maxGForceSize = int(12 * (1 / CrashDetector.GFORCE_INTERVAL)); # from last 12 seconds

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.timerGForce.stop();
    },

    #
    # Check different values
    #
    # @param bool withOrientation - Set false for exclude isOrientationOK,
    #                               needed for space shuttle where pitch is 90 degree for takeoff
    # @return bool
    #
    isCrash: func(withOrientation = 1) {
        return (withOrientation and !me.isOrientationOK())
            or me.isGForceAbnormal()
            or me.isSimCrashedFlag()
            or me.isC172PBrokenGear()
            or me.isC172PBrokenWing()
            or me.spaceShuttle.isCrashed();
    },

    #
    # Return true if testCrash positive within 3 seconds
    #
    # @param bool onGround
    # @return bool
    #
    isCrashByTesting: func(onGround) {
        if (me.testCrash(onGround)) {
            me.crashCounter += 1;
            logprint(MY_LOG_LEVEL, "Logbook Add-on - crash counter  = ", me.crashCounter);

            # testCrash detected per 3 sec, assume that it's true
            return me.crashCounter > 3;
        }

        return false;
    },

    #
    # Return true if possible crash occurred
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

        if (me.isSimCrashedFlag() or me.isC172PBrokenGear() or me.isC172PBrokenWing()) {
            return true;
        }

        var aircraftCoord = geo.aircraft_position();

        if (me.lastAircraftCoord != nil
            and me.lastAircraftAltAgl != nil
            and sprintf("%.5f", aircraftCoord.lat()) == sprintf("%.5f", me.lastAircraftCoord.lat())
            and sprintf("%.5f", aircraftCoord.lon()) == sprintf("%.5f", me.lastAircraftCoord.lon())
            and sprintf("%.2f", getprop("/position/altitude-agl-ft")) == sprintf("%.2f", me.lastAircraftAltAgl)
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
        return  math.abs(getprop("/orientation/roll-deg"))  < 30
            and math.abs(getprop("/orientation/pitch-deg")) < 30;
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
        if (me.propWingLeft == nil or me.propWingRight == nil) {
            return false;
        }

        return me.propWingLeft.getValue()  >= 1.0
            or me.propWingRight.getValue() >= 1.0;
    },

    #
    # Check "sim/crashed" property
    #
    # @return bool
    #
    isSimCrashedFlag: func() {
        var crashed = getprop("/sim/crashed");
        if (crashed == nil) {
            return false;
        }

        return crashed;
    },

    #
    # Start timer for collection G-force values
    #
    # @param bool onGround
    # @return void
    #
    startGForce: func(onGround) {
        if (!onGround and !me.timerGForce.isRunning) {
            me.timerGForce.start();
        }
    },

    #
    # Stop timer for collection G-force values
    #
    # @return void
    #
    stopGForce: func() {
        if (me.timerGForce.isRunning) {
            me.timerGForce.stop();
        }
    },

    #
    # @return bool - Return true if G-Force in the last 12 seconds exceeds 3.0 g
    #
    isGForceAbnormal: func() {
        foreach (var valueZeroBase; me.lastGForces.vector) {
            if (valueZeroBase > 2.0) {
                return true;
            }
        }

        return false;
    },

    #
    # Timer function for collecting G-force values
    #
    # @return void
    #
    gForceCallback: func() {
        var zeroBase = math.abs(me.propGForce.getValue() - 1.0);
        me.lastGForces.append(zeroBase);
        if (me.lastGForces.size() > me.maxGForceSize) {
            me.lastGForces.pop(0); # Maximum reached, delete first value
        }
    },
};
