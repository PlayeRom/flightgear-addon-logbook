#
# PlaneIcon - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# PlaneIcon component is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Class for drawing a plane icon in FlightProfile and FlightMap widgets
#
var PlaneIcon = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func {
        return {
            parents: [PlaneIcon],
            _svgImg: nil,
            _width : 0,
            _height: 0,
        };
    },

    #
    # Create SVG plane image
    #
    # @param  hash  context
    # @param  string  file
    # @return void
    #
    create: func(context, file) {
        me._svgImg = context.createChild("group").set("z-index", 2);
        canvas.parsesvg(me._svgImg, file);

        (me._width, me._height) = me._svgImg.getSize();
    },

    #
    # Draw plane from SVG file
    #
    # @param  double  x
    # @param  double  y
    # @param  double  rotate
    # @param  double  heightFactor  Normally it should be 0.5 to center the image, but the plane in profile needs
    #                               to be higher so that the fuselage aligns with the flight path.
    # @return void
    #
    draw: func(x, y, rotate = 0, heightFactor = 0.5) {
        var angleInRadians = rotate * globals.D2R;
        var offset = me._getRotationOffset(me._width, me._height, angleInRadians);

        me._svgImg.setRotation(angleInRadians);
        me._svgImg.setTranslation(
            x - (me._width  * 0.5         ) + offset.dx,
            y - (me._height * heightFactor) + offset.dy,
        );
    },

    #
    # Calculate offset for rotation because the image rotation point is in the upper left corner
    #
    # @param  double  width  Image width
    # @param  double  height  Image height
    # @param  double  angleInRadians
    # @return hash  Hash with delta X and delta Y
    #
    _getRotationOffset: func(width, height, angleInRadians) {
        var deltaX = -(width / 2) * (math.cos(angleInRadians) - 1) + (height / 2) *  math.sin(angleInRadians);
        var deltaY = -(width / 2) *  math.sin(angleInRadians)      - (height / 2) * (math.cos(angleInRadians) - 1);

        return {
            dx: deltaX,
            dy: deltaY,
        };
    },

    #
    # @return double
    #
    getWidth: func {
        return me._width;
    },
};
