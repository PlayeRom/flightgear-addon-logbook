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
    # @return hash
    #
    new: func(spaceShuttle) {
        var obj = {
            parents: [CrashDetector],
            _spaceShuttle: spaceShuttle,
        };

        obj._lastAircraftCoord = nil;
        obj._lastAircraftAltAgl = nil;
        obj._crashCounter = 0;

        obj._propWingLeft    = props.globals.getNode("/fdm/jsbsim/wing-damage/left-wing");
        obj._propWingRight   = props.globals.getNode("/fdm/jsbsim/wing-damage/right-wing");
        obj._propAltAglFt    = props.globals.getNode("/position/altitude-agl-ft");
        obj._propRollDeg     = props.globals.getNode("/orientation/roll-deg");
        obj._propPitchDeg    = props.globals.getNode("/orientation/pitch-deg");
        obj._propJsbSimGear  = props.globals.getNode("/fdm/jsbsim/gear");
        obj._propSimCrashed  = props.globals.getNode("/sim/crashed");
        obj._propB707Crashed = props.globals.getNode("/b707/crashed");

        obj._propGForce = props.globals.getNode("/accelerations/pilot-gdamped");
        obj._lastGForces = std.Vector.new();

        obj._timerGForce = Timer.make(CrashDetector.G_FORCE_INTERVAL, obj, obj._gForceCallback);

        obj._maxGForceSize = int(12 * (1 / CrashDetector.G_FORCE_INTERVAL)); # from last 12 seconds

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func {
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
            or me._isB707Crashed()
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
            Log.print("crash counter  = ", me._crashCounter);

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

        if (me._isSimCrashedFlag()
            or me._isC172PBrokenGear()
            or me._isC172PBrokenWing()
            or me._isB707Crashed()
        ) {
            return true;
        }

        var aircraftCoord = geo.aircraft_position();

        if (me._lastAircraftCoord != nil
            and me._lastAircraftAltAgl != nil
            and sprintf("%.5f", aircraftCoord.lat()) == sprintf("%.5f", me._lastAircraftCoord.lat())
            and sprintf("%.5f", aircraftCoord.lon()) == sprintf("%.5f", me._lastAircraftCoord.lon())
            and sprintf("%.2f", me._propAltAglFt.getValue()) == sprintf("%.2f", me._lastAircraftAltAgl)
        ) {
            # The position and altitude relative to the ground is exactly the same,
            # I assume that even an outstanding helicopter pilot in hover makes a tiny difference :)
            return true;
        }

        # Update last position
        me._lastAircraftCoord = aircraftCoord;
        me._lastAircraftAltAgl = me._propAltAglFt.getValue();
        me._crashCounter = 0;

        return false;
    },

    #
    # Return true if roll and pitch is less than 30 degrees
    #
    # @return bool
    #
    isOrientationOK: func {
        return  math.abs(me._propRollDeg.getValue())  < 30
            and math.abs(me._propPitchDeg.getValue()) < 30;
    },

    #
    # Return true if any gear is broken for Cessna 172P.
    #
    # @return bool
    #
    _isC172PBrokenGear: func {
        if (me._propJsbSimGear != nil) {
            foreach (var gear; me._propJsbSimGear.getChildren("unit")) {
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
    _isC172PBrokenWing: func {
        return (me._propWingLeft  != nil and me._propWingLeft.getValue()  >= 1.0)
            or (me._propWingRight != nil and me._propWingRight.getValue() >= 1.0);
    },

    #
    # Check "/sim/crashed" property
    #
    # @return bool
    #
    _isSimCrashedFlag: func {
        return me._propSimCrashed != nil and me._propSimCrashed.getBoolValue();
    },

    #
    # Check "/b707/crashed" property
    #
    # @return bool
    #
    _isB707Crashed: func {
        return me._propB707Crashed != nil and me._propB707Crashed.getBoolValue();
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
    stopGForce: func {
        if (me._timerGForce.isRunning) {
            me._timerGForce.stop();
        }
    },

    #
    # @return bool  Return true if G-Force in the last 12 seconds exceeds 3.0 g
    #
    _isGForceAbnormal: func {
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
    _gForceCallback: func {
        var zeroBase = math.abs(me._propGForce.getValue() - 1.0);
        me._lastGForces.append(zeroBase);
        if (me._lastGForces.size() > me._maxGForceSize) {
            me._lastGForces.pop(0); # Maximum reached, delete first value
        }
    },
};
