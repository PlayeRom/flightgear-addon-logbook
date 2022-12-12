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
    new: func () {
        var me = { parents: [Environment] };

        me.dayCounter        = 0;
        me.nightCounter      = 0;
        me.instrumentCounter = 0;
        me.maxAlt            = 0.0;
        me.lastElapsedSec    = me.getElapsedSec();
        me.isReplayMode      = false;

        return me;
    },

    #
    # Get real date as string in ISO format
    #
    # return string
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
    # return string
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
    resetCounters: func() {
        me.dayCounter        = 0;
        me.nightCounter      = 0;
        me.instrumentCounter = 0;
        me.maxAlt            = 0.0;
        me.lastElapsedSec    = me.getElapsedSec();
    },

    #
    # Update all environment counters
    #
    update: func () {
        var currentElapsedSec = me.getElapsedSec();

        if (!me.isReplayMode) {
            var diffElapsedSec = currentElapsedSec - me.lastElapsedSec;

            me.isNight()
                ? (me.nightCounter += diffElapsedSec)
                : (me.dayCounter   += diffElapsedSec);

            if (me.isIMC()) {
                me.instrumentCounter += diffElapsedSec;
            }

            var alt = getprop("/position/altitude-ft");
            if (alt > me.maxAlt) {
                me.maxAlt = alt;
            }
        }

        me.lastElapsedSec = currentElapsedSec;
    },

    #
    # Return true when we have a night. It is a trick to check the color of the sky.
    #
    # return bool
    #
    isNight: func() {
        return getprop("/rendering/dome/sky/red")   < Environment.SKY_DOME_COLOR_THRESHOLD and
               getprop("/rendering/dome/sky/green") < Environment.SKY_DOME_COLOR_THRESHOLD and
               getprop("/rendering/dome/sky/blue")  < Environment.SKY_DOME_COLOR_THRESHOLD;
    },

    #
    # Return true if visibility is for IFR conditions.
    #
    # return bool
    #
    isIMC: func() {
        return getprop("/environment/ground-visibility-m")    < Environment.MINIMUM_VFR_VISIBILITY or
               getprop("/environment/effective-visibility-m") < Environment.MINIMUM_VFR_VISIBILITY;
    },

    #
    # Get flight duration in day in hours
    #
    # return double
    #
    getDayHours: func() {
        return me.dayCounter / 3600;
    },

    #
    # Get flight duration in night in hours
    #
    # return double
    #
    getNightHours: func() {
        return me.nightCounter / 3600;
    },

    #
    # Get flight duration in IMC in hours
    #
    # return double
    #
    getInstrumentHours: func() {
        return me.instrumentCounter / 3600;
    },

    #
    # Get max altitude in ft
    #
    # return double
    #
    getMaxAlt: func() {
        return me.maxAlt;
    },

    #
    # Get elapsed time in seconds in simulation.
    # The "/sim/time/elapsed-sec" property is count automatically and also paused when sim is paused.
    #
    # return double
    #
    getElapsedSec: func() {
        return getprop("/sim/time/elapsed-sec");
    },

    #
    # Set replay mode flag. If true then sim is in replay mode and the counters should not be updated.
    # The problem is that elapsed-sec in reply mode is continuing counting, so we have to handle it manually.
    #
    # bool isReplayMode
    #
    setReplayMode: func(isReplayMode) {
        me.isReplayMode = isReplayMode;
    },
};
