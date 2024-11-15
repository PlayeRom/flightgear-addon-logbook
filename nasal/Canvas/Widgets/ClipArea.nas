#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# ClipArea widget model
#
gui.widgets.ClipArea = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.ClipArea);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "clip-area", me._cfg));

        return me;
    },

    #
    # Return the content object as a drawable area
    #
    # @return ghost
    #
    getContent: func() {
        return me._view.content;
    },
};
