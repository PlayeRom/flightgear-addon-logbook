#
# CanvasSkeleton Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Wrapper for calling the callback function.
#
var Callback = {
    #
    # Constructor.
    #
    # @param  func  function  Callback function to call.
    # @param  hash|nil  owner  Owner object of function.
    # @return hash
    #
    new: func(function, owner = nil) {
        return {
            parents: [Callback],
            _function: function,
            _owner: owner,
        };
    },

    #
    # Invoke the callback function.
    #
    # @param  mixed  arg  Array of parameters.
    # @return mixed
    #
    invoke: func() {
        return call(me._function, [] ~ arg, me._owner);
    },
};
