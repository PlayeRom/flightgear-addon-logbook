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
# Environment class for handle date, time, day, night, IMC, altitude.
#
var Environment = {
    #
    # Constants
    #
    SKY_DOME_COLOR_THRESHOLD : 0.4,
    MINIMUM_VFR_VISIBILITY   : 5000, # in meters

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [
            Environment,
            BaseCounter.new(
                func()               { me._onResetCounters(); },
                func(diffElapsedSec) { me._onUpdate(diffElapsedSec); }
            ),
        ] };

        me._dayCounter         = 0;
        me._nightCounter       = 0;
        me._instrumentCounter  = 0;
        me._maxAlt             = 0.0;

        me._propAltFt          = props.globals.getNode("/position/altitude-ft");

        me._propSkyRed         = props.globals.getNode("/rendering/dome/sky/red");
        me._propSkyGreen       = props.globals.getNode("/rendering/dome/sky/green");
        me._propSkyBlue        = props.globals.getNode("/rendering/dome/sky/blue");

        me._propGroundVisiM    = props.globals.getNode("/environment/ground-visibility-m");
        me._propEffectiveVisiM = props.globals.getNode("/environment/effective-visibility-m");

        return me;
    },

    #
    # Get real date as string in ISO format
    #
    # @return string
    #
    getDateString: func() {
        return sprintf(
            "%d-%02d-%02d",
            getprop("/sim/time/real/year"),
            getprop("/sim/time/real/month"),
            getprop("/sim/time/real/day")
        );
    },

    #
    # Get real time as string
    #
    # @return string
    #
    getTimeString: func() {
        return sprintf(
            "%02d:%02d",
            getprop("/sim/time/real/hour"),
            getprop("/sim/time/real/minute")
        );
    },

    #
    # Reset all environment counters
    #
    # @return void
    #
    _onResetCounters: func() {
        me._dayCounter        = 0;
        me._nightCounter      = 0;
        me._instrumentCounter = 0;
        me._maxAlt            = 0.0;
    },

    #
    # Update all environment counters
    #
    # @param double diffElapsedSec
    # @return void
    #
    _onUpdate: func(diffElapsedSec) {
        me._isNight()
            ? (me._nightCounter += diffElapsedSec)
            : (me._dayCounter   += diffElapsedSec);

        if (me._isIMC()) {
            me._instrumentCounter += diffElapsedSec;
        }

        var alt = me._propAltFt.getValue();
        if (alt > me._maxAlt) {
            me._maxAlt = alt;
        }
    },

    #
    # Return true when we have a night. It is a trick to check the color of the sky.
    #
    # @return bool
    #
    _isNight: func() {
        return  me._propSkyRed.getValue()   < Environment.SKY_DOME_COLOR_THRESHOLD
            and me._propSkyGreen.getValue() < Environment.SKY_DOME_COLOR_THRESHOLD
            and me._propSkyBlue.getValue()  < Environment.SKY_DOME_COLOR_THRESHOLD;
    },

    #
    # Return true if visibility is for IFR conditions.
    #
    # @return bool
    #
    _isIMC: func() {
        return me._propGroundVisiM.getValue()    < Environment.MINIMUM_VFR_VISIBILITY
            or me._propEffectiveVisiM.getValue() < Environment.MINIMUM_VFR_VISIBILITY;
    },

    #
    # Get flight duration in day in hours
    #
    # @return double
    #
    getDayHours: func() {
        return me._dayCounter / 3600;
    },

    #
    # Get flight duration in night in hours
    #
    # @return double
    #
    getNightHours: func() {
        return me._nightCounter / 3600;
    },

    #
    # Get flight duration in IMC in hours
    #
    # @return double
    #
    getInstrumentHours: func() {
        return me._instrumentCounter / 3600;
    },

    #
    # Get max altitude in ft
    #
    # @return double
    #
    getMaxAlt: func() {
        return me._maxAlt;
    },
};
