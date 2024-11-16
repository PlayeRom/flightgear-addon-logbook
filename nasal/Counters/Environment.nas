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
    SUN_ANG_NIGHT_THRESHOLD  : 1.57,
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

        me._propAltFt          = props.globals.getNode("/position/altitude-ft");

        me._propSunAngleRad    = props.globals.getNode("/sim/time/sun-angle-rad");

        me._propGroundVisiM    = props.globals.getNode("/environment/ground-visibility-m");
        me._propEffectiveVisiM = props.globals.getNode("/environment/effective-visibility-m");

        return me;
    },

    #
    # Get real date as string in ISO format
    #
    # @return string
    #
    getRealDateString: func() {
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
    getRealTimeString: func() {
        return sprintf(
            "%02d:%02d",
            getprop("/sim/time/real/hour"),
            getprop("/sim/time/real/minute")
        );
    },

    #
    # Get sim UTC date as string in ISO format
    #
    # @return string
    #
    getSimUtcDateString: func() {
        var year  = getprop("/sim/time/utc/year");
        var month = getprop("/sim/time/utc/month");
        var day   = getprop("/sim/time/utc/day");

        return sprintf("%d-%02d-%02d", year, month, day);
    },

    #
    # Get sim UTC time as string
    #
    # @return string
    #
    getSimUtcTimeString: func() {
        return sprintf(
            "%02d:%02d",
            getprop("/sim/time/utc/hour"),
            getprop("/sim/time/utc/minute")
        );
    },

    #
    # Get sim local date as string in ISO format
    #
    # @return string
    #
    getSimLocalDateString: func() {
        return me._getLocalDate();
    },

    #
    # Get sim local time as string
    #
    # @return string
    #
    getSimLocalTimeString: func() {
        return utf8.substr(getprop("/sim/time/local-time-string"), 0, 5);
    },

    #
    # A function that calculates the local date from a UTC date, a UTC time, and an offset in seconds.
    #
    # @return string
    #
    _getLocalDate: func() {
        # Get sim UTC date
        var year  = int(getprop("/sim/time/utc/year"));
        var month = int(getprop("/sim/time/utc/month"));
        var day   = int(getprop("/sim/time/utc/day"));

        # Get sim UTC time
        var hour   = int(getprop("/sim/time/utc/hour"));
        var minute = int(getprop("/sim/time/utc/minute"));

        # Convert offset from seconds to total minutes
        var localOffset =  num(getprop("/sim/time/local-offset"));
        var offsetMinutes = localOffset / 60;

        # Calculate total minutes from midnight UTC, applying the local offset
        var totalMinutes = (hour * 60 + minute) + offsetMinutes;

        # Calculate new hour and minute from total minutes
        var newHour = math.floor(totalMinutes / 60);
        var newMinute = math.mod(totalMinutes, 60);

        # If newMinute is negative, adjust newHour and newMinute
        if (newMinute < 0) {
            newMinute += 60;  # Correct the negative minute value
            newHour -= 1;  # Decrease the hour
        }

        # Adjust the day based on newHour
        var dayShift = math.floor(newHour / 24);
        newHour = math.mod(newHour, 24);  # Get the correct hour in the range of 0-23

        # If newHour is negative, adjust dayShift and newHour
        if (newHour < 0) {
            newHour += 24;  # Correct the hour value
            dayShift -= 1;  # Adjust day shift
        }

        # Update the day with dayShift
        day += dayShift;

        # Normalize the date if day exceeds the days in the month
        while (day > me._daysInMonth(year, month)) {
            day -= me._daysInMonth(year, month);
            month += 1;
            if (month > 12) {
                month = 1;
                year += 1;
            }
        }

        # Normalize the date if day is less than 1
        while (day < 1) {
            month -= 1;
            if (month < 1) {
                month = 12;
                year -= 1;
            }
            day += me._daysInMonth(year, month);
        }

        # We return the local date in the format "YYYY-MM-DD" and the time in the format "HH:MM"
        # var formattedDate = sprintf("%04d-%02d-%02d", year, month, day);
        # var formattedTime = sprintf("%02d:%02d", newHour, newMinute);
        # return [formattedDate, formattedTime];

        return sprintf("%d-%02d-%02d", year, month, day);
    },

    #
    # A function that returns the number of days in a given month, taking into account leap year for February
    #
    # @param  int  year
    # @param  int  month
    # @return int
    #
    _daysInMonth: func(year, month) {
        var monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (month == 2 and ((math.fmod(year, 4) == 0 and math.fmod(year, 100) != 0) or math.fmod(year, 400) == 0)) {
            return 29;  # February in a leap year
        }

        return monthDays[month - 1];
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
    },

    #
    # Return true when we have a night. It is a trick to check the color of the sky.
    #
    # @return bool
    #
    _isNight: func() {
        return me._propSunAngleRad.getValue() > Environment.SUN_ANG_NIGHT_THRESHOLD;
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
};
