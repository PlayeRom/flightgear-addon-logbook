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
    new: func() {
        var me = { parents: [
            Multiplayer,
            BaseCounter.new(
                func()               { me._onResetCounters(); },
                func(diffElapsedSec) { me._onUpdate(diffElapsedSec); }
            ),
        ] };

        me._multiplayerCounter = 0;
        me._swiftCounter       = 0;

        me._propMultiplayer = nil;
        me._propSwift       = nil;

        return me;
    },

    #
    # Reset all counters
    #
    # @return void
    #
    _onResetCounters: func() {
        me._multiplayerCounter = 0;
        me._swiftCounter       = 0;
    },

    #
    # Update all counters
    #
    # @param  double  diffElapsedSec
    # @return void
    #
    _onUpdate: func(diffElapsedSec) {
        if (me._isMultiplayerOnline()) {
            me._multiplayerCounter += diffElapsedSec;
        }

        if (me._isSwiftOnline()) {
            me._swiftCounter += diffElapsedSec;
        }
    },

    #
    # Return true when we have connection to multiplayer serwer
    #
    # @return bool
    #
    _isMultiplayerOnline: func() {
        if (me._propMultiplayer == nil) {
            me._propMultiplayer = props.globals.getNode("/sim/multiplay/online");
        }

        return me._propMultiplayer != nil and me._propMultiplayer.getBoolValue();
    },

    #
    # Return true when we have connection to swift serwer
    #
    # @return bool
    #
    _isSwiftOnline: func() {
        if (me._propSwift == nil) {
            me._propSwift = props.globals.getNode("/sim/swift/serverRunning");
        }

        return me._propSwift != nil and me._propSwift.getBoolValue();
    },

    #
    # Get flight duration with multiplayer mode in hours
    #
    # @return double
    #
    getMultiplayerHours: func() {
        return me._multiplayerCounter / 3600;
    },

    #
    # Get flight duration with swift connection in hours
    #
    # @return double
    #
    getSwiftHours: func() {
        return me._swiftCounter / 3600;
    },
};
