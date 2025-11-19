#
# WindBarbs - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WindBarbs component is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Class for drawing a wind indicator in FlightMap widget
#
var WindBarbs = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func {
        var obj = { parents: [WindBarbs] };

        obj._LENGTH          = 50;
        obj._MARGIN          = 10;
        obj._WIND_LINE_WIDTH = 2;

        obj._windPath = nil;

        obj._windBarbRules = obj._createBarbRules();

        return obj;
    },

    #
    # Return barbs at a given speed
    # Barbs are marked by three numbers 5 (short barb), 10 (long barb), 50 (flag).
    #
    # @return vector
    #
    _createBarbRules: func {
        return [
            { speed:   1, barbs: [] },                       #  1-2  kt: no barb
            { speed:   2, barbs: [5] },                      #  2-7  kt: 1 short
            { speed:   7, barbs: [10] },                     #  7-12 kt: 1 long
            { speed:  12, barbs: [10, 5] },                  # 12-17 kt: 1 long + short
            { speed:  17, barbs: [10, 10] },                 # 17-22 kt: 2 long
            { speed:  22, barbs: [10, 10, 5] },              # 22-27 kt: 2 long + short
            { speed:  27, barbs: [10, 10, 10] },             # 27-32 kt: 3 long
            { speed:  32, barbs: [10, 10, 10, 5] },          # 32-37 kt: 3 long + short
            { speed:  37, barbs: [10, 10, 10, 10] },         # 37-42 kt: 4 long
            { speed:  42, barbs: [10, 10, 10, 10, 5] },      # 42-47 kt: 4 long + short
            { speed:  47, barbs: [50] },                     # 47-52 kt: 1 flag
            { speed:  52, barbs: [50, 5] },                  # 52-57 kt: 1 flag + short
            { speed:  57, barbs: [50, 10] },                 # 57-62 kt: 1 flag + long
            { speed:  62, barbs: [50, 10, 5] },              # 62-67 kt: 1 flag + long + short
            { speed:  67, barbs: [50, 10, 10] },             # 67-72 kt: 1 flag + 2 long
            { speed:  72, barbs: [50, 10, 10, 5] },          # etc.
            { speed:  77, barbs: [50, 10, 10, 10] },
            { speed:  82, barbs: [50, 10, 10, 10, 5] },
            { speed:  87, barbs: [50, 10, 10, 10, 10] },
            { speed:  92, barbs: [50, 10, 10, 10, 10, 5] },
            { speed:  97, barbs: [50, 50] },
            { speed: 102, barbs: [50, 50, 5] },
            { speed: 107, barbs: [50, 50, 10] },
            { speed: 112, barbs: [50, 50, 10, 5] },
            { speed: 117, barbs: [50, 50, 10, 10] },
            { speed: 122, barbs: [50, 50, 10, 10, 5] },
            { speed: 127, barbs: [50, 50, 10, 10, 10] },
            { speed: 132, barbs: [50, 50, 10, 10, 10, 5] },
            { speed: 137, barbs: [50, 50, 10, 10, 10, 10] },
            { speed: 142, barbs: [50, 50, 10, 10, 10, 10, 5] },
            { speed: 147, barbs: [50, 50, 50] },
        ];
    },

    #
    # @param  ghost  context
    # @return void
    #
    create: func(context) {
        me._windPath = context.createChild("path", "wind")
            .setColor(0.0, 0.0, 0.0)
            .setStrokeLineWidth(me._WIND_LINE_WIDTH);
    },

    #
    # @param  ghost  model  FlightMap model
    # @param  double  windHeading
    # @param  double  windSpeed
    # @return void
    #
    draw: func(model, windHeading, windSpeed) {
        me._windPath.reset();

        var (width, height) = model._size;

        var center = {
            x: width - (me._LENGTH + me._MARGIN),
            y:          me._LENGTH + me._MARGIN,
        };

        if (windSpeed < 1) { # calm (draw circles)
            # TODO: We don't want a fill color here and it would be best to turn it off,
            # but alpha 0.0 works like 1.0, so I set it to the lowest possible
            me._windPath.setColorFill(1.0, 1.0, 1.0, 0.0022);

            me._windPath.circle( 7);
            me._windPath.circle(10);
        }
        else { # draw vector of wind
            # Set fill color for flag barb
            me._windPath.setColorFill(0.0, 0.0, 0.0, 1.0);

            var halfLength = me._LENGTH / 2;

            # We draw a vertical line in the local coordinate system (directly relative to the center)
            me._windPath.moveTo(0,  halfLength);
            me._windPath.lineTo(0, -halfLength); # draw vertical line to up

            var barbRule = me._findWindBarbRule(windSpeed);
            if (barbRule != nil) {
                var y = -halfLength; # Set y to end of wind vector
                foreach (var barb; barbRule) {
                    if (barb == 5) {
                        if (y == -halfLength) {
                            # This is first short which need offset
                            y += 5;
                        }

                        me._shortBarb(y);
                        y += 5;
                    }
                    elsif (barb == 10) {
                        me._longBarb(y);
                        y += 5;
                    }
                    elsif (barb == 50) {
                        me._flagBarb(y);
                        y += 10;
                    }
                };
            }

            # We set the path rotation relative to the center (0,0) - local coordinates
            me._windPath.setRotation(windHeading * globals.D2R);
        }

        # We move the path to the global center
        me._windPath.setTranslation(center.x, center.y);
    },

    #
    # Return vector with barbs according to given wind speed in knots
    #
    # @param  double  windSpeed
    # @return vector|nil
    #
    _findWindBarbRule: func(windSpeed) {
        for (var i = size(me._windBarbRules) - 1; i >= 0; i -= 1) {
            if (windSpeed >= me._windBarbRules[i].speed) {
                return me._windBarbRules[i].barbs;
            }
        }

        return nil;
    },

    #
    # Draw short (5 kt) wind barb line
    #
    # @param  int  y
    # @return void
    #
    _shortBarb: func(y) {
        me._windPath.moveTo(0, y);
        me._windPath.lineTo(5, y); # 5 px length of short barb
    },

    #
    # Draw long (10 kt) wind barb line
    #
    # @param  int  y
    # @return void
    #
    _longBarb: func(y) {
        me._windPath.moveTo( 0, y);
        me._windPath.lineTo(10, y);  # 10 px length of long barb
    },

    #
    # Draw flag (50 kt) wind barb
    #
    # @param  int  y
    # @return void
    #
    _flagBarb: func(y) {
        me._windPath.moveTo( 0, y);
        me._windPath.lineTo(10, y + 3.5); # 10 px height of flag
        me._windPath.lineTo( 0, y + 7);
    },
};
