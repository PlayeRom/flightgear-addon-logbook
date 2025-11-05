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

# Unit tests for `/nasal/Utils/Message.nas`

var setUp = func {
    var namespace = globals['__addon[org.flightgear.addons.framework]__'];
};

var tearDown = func {
};

var test_messageSuccess = func {
    var msg = 'Message success';
    namespace.Message.success(msg);
    unitTest.assert_equal(getprop('/sim/sound/voices/ai-plane'), msg);
};

var test_messageError = func {
    var msg = 'Message error';
    namespace.Message.error(msg);
    unitTest.assert_equal(getprop('/sim/sound/voices/ai-plane'), msg);
};
