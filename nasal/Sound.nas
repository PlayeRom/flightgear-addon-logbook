#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2023 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Sound class
#
var Sound = {
    #
    # Constructor
    #
    # @param hash addon - addons.Addon object
    # @return me
    #
    new: func (addon) {
        var me = { parents: [Sound] };

        # Unfortunately, reading wav from $FG_ROOT does not work:
        # getprop('/sim/fg-root') ~ '/Sounds',
        # Read sounds from addon path:
        var addonSoundsPath = addon.basePath ~ '/FGData/Sounds';

        me.samples = {
            'paper' : props.Node.new({
                path   : addonSoundsPath,
                file   : 'paper.wav',
                volume : 1.0,
                queue  : 'instant',
            }),
            'delete' : props.Node.new({
                path   : addonSoundsPath,
                file   : 'delete.wav',
                volume : 0.8,
                queue  : 'instant',
            }),
        };

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
    },

    #
    # Play given sample
    #
    # @param string sampleName
    # @return bool
    #
    play: func(sampleName) {
        if (!g_Settings.isSoundEnabled()) {
            return false;
        }

        return fgcommand('play-audio-sample', me.samples[sampleName]);
    },
};
