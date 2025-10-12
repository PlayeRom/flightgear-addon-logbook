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
# Class LandingGear
#
var LandingGear = {
    #
    # Constants
    #
    GEAR_FLOATS : "floats",

    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var obj = { parents: [LandingGear] };

        obj._gearIndexes = std.Vector.new();

        # Used to count seconds during landing without landing gear recognition
        obj._landingCountSec = 0;
        obj._landingAmount = 0;

        obj._addonHintsNode = props.globals.getNode(g_Addon.node.getPath() ~ "/hints");

        return obj;
    },

    #
    # Recognize and count landing gears if possible
    #
    # @param  bool  onGround  If true then aircraft start on the ground, otherwise in air
    # @return int  Number of found wheels/landing gears
    #
    recognizeGears: func(onGround) {
        me._resetLandingWithNoGearRecognized();

        me._gearIndexes.clear();

        if (!me._recognizeGearsByAddonHints()) {
            # Gears not loaded from hints, try to find gears by "/gear/gear[n]/wow" or float

            if (onGround) {
                # We are on the ground, so we can count the gears from "/gear/gear[n]/wow" property
                me._loopThroughGears(func(index) {
                    Log.alert("recognizeGears: landing gear found at index = ", index);
                    me._gearIndexes.append(index);
                });

                if (me._gearIndexes.size() == 0) {
                    # No landing gear found, check floats
                    if (me._isFloatsDragOnWater()) {
                        Log.alert("recognizeGears: floats detected");
                        me._gearIndexes.append(LandingGear.GEAR_FLOATS);
                    }
                }
            }
        }

        return me._gearIndexes.size();
    },

    #
    # Recognize and count landing gears by addon hints. The hints should be specify in the following way:
    # <addons>
    #     <by-id>
    #         <org.flightgear.addons.logbook>
    #             <hints>
    #                 <landing-gear-idx type="int">12</landing-gear-idx>
    #                 <landing-gear-idx type="int">13</landing-gear-idx>
    #             </hints>
    #         </org.flightgear.addons.logbook>
    #     </by-id>
    # </addons>
    #
    # @return bool  Return true if gears have been loaded from the hints
    #
    _recognizeGearsByAddonHints: func() {
        if (me._addonHintsNode != nil) {
            # We use landing-gear hints directly from the model.
            foreach (var landingGearIdx; me._addonHintsNode.getChildren("landing-gear-idx")) {
                var value = landingGearIdx.getValue();
                if (value != nil) {
                    Log.alert("recognize landing gear by hints at index = ", value);
                    me._gearIndexes.append(value);
                }
            }

            if (me._gearIndexes.size()) {
                # at least one gear hint was found
                return true;
            }

            Log.alert("hints node present, but no landing gear hints detected");
        }

        return false;
    },

    #
    # Check the WoW state of all landing gears
    #
    # @param  bool  onGround
    # @return bool
    #
    checkWow: func(onGround) {
        var counters = {
            'onGroundGearCounter' : 0,
            'inAirGearCounter'    : 0,
            'expectedCount'       : me._gearIndexes.size(),
        };

        if (counters.expectedCount > 0) {
            # We know we have some landing gears
            counters = me._checkWowWithGearRecognized(counters, onGround);
        } elsif (!onGround) {
            # We know nothing about landing gears, try check all of them, it make sense for landing only
            counters = me._checkWowWithNoGearRecognized(counters);
        }

        if (counters.inAirGearCounter == 0 and counters.onGroundGearCounter == 0) {
            # Nothing detected
            return false;
        }

        return onGround
            ? (counters.expectedCount == counters.inAirGearCounter) # all wheels are in the air - takeoff
            : (counters.expectedCount == counters.onGroundGearCounter); # all wheels are on the ground - landing
    },

    #
    # Check Wow with gear recognized.
    #
    # @param  hash  counters
    # @param  bool  onGround
    # @return hash
    #
    _checkWowWithGearRecognized: func(counters, onGround) {
        foreach (var index; me._gearIndexes.vector) {
            if (index == LandingGear.GEAR_FLOATS) {
                # Check whether gear down
                if (!onGround and getprop("/controls/gear/gear-down")) {
                    # Probably the amphibian took off on floats and it's now landing on wheels
                    counters = me._checkWowWithNoGearRecognized(counters);
                }
                else {
                    # Probably using floats
                    me._isFloatsDragOnWater()
                        ? (counters.onGroundGearCounter += 1)
                        : (counters.inAirGearCounter += 1);
                }
            }
            else {
                # Log.print("checkWow index = ", index);
                getprop("/gear/gear[" ~ index ~ "]/wow")
                    ? (counters.onGroundGearCounter += 1)
                    : (counters.inAirGearCounter += 1);

                if (me._isMD11CenterGearUp() and counters.expectedCount == 4) {
                    # Reduce expectedCount because we taken off with 4 wheels,
                    # but now center gear is up, so we will use 3 wheels.
                    counters.expectedCount -= 1;
                }
            }
        }

        if (!onGround and counters.onGroundGearCounter == 0 and counters.inAirGearCounter == 0) {
            # A case where an amphibian took off on wheels and now might want to land on water

            if (me._isFloatsDragOnWater()) {
                # Force water landing confirmation
                counters.onGroundGearCounter = 1;
                counters.expectedCount = 1;
            }
        }

        return counters;
    },

    #
    # Try to check WoW with NO gear recognized by check all of them. It make sense for landing only.
    #
    # @param  hash  counters
    # @return hash
    #
    _checkWowWithNoGearRecognized: func(counters) {
        me._loopThroughGears(func {
            counters.onGroundGearCounter += 1;
        });

        if (counters.onGroundGearCounter > 0) {
            # We know how many wheels we put on the ground, but we don't know how many there should be!
            # We can assume that if it keeps returning the same number for x seconds, we've landed.
            if (me._landingCountSec > 2) {
                # We assume we have landed
                counters.expectedCount = counters.onGroundGearCounter;
            }
            else {
                if (me._landingAmount == counters.onGroundGearCounter) {
                    me._landingCountSec += 1;
                }
                else {
                    me._landingAmount = counters.onGroundGearCounter;
                    me._landingCountSec = 0;
                }
            }
        }
        else {
            me._resetLandingWithNoGearRecognized();

            # Maybe floats?
            if (me._isFloatsDragOnWater()) {
                # We have landing on floats
                counters.onGroundGearCounter = 1;
                counters.expectedCount = 1;
            }
        }

        return counters;
    },

    #
    # Check if the airplane has water drag on the floats (JSBSim only).
    #
    # @return bool  Return true if drag force detected.
    #
    _isFloatsDragOnWater: func() {
        var fDragLbs = getprop("/fdm/jsbsim/hydro/fdrag-lbs");
        return fDragLbs != nil and fDragLbs > 0;
    },

    #
    # @return void
    #
    _resetLandingWithNoGearRecognized: func() {
        me._landingAmount = 0;
        me._landingCountSec = 0;
    },

    #
    # Loop through all gears properties
    #
    # @param  func  callback  Function that will be called with the gear index of which WoW is true.
    # @return void
    #
    _loopThroughGears: func(callback) {
        foreach (var gear; props.globals.getNode("/gear").getChildren("gear")) {
            var wow = gear.getChild("wow");
            if (wow != nil and wow.getValue()) {
                callback(gear.getIndex());
            }
        }
    },

    #
    # MD-11 is take off on 4 gears but can landing on 3 gears when `center-gear-up` is enabled.
    #
    # @return bool  Return true when center gear up is blocked and we will land on 3 gears.
    #
    _isMD11CenterGearUp: func() {
        return getprop("/controls/gear/center-gear-up") or false;
    },
};
