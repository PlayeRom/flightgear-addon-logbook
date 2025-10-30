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

# Unit tests for `/nasal/Utils/Utils.nas`

io.include('TestHelper.nut');

var setUp = func {
    # Get add-on namespace:
    var namespace = globals[getAddonNamespaceName()];
};

var tearDown = func {
};

var test_urlEncode = func {
    if (!defined('namespace')) {
        unitTest.assert(0);
        return;
    }

    unitTest.assert_equal(namespace.Utils.urlEncode('HelloWorld'), 'HelloWorld');
    unitTest.assert_equal(namespace.Utils.urlEncode('Hello World'), 'Hello%20World');
    unitTest.assert_equal(namespace.Utils.urlEncode('a+b=c'), 'a%2Bb%3Dc');
    unitTest.assert_equal(namespace.Utils.urlEncode('~_.-'), '~_.-');
    unitTest.assert_equal(namespace.Utils.urlEncode('AZaz09'), 'AZaz09');
    unitTest.assert_equal(namespace.Utils.urlEncode('ą'), '%C4%85'); # UTF8, 2 bytes
    unitTest.assert_equal(namespace.Utils.urlEncode('%'), '%25');
    unitTest.assert_equal(namespace.Utils.urlEncode(''), '');
    unitTest.assert_equal(namespace.Utils.urlEncode("A\nB\tC"), 'A%0AB%09C'); # end line and tab
    unitTest.assert_equal(namespace.Utils.urlEncode('Email: a+b@c.com'), 'Email%3A%20a%2Bb%40c.com'); # mixed
};

var test_tryCatch = func {
    if (!defined('namespace')) {
        unitTest.assert(0);
        return;
    }

    var result = namespace.Utils.tryCatch(func typeof(noneExistObject));
    unitTest.assert_equal(result, 0);

    var testFunc = func(pow) {
        return pow * pow;
    };
    var result = namespace.Utils.tryCatch(testFunc, [2]);
    unitTest.assert_equal(result, 1);
};
