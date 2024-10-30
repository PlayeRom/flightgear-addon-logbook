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
    ALT_AGL_FT_THRESHOLD : 500,
    MAIN_TIMER_INTERVAL  : 1,

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [Logbook] };

        # Auxiliary variables
        me.startFuel     = 0.0; # amount of fuel at takeoff
        me.startOdometer = 0.0; # distance at takeoff
        me.onGround      = getprop("/sim/presets/onground"); # 1 - on ground, 0 - in air
        logprint(MY_LOG_LEVEL, "Logbook Add-on - init onGround = ", me.onGround);
        me.addonHintsNode = props.globals.getNode("/sim/addon-hints/Logbook");
        if (me.addonHintsNode != nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - init HINTS NODE = ", me.addonHintsNode.getName());
        }
        me.initAltAglFt  = Logbook.ALT_AGL_FT_THRESHOLD;
        me.isSimPaused   = false;
        me.isReplayMode  = false;

        me.wowSec        = 0;
        me.mainTimer     = maketimer(Logbook.MAIN_TIMER_INTERVAL, me, me.update);
        me.delayInit     = maketimer(2, me, me.initLogbook);

        me.logData       = nil;
        me.environment   = Environment.new();
        me.multiplayer   = Multiplayer.new();
        me.landingGear   = LandingGear.new(me.addonHintsNode);
        me.filters       = Filters.new();
        me.storage       = Storage.new(me.filters);
        me.spaceShuttle  = SpaceShuttle.new();
        me.crashDetector = CrashDetector.new(me.spaceShuttle);
        me.airport       = Airport.new();

        me.recovery      = me.storage.isStorageSQLite()
            ? RecoverySQLite.new(me.storage)
            : RecoveryCsv.new(me.storage);

        me.aircraft      = Aircraft.new();
        me.logbookDialog = LogbookDialog.new(me.storage, me.filters);

        me.aircraftType = AircraftType.new().getType();
        logprint(MY_LOG_LEVEL, "Logbook Add-on - Aircraft Type = ", me.aircraftType);

        me.propAltAglFt = props.globals.getNode("/position/altitude-agl-ft");

        var runListenerOnInit = true;

        setlistener("/sim/signals/fdm-initialized", func(node) {
            # This listener will be called after first run the sim and every time after reposition the aircraft
            # (by changing the airport or start in the air in the sim) and after restart the sim
            logprint(MY_LOG_LEVEL, "Logbook Add-on - /sim/signals/fdm-initialized = ", node.getBoolValue());

            if (node.getBoolValue()) {
                # Run initLogbook with delay to stabilize the aircraft
                # (e.g. Twin Otter on Wheels and seaplanes needs it)
                me.delayInit.singleShot = true;
                me.delayInit.start();
            }
        }, runListenerOnInit);

        setlistener("/sim/presets/onground", func(node) {
            var oldOnGround = me.onGround;
            me.onGround = node.getBoolValue(); # 1 - on ground, 0 - in air
            logprint(MY_LOG_LEVEL, "Logbook Add-on - init onGround = ", me.onGround);

            # User probably used the "Location" -> "in air" or change airport even during a flight
            if (!oldOnGround and me.onGround) {
                # I was in the air, now I'm on the ground, try to stop logging
                me.stopLogging(false);
            }

            # me.initLogbook(); # initLogbook will be run in "/sim/signals/fdm-initialized"
        });

        setlistener("/sim/freeze/master", func(node) {
            me.isSimPaused = node.getBoolValue();
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - isSimPaused = ", me.isSimPaused);
        }, runListenerOnInit);

        setlistener("/sim/replay/replay-state", func(node) {
            me.isReplayMode = node.getBoolValue();
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - isReplayMode = ", me.isReplayMode);
        }, runListenerOnInit);

        setlistener("/sim/signals/exit", func(node) {
            if (node.getBoolValue()) {
                # sim is going to exit, save the logData
                me.stopLogging(false);
            }
        });

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.mainTimer.stop();
        me.crashDetector.del();
        me.recovery.del();
        me.logbookDialog.del();
        me.storage.del();
    },

    #
    # @return string - ICAO code or empty
    #
    getStartAirport: func() {

        # Try to get nearest airport
        var maxDistance = me.spaceShuttle.isLaunched()
            ? 9000  # Max distance to 9 km, needed by Space Shuttle started from Launch Pad 39A
            : 6000; # Use max distance as 6000 m (Schiphol need 6 km)

        return me.airport.getNearestIcao(maxDistance);
    },

    #
    # Recognition that the aircraft has taken off
    #
    # @return void
    #
    initLogbook: func() {
        me.landingGear.recognizeGears(me.onGround);

        me.initAltAglThreshold();

        if (!me.onGround and !me.spaceShuttle.isPreLaunch()) {
            # We start in air, start logging immediately
            me.startLogging();
        }

        # Start to watch WoW of gears
        me.wowSec = 0;
        me.mainTimer.start();
    },

    #
    # Initialize altitude AGL threshold
    #
    # @return void
    #
    initAltAglThreshold: func() {
        me.initAltAglFt = me.onGround
            ? (me.propAltAglFt.getValue() + Logbook.ALT_AGL_FT_THRESHOLD)
            : Logbook.ALT_AGL_FT_THRESHOLD;
    },

    #
    # Main timer callback for recognize takeoff, landing and crash
    #
    # @return void
    #
    update: func() {
        if (me.isSimPaused or me.isReplayMode) {
            me.crashDetector.stopGForce();
            return;
        }

        me.environment.update();
        me.multiplayer.update();

        if (me.spaceShuttle.isLiftOff()) {
            logprint(LOG_ALERT, "Logbook Add-on - SpaceShuttle liftoff detected");
            me.startLogging();
            return;
        }

        if (!me.onGround and me.propAltAglFt.getValue() > me.initAltAglFt) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - update do nothing");
            # There's nothing to check for landing, we're too high
            me.crashDetector.stopGForce();
            return;
        }

        me.crashDetector.startGForce(me.onGround);

        if (me.landingGear.checkWow(me.onGround) and !me.crashDetector.isCrash(false)) {
            if (me.onGround) {
                # Our state is on the ground and all wheels are in the air - we have take-off
                me.wowSec += 1;
                logprint(MY_LOG_LEVEL, "Logbook Add-on - takeoff detected, wowSec = ", me.wowSec);
                if (me.wowSec > 2) {
                    # We recognize that we taken off after testing WoW for 3 seconds.
                    # This is to not recognize the takeoff when we bounce off the ground.
                    me.startLogging();
                    me.wowSec = 0;
                }
            }
            else {
                # Our state is in the air and all wheels are on the ground
                me.wowSec += 1;
                logprint(MY_LOG_LEVEL, "Logbook Add-on - landing detected, wowSec = ", me.wowSec);
                if (me.wowSec > 2) {
                    # We recognize that we landed after maintaining WoW for 3 seconds.
                    # This is to not recognize the landing when we bounce off the ground.
                    me.stopLogging(true);
                    me.wowSec = 0;
                }
            }

            return;
        }

        me.wowSec = 0;

        var isLogging = me.logData != nil;
        if (isLogging and me.crashDetector.isCrashByTesting(me.onGround)) {
            me.stopLogging(false, true);
        }
    },

    #
    # Call when aircraft is in the air
    #
    # @return void
    #
    startLogging: func() {
        if (me.logData != nil) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - startLogging: invalid state, it's trying to run start again without stop.");
            return;
        }

        var aircraftId = me.aircraft.getAircraftId();

        if (me.aircraft.isUfo(aircraftId)) {
            # We don't log UFO, FG Video Assistant
            return;
        }

        logprint(LOG_ALERT, "Logbook Add-on - takeoff confirmed");

        me.recovery.start(me, me.recoveryCallback);

        me.logData = LogData.new();
        me.logData.setDate(me.environment.getDateString());
        me.logData.setTime(me.environment.getTimeString());
        me.logData.setAircraft(me.aircraft.getAircraftPrimary());
        me.logData.setVariant(aircraftId);
        me.logData.setAircraftType(me.aircraftType);
        me.logData.setNote(getprop("/sim/description"));
        me.logData.setCallsign(getprop("/sim/multiplay/callsign"));

        me.startFuel     = getprop("/consumables/fuel/total-fuel-gal_us");
        me.startOdometer = getprop("/instrumentation/gps/odometer");

        if (me.onGround or me.spaceShuttle.isLaunched()) {
            me.logData.setFrom(me.getStartAirport());
        }

        me.environment.resetCounters();
        me.multiplayer.resetCounters();

        me.onGround = false;

        me.crashDetector.startGForce(me.onGround);
    },

    #
    # Collect all information and save it to CSV file
    #
    # @param bool landed - If true then aircraft landed, otherwise the flight aborted mid-air
    # @param bool crashed - Set true when aircraft crashed
    # @return void
    #
    stopLogging: func(landed, crashed = 0) {
        if (me.logData == nil) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - stopLogging: invalid state, it's trying to run stop without running start.");
            return;
        }

        me.recovery.stop();
        me.crashDetector.stopGForce();

        # Some aircraft report a correct landing despite landing on a ridge, so we do an additional crash check
        if (landed and me.crashDetector.isCrash()) {
            crashed = true; # force crash state
        }

        me.logData.setFuel(me.getFuel());
        me.logData.setDistance(me.getDistance());

        if (landed) {
            if (me.crashDetector.isOrientationOK()) {
                logprint(LOG_ALERT, "Logbook Add-on - landing confirmed");

                me.logData.setLanding();

                # Use max distance as 6000 m (Schiphol need 6 km)
                var icao = me.airport.getNearestIcao(6000);
                me.logData.setTo(icao);
            }

            # We know it's landed, so reset some states like detect the landing gear again in case it will takeoff again.
            me.onGround = true;
            me.landingGear.recognizeGears(me.onGround);
            me.initAltAglThreshold();
        }

        me.logData.setDay(me.environment.getDayHours());
        me.logData.setNight(me.environment.getNightHours());
        me.logData.setInstrument(me.environment.getInstrumentHours());
        me.logData.setMaxAlt(me.environment.getMaxAlt());

        me.logData.setMultiplayer(me.multiplayer.getMultiplayerHours());
        me.logData.setSwift(me.multiplayer.getSwiftHours());

        if (crashed) {
            logprint(LOG_ALERT, "Logbook Add-on - crash detected");
            me.logData.setCrash();

            me.onGround = true;
        }

        me.storage.saveLogData(me.logData, me.recovery.recordId);
        me.logData = nil;
        me.wowSec = 0;

        me.recovery.clear();

        if (me.logbookDialog.isWindowVisible()) {
            me.logbookDialog.reloadData();
        }
    },

    #
    # Get amount of fuel burned
    #
    # @return double
    #
    getFuel: func() {
        var fuel = getprop("/consumables/fuel/total-fuel-gal_us");
        return math.abs(me.startFuel - fuel);
    },

    #
    # Take the distance flown
    #
    # @return double
    #
    getDistance: func() {
        var odometer = getprop("/instrumentation/gps/odometer");
        return odometer - me.startOdometer;
    },

    #
    # Callback for Recovery class. Get last statistics data and put it to Recovery.
    #
    # @return void
    #
    recoveryCallback: func() {
        var recoveryData = me.logData.getClone();

        recoveryData.setFuel(me.getFuel());
        recoveryData.setDistance(me.getDistance());
        recoveryData.setDay(me.environment.getDayHours());
        recoveryData.setNight(me.environment.getNightHours());
        recoveryData.setInstrument(me.environment.getInstrumentHours());
        recoveryData.setMaxAlt(me.environment.getMaxAlt());

        recoveryData.setMultiplayer(me.multiplayer.getMultiplayerHours());
        recoveryData.setSwift(me.multiplayer.getSwiftHours());

        me.recovery.save(recoveryData);
    },

    #
    # Show Logbook canvas dialog
    #
    # @return void
    #
    showLogbookDialog: func() {
        me.logbookDialog.show();
    },

    #
    # Show Help canvas dialog
    #
    # @return void
    #
    showHelpDialog: func() {
        me.logbookDialog.helpDialog.show();
    },

    #
    # Show About canvas dialog
    #
    # @return void
    #
    showAboutDialog: func() {
        me.logbookDialog.aboutDialog.show();
    },
};
