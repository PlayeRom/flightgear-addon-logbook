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
        me._startFuel     = 0.0; # amount of fuel at takeoff
        me._startOdometer = 0.0; # distance at takeoff
        me._onGround      = getprop("/sim/presets/onground"); # 1 - on ground, 0 - in air
        logprint(MY_LOG_LEVEL, "Logbook Add-on - init onGround = ", me._onGround);
        me._addonHintsNode = props.globals.getNode("/sim/addon-hints/Logbook");
        if (me._addonHintsNode != nil) {
            logprint(MY_LOG_LEVEL, "Logbook Add-on - init HINTS NODE = ", me._addonHintsNode.getName());
        }
        me._initAltAglFt  = Logbook.ALT_AGL_FT_THRESHOLD;
        me._isSimPaused   = false;
        me._isReplayMode  = false;

        me._wowSec        = 0;
        me._mainTimer     = maketimer(Logbook.MAIN_TIMER_INTERVAL, me, me._update);
        me._delayInit     = maketimer(2, me, me._initLogbook);

        me._logData       = nil;
        me._environment   = Environment.new();
        me._multiplayer   = Multiplayer.new();
        me._landingGear   = LandingGear.new(me._addonHintsNode);
        me._columns       = Columns.new();
        me._filters       = Filters.new();
        me._storage       = Storage.new(me._filters, me._columns);
        me._spaceShuttle  = SpaceShuttle.new();
        me._crashDetector = CrashDetector.new(me._spaceShuttle);
        me._airport       = Airport.new();

        me._recovery      = Utils.isUsingSQLite()
            ? RecoverySQLite.new(me._storage)
            : RecoveryCsv.new(me._storage);

        me._aircraft       = Aircraft.new();
        me._logbookDialog  = LogbookDialog.new(me._storage, me._filters, me._columns, me);
        me._settingsDialog = Utils.isUsingSQLite()
            ? SettingsDialogSQLite.new(me._columns, me)
            : SettingsDialogCsv.new(me._columns, me);

        me._aircraftType  = AircraftType.new().getType();
        logprint(MY_LOG_LEVEL, "Logbook Add-on - Aircraft Type = ", me._aircraftType);

        me._propAltAglFt = props.globals.getNode("/position/altitude-agl-ft");

        var runListenerOnInit = true;

        setlistener("/sim/signals/fdm-initialized", func(node) {
            # This listener will be called after first run the sim and every time after reposition the aircraft
            # (by changing the airport or start in the air in the sim) and after restart the sim
            logprint(MY_LOG_LEVEL, "Logbook Add-on - /sim/signals/fdm-initialized = ", node.getBoolValue());

            if (node.getBoolValue()) {
                # Run _initLogbook with delay to stabilize the aircraft
                # (e.g. Twin Otter on Wheels and seaplanes needs it)
                me._delayInit.singleShot = true;
                me._delayInit.start();
            }
        }, runListenerOnInit);

        setlistener("/sim/presets/onground", func(node) {
            var oldOnGround = me._onGround;
            me._onGround = node.getBoolValue(); # 1 - on ground, 0 - in air
            logprint(MY_LOG_LEVEL, "Logbook Add-on - init onGround = ", me._onGround);

            # User probably used the "Location" -> "in air" or change airport even during a flight
            if (!oldOnGround and me._onGround) {
                # I was in the air, now I'm on the ground, try to stop logging
                me._stopLogging(false);
            }

            # me._initLogbook(); # _initLogbook will be run in "/sim/signals/fdm-initialized"
        });

        setlistener("/sim/freeze/master", func(node) {
            me._isSimPaused = node.getBoolValue();
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - isSimPaused = ", me._isSimPaused);
        }, runListenerOnInit);

        setlistener("/sim/replay/replay-state", func(node) {
            me._isReplayMode = node.getBoolValue();
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - isReplayMode = ", me._isReplayMode);
        }, runListenerOnInit);

        setlistener("/sim/signals/exit", func(node) {
            if (node.getBoolValue()) {
                # sim is going to exit, save the logData
                me._stopLogging(false);
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
        me._mainTimer.stop();
        me._crashDetector.del();
        me._recovery.del();
        me._logbookDialog.del();
        me._storage.del();
        me._settingsDialog.del();
    },

    #
    # @return string - ICAO code or empty
    #
    _getStartAirport: func() {
        # Try to get nearest airport
        var maxDistance = me._spaceShuttle.isLaunched()
            ? 9000  # Max distance to 9 km, needed by Space Shuttle started from Launch Pad 39A
            : 6000; # Use max distance as 6000 m (Schiphol need 6 km)

        return me._airport.getNearestIcao(maxDistance);
    },

    #
    # Recognition that the aircraft has taken off
    #
    # @return void
    #
    _initLogbook: func() {
        me._landingGear.recognizeGears(me._onGround);

        me._initAltAglThreshold();

        if (!me._onGround and !me._spaceShuttle.isPreLaunch()) {
            # We start in air, start logging immediately
            me._startLogging();
        }

        # Start to watch WoW of gears
        me._wowSec = 0;
        me._mainTimer.start();
    },

    #
    # Initialize altitude AGL threshold
    #
    # @return void
    #
    _initAltAglThreshold: func() {
        me._initAltAglFt = me._onGround
            ? (me._propAltAglFt.getValue() + Logbook.ALT_AGL_FT_THRESHOLD)
            : Logbook.ALT_AGL_FT_THRESHOLD;
    },

    #
    # Main timer callback for recognize takeoff, landing and crash
    #
    # @return void
    #
    _update: func() {
        if (me._isSimPaused or me._isReplayMode) {
            me._crashDetector.stopGForce();
            return;
        }

        me._environment.update();
        me._multiplayer.update();

        if (me._spaceShuttle.isLiftOff()) {
            logprint(LOG_ALERT, "Logbook Add-on - SpaceShuttle liftoff detected");
            me._startLogging();
            return;
        }

        if (!me._onGround and me._propAltAglFt.getValue() > me._initAltAglFt) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - update do nothing");
            # There's nothing to check for landing, we're too high
            me._crashDetector.stopGForce();
            return;
        }

        me._crashDetector.startGForce(me._onGround);

        if (me._landingGear.checkWow(me._onGround) and !me._crashDetector.isCrash(false)) {
            if (me._onGround) {
                # Our state is on the ground and all wheels are in the air - we have take-off
                me._wowSec += 1;
                logprint(MY_LOG_LEVEL, "Logbook Add-on - takeoff detected, wowSec = ", me._wowSec);
                if (me._wowSec > 2) {
                    # We recognize that we taken off after testing WoW for 3 seconds.
                    # This is to not recognize the takeoff when we bounce off the ground.
                    me._startLogging();
                    me._wowSec = 0;
                }
            }
            else {
                # Our state is in the air and all wheels are on the ground
                me._wowSec += 1;
                logprint(MY_LOG_LEVEL, "Logbook Add-on - landing detected, wowSec = ", me._wowSec);
                if (me._wowSec > 2) {
                    # We recognize that we landed after maintaining WoW for 3 seconds.
                    # This is to not recognize the landing when we bounce off the ground.
                    me._stopLogging(true);
                    me._wowSec = 0;
                }
            }

            return;
        }

        me._wowSec = 0;

        var isLogging = me._logData != nil;
        if (isLogging and me._crashDetector.isCrashByTesting(me._onGround)) {
            me._stopLogging(false, true);
        }
    },

    #
    # Call when aircraft is in the air
    #
    # @return void
    #
    _startLogging: func() {
        if (me._logData != nil) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - _startLogging: invalid state, it's trying to run start again without stop.");
            return;
        }

        var aircraftId = me._aircraft.getAircraftId();

        if (me._aircraft.isUfo(aircraftId)) {
            # We don't log UFO, FG Video Assistant
            return;
        }

        logprint(LOG_ALERT, "Logbook Add-on - takeoff confirmed");

        me._recovery.start(me, me._recoveryCallback);

        me._logData = LogData.new();

        me._logData.setRealDate(me._environment.getRealDateString());
        me._logData.setRealTime(me._environment.getRealTimeString());

        me._logData.setSimUtcDate(me._environment.getSimUtcDateString());
        me._logData.setSimUtcTime(me._environment.getSimUtcTimeString());

        me._logData.setSimLocalDate(me._environment.getSimLocalDateString());
        me._logData.setSimLocalTime(me._environment.getSimLocalTimeString());

        me._logData.setAircraft(me._aircraft.getAircraftPrimary());
        me._logData.setVariant(aircraftId);
        me._logData.setAircraftType(me._aircraftType);
        me._logData.setNote(getprop("/sim/description"));
        me._logData.setCallsign(getprop("/sim/multiplay/callsign"));

        me._startFuel     = getprop("/consumables/fuel/total-fuel-gal_us");
        me._startOdometer = getprop("/instrumentation/gps/odometer");

        if (me._onGround or me._spaceShuttle.isLaunched()) {
            me._logData.setFrom(me._getStartAirport());
        }

        me._environment.resetCounters();
        me._multiplayer.resetCounters();

        me._onGround = false;

        me._crashDetector.startGForce(me._onGround);
    },

    #
    # Collect all information and save it to CSV file
    #
    # @param bool landed - If true then aircraft landed, otherwise the flight aborted mid-air
    # @param bool crashed - Set true when aircraft crashed
    # @return void
    #
    _stopLogging: func(landed, crashed = 0) {
        if (me._logData == nil) {
            # logprint(MY_LOG_LEVEL, "Logbook Add-on - _stopLogging: invalid state, it's trying to run stop without running start.");
            return;
        }

        me._recovery.stop();
        me._crashDetector.stopGForce();

        # Some aircraft report a correct landing despite landing on a ridge, so we do an additional crash check
        if (landed and me._crashDetector.isCrash()) {
            crashed = true; # force crash state
        }

        me._logData.setFuel(me._getFuel());
        me._logData.setDistance(me._getDistance());

        if (landed) {
            if (me._crashDetector.isOrientationOK()) {
                logprint(LOG_ALERT, "Logbook Add-on - landing confirmed");

                me._logData.setLanding();

                # Use max distance as 6000 m (Schiphol need 6 km)
                var icao = me._airport.getNearestIcao(6000);
                me._logData.setTo(icao);
            }

            # We know it's landed, so reset some states like detect the landing gear again in case it will takeoff again.
            me._onGround = true;
            me._landingGear.recognizeGears(me._onGround);
            me._initAltAglThreshold();
        }

        me._logData.setDay(me._environment.getDayHours());
        me._logData.setNight(me._environment.getNightHours());
        me._logData.setInstrument(me._environment.getInstrumentHours());
        me._logData.setMaxAlt(me._environment.getMaxAlt());

        me._logData.setMultiplayer(me._multiplayer.getMultiplayerHours());
        me._logData.setSwift(me._multiplayer.getSwiftHours());

        if (crashed) {
            logprint(LOG_ALERT, "Logbook Add-on - crash detected");
            me._logData.setCrash();

            me._onGround = true;
        }

        me._storage.saveLogData(me._logData, me._recovery.getRecordId());
        me._logData = nil;
        me._wowSec = 0;

        me._recovery.clear();

        if (me._logbookDialog.isWindowVisible()) {
            me._logbookDialog.reloadData();
        }
    },

    #
    # Get amount of fuel burned
    #
    # @return double
    #
    _getFuel: func() {
        var fuel = getprop("/consumables/fuel/total-fuel-gal_us");
        return math.abs(me._startFuel - fuel);
    },

    #
    # Take the distance flown
    #
    # @return double
    #
    _getDistance: func() {
        var odometer = getprop("/instrumentation/gps/odometer");
        return odometer - me._startOdometer;
    },

    #
    # Callback for Recovery class. Get last statistics data and put it to Recovery.
    #
    # @return void
    #
    _recoveryCallback: func() {
        var recoveryData = me._logData.getClone();

        recoveryData.setFuel(me._getFuel());
        recoveryData.setDistance(me._getDistance());
        recoveryData.setDay(me._environment.getDayHours());
        recoveryData.setNight(me._environment.getNightHours());
        recoveryData.setInstrument(me._environment.getInstrumentHours());
        recoveryData.setMaxAlt(me._environment.getMaxAlt());

        recoveryData.setMultiplayer(me._multiplayer.getMultiplayerHours());
        recoveryData.setSwift(me._multiplayer.getSwiftHours());

        me._recovery.save(recoveryData);
    },

    #
    # Show Logbook canvas dialog
    #
    # @return void
    #
    showLogbookDialog: func() {
        me._logbookDialog.show();
    },

    #
    # Show Help canvas dialog
    #
    # @return void
    #
    showHelpDialog: func() {
        me._logbookDialog.helpDialog.show();
    },

    #
    # Show About canvas dialog
    #
    # @return void
    #
    showAboutDialog: func() {
        me._logbookDialog.aboutDialog.show();
    },

    #
    # Show Settings canvas dialog
    #
    # @return void
    #
    showSettingDialog: func() {
        me._settingsDialog.show();
    },

    #
    # Export logbook from SQLite to CSV file
    #
    # @return void
    #
    exportToCsv: func() {
        me._storage.exportToCsv();
    },

    #
    # Reset Logbook dialog
    #
    # @return void
    #
    resetLogbookDialog: func() {
        me._logbookDialog.del();
        me._logbookDialog = LogbookDialog.new(me._storage, me._filters, me._columns, me);
        me.showLogbookDialog();
    },
};
