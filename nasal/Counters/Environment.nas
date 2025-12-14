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
    # Constants:
    #
    SUN_ANG_NIGHT_THRESHOLD: 1.57,
    MINIMUM_VFR_VISIBILITY : 5000, # in meters

    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = { parents: [
            Environment,
            BaseCounter.new(
                func               { obj._onResetCounters(); },
                func(diffElapsedSec) { obj._onUpdate(diffElapsedSec); }
            ),
        ] };

        obj._dayCounter         = 0;
        obj._nightCounter       = 0;
        obj._instrumentCounter  = 0;

        obj._propSunAngleRad    = props.globals.getNode("/sim/time/sun-angle-rad");

        obj._propGroundVisiM    = props.globals.getNode("/environment/ground-visibility-m");
        obj._propEffectiveVisiM = props.globals.getNode("/environment/effective-visibility-m");

        obj._propWindHeading    = props.globals.getNode("/environment/wind-from-heading-deg");
        obj._propWindSpeed      = props.globals.getNode("/environment/wind-speed-kt");

        obj._propRealTimeYear   = props.globals.getNode("/sim/time/real/year");
        obj._propRealTimeMonth  = props.globals.getNode("/sim/time/real/month");
        obj._propRealTimeDay    = props.globals.getNode("/sim/time/real/day");
        obj._propRealTimeHour   = props.globals.getNode("/sim/time/real/hour");
        obj._propRealTimeMinute = props.globals.getNode("/sim/time/real/minute");

        obj._propUtcTimeYear    = props.globals.getNode("/sim/time/utc/year");
        obj._propUtcTimeMonth   = props.globals.getNode("/sim/time/utc/month");
        obj._propUtcTimeDay     = props.globals.getNode("/sim/time/utc/day");
        obj._propUtcTimeHour    = props.globals.getNode("/sim/time/utc/hour");
        obj._propUtcTimeMinute  = props.globals.getNode("/sim/time/utc/minute");

        obj._propLocalTimeString = props.globals.getNode("/sim/time/local-time-string");
        obj._nodeLocalOffsetTime = props.globals.getNode("/sim/time/local-offset");

        return obj;
    },

    #
    # Get real date as string in ISO format.
    #
    # @return string
    #
    getRealDateString: func {
        return sprintf(
            "%d-%02d-%02d",
            me._propRealTimeYear.getValue(),
            me._propRealTimeMonth.getValue(),
            me._propRealTimeDay.getValue(),
        );
    },

    #
    # Get real time as string.
    #
    # @return string
    #
    getRealTimeString: func {
        return sprintf(
            "%02d:%02d",
            me._propRealTimeHour.getValue(),
            me._propRealTimeMinute.getValue(),
        );
    },

    #
    # Get sim UTC date as string in ISO format.
    #
    # @return string
    #
    getSimUtcDateString: func {
        return sprintf(
            "%d-%02d-%02d",
            me._propUtcTimeYear.getValue(),
            me._propUtcTimeMonth.getValue(),
            me._propUtcTimeDay.getValue(),
        );
    },

    #
    # Get sim UTC time as string.
    #
    # @return string
    #
    getSimUtcTimeString: func {
        return sprintf(
            "%02d:%02d",
            me._propUtcTimeHour.getValue(),
            me._propUtcTimeMinute.getValue(),
        );
    },

    #
    # Get sim local date as string in ISO format.
    #
    # @return string
    #
    getSimLocalDateString: func {
        return me._getLocalDate();
    },

    #
    # Get sim local time as string.
    #
    # @return string
    #
    getSimLocalTimeString: func {
        return utf8.substr(me._propLocalTimeString.getValue(), 0, 5);
    },

    #
    # A function that calculates the local date from a UTC date, a UTC time, and an offset in seconds.
    #
    # @return string
    #
    _getLocalDate: func {
        # Get sim UTC date
        var year  = int(me._propUtcTimeYear.getValue());
        var month = int(me._propUtcTimeMonth.getValue());
        var day   = int(me._propUtcTimeDay.getValue());

        # Get sim UTC time
        var hour   = int(me._propUtcTimeHour.getValue());
        var minute = int(me._propUtcTimeMinute.getValue());

        # Convert offset from seconds to total minutes
        var localOffset =  num(me._nodeLocalOffsetTime.getValue());
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
    # A function that returns the number of days in a given month, taking into account leap year for February.
    #
    # @param  int  year
    # @param  int  month
    # @return int
    #
    _daysInMonth: func(year, month) {
        var monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (month == 2 and ((math.mod(year, 4) == 0 and math.mod(year, 100) != 0) or math.mod(year, 400) == 0)) {
            return 29;  # February in a leap year
        }

        return monthDays[month - 1];
    },

    #
    # Reset all environment counters.
    #
    # @return void
    #
    _onResetCounters: func {
        me._dayCounter        = 0;
        me._nightCounter      = 0;
        me._instrumentCounter = 0;
    },

    #
    # Update all environment counters.
    #
    # @param  double  diffElapsedSec
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
    # Return true when we have a night. This is a trick to check the angle of the sun in the sky.
    #
    # @return bool
    #
    _isNight: func {
        return me._propSunAngleRad.getValue() > Environment.SUN_ANG_NIGHT_THRESHOLD;
    },

    #
    # Return true if visibility is for IFR conditions.
    #
    # @return bool
    #
    _isIMC: func {
        return me._propGroundVisiM.getValue()    < Environment.MINIMUM_VFR_VISIBILITY
            or me._propEffectiveVisiM.getValue() < Environment.MINIMUM_VFR_VISIBILITY;
    },

    #
    # Get flight duration in day in hours.
    #
    # @return double
    #
    getDayHours: func {
        return me._dayCounter / 3600;
    },

    #
    # Get flight duration in night in hours.
    #
    # @return double
    #
    getNightHours: func {
        return me._nightCounter / 3600;
    },

    #
    # Get flight duration in IMC in hours.
    #
    # @return double
    #
    getInstrumentHours: func {
        return me._instrumentCounter / 3600;
    },

    #
    # Get current wind heading in deg.
    #
    # @return double
    #
    getWindHeading: func {
        return me._propWindHeading.getDoubleValue();
    },

    #
    # Get current wind speed in knots.
    #
    # @return double
    #
    getWindSpeed: func {
        return me._propWindSpeed.getDoubleValue();
    },
};
