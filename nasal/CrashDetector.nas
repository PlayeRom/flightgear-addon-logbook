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
    G_FORCE_INTERVAL: 0.2,

    #
    # Constructor
    #
    # @param  hash  spaceShuttle  SpaceShuttle object
    # @return me
    #
    new: func(spaceShuttle) {
        var me = { parents: [CrashDetector] };

        me._spaceShuttle = spaceShuttle;

        me._lastAircraftCoord = nil;
        me._lastAircraftAltAgl = nil;
        me._crashCounter = 0;

        me._propWingLeft  = props.globals.getNode("/fdm/jsbsim/wing-damage/left-wing");
        me._propWingRight = props.globals.getNode("/fdm/jsbsim/wing-damage/right-wing");

        me._propGForce = props.globals.getNode("/accelerations/pilot-gdamped");
        me._lastGForces = std.Vector.new();

        me._timerGForce = maketimer(CrashDetector.G_FORCE_INTERVAL, me, me._gForceCallback);

        me._maxGForceSize = int(12 * (1 / CrashDetector.G_FORCE_INTERVAL)); # from last 12 seconds

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._timerGForce.stop();
    },

    #
    # Check different values
    #
    # @param  bool  withOrientation  Set false for exclude isOrientationOK,
    #     needed for space shuttle where pitch is 90 degree for takeoff
    # @return bool
    #
    isCrash: func(withOrientation = 1) {
        return (withOrientation and !me.isOrientationOK())
            or me._isGForceAbnormal()
            or me._isSimCrashedFlag()
            or me._isC172PBrokenGear()
            or me._isC172PBrokenWing()
            or me._spaceShuttle.isCrashed();
    },

    #
    # Return true if _testCrash positive within 3 seconds
    #
    # @param  bool  onGround
    # @return bool
    #
    isCrashByTesting: func(onGround) {
        if (me._testCrash(onGround)) {
            me._crashCounter += 1;
            logprint(MY_LOG_LEVEL, "Logbook Add-on - crash counter  = ", me._crashCounter);

            # _testCrash detected per 3 sec, assume that it's true
            return me._crashCounter > 3;
        }

        return false;
    },

    #
    # Return true if possible crash occurred
    #
    # @param  bool  onGround
    # @return bool
    #
    _testCrash: func(onGround) {
        if (me._spaceShuttle.isCrashed()) {
            return true;
        }

        if (onGround) {
            return false;
        }

        if (me._isSimCrashedFlag() or me._isC172PBrokenGear() or me._isC172PBrokenWing()) {
            return true;
        }

        var aircraftCoord = geo.aircraft_position();

        if (me._lastAircraftCoord != nil
            and me._lastAircraftAltAgl != nil
            and sprintf("%.5f", aircraftCoord.lat()) == sprintf("%.5f", me._lastAircraftCoord.lat())
            and sprintf("%.5f", aircraftCoord.lon()) == sprintf("%.5f", me._lastAircraftCoord.lon())
            and sprintf("%.2f", getprop("/position/altitude-agl-ft")) == sprintf("%.2f", me._lastAircraftAltAgl)
        ) {
            # The position and altitude relative to the ground is exactly the same,
            # I assume that even an outstanding helicopter pilot in hover makes a tiny difference :)
            return true;
        }

        # Update last position
        me._lastAircraftCoord = aircraftCoord;
        me._lastAircraftAltAgl = getprop("/position/altitude-agl-ft");
        me._crashCounter = 0;

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
    _isC172PBrokenGear: func() {
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
    _isC172PBrokenWing: func() {
        if (me._propWingLeft == nil or me._propWingRight == nil) {
            return false;
        }

        return me._propWingLeft.getValue()  >= 1.0
            or me._propWingRight.getValue() >= 1.0;
    },

    #
    # Check "sim/crashed" property
    #
    # @return bool
    #
    _isSimCrashedFlag: func() {
        var crashed = getprop("/sim/crashed");
        if (crashed == nil) {
            return false;
        }

        return crashed;
    },

    #
    # Start timer for collection G-force values
    #
    # @param  bool  onGround
    # @return void
    #
    startGForce: func(onGround) {
        if (!onGround and !me._timerGForce.isRunning) {
            me._timerGForce.start();
        }
    },

    #
    # Stop timer for collection G-force values
    #
    # @return void
    #
    stopGForce: func() {
        if (me._timerGForce.isRunning) {
            me._timerGForce.stop();
        }
    },

    #
    # @return bool  Return true if G-Force in the last 12 seconds exceeds 3.0 g
    #
    _isGForceAbnormal: func() {
        foreach (var valueZeroBase; me._lastGForces.vector) {
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
    _gForceCallback: func() {
        var zeroBase = math.abs(me._propGForce.getValue() - 1.0);
        me._lastGForces.append(zeroBase);
        if (me._lastGForces.size() > me._maxGForceSize) {
            me._lastGForces.pop(0); # Maximum reached, delete first value
        }
    },
};
