
#
# ZoomFractions - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# ZoomFractions component is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Class to handle zoom fractions in FlightProfile widget
#
var ZoomFractions = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents: [ZoomFractions],

            # If zoom is used, in which fraction of the graph is the plane located
            _fractionIndex: 0,

            _maxZoomLevel: gui.widgets.FlightProfile.ZOOM_MAX,

            _zoomFractions: {
                distance : std.Vector.new(),
                timestamp: std.Vector.new(),
            },

            _isCreated: false,
            _firstFractionPosition: nil,
        };
    },

    #
    # Build zoom fractions, once for model._trackItems data
    #
    # @param  ghost  model  FlightProfile model
    # @return void
    #
    create: func(model) {
        if (me._isCreated or model._isLiveUpdateMode) {
            return;
        }

        me._isCreated = true;

        me._maxZoomLevel = gui.widgets.FlightProfile.ZOOM_MAX;

        while (me._maxZoomLevel >= gui.widgets.FlightProfile.ZOOM_MIN) {
            if (me._tryCatch(me._createInternal, [model])) {
                break; # No errors, break the loop
            }

            # Reduce the number of fractions by half
            me._maxZoomLevel = int(me._maxZoomLevel / 2);
        }
    },

    #
    # @param  func  function
    # @param  vector  params
    # @return bool  Return true if given function was called without errors (die)
    #
    _tryCatch: func(function, params) {
        var errors = [];
        call(function, params, me, nil, errors);

        return !size(errors);
    },

    #
    # @param  ghost  model
    # @return void
    #
    _createInternal: func(model) {
        me._zoomFractions.distance.clear();
        me._zoomFractions.timestamp.clear();

        var lastIndex = model._trackItemsSize - 1;
        var lastItem  = model._trackItems[lastIndex];

        var distFraction = lastItem.distance  / me._maxZoomLevel;
        var timeFraction = lastItem.timestamp / me._maxZoomLevel;

        var nextDistValue = distFraction;
        var nextTimeValue = timeFraction;

        var distObj = {
            firstPosition: nil,
            lastPosition : nil,
            items        : [],
            itemsSize    : 0,
        };

        var timeObj = {
            firstPosition: nil,
            lastPosition : nil,
            items        : [],
            itemsSize    : 0,
        };

        var distCounter = 0;
        var timeCounter = 0;

        forindex (var index; model._trackItems) {
            var item = model._trackItems[index];

            var isLast = index == lastIndex;

            (nextDistValue, distObj, distCounter) = me._buildZoomFraction(index, item, "distance",  nextDistValue, distFraction, distObj, isLast, distCounter);
            (nextTimeValue, timeObj, timeCounter) = me._buildZoomFraction(index, item, "timestamp", nextTimeValue, timeFraction, timeObj, isLast, timeCounter);
        }
    },

    #
    # Build zoom fraction for distance or timestamp
    #
    # @param  int  index  Current index of model._trackItems
    # @param  hash  item  Current item of model._trackItems
    # @param  string  key  "distance" or "timestamp"
    # @param  double  nextValue  Limit value for current faction
    # @param  double  fractionValue  A fractional part of a time or distance value
    # @param  hash  fractionObj  Fraction object with min and max positions, vector of points and size of vector
    # @param  bool  isLast  True if it's last index of model._trackItems vector
    # @param  int  counter
    # @return vector  New value of nextValue and fractionObj
    #
    _buildZoomFraction: func(index, item, key, nextValue, fractionValue, fractionObj, isLast, counter) {
        if (item[key] <= nextValue or isLast) {
            if (fractionObj.firstPosition == nil) {
                fractionObj.firstPosition = index;
            }

            fractionObj.lastPosition = index;
            fractionObj.itemsSize += 1;

            append(fractionObj.items, item);
            counter += 1;
        }

        if (item[key] > nextValue or isLast) {
            if (counter < 2 and me._maxZoomLevel > gui.widgets.FlightProfile.ZOOM_MIN) {
                # With the current _maxZoomLevel value, the number of points per fraction is less than 2,
                # this is unacceptable, so throw an exception to decrease the _maxZoomLevel,
                # unless the _maxZoomLevel has reached its minimum
                die("Max zoom level to height");
            }

            counter = 0;

            me._zoomFractions[key].append(fractionObj);

            if (!isLast) {
                fractionObj = {
                    firstPosition: index,
                    lastPosition : index,
                    items        : [],
                    itemsSize    : 1,
                };

                append(fractionObj.items, item);

                nextValue += fractionValue;
            }
        }

        return [nextValue, fractionObj, counter];
    },

    #
    # @return int
    #
    getFirstFractionPosition: func() {
        if (me._firstFractionPosition == nil) {
            return 0;
        }

        return me._firstFractionPosition;
    },

    #
    # Set range of points to draw according to zoom level
    #
    # @param  ghost  model  FlightProfile model
    # @param  ghost  view  FlightProfile view
    # @return void
    #
    setRangeOfPointsToDraw: func(model, view) {
        if (model._isLiveUpdateMode) {
            # For live mode the zoom is disabled
            view._trackItems     = model._trackItems;
            view._trackItemsSize = model._trackItemsSize;
            return;
        }

        var fractions = me._getZoomFractions(model);

        var indexAllFractions = me.getCurrentFractionIndex(model);
        var invert = math.min(fractions.size(), me._maxZoomLevel) / model._zoom;
        var firstIndex = (math.floor(indexAllFractions / invert)) * invert;

        view._trackItems = [];
        view._trackItemsSize = 0;
        me._firstFractionPosition = nil;

        foreach (var item; fractions.vector[firstIndex:(firstIndex + invert - 1)]) {
            view._trackItems ~= item.items; # merge vectors
            view._trackItemsSize += item.itemsSize;
            if (me._firstFractionPosition == nil) {
                me._firstFractionPosition = item.firstPosition;
            }
        }

        me._fractionIndex = me.getIndexMergedFractions(model, indexAllFractions);
    },

    #
    # Return the index of the part of the graph where the aircraft is currently located.
    # For example, if zoom level is 8, it can be index from 0 do 7.
    #
    # @param  ghost  model  FlightProfile model
    # @return int
    #
    getCurrentFractionIndex: func(model) {
        var vector = me._getZoomFractions(model).vector;
        forindex (var index; vector) {
            var item = vector[index];

            if (item.firstPosition == nil) {
                return 0;
            }

            if (    model._position >= item.firstPosition
                and model._position <= item.lastPosition
            ) {
                return index;
            }
        }

        return 0;
    },

    #
    # Get vector of zoom fractions depend of draw mode
    #
    # @param  ghost  model  FlightProfile model
    # @return std.Vector
    #
    _getZoomFractions: func(model) {
        return model.isDrawModeTime()
            ? me._zoomFractions.timestamp
            : me._zoomFractions.distance;
    },

    #
    # Returned index value depend of zoom level. The fractions vectors have been merged according to zoom level
    # e.g. when zoom = 2, then me._maxZoomLevel vectors will be merged to 2 vectors, then this function will return 0 or 1.
    #
    # @param  ghost model  FlightProfile mode
    # @param  int  indexAllFractions
    # @return int
    #
    getIndexMergedFractions: func(model, indexAllFractions) {
        return math.floor(indexAllFractions / (me._maxZoomLevel / model._zoom));
    },

    #
    # Index of the faction in which the plane is located. It's the same as getIndexMergedFractions,
    # but remembered during redraw the FlightProfile graph.
    #
    # @return int
    #
    getFractionIndex: func() {
        return me._fractionIndex;
    },

    #
    # Return max zoom level
    #
    # @return int
    #
    getMaxZoomLevel: func() {
        return me._maxZoomLevel;
    },

    #
    # Set _isCreated flag to false, to recreate fractions
    #
    # @return void
    #
    setToRecreate: func() {
        me._isCreated = false;
    },
};
