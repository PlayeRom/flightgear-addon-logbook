#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Helper class for ComboBox widget.
#
var ComboBoxHelper = {
    #
    # Create ComboBox widget.
    #
    # @param  ghost  context
    # @param  vector  items  Vector of hashes, each hash with `label` and `value` field.
    # @param  int|int  width
    # @param  int|int  height
    # @return ghost  ComboBix widget.
    #
    create: func(context, items, width = nil, height = nil) {
        var comboBox = canvas.gui.widgets.ComboBox.new(context);

        if (width != nil and height != nil) {
            comboBox.setFixedSize(width, height);
        }

        return me.addItems(comboBox, items);
    },

    #
    # Add items to ComboBox widget.
    #
    # @param  ghost  comboBoxWidget
    # @param  vector  items  Vector of hashes, each hash with `label` and `value` field.
    # @return ghost  ComboBix widget.
    #
    addItems: func(comboBoxWidget, items) {
        var funcName = me._isCreateItemAvailable(comboBoxWidget)
            ? "createItem"   # <- FG dev version
            : "addMenuItem"; # <- FG 2024.1.x

        foreach (var item; items) {
            call(canvas.gui.widgets.ComboBox[funcName], [item.label, item.value], comboBoxWidget);
        }

        return comboBoxWidget;
    },

    #
    # Check whether ComboBox widget has createItem method. It's available in dev FG version.
    #
    # @param  ghost  comboBoxWidget
    # @return bool
    #
    _isCreateItemAvailable: func(comboBoxWidget) {
        return Utils.tryCatch(func typeof(comboBoxWidget.createItem), []);
    }
};
