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
# FilterSelector class
#
var FilterSelector = {
    #
    # Constants
    #
    WINDOW_WIDTH       : 250,
    WINDOW_HEIGHT      : 300,
    MAX_WINDOW_HEIGHT  : LogbookDialog.WINDOW_HEIGHT,
    PADDING            : 10,
    BUTTON_HEIGHT      : 26,
    ID_DATE            : "Date",
    ID_AC              : "Aircraft",
    ID_AC_TYPE         : "Type",
    ID_AIRPORT_FROM    : "From",
    ID_AIRPORT_TO      : "To",
    CLEAR_FILTER_VALUE : "All",

    #
    # Constructor
    #
    # return me
    #
    new: func () {
        var me = { parents: [
            FilterSelector,
            Dialog.new(Dialog.ID_FILTER_SELECTOR, FilterSelector.WINDOW_WIDTH, FilterSelector.WINDOW_HEIGHT, "Logbook About"),
        ] };

        me.window.set("decoration-border", "0 0 0");

        me.bgImage.hide();

        me.canvas.set("background", me.style.CANVAS_BG);

        me.items = [];
        me.withDefaultAll = true;

        me.scrollData = nil;
        me.scrollDataContent = nil;
        me.callback = nil;
        me.objCallback = nil;
        me.id = nil;

        return me;
    },

    #
    # Destructor
    #
    # return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Hide canvas dialog
    #
    # return void
    #
    hide: func() {
        call(Dialog.hide, [], me);
    },

    #
    # int x, y
    # return void
    #
    setPosition: func(x, y) {
        me.window.setPosition(x, y);
    },

    #
    # string title
    # return void
    #
    setTitle: func(title) {
        me.window.setTitle(title);
    },

    #
    # vector items
    # bool withDefaultAll
    # return void
    #
    setItems: func(items, withDefaultAll = 1) {
        me.items = items;
        me.withDefaultAll = withDefaultAll;

        me.recalculateWindowHeight();
        me.reDrawContent();
    },

    #
    # return void
    #
    recalculateWindowHeight: func() {
        var paddingMultiplier = 2;
        var count = size(me.items);

        if (me.withDefaultAll) {
            count += 1;  # +1 for "Default All"
            paddingMultiplier += 1;
        }

        # 5 = spacing between buttons:
        var windowHeight = count * (FilterSelector.BUTTON_HEIGHT + 5) + (FilterSelector.PADDING * paddingMultiplier);
        if (windowHeight > FilterSelector.MAX_WINDOW_HEIGHT) {
            windowHeight = FilterSelector.MAX_WINDOW_HEIGHT;
        }

        me.window.setSize(FilterSelector.WINDOW_WIDTH, windowHeight);
    },

    #
    # Set ID of filter: ID_AC, ID_AC_TYPE, etc.
    #
    # int id
    # return void
    #
    setId: func(id) {
        me.id = id;
    },

    #
    # Set callback function (with object) which will be call to apply filter
    #
    # hash objCallback - The class object which contains the callback function
    # func callback
    # return void
    #
    setCallback: func(objCallback, callback) {
        me.objCallback = objCallback;
        me.callback = callback;
    },

    #
    # hash style
    # return void
    #
    setStyle: func(style) {
        me.style = style;

        me.canvas.set("background", me.style.CANVAS_BG);
        if (me.scrollData != nil) {
            me.scrollData.setColorBackground(me.style.CANVAS_BG);
        }
    },

    #
    # return void
    #
    reDrawContent: func() {
        me.vbox.clear();

        var margins = {"left": FilterSelector.PADDING, "top": FilterSelector.PADDING, "right": 0, "bottom": FilterSelector.PADDING};
        me.scrollData = me.createScrollArea(me.style.CANVAS_BG, margins);

        me.vbox.addItem(me.scrollData, 1); # 2nd param = stretch

        me.scrollDataContent = me.getScrollAreaContent(me.scrollData);

        me.drawScrollable();
    },

    #
    # Draw content for scrollable area
    #
    # return void
    #
    drawScrollable: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        if (me.withDefaultAll) {
            # Add "All" item to reset filter
            var btnRepo = canvas.gui.widgets.Button.new(me.scrollDataContent, canvas.style, {})
                .setText("Default All")
                .setFixedSize(FilterSelector.WINDOW_WIDTH - (FilterSelector.PADDING * 2), FilterSelector.BUTTON_HEIGHT)
                .listen("clicked", func {
                    call(me.callback, [me.id, FilterSelector.CLEAR_FILTER_VALUE], me.objCallback);
                    me.window.hide();
                });

            vBoxLayout.addItem(btnRepo);
            vBoxLayout.addSpacing(FilterSelector.PADDING);
        }

        # Add others available items
        foreach (var item; me.items) {
            (func { # A magic function that makes the correct "text" available in the "clicked" listener.
                    # Without it, in "clicked" we will always get the last item.
                var text = item;
                var btnRepo = canvas.gui.widgets.Button.new(me.scrollDataContent, canvas.style, {})
                    .setText(text)
                    .setFixedSize(FilterSelector.WINDOW_WIDTH - (FilterSelector.PADDING * 2), FilterSelector.BUTTON_HEIGHT)
                    .listen("clicked", func {
                        call(me.callback, [me.id, text], me.objCallback);
                        me.window.hide();
                    });

                vBoxLayout.addItem(btnRepo);
            })();
        }

        me.scrollData.setLayout(vBoxLayout);
    },

    #
    # string text - Label text
    # return hash - Label widget
    #
    getLabel: func(text) {
        return canvas.gui.widgets.Label.new(me.scrollDataContent, canvas.style, {})
            .setText(text);
    },
};
