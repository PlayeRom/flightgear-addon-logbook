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
# MouseHover class
#
var MouseHover = {
    #
    # Constructor
    #
    # hash element - The element that will listen to the event
    # hash style - My style structure from Dialog
    # hash target - The element on which the event will be executed. If nil then `element` will be use as `target`.
    #
    new: func (element, style, target = nil) {
        var me = { parents: [MouseHover] };

        me.element = element;
        me.style = style;
        me.target = target == nil ? element : target;

        return me;
    },

    addEvents: func() {
        me.element.addEventListener("mouseenter", func {
            me.target.setColorFill(me.style.HOVER_BG);
        });

        me.element.addEventListener("mouseleave", func {
            me.target.setColorFill([0.0, 0.0, 0.0, 0.0]);
        });
    },
};
