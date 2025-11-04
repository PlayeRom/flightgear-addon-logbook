#
# Framework Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Profiler class for measuring code execution time.
#
var Profiler = {
    #
    # Call stack.
    #
    _stack: std.Vector.new(),

    #
    # Start profiler.
    #
    # @param  string  message  Extra context message.
    # @return void
    #
    start: func(message = nil) {
        me._stack.append({
            message: message == nil ? '' : 'Context: ' ~ message,
            startTime: systime(),
        });
    },

    #
    # Stop profiler and log result.
    #
    # @return double  Measurement time in seconds.
    #
    stop: func {
        var count = me._stack.size();

        if (count == 0) {
            Log.print('profiler time = ? seconds. FIRST RUN start() METHOD.');
            return 0;
        }

        var item = me._stack.pop(count - 1);

        var time = systime() - item.startTime;

        Log.print('profiler time = ', (time * 1000), ' ms. ', item.message);

        return time;
    },

    #
    # Clear all call stack.
    #
    # @return void
    #
    clear: func {
        me._stack.clear();
    },
};
