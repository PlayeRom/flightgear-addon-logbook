#
# MapButtons - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# MapButtons component is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Class for drawing and handling buttons drawn on a FlightMap widget
#
var MapButtons = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents     : [MapButtons],
            _SIZE       : 32,  # button/image size in pixels
            _POS_X      : 20,
            _POS_Y      : 50,
            _MARGIN     : 10,  # space between buttons
            _HOVER_ZOOM : 4,   # pixels how much the button should be enlarged when you hover the mouse over it
            _buttons    : [
                {
                    object: nil,
                    file  : "Textures/OpenStreetMap.png",
                    click : func(model) { model.setOpenStreetMap(); },
                },
                {
                    object: nil,
                    file  : "Textures/OpenTopoMap.png",
                    click : func(model) { model.setOpenTopoMap(); },
                },
            ],
        };
    },

    #
    # Create buttons on the map
    #
    # @param  ghost  model  FlightMap model object
    # @param  ghost  context  Canvas context on which button will be drawn
    # @return void
    #
    create: func(model, context) {
        forindex (var i; me._buttons) {
            me._buttons[i].object = me._createImg(context, me._buttons[i].file)
                .setTranslation(
                    me._POS_X,
                    me._POS_Y + ((me._SIZE + me._MARGIN) * i),
                );

            func() {
                var index = i;
                me._setEvents(model, me._buttons[index], index);
            }();
        }
    },

    #
    # Crate single button
    #
    # @param  ghost  context  Canvas context on which button will be drawn
    # @param  string  file  File name with path
    # @return ghost  Image element
    #
    _createImg: func(context, file) {
        return context.createChild("image")
            .setFile(file)
            .setSize(me._SIZE, me._SIZE)
            .set("z-index", 5);
    },

    #
    # Set button events
    #
    # @param  ghost  model  FlightMap model object
    # @param  hash  button
    # @param  int  index
    # @return void
    #
    _setEvents: func(model, button, index) {
        button.object.addEventListener("click", func(e) {
            e.stopPropagation();

            button.click(model);
            model.hardUpdateView();
        });

        button.object.addEventListener("mouseenter", func(e) {
            button.object
                .setTranslation(
                    me._POS_X                                     - (me._HOVER_ZOOM / 2),
                    me._POS_Y + ((me._SIZE + me._MARGIN) * index) - (me._HOVER_ZOOM / 2),
                )
                .setSize(
                    me._SIZE + me._HOVER_ZOOM,
                    me._SIZE + me._HOVER_ZOOM,
                );
        });

        button.object.addEventListener("mouseleave", func(e) {
            button.object
                .setTranslation(
                    me._POS_X,
                    me._POS_Y + ((me._SIZE + me._MARGIN) * index),
                )
                .setSize(me._SIZE, me._SIZE);
        });
    },
};
