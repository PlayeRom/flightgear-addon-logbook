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
    PADDING            : 10,
    ID_AC              : "Aircraft",
    ID_AC_TYPE         : "Type",
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

        me.bgImage.hide();

        me.canvas.set("background", me.style.CANVAS_BG);

        me.items = [];

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
    # return void
    #
    setItems: func(items) {
        me.items = items;

        me.reDrawContent();
    },

    setId: func(id) {
        me.id = id;
    },

    setCallback: func(objCallback, callback) {
        me.objCallback = objCallback;
        me.callback = callback;
    },

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

        # var buttonBoxClose = me.drawBottomBar("Cancel", func() { me.window.hide(); });
        # me.vbox.addSpacing(10);
        # me.vbox.addItem(buttonBoxClose);
        # me.vbox.addSpacing(10);
    },

    #
    # Draw content for scrollable area
    #
    # return void
    #
    drawScrollable: func() {
        var vBoxLayout = canvas.VBoxLayout.new();

        # Add "All" item to reset filter
        var btnRepo = canvas.gui.widgets.Button.new(me.scrollDataContent, canvas.style, {})
            .setText("Default All")
            .setFixedSize(FilterSelector.WINDOW_WIDTH - (FilterSelector.PADDING * 2), 26)
            .listen("clicked", func {
                call(me.callback, [me.id, FilterSelector.CLEAR_FILTER_VALUE], me.objCallback);
                me.window.hide();
            });

        vBoxLayout.addItem(btnRepo);
        vBoxLayout.addSpacing(FilterSelector.PADDING);

        # Add others available items
        foreach (var item; me.items) {
            (func { # A magic function that makes the correct "text" available in the "clicked" listener.
                    # Without it, in "clicked" we will always get the last item.
                var text = item;
                var btnRepo = canvas.gui.widgets.Button.new(me.scrollDataContent, canvas.style, {})
                    .setText(text)
                    .setFixedSize(FilterSelector.WINDOW_WIDTH - (FilterSelector.PADDING * 2), 26)
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

    #
    # string label - Label of button
    # func callback - function which will be executed after click the button
    # return hash - HBoxLayout object with button
    #
    # drawBottomBar: func(label, callback) {
    #     var buttonBox = canvas.HBoxLayout.new();

    #     var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
    #         .setText(label)
    #         .setFixedSize(75, 26)
    #         .listen("clicked", callback);

    #     buttonBox.addStretch(1);
    #     buttonBox.addItem(btnClose);
    #     buttonBox.addStretch(1);

    #     return buttonBox;
    # },
};
