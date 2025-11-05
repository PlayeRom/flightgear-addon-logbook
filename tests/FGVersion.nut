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

# Unit tests for `/nasal/Utils/FGVersion.nas`

var setUp = func {
    var namespace = globals['__addon[org.flightgear.addons.framework]__'];
};

var tearDown = func {
};

var getVersionString = func(major, minor, patch) {
    return sprintf('%d.%d.%d', major, minor, patch);
};

var test_fgVersion = func {
    var strVersion = getprop('/sim/version/flightgear');
    var parts = split('.', strVersion);
    var major = num(parts[0]);
    var minor = num(parts[1]);
    var patch = num(parts[2]);

    var fgVer = namespace.FGVersion.new();

    unitTest.assert_equal(fgVer.equal(getVersionString(major, minor, patch)), 1);

    unitTest.assert_equal(fgVer.nonEqual(getVersionString(major + 1, minor, patch)), 1);
    unitTest.assert_equal(fgVer.nonEqual(getVersionString(major, minor + 1, patch)), 1);
    unitTest.assert_equal(fgVer.nonEqual(getVersionString(major, minor, patch + 1)), 1);
    unitTest.assert_equal(fgVer.nonEqual(getVersionString(major - 1, minor, patch)), 1);
    unitTest.assert_equal(fgVer.nonEqual(getVersionString(major, minor - 1, patch)), 1);
    unitTest.assert_equal(fgVer.nonEqual(getVersionString(major, minor, patch - 1)), 1);

    unitTest.assert_equal(fgVer.lowerThan(getVersionString(major, minor, patch)), 0);
    unitTest.assert_equal(fgVer.lowerThan(getVersionString(major - 1, minor, patch)), 0);
    unitTest.assert_equal(fgVer.lowerThan(getVersionString(major, minor - 1, patch)), 0);
    unitTest.assert_equal(fgVer.lowerThan(getVersionString(major, minor, patch - 1)), 0);
    unitTest.assert_equal(fgVer.lowerThan(getVersionString(major + 1, minor, patch)), 1);
    unitTest.assert_equal(fgVer.lowerThan(getVersionString(major, minor + 1, patch)), 1);
    unitTest.assert_equal(fgVer.lowerThan(getVersionString(major, minor, patch + 1)), 1);

    unitTest.assert_equal(fgVer.lowerThanOrEqual(getVersionString(major, minor, patch)), 1);
    unitTest.assert_equal(fgVer.lowerThanOrEqual(getVersionString(major - 1, minor, patch)), 0);
    unitTest.assert_equal(fgVer.lowerThanOrEqual(getVersionString(major, minor - 1, patch)), 0);
    unitTest.assert_equal(fgVer.lowerThanOrEqual(getVersionString(major, minor, patch - 1)), 0);
    unitTest.assert_equal(fgVer.lowerThanOrEqual(getVersionString(major + 1, minor, patch)), 1);
    unitTest.assert_equal(fgVer.lowerThanOrEqual(getVersionString(major, minor + 1, patch)), 1);
    unitTest.assert_equal(fgVer.lowerThanOrEqual(getVersionString(major, minor, patch + 1)), 1);

    unitTest.assert_equal(fgVer.greaterThan(getVersionString(major, minor, patch)), 0);
    unitTest.assert_equal(fgVer.greaterThan(getVersionString(major - 1, minor, patch)), 1);
    unitTest.assert_equal(fgVer.greaterThan(getVersionString(major, minor - 1, patch)), 1);
    unitTest.assert_equal(fgVer.greaterThan(getVersionString(major, minor, patch - 1)), 1);
    unitTest.assert_equal(fgVer.greaterThan(getVersionString(major + 1, minor, patch)), 0);
    unitTest.assert_equal(fgVer.greaterThan(getVersionString(major, minor + 1, patch)), 0);
    unitTest.assert_equal(fgVer.greaterThan(getVersionString(major, minor, patch + 1)), 0);

    unitTest.assert_equal(fgVer.greaterThanOrEqual(getVersionString(major, minor, patch)), 1);
    unitTest.assert_equal(fgVer.greaterThanOrEqual(getVersionString(major - 1, minor, patch)), 1);
    unitTest.assert_equal(fgVer.greaterThanOrEqual(getVersionString(major, minor - 1, patch)), 1);
    unitTest.assert_equal(fgVer.greaterThanOrEqual(getVersionString(major, minor, patch - 1)), 1);
    unitTest.assert_equal(fgVer.greaterThanOrEqual(getVersionString(major + 1, minor, patch)), 0);
    unitTest.assert_equal(fgVer.greaterThanOrEqual(getVersionString(major, minor + 1, patch)), 0);
    unitTest.assert_equal(fgVer.greaterThanOrEqual(getVersionString(major, minor, patch + 1)), 0);
};
