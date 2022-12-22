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
# ListView widget Model
#
gui.widgets.ListView = {
    #
    # Constructor
    #
    # @param hash parent
    # @param hash style
    # @param hash cfg
    # @return me
    #
    new: func(parent, style, cfg) {
        var me = gui.Widget.new(gui.widgets.ListView);
        me._cfg = Config.new(cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "ListView", me._cfg));

        me.title = nil;
        me.items = [];
        me.callbackContext = nil;
        me.callback = func;

        return me;
    },

    #
    # Set title as non clickable description text on the top
    #
    # @param string text
    # @return me
    #
    setTitle: func(text) {
        me.title = text;
        me._view.setTitle(me, text);
        return me;
    },

    #
    # @param vector items
    # @param hash callbackContext - The click callback context
    # @param func callback - The click callback with int parameter as clicked item index
    # @return me
    #
    setItems: func(items, callbackContext, callback) {
        me.items = items;
        me.callbackContext = callbackContext;
        me.callback = callback;

        me._view.reDrawItems(me);

        return me;
    },

    #
    # @param vector color
    # @return me
    #
    setTextColor: func(color) {
        me._view.setTextColor(me, color);
        return me;
    },

    #
    # @param vector color
    # @return me
    #
    setBackgroundColor: func(color) {
        me._view.setBackgroundColor(me, color);
        return me;
    },

    #
    # @param vector color
    # @return me
    #
    setHoverBackgroundColor: func(color) {
        me._view.setHoverBackgroundColor(me, color);
        return me;
    },

    #
    # @return me
    #
    setFontSizeSmall: func() {
        me._view.setFontSize(me, 12);
        return me;
    },

    #
    # @return me
    #
    setFontSizeMedium: func() {
        me._view.setFontSize(me, 14);
        return me;
    },

    #
    # @return me
    #
    setFontSizeLarge: func() {
        me._view.setFontSize(me, 16);
        return me;
    },
};
