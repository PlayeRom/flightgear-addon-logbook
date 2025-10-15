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
# Class Timer for wrapping maketimer() function.
#
var Timer = {
    #
    # Run timer as single shot.
    #
    # @param  double  delaySec  Delay in seconds for execute timer's callback.
    # @param  hash  self  Optional parameter specifying what any "me" references
    #                     in the function being called will refer to.
    # @param  func  callback  Function to be called after given delay.
    # @return ghost  Return timer object.
    #
    singleShot: func(delaySec, args...) {
        var count = size(args);
        var timer = nil;

        if (count == 1) {
            timer = maketimer(delaySec, func { args[0]() });
        } elsif (count == 2) {
            timer = maketimer(delaySec, args[0], args[1]);
        }

        timer.singleShot = true;
        timer.start();

        return timer;
    },

    #
    # Create a timer object with a "self" parameter that points to the owner of the callback.
    #
    # @param  double  delaySec  Delay in seconds for execute timer's callback.
    # @param  hash  self  Optional parameter specifying what any "me" references
    #                     in the function being called will refer to.
    # @param  func  callback  Function to be called after given delay.
    # @return ghost  Return timer object.
    #
    make: func(delaySec, self, callback) {
        return maketimer(delaySec, self, callback);
    },

    #
    # Create timer object without self parameter.
    #
    # @param  double  delaySec  Delay in seconds for execute timer's callback.
    # @param  func  callback  Function to be called after given delay.
    # @return ghost  Return timer object.
    #
    makeSelf: func(delaySec, callback) {
        return maketimer(delaySec, func { callback() });
    },
};
