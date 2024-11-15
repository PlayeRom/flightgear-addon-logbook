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
# ClipArea widget view
#
DefaultStyle.widgets["clip-area"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "clip-area");

        me.content = me._root.createChild("group", "clip-content")
            .set("clip-frame", Element.PARENT);
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  MapView model
    # @param  int w, h  Width and height of widget
    # @return me
    #
    setSize: func(model, w, h) {
        return me;
    },

    #
    # @param  ghost  model  Area model
    # @return void
    #
    update: func(model) {
        me.content.set(
            "clip",
            "rect(0, " ~ model._size[0] ~ ", " ~ model._size[1] ~ ", 0)"
        );
    },
};

