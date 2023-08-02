#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Main Nasal function
#
# @param hash addon - addons.Addon object
# @return void
#
var main = func(addon) {
    logprint(LOG_INFO, "Logbook addon initialized from path ", addon.basePath);

    loadExtraNasalFiles(addon);

    # Create $FG_HOME/Export/Addons/org.flightgear.addons.logbook directory
    addon.createStorageDir();

    logbook.init(addon);
};

#
# Load extra Nasal files in main add-on directory
#
# @param hash addon - addons.Addon object
# @return void
#
var loadExtraNasalFiles = func(addon) {
    var modules = [
        "nasal/File", # Must be before LogbookDialog
        "nasal/Canvas/InputDialog",
        "nasal/Canvas/ConfirmationDialog",
        "nasal/Canvas/Dialog",
        "nasal/Canvas/AboutDialog",
        "nasal/Canvas/DetailsDialog",
        "nasal/Canvas/HelpDialog",
        "nasal/Canvas/LogbookDialog",
        "nasal/Canvas/FilterSelector", # Must be after LogbookDialog
        "nasal/Aircraft",
        "nasal/AircraftType",
        "nasal/Airport",
        "nasal/CrashDetector",
        "nasal/BaseCounter",
        "nasal/Environment",
        "nasal/Multiplayer",
        "nasal/FileMigration",
        "nasal/FilterData",
        "nasal/Filters",
        "nasal/LandingGear",
        "nasal/LogData",
        "nasal/Logbook",
        "nasal/Recovery",
        "nasal/Settings",
        "nasal/SpaceShuttle",
        "nasal/Thread",
        "nasal/Sound",
    ];

    if (!isFGNextVersion()) {
        # Nasal in next version is support `true` and `false` keywords but previous FG versions not,
        # so for them add Boolean.nas file
        append(modules, "Boolean");
    }

    # Boolean.nas must be before Logbook.nas
    append(modules, "Logbook");

    loadVectorOfModules(addon, modules, "logbook");

    # Add widgets to canvas namespace
    var widgets = [
        "nasal/Canvas/Widgets/ListView",
        "nasal/Canvas/Widgets/Styles/DefaultStyle",
    ];

    loadVectorOfModules(addon, widgets, "canvas");
};

#
# @return bool Return true if running on FG version 2020.4 (next branch)
#
var isFGNextVersion = func() {
    var fgversion = getprop("/sim/version/flightgear");
    var (major, minor, patch) = split(".", fgversion);
    return major >= 2020 and minor >= 4;
}

#
# @param hash addon - addons.Addon object
# @param vector modules
# @param string namespace
# @return void
#
var loadVectorOfModules = func(addon, modules, namespace) {
    foreach (var scriptName; modules) {
        var fileName = addon.basePath ~ "/" ~ scriptName ~ ".nas";

        if (!io.load_nasal(fileName, namespace)) {
            logprint(LOG_ALERT, "Logbook Add-on module \"", scriptName, "\" loading failed");
        }
    }
};

#
# This function is for addon development only. It is called on addon reload.
# The addons system will replace setlistener() and maketimer() to track this
# resources automatically for you.
#
# Listeners created with setlistener() will be removed automatically for you.
# Timers created with maketimer() will have their stop() method called
# automatically for you. You should NOT use settimer anymore, see wiki at
# http://wiki.flightgear.org/Nasal_library#maketimer.28.29
#
# Other resources should be freed by adding the corresponding code here,
# e.g. myCanvas.del();
#
# @param hash addon - addons.Addon object
# @return void
#
var unload = func(addon) {
    logprint(LOG_INFO, "Logbook addon unload");
    logbook.uninit();
};
