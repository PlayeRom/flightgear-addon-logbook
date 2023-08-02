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
# Multiplayer class for handle flight duration in multiplayer mode.
#
var Multiplayer = {
    #
    # Constructor
    #
    # @return me
    #
    new: func () {
        var me = { parents: [
            Multiplayer,
            BaseCounter.new(
                func()               { me.onResetCounters(); },
                func(diffElapsedSec) { me.onUpdate(diffElapsedSec); }
            ),
        ] };

        me.multiplayerCounter = 0;
        me.swiftCounter       = 0;

        me.propMultiplayer = nil;
        me.propSwift       = nil;

        return me;
    },

    #
    # Reset all counters
    #
    # @return void
    #
    onResetCounters: func() {
        me.multiplayerCounter = 0;
        me.swiftCounter       = 0;
    },

    #
    # Update all counters
    #
    # @param double diffElapsedSec
    # @return void
    #
    onUpdate: func (diffElapsedSec) {
        if (me.isMultiplayerOnline()) {
            me.multiplayerCounter += diffElapsedSec;
        }

        if (me.isSwiftOnline()) {
            me.swiftCounter += diffElapsedSec;
        }
    },

    #
    # Return true when we have connection to multiplayer serwer
    #
    # @return bool
    #
    isMultiplayerOnline: func() {
        if (me.propMultiplayer == nil) {
            me.propMultiplayer = props.globals.getNode("/sim/multiplay/online");
        }

        return me.propMultiplayer != nil and me.propMultiplayer.getBoolValue();
    },

    #
    # Return true when we have connection to swift serwer
    #
    # @return bool
    #
    isSwiftOnline: func() {
        if (me.propSwift == nil) {
            me.propSwift = props.globals.getNode("/sim/swift/serverRunning");
        }

        return me.propSwift != nil and me.propSwift.getBoolValue();
    },

    #
    # Get flight duration with multiplayer mode in hours
    #
    # @return double
    #
    getMultiplayerHours: func() {
        return me.multiplayerCounter / 3600;
    },

    #
    # Get flight duration with swift connection in hours
    #
    # @return double
    #
    getSwiftHours: func() {
        return me.swiftCounter / 3600;
    },
};
