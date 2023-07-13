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

        me.samples = {
            'paper' : props.Node.new({
                # path   : getprop('/sim/fg-root') ~ '/Sounds', # <- Unfortunately, reading from $FG_ROOT does not work
                path   : addon.basePath ~ '/FGData/Sounds',
                file   : 'paper.wav',
                volume : 1.0,
                queue  : 'instant',
            }),
            'delete' : props.Node.new({
                path   : addon.basePath ~ '/FGData/Sounds',
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
