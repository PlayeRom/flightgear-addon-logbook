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
    # hash|nil clickDialog - The dialog which will be opened after click the row
    # hash style - My style structure from Dialog
    # hash element - The element that will listen to the event
    # hash target - The element on which the event will be executed. If nil then `element` will be used as `target`.
    # vector dataToPass - Logbook one row data to display after click. If nil then click event is not handling.
    #
    new: func (clickDialog, style, element, target = nil, dataToPass = nil) {
        var me = { parents: [MouseHover] };

        me.clickDialog = clickDialog;
        me.style = style;
        me.element = element;
        me.target = target == nil ? element : target;
        me.dataToPass = dataToPass;

        return me;
    },

    #
    # Add mouse events to the logbook row
    #
    # return void
    #
    addEvents: func() {
        me.element.addEventListener("mouseenter", func {
            if (!g_isThreadPending) {
                if (me.isBlocked()) {
                    me.target.setColorFill(me.style.SELECTED_BAR);
                }
                else {
                    me.target.setColorFill(me.style.HOVER_BG);
                }
            }
        });

        me.element.addEventListener("mouseleave", func {
            if (!g_isThreadPending) {
                if (me.isBlocked()) {
                    me.target.setColorFill(me.style.SELECTED_BAR);
                }
                else {
                    me.target.setColorFill([0.0, 0.0, 0.0, 0.0]);
                }
            }
        });

        if (me.clickDialog != nil and me.dataToPass != nil) {
            me.element.addEventListener("click", func {
                if (!g_isThreadPending) {
                    me.clickDialog.show(me.dataToPass);
                }
            });
        }
    },

    #
    # Check if the "next" dialog (clickDialog) is visible and is related to the current row.
    #
    # return bool
    #
    isBlocked: func() {
        return me.clickDialog != nil and
            me.dataToPass != nil and
            me.clickDialog.isWindowVisible() and
            me.dataToPass[0] == me.clickDialog.parentDataIndex;
    },
};