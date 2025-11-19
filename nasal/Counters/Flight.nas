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
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = { parents: [
            Flight,
            BaseCounter.new(
                func               { obj._onResetCounters(); },
                func(diffElapsedSec) { obj._onUpdate(diffElapsedSec); }
            ),
        ] };

        obj._maxAlt        = 0.0;
        obj._maxGSKt       = 0.0;
        obj._maxMach       = 0.0;
        obj._odometer      = 0.0;
        obj._startFuel     = 0.0; # amount of fuel at takeoff
        obj._startOdometer = 0.0; # distance at takeoff

        obj._propAltFt    = props.globals.getNode("/position/altitude-ft");
        obj._propGSKt     = props.globals.getNode("/velocities/groundspeed-kt");
        obj._propASKt     = props.globals.getNode("/velocities/airspeed-kt");
        obj._propMach     = props.globals.getNode("/velocities/mach");
        obj._propHdgTrue  = props.globals.getNode("/orientation/heading-deg");
        obj._propHdgMag   = props.globals.getNode("/orientation/heading-magnetic-deg");
        obj._propPitch    = props.globals.getNode("/orientation/pitch-deg");
        obj._propFuel     = props.globals.getNode("/consumables/fuel/total-fuel-gal_us");
        obj._propOdometer = props.globals.getNode("/instrumentation/gps/odometer");

        return obj;
    },

    #
    # Reset all counters called on start logging flight data (after take-off).
    #
    # @return void
    #
    _onResetCounters: func {
        me._maxAlt   = 0.0;
        me._maxGSKt  = 0.0;
        me._maxMach  = 0.0;
        me._odometer = 0.0;

        me.setStartFuel();
        me.setStartOdometer();
    },

    #
    # Update all counters.
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
    # Get max altitude in ft.
    #
    # @return double
    #
    getMaxAlt: func {
        return me._maxAlt;
    },

    #
    # Get max groundspeed in knots.
    #
    # @return double
    #
    getMaxGroundspeedKt: func {
        return me._maxGSKt;
    },

    #
    # Get current groundspeed in knots.
    #
    # @return double
    #
    getGroundspeedKt: func {
        return me._propGSKt.getValue();
    },

    #
    # Get current airspeed in knots.
    #
    # @return double
    #
    getAirspeedKt: func {
        return me._propASKt.getValue();
    },

    #
    # Get max speed in Mach number.
    #
    # @return double
    #
    getMaxMach: func {
        return me._maxMach;
    },

    #
    # Get true heading.
    #
    # @return double
    #
    getHeadingTrue: func {
        return me._propHdgTrue.getValue();
    },

    #
    # Get magnetic heading.
    #
    # @return double
    #
    getHeadingMag: func {
        return me._propHdgMag.getValue();
    },

    #
    # Get aircraft pitch in degrees.
    #
    # @return double
    #
    getPitch: func {
        return me._propPitch.getValue();
    },

    #
    # Record the fuel spent on a taxi.
    #
    # @return void
    #
    setStartFuel: func {
        me._startFuel = me._propFuel.getValue();
    },

    #
    # Get amount of fuel burned during a flight only.
    #
    # @return double
    #
    getFuel: func {
        var currentFuel = me._propFuel.getValue();
        return math.abs(me._startFuel - currentFuel);
    },

    #
    # Record the distance traveled spent in a taxi.
    #
    # @return void
    #
    setStartOdometer: func {
        me._startOdometer = me._propOdometer.getValue();
    },

    #
    # Take the total distance traveled, including taxi.
    #
    # @return double
    #
    getFullDistance: func {
        return me._propOdometer.getValue();
    },

    #
    # Take the distance traveled but only the flight itself.
    #
    # @return double
    #
    getFlyDistance: func {
        return me.getFullDistance() - me._startOdometer;
    },
};
