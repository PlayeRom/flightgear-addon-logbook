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
# Class for check FG version.
#
var FGVersion = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [
                FGVersion,
            ],
        };

        obj._fgVersion = addons.AddonVersion.new(getprop('/sim/version/flightgear'));

        obj._usedVersions = std.Hash.new();

        return obj;
    },

    #
    # @param  string  version  Full version in format: 'major.minor.patch'.
    # @return bool
    #
    equal: func(version) me._fgVersion.equal(me._getVersionObj(version)),

    #
    # @param  string  version  Full version in format: 'major.minor.patch'.
    # @return bool
    #
    nonEqual: func(version) me._fgVersion.nonEqual(me._getVersionObj(version)),

    #
    # @param  string  version  Full version in format: 'major.minor.patch'.
    # @return bool
    #
    lowerThan: func(version) me._fgVersion.lowerThan(me._getVersionObj(version)),

    #
    # @param  string  version  Full version in format: 'major.minor.patch'.
    # @return bool
    #
    lowerThanOrEqual: func(version) me._fgVersion.lowerThanOrEqual(me._getVersionObj(version)),

    #
    # @param  string  version  Full version in format: 'major.minor.patch'.
    # @return bool
    #
    greaterThan: func(version) me._fgVersion.greaterThan(me._getVersionObj(version)),

    #
    # @param  string  version  Full version in format: 'major.minor.patch'.
    # @return bool
    #
    greaterThanOrEqual: func(version) me._fgVersion.greaterThanOrEqual(me._getVersionObj(version)),

    #
    # Convert string to addons.AddonVersion object.
    #
    # @param  string  version  Full version in format: 'major.minor.patch'.
    # @return ghost
    #
    _getVersionObj: func(version) {
        if (!me._usedVersions.contains(version)) {
            var versionObj = addons.AddonVersion.new(version);
            me._usedVersions.set(version, versionObj);
        }

        return me._usedVersions.get(version);
    },
};
