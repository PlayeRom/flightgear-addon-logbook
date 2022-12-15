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
# Class Logbook
#
var Logbook = {
    #
    # Constants
    #
    ALT_AGL_FT_THRESHOLD : 100,

    #
    # Constructor
    #
    # hash addon - addons.Addon object
    # return me
    #
    new: func(addon) {
        var me = { parents: [Logbook] };

        me.addonNodePath = addon.node.getPath();

        # Auxiliary variables
        me.startFuel     = 0.0; # amount of fuel at takeoff
        me.startOdometer = 0.0; # distance at takeoff
        me.onGround      = getprop("/sim/presets/onground"); # 1 - on ground, 0 - in air
        logprint(MY_LOG_LEVEL, "Logbook Add-on - init onGround = ", me.onGround);
        me.initAltAglFt  = Logbook.ALT_AGL_FT_THRESHOLD;
        me.isSimPaused   = false;
        me.isReplayMode  = false;

        me.wowSec        = 0;
        me.mainTimer     = maketimer(1, me, me.update);
        me.delayInit     = maketimer(5, me, me.initLogbook);

        me.logData       = nil;
        me.environment   = Environment.new();
        me.landingGear   = LandingGear.new();
        me.file          = File.new(addon);
        me.spaceShuttle  = SpaceShuttle.new();
        me.crashDetector = CrashDetector.new(me.spaceShuttle);
        me.airport       = Airport.new();
        me.logbookDialog = LogbookDialog.new(me.file);

        me.aircraftType = AircraftType.new().getType();
        logprint(MY_LOG_LEVEL, "Logbook Add-on - Aircraft Type = ", me.aircraftType);

        setlistener("/sim/presets/airport-id", func(node) {
            me.initStartAirport();
        }, true);

        setlistener("/sim/presets/onground", func(node) {
            var oldOnGround = me.onGround;
            me.onGround = node.getValue(); # 1 - on ground, 0 - in air
            logprint(MY_LOG_LEVEL, "Logbook Add-on - init onGround = ", me.onGround);

            # User probably used the "Location" -> "in air" or change airport even during a flight
            if (!oldOnGround and me.onGround) {
                # I was in the air, now I'm in the ground, try to stop logging
                me.stopLogging(false);
            }

            me.initLogbook();
        });

        setlistener("/sim/freeze/master", func(node) {
            me.isSimPaused = node.getValue();
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - isSimPaused = ", me.isSimPaused);
        });

        setlistener("/sim/replay/replay-state", func(node) {
            me.isReplayMode = node.getValue();
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - isReplayMode = ", me.isReplayMode);
        });

        setlistener("/sim/signals/exit", func(node) {
            if (node.getValue()) {
                # sim is going to exit, save the logData
                me.stopLogging(false);
            }
        });

        me.isInitialized = false;
        me.fdmInit = me.fdmInitialized();

        return me;
    },

    #
    # Uninitialize Logbook module
    #
    # return void
    #
    del: func() {
        me.mainTimer.stop();
        me.logbookDialog.del();
    },

    #
    # Initialize logbook after FDM initialized
    #
    # return void
    #
    fdmInitialized: func() {
        return setlistener(
            "/sim/signals/fdm-initialized",
            func(node) {
                if (me.isInitialized) {
                    # We don't need this listener any more
                    removelistener(me.fdmInit);
                } else if (node.getValue()) {
                    # Run initLogbook with 5 sec delay to stabilize the aircraft
                    me.delayInit.singleShot = true;
                    me.delayInit.start();
                }
            },
            true # call directly on initialize because we may already have FDM initialized before the add-on starts
        );
    },

    #
    # return void
    #
    initStartAirport: func() {
        me.startAirportIcao = getprop("/sim/presets/airport-id");

        # Note: when user will use --lat, --lon then startAirportIcao is an empty string,
        # try to get nearest airport for space shuttle only
        if (me.spaceShuttle.isPreLaunch() and (me.startAirportIcao == nil or me.startAirportIcao == "")) {
            # Max distance to 9 km, neede by Space Shuttle startd from Launch Pad 39A
            me.startAirportIcao = me.airport.getNearestIcao(9000);
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - init startAirportIcao changed to nearest = ", me.startAirportIcao);
        }

        # logprint(MY_LOG_LEVEL, "Logbook Add-on - init startAirportIcao = ", me.startAirportIcao);
    },

    #
    # Recognition that the aircraft has taken off
    #
    # return void
    #
    initLogbook: func() {
        # logprint(MY_LOG_LEVEL, "Logbook Add-on - initLogbook <------------------------------------------");
        me.landingGear.recognizeGears(me.onGround);

        me.initAltAglThreshold();

        if (!me.onGround and !me.spaceShuttle.isPreLaunch()) {
            # We start in air, start logging immediatly
            me.startLogging();
        }

        # Start to watch WoW of gears
        me.wowSec = 0;
        me.mainTimer.start();

        me.isInitialized = true;
    },

    #
    # Initialize alitutde AGL threshold
    #
    # return void
    #
    initAltAglThreshold: func() {
        me.initAltAglFt = me.onGround
            ? (getprop("/position/altitude-agl-ft") + Logbook.ALT_AGL_FT_THRESHOLD)
            : Logbook.ALT_AGL_FT_THRESHOLD;
    },

    #
    # Main timer callback for recognize takeoff, landing and crash
    #
    # return void
    #
    update: func() {
        if (me.isSimPaused or me.isReplayMode) {
            return;
        }

        me.environment.update();

        if (me.spaceShuttle.isLiftOff()) {
            logprint(LOG_ALERT, "Logbook Add-on - SpaceShuttle liftoff detected");
            me.startLogging();
            return;
        }

        if (!me.onGround and getprop("/position/altitude-agl-ft") > me.initAltAglFt) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - update do nothing");
            # There's nothing to check for landing, we're too high
            return;
        }

        if (me.landingGear.checkWow(me.onGround)) {
            if (me.onGround) {
                # Our state is on the ground and all wheels are in the air - we have takte-off
                logprint(LOG_ALERT, "Logbook Add-on - takeoff detected");

                me.startLogging();
            }
            else {
                # Our state is in the air and all wheels are on the ground
                me.wowSec += 1;
                logprint(MY_LOG_LEVEL, "Logbook Add-on - landing detected, wowSec = ", me.wowSec);
                if (me.wowSec > 2) {
                    logprint(LOG_ALERT, "Logbook Add-on - landing confirmed");

                    # We recognise that we landed after maintaining WoW for 3 seconds.
                    # This is to not recognise the landing when we bounce off the ground.
                    me.stopLogging(true);
                }
            }

            return;
        }

        me.wowSec = 0;

        if (me.crashDetector.isCrash(me.onGround)) {
            logprint(LOG_ALERT, "Logbook Add-on - crash detected");
            me.stopLogging(false, true);
        }
    },

    #
    # Call when aircraft is in the air
    #
    # return void
    #
    startLogging: func() {
        if (me.logData != nil) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - startLogging: invalid state, it's trying to run start again without stop.");
            return;
        }

        me.logData = LogData.new();
        me.logData.setDate(me.environment.getDateString());
        me.logData.setTime(me.environment.getTimeString());
        me.logData.setAircraft(getprop("/sim/aircraft-id"));
        me.logData.setAircraftType(me.aircraftType);
        me.logData.setNote(getprop("/sim/description"));
        me.logData.setCallsign(getprop("/sim/multiplay/callsign"));

        me.startFuel     = getprop("/consumables/fuel/total-fuel-gal_us");
        me.startOdometer = getprop("/instrumentation/gps/odometer");

        if (me.onGround or me.spaceShuttle.isLaunched()) {
            me.logData.setFrom(me.startAirportIcao);
        }

        me.environment.resetCounters();

        me.onGround = false;
    },

    #
    # Collect all information and save it to CSV file
    #
    # bool landed - If true then aircraft landed, otherwise the flight aborted mid-air
    # bool crashed - Set true when aircraft crashed
    # return void
    #
    stopLogging: func(landed, crashed = 0) {
        if (me.logData == nil) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - stopLogging: invalid state, it's trying to run stop without running start.");
            return;
        }

        # Some aircrafts report a correct landing despite landing on a ridge, so we do an additional orientation check
        var isOrientationOk = me.crashDetector.isOrientationOK();
        if ((landed and !isOrientationOk) or me.spaceShuttle.isCrashed()) {
            crashed = 1; # force crash state
        }

        var fuel = getprop("/consumables/fuel/total-fuel-gal_us");
        me.logData.setFuel(math.abs(me.startFuel - fuel));

        var odometer = getprop("/instrumentation/gps/odometer");
        me.logData.setDistance(odometer - me.startOdometer);

        if (landed) {
            if (isOrientationOk) {
                me.logData.setLanding();
                # Use max distance as 6000 m (Schiphol need 6 km)
                var icao = me.airport.getNearestIcao(6000);
                me.logData.setTo(icao);
            }

            # We know it's landed, so reset some states like detect the landing gear again in case it will takeoff again.
            me.onGround = true;
            me.landingGear.recognizeGears(me.onGround);
            me.initAltAglThreshold();
            me.startAirportIcao = icao; # Set a new potential airport to next take off
        }

        me.logData.setDay(me.environment.getDayHours());
        me.logData.setNight(me.environment.getNightHours());
        me.logData.setInstrument(me.environment.getInstrumentHours());
        me.logData.setMaxAlt(me.environment.getMaxAlt());

        if (crashed) {
            me.logData.setCrash();
        }

        me.file.saveData(me.logData);
        me.logData = nil;
        me.wowSec = 0;
    },

    #
    # Show Logbook canvas dialog
    #
    # return void
    #
    showLogbookDialog: func() {
        me.logbookDialog.show();
    },

    #
    # Show Help canvas dialog
    #
    # return void
    #
    showHelpDialog: func() {
        me.logbookDialog.helpDialog.show();
    },

    #
    # Show About canvas dialog
    #
    # return void
    #
    showAboutDialog: func() {
        me.logbookDialog.aboutDialog.show();
    },
};
