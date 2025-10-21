#
# CanvasSkeleton Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Handles enabling and disabling menu items by name.
#
var MenuStateHandler = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = {
            parents: [
                MenuStateHandler,
            ],
        };

        obj._menuNames = std.Hash.new();

        obj._collectItems();

        return obj;
    },

    #
    # Enable/disable menu items by name.
    #
    # @param  bool  state
    # @param  hash|nil  excluded  List of menu name (as key of hash) to excluded from change state.
    # @return void
    #
    toggleItems: func(state, excluded = nil) {
        if (excluded == nil) {
            excluded = {};
        }

        foreach (var name; me._menuNames.getKeys()) {
            if (contains(excluded, name)) {
                continue;
            }

            gui.menuEnable(name, state);
        }
    },

    #
    # Check which menu items have the <name> tag and save their `name` in the hash.
    #
    # @return void
    #
    _collectItems: func() {
        me._menuNames.clear();

        var menuNode = io.read_properties(g_Addon.basePath ~ "/addon-menubar-items.xml");
        if (menuNode == nil) {
            return;
        }

        var menuBarItems = menuNode.getChild("menubar-items");
        if (menuBarItems == nil) {
            return;
        }

        var menu = menuBarItems.getChild("menu");
        if (menu == nil) {
            return;
        }

        foreach (var item; menu.getChildren("item")) {
            if (item == nil) {
                continue;
            }

            var name = item.getChild("name");
            if (name == nil) {
                continue;
            }

            me._menuNames.set(name.getValue(), nil);
        }
    },
};
