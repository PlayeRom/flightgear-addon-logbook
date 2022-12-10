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
# addon - Addon object
#
var main = func(addon) {
    logprint(LOG_INFO, "Logbook addon initialized from path ", addon.basePath);

    loadExtraNasalFiles(addon);

    # Create $FG_HOME/Export/Addons/org.flightgear.addons.logbook directory
    addon.createStorageDir();

    logbook.init(addon);
}

#
# Load extra Nasal files in main add-on directory
#
# addon - Addon object
#
var loadExtraNasalFiles = func (addon) {
    var modules = [
        "nasal/MouseHover",
        "nasal/Canvas/DetailsDialog",
        "nasal/Canvas/LogbookDialog",
        "nasal/Airport",
        "nasal/CrashDetector",
        "nasal/SpaceShuttle",
        "nasal/Environment",
        "nasal/LandingGear",
        "nasal/LogData",
        "nasal/File",
        "nasal/Logbook",
        "Logbook",
    ];

    foreach (var scriptName; modules) {
        var fileName = addon.basePath ~ "/" ~ scriptName ~ ".nas";

        if (io.load_nasal(fileName, "logbook")) {
            logprint(LOG_INFO, "Logbook Add-on module \"", scriptName, "\" loaded OK");
        }
    }
}

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
var unload = func(addon) {
    logprint(LOG_INFO, "Logbook addon unload");
    logbook.uninit();
}
