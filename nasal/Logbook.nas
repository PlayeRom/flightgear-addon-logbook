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
    # @return hash
    #
    new: func {
        var obj = { parents: [Logbook] };

        # Auxiliary variables
        obj._isUsingSQLite  = Utils.isUsingSQLite();
        obj._onGround       = getprop("/sim/presets/onground"); # 1 - on ground, 0 - in air
        Log.print("init onGround = ", obj._onGround);
        obj._initAltAglFt   = Logbook.ALT_AGL_FT_THRESHOLD;
        obj._isSimPaused    = false;
        obj._isReplayMode   = false;

        obj._mainTimer      = Timer.make(Logbook.MAIN_TIMER_INTERVAL, obj, obj._update);
        obj._delayInit      = Timer.make(2, obj, obj._initLogbook);

        obj._wowSec         = 0;
        obj._logData        = nil;
        obj._environment    = Environment.new();
        obj._multiplayer    = Multiplayer.new();
        obj._flight         = Flight.new();
        obj._landingGear    = LandingGear.new();
        obj._columns        = Columns.new();
        obj._filters        = Filters.new();
        obj._storage        = Storage.new(obj._filters, obj._columns);
        obj._spaceShuttle   = SpaceShuttle.new();
        obj._crashDetector  = CrashDetector.new(obj._spaceShuttle);
        obj._airport        = Airport.new();
        obj._flightAnalysis = FlightAnalysis.new();
        obj._recovery       = Recovery.new(obj._storage);
        obj._aircraft       = Aircraft.new();
        obj._logbookDialog  = LogbookDialog.new(obj._storage, obj._filters, obj._columns, obj);
        obj._settingsDialog = SettingsDialog.new(obj._columns, obj);

        obj._aircraftPrimary = "";
        obj._aircraftId      = "";
        obj._aircraftType    = "";

        obj._isLoggingStarted = false;
        obj._firstTrackPoint = nil;

        obj._propAltAglFt = props.globals.getNode("/position/altitude-agl-ft");

        obj._listeners = Listeners.new();
        obj._setListeners();

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func {
        me._listeners.del();
        me._mainTimer.stop();
        me._crashDetector.del();
        me._recovery.del();
        me._logbookDialog.del();
        me._storage.del();
        me._spaceShuttle.del();
        me._settingsDialog.del();
        me._flightAnalysis.del();
    },

    #
    # Set listeners.
    #
    # @return void
    #
    _setListeners: func {
        me._listeners.add(
            node: "/sim/signals/fdm-initialized",
            code: func(node) {
                # This listener will be called after first run the sim and every time after reposition the aircraft
                # (by changing the airport or start in the air in the sim) and after restart the sim
                Log.print("/sim/signals/fdm-initialized = ", node.getBoolValue());

                if (node.getBoolValue()) {
                    # Run _initLogbook with delay to stabilize the aircraft
                    # (e.g. Twin Otter on Wheels and seaplanes needs it)
                    me._delayInit.singleShot = true;
                    me._delayInit.start();
                }
            },
            init: true,
        );

        me._listeners.add(
            node: "/sim/presets/onground",
            code: func(node) {
                var oldOnGround = me._onGround;
                me._onGround = node.getBoolValue(); # 1 - on ground, 0 - in air
                Log.print("init onGround by listener = ", me._onGround);

                # User probably used the "Location" -> "in air" or change airport even during a flight
                if (!oldOnGround and me._onGround) {
                    # I was in the air, now I'm on the ground, try to stop logging
                    me._stopLogging(landed: false);
                }

                # me._initLogbook(); # _initLogbook will be run in "/sim/signals/fdm-initialized"
            },
        );

        me._listeners.add(
            node: "/sim/freeze/master",
            code: func(node) {
                me._isSimPaused = node.getBoolValue();
                # Log.print("isSimPaused = ", me._isSimPaused);
            },
            init: true,
        );

        me._listeners.add(
            node: "/sim/replay/replay-state",
            code: func(node) {
                me._isReplayMode = node.getBoolValue();
                # Log.print("isReplayMode = ", me._isReplayMode);
            },
            init: true,
        );

        me._listeners.add(
            node: "/sim/signals/reinit",
            code: func(node) {
                if (node.getBoolValue()) {
                    # User restart the sim by Shift + Esc, or reposition the aircraft
                    me._stopLogging(landed: false);

                    # Stop all timers
                    me._mainTimer.stop();
                    me._recovery.stop();
                    me._flightAnalysis.stop();
                    me._crashDetector.stopGForce();
                }
            },
        );

        me._listeners.add(
            node: "/sim/signals/exit",
            code: func(node) {
                if (node.getBoolValue()) {
                    # sim is going to exit, save the logData
                    me._stopLogging(landed: false);

                    if (me._isUsingSQLite) {
                        DB.close();
                    }
                }
            },
        );
    },

    #
    # @return string  ICAO code or empty
    #
    _getStartAirport: func {
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
    _initLogbook: func {
        me._aircraftPrimary = me._aircraft.getAircraftPrimary();
        me._aircraftId      = me._aircraft.getAircraftId();
        me._aircraftType    = AircraftType.new().getType();
        Log.alert("Aircraft: primary = ", me._aircraftPrimary, ", id = ", me._aircraftId, ", type = ", me._aircraftType);

        me._landingGear.recognizeGears(me._onGround);

        me._initAltAglThreshold();

        me._flightAnalysis.start(Callback.new(me._updateFlightAnalysisData, me));

        if (!me._onGround and !me._spaceShuttle.isPreLaunch()) {
            # We start in air, start logging immediately
            me._preStartLogging();
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
    _initAltAglThreshold: func {
        me._initAltAglFt = me._onGround
            ? (me._propAltAglFt.getValue() + Logbook.ALT_AGL_FT_THRESHOLD)
            : Logbook.ALT_AGL_FT_THRESHOLD;
    },

    #
    # Main timer callback for recognize takeoff, landing and crash
    #
    # @return void
    #
    _update: func {
        if (me._isSimPaused or me._isReplayMode) {
            me._crashDetector.stopGForce();
            return;
        }

        me._environment.update();
        me._multiplayer.update();
        me._flight.update();

        me._flightAnalysis.updateIntervalSec();

        if (me._spaceShuttle.isLiftOff()) {
            Log.print("SpaceShuttle liftoff detected");
            me._preStartLogging();
            me._startLogging();
            return;
        }

        if (!me._onGround and me._propAltAglFt.getValue() > me._initAltAglFt) {
            # Log.print("update do nothing");
            # There's nothing to check for landing, we're too high
            me._crashDetector.stopGForce();
            return;
        }

        me._crashDetector.startGForce(me._onGround);

        var withOrientation = !me._aircraft.isSpaceShuttle(me._aircraftPrimary);
        if (me._landingGear.checkWow(me._onGround) and !me._crashDetector.isCrash(withOrientation)) {
            if (me._onGround) {
                # Our state is on the ground and all wheels are in the air - we have take-off
                me._wowSec += 1;
                Log.print("takeoff detected, wowSec = ", me._wowSec);

                # We probably took off
                # Create a log data and reset the counters now before we count down 3 seconds
                # to get a more accurate reading of the start time
                me._preStartLogging();

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
                Log.print("landing detected, wowSec = ", me._wowSec);
                if (me._wowSec > 2) {
                    # We recognize that we landed after maintaining WoW for 3 seconds.
                    # This is to not recognize the landing when we bounce off the ground.
                    me._stopLogging(landed: true);
                    me._wowSec = 0;
                }
            }

            return;
        }

        if (me._logData != nil and !me._isLoggingStarted) {
            # The case when we detected the takeoff and the _preStartLogging() function was called,
            # but the takeoff was not confirmed for another 3 seconds (_startLogging() was not called),
            # so we remove _logData and _firstTrackPoint
            me._cancelPreStartLogging();
        }

        me._wowSec = 0;

        if (me._isLoggingStarted and me._crashDetector.isCrashByTesting(me._onGround)) {
            me._stopLogging(landed: false, crashed: true);
        }
    },

    #
    # Run before _startLogging() to capture the moment of takeoff,
    # even if we are not sure that we have actually taken off.
    #
    # @return void
    #
    _preStartLogging: func {
        me._createLogData();

        # Set data for flight analysis as a first track point
        if (me._firstTrackPoint == nil) {
            me._firstTrackPoint = me._buildAnalysisData();
        }
    },

    #
    # @return void
    #
    _cancelPreStartLogging: func {
        me._logData = nil;
        me._firstTrackPoint = nil;
    },

    #
    # Crate LogData object for collecting log data
    #
    # @return void
    #
    _createLogData: func {
        if (me._logData != nil) {
            # Log.print("_startLogging: invalid state, it's trying to run start again without stop.");
            return;
        }

        if (me._aircraft.isUfo(me._aircraftId)) {
            # We don't log UFO, FG Video Assistant
            return;
        }

        me._logData = LogData.new();

        me._logData.setRealDate(me._environment.getRealDateString());
        me._logData.setRealTime(me._environment.getRealTimeString());

        me._logData.setSimUtcDate(me._environment.getSimUtcDateString());
        me._logData.setSimUtcTime(me._environment.getSimUtcTimeString());

        me._logData.setSimLocalDate(me._environment.getSimLocalDateString());
        me._logData.setSimLocalTime(me._environment.getSimLocalTimeString());

        me._logData.setAircraft(me._aircraftPrimary);
        me._logData.setVariant(me._aircraftId);
        me._logData.setAircraftType(me._aircraftType);
        me._logData.setNote(getprop("/sim/description"));
        me._logData.setCallsign(getprop("/sim/multiplay/callsign"));

        if (me._onGround or me._spaceShuttle.isLaunched()) {
            me._logData.setFrom(me._getStartAirport());
        }

        me._environment.resetCounters();
        me._multiplayer.resetCounters();
        me._flight.resetCounters();
    },

    #
    # Call when we are sure that aircraft is in the air
    #
    # @return void
    #
    _startLogging: func {
        if (me._aircraft.isUfo(me._aircraftId)) {
            # We don't log UFO, FG Video Assistant
            return;
        }

        me._isLoggingStarted = true;

        Log.alertSuccess("takeoff confirmed");

        me._recovery.start(Callback.new(me._recoveryCallback, me));

        if (me._logData == nil) {
            me._createLogData();
        }

        me._onGround = false;

        me._crashDetector.startGForce(me._onGround);

        # Save first recovery and flight analysis immediately
        me._recoveryCallback();

        # Save me._firstTrackPoint
        if (me._firstTrackPoint != nil) {
            var logbookId = me._recovery.getLogbookId();
            me._storage.addTrackerItem(logbookId, me._firstTrackPoint);
            me._firstTrackPoint = nil;
        }
    },

    #
    # Collect all information and save it to SQLite/CSV file
    #
    # @param  bool  landed  If true then aircraft landed, otherwise the flight aborted mid-air
    # @param  bool  crashed  Set true when aircraft crashed
    # @return void
    #
    _stopLogging: func(landed, crashed = 0) {
        if (me._logData == nil) {
            # Log.print("_stopLogging: invalid state, it's trying to run stop without running start.");
            return;
        }

        me._isLoggingStarted = false;

        me._recovery.stop();
        me._crashDetector.stopGForce();

        # Some aircraft report a correct landing despite landing on a ridge, so we do an additional crash check
        if (landed and me._crashDetector.isCrash()) {
            crashed = true; # force crash state
        }

        me._logData.setFuel(me._flight.getFuel());
        me._logData.setDistance(me._flight.getFlyDistance());

        if (landed) {
            if (me._crashDetector.isOrientationOK()) {
                Log.alertSuccess("landing confirmed");

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

        me._logData.setMultiplayer(me._multiplayer.getMultiplayerHours());
        me._logData.setSwift(me._multiplayer.getSwiftHours());

        me._logData.setMaxAlt(me._flight.getMaxAlt());
        me._logData.setMaxGroundspeedKt(me._flight.getMaxGroundspeedKt());
        me._logData.setMaxMach(me._flight.getMaxMach());

        if (crashed) {
            Log.alertSuccess("crash detected");
            me._logData.setCrash();

            me._onGround = true;
        }

        var logbookId = me._recovery.getLogbookId();

        # Save only if flight duration > 5s to prevent creating "empty" records if something go wrong.
        if (me._logData.duration > (5 / 360)) {
            me._storage.saveLogData(me._logData, logbookId);

            # Also save data to the trackers table for a given logbook record
            if (me._isUsingSQLite) {
                me._storage.addTrackerItem(logbookId, me._buildAnalysisData(me._logData));
            }
        } else {
            # Delete the record created by recovery (SQLite only)
            if (logbookId != nil) {
                me._storage.deleteLogQuiet(logbookId);
            }
        }

        me._logData = nil;
        me._wowSec = 0;

        me._recovery.clear();

        if (me._logbookDialog.isWindowVisible()) {
            me._logbookDialog.reloadData();
        }
    },

    #
    # Callback for Recovery class. Get last statistics data and put it to Recovery.
    #
    # @return void
    #
    _recoveryCallback: func {
        if (me._logData == nil) {
            return;
        }

        var recoveryData = me._logData.getClone();

        recoveryData.setFuel(me._flight.getFuel());
        recoveryData.setDistance(me._flight.getFlyDistance());
        recoveryData.setDay(me._environment.getDayHours());
        recoveryData.setNight(me._environment.getNightHours());
        recoveryData.setInstrument(me._environment.getInstrumentHours());

        recoveryData.setMultiplayer(me._multiplayer.getMultiplayerHours());
        recoveryData.setSwift(me._multiplayer.getSwiftHours());

        recoveryData.setMaxAlt(me._flight.getMaxAlt());
        recoveryData.setMaxGroundspeedKt(me._flight.getMaxGroundspeedKt());
        recoveryData.setMaxMach(me._flight.getMaxMach());

        me._recovery.save(recoveryData);
    },

    #
    # Gat data for analysis for save to DB and for current session
    #
    # @param  hash|nil  logData
    # @return hash
    #
    _buildAnalysisData: func(logData = nil) {
        var pos = geo.aircraft_position();
        var elevationMeters = geo.elevation(pos.lat(), pos.lon());
        if (elevationMeters == nil) {
            # The geo.elevation can return nil if no scenery loaded.
            elevationMeters = 0;
        }

        var timestamp = 0.0;
        var distance = 0.0;

        if (logData != nil) {
            timestamp = logData.duration;
            distance  = logData.distance;
        }
        else {
            timestamp = me._environment.getDayHours() + me._environment.getNightHours();
            distance  = me._flight.getFlyDistance();
        }

        return {
            "timestamp"    : timestamp,                        # elapsed time in sim in hours, this is set in FlightAnalysis
            "lat"          : pos.lat(),                        # aircraft position
            "lon"          : pos.lon(),                        # aircraft position
            "alt_m"        : pos.alt(),                        # aircraft altitude in meters
            "elevation_m"  : elevationMeters,                  # elevation in metres of a lat,lon point on the scenery
            "distance"     : distance,                         # distance traveled from the starting point in nautical miles
            "heading_true" : me._flight.getHeadingTrue(),      # aircraft true heading
            "heading_mag"  : me._flight.getHeadingMag(),       # aircraft magnetic heading
            "groundspeed"  : me._flight.getGroundspeedKt(),    # aircraft groundspeed in knots
            "airspeed"     : me._flight.getAirspeedKt(),       # aircraft airspeed in knots
            "pitch"        : me._flight.getPitch(),            # aircraft pitch in deg
            "wind_heading" : me._environment.getWindHeading(), # wind from heading in deg
            "wind_speed"   : me._environment.getWindSpeed(),   # wind speed in kt
        }
    },

    #
    # Collect data for flight analysis of the current session
    #
    # @return hash
    #
    _updateFlightAnalysisData: func {
        if (me._isSimPaused or me._isReplayMode) {
            # Don't save track when paused or watching replay
            return nil;
        }

        # Set data during a fly
        var data = me._buildAnalysisData();

        # Also save data to the trackers table for a given logbook record
        var logbookId = me._recovery.getLogbookId();
        me._storage.addTrackerItem(logbookId, data);

        # Set data for current session (including taxi),
        # timestamp will be set in FlightAnalysis
        data.timestamp = 0;
        data.distance = me._flight.getFullDistance();

        return data;
    },

    #
    # @param  int  logbookId  Logbook ID (SQLite) or index (CSV) to delete
    # @return bool
    #
    deleteLog: func(logbookId) {
        var deleted = me._storage.deleteLog(logbookId);
        if (deleted) {
            if (logbookId == me._recovery.getLogbookId()) {
                # If I deleted the current record, then clear the ID in recovery class
                me._recovery.clear();
            }

            return true;
        }

        return false;
    },

    #
    # Show Logbook canvas dialog
    #
    # @return void
    #
    showLogbookDialog: func {
        me._logbookDialog.show();
    },

    #
    # Show Help canvas dialog
    #
    # @return void
    #
    showHelpDialog: func {
        me._logbookDialog.helpDialog.show();
    },

    #
    # Show About canvas dialog
    #
    # @return void
    #
    showAboutDialog: func {
        me._logbookDialog.aboutDialog.show();
    },

    #
    # Show Settings canvas dialog
    #
    # @return void
    #
    showSettingDialog: func {
        me._settingsDialog.show();
    },

    #
    # Export logbook from SQLite to CSV file
    #
    # @return void
    #
    exportToCsv: func {
        me._storage.exportToCsv();
    },

    #
    # Vacuum SQLite file
    #
    # @return bool
    #
    vacuumSQLite: func {
        me._storage.vacuumSQLite();
    },

    #
    # Reset Logbook dialog
    #
    # @return void
    #
    resetLogbookDialog: func {
        me._logbookDialog.del();
        me._logbookDialog = LogbookDialog.new(me._storage, me._filters, me._columns, me);
        me.showLogbookDialog();
    },

    #
    # Open Flight Analysis dialog for current session
    #
    # @return void
    #
    showCurrentFlightAnalysisDialog: func {
        me._flightAnalysis.showDialog();
    },
};
