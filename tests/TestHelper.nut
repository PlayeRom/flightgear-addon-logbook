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
# Common test functions
#

#
# Get the namespace depending on the directory from which the test add-on is called.
#
# @return string
#
var getAddonNamespaceName = func {
    var path = caller(0)[2];
    var parts = split('/', path);
    var path = string.join('/', parts[0:-3]); # remove 'tests/file.nut'

    foreach (var addon; addons.registeredAddons()) {
        if (addon.basePath == path) {
            return addons.getNamespaceName(addon);
        }
    }

    die('Namespace not found');
};
