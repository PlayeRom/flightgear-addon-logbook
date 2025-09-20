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
# A class that adds a "Dev Reload" item to the add-on menu to reload the add-on's Nasal code.
# This is for development purposes only.
#
var DevReload = {
    #
    # Constants:
    #
    MENU_LABEL: "Dev Reload",
    MAIN_MENU_NAME: "logbook-addon",

    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [DevReload] };

        me._menuName = g_Addon.id ~ "-dev-reload";

        return me;
    },

    #
    # Add "Dev Reload" menu item to our add-on menu.
    #
    # @return void
    #
    addMenu: func() {
        var menuNode = me._getMenuNode();
        if (menuNode == nil) {
            Log.print("menu node not found");
            return;
        }

        if (me._isMenuItemExists(menuNode)) {
            Log.print("menu item already exist");
            return;
        }

        var data = {
            label  : DevReload.MENU_LABEL,
            name   : me._menuName,
            binding: {
                "command": "addon-reload",
                "id"     : g_Addon.id,
            }
        };

        menuNode.addChild("item").setValues(data);
        fgcommand("gui-redraw");

        Log.print("the menu item \"", DevReload.MENU_LABEL, "\" has been added.");
    },

    #
    # Remove "Dev Reload" menu item from our add-on menu.
    #
    # @return void
    #
    removeMenu: func() {
        var menuNode = me._getMenuNode();
        if (menuNode == nil) {
            Log.print("menu node not found");
            return;
        }

        var item = me._getMenuItem(menuNode);
        if (item == nil) {
            Log.print("menu item already doesn't exist");
            return;
        }

        item.remove();
        fgcommand("gui-redraw");

        Log.print("the menu item \"", DevReload.MENU_LABEL, "\" has been removed.");
    },

    #
    # Get node with addon menu or nil if not found.
    #
    # @return ghost|nil
    #
    _getMenuNode: func() {
        foreach (var menu; props.globals.getNode("/sim/menubar/default").getChildren("menu")) {
            var name = menu.getChild("name");
            if (name != nil and name.getValue() == DevReload.MAIN_MENU_NAME) {
                return menu;
            }
        }

        return nil;
    },

    #
    # Prevent to add menu item more than once, e.g. after reload the sim by <Shift-Esc>
    #
    # @param  ghost  menuNode
    # @return bool
    #
    _isMenuItemExists: func(menuNode) {
        return me._getMenuItem(menuNode) != nil;
    },

    #
    # Get "Dev Reload" menu item or nil if not found.
    #
    # @param  ghost  menuItemNode
    # @return ghost|nil
    #
    _getMenuItem: func(menuNode) {
        foreach (var item; menuNode.getChildren("item")) {
            var name = item.getChild("name");
            if (name != nil and name.getValue() == me._menuName) {
                return item;
            }
        }

        return nil;
    },
};
