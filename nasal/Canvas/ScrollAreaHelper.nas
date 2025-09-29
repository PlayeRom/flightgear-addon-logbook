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
# Helper class for ScrollArea.
#
var ScrollAreaHelper = {
    #
    # Create ScrollArea widget.
    #
    # @param  ghost  context
    # @param  hash|nil  margins  Margins hash or nil.
    # @param  vector|nil  bgColor  RGB color for background.
    # @return ghost  ScrollArea widget.
    #
    create: func(context, margins = nil, bgColor = nil) {
        var scrollArea = canvas.gui.widgets.ScrollArea.new(context, canvas.style, {});

        scrollArea.setColorBackground(bgColor or canvas.style.getColor("bg_color"));

        if (margins != nil) {
            scrollArea.setContentsMargins(margins.left, margins.top, margins.right, margins.bottom);
        }

        return scrollArea;
    },

    #
    # @param  ghost  context  ScrollArea widget.
    # @param  string|nil  font  Font file name.
    # @param  int|nil  fontSize  Font size.
    # @param  string|nil  alignment  Content alignment value.
    # @return ghost  Content group of ScrollArea.
    #
    getContent: func(context, font = nil, fontSize = nil, alignment = nil) {
        var scrollContent = context.getContent();

        if (font != nil) {
            scrollContent.set("font", font);
        }

        if (fontSize != nil) {
            scrollContent.set("character-size", fontSize);
        }

        if (alignment != nil) {
            scrollContent.set("alignment", alignment);
        }

        return scrollContent;
    },
};
