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

# Unit tests for `/nasal/Utils/Listeners.nas`

var setUp = func {
    var namespace = globals['__addon[org.flightgear.addons.framework]__'];

    var nodeListen = props.globals.getNode('/addons/by-id/org.flightgear.addons.framework/dev/test-listener');
    var nodeValue  = props.globals.getNode('/addons/by-id/org.flightgear.addons.framework/dev/test-value');

    nodeListen.setValue(1);
    nodeValue.setValue(1);
};

var tearDown = func {
};

var test_listeners = func {
    var listeners = namespace.Listeners.new();

    unitTest.assert_equal(listeners.size(), 0);

    var handler = listeners.add(
        node: nodeListen,
        code: func(node) {
            nodeValue.setValue(node.getValue());
            unitTest.assert_equal(nodeValue.getValue(), 2);
        },
        # type: namespace.Listeners.ON_CHANGE_ONLY,
    );

    unitTest.assert_equal(listeners.size(), 1);

    nodeListen.setValue(2);

    listeners.clear();

    nodeListen.setValue(3);
    unitTest.assert_equal(nodeValue.getValue(), 2);
};
