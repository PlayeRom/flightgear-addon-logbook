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

# Unit tests for `/nasal/Utils/Callback.nas`

var setUp = func {
    var namespace = globals['__addon[org.flightgear.addons.framework]__'];
};

var tearDown = func {
};

var test_callbackByClassMethod = func {
    var Class = {
        new: func {
            return { parents: [Class] };
        },

        _pow: func(number) {
            return number * number;
        },
    };

    var class = Class.new();

    var cb = namespace.Callback.new(class._pow, class);
    var result = cb.invoke(4);

    unitTest.assert_equal(result, 16);
};

var test_callbackByClosure = func {
    var pow = func(number) {
        return number * number;
    };

    var cb = namespace.Callback.new(pow);
    var result = cb.invoke(4);

    unitTest.assert_equal(result, 16);
};
