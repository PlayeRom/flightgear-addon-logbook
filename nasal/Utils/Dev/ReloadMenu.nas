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
var ReloadMenu = {
    #
    # Constants:
    #
    MAIN_MENU_LABEL: "Logbook",
    RELOAD_MENU_LABEL: "Dev Reload",

    #
    # Constructor.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @return hash
    #
    new: func(addon) {
        var me = {parents: [
            ReloadMenu,
            DevBase.new(addon),
        ]};

        me._reloadMenuName = me._addon.id ~ "-dev-reload";

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
            me._printLog("menu node not found");
            return;
        }

        if (me._isMenuItemExists(menuNode)) {
            me._printLog("menu item already exist");
            return;
        }

        var data = {
            label  : ReloadMenu.RELOAD_MENU_LABEL,
            name   : me._reloadMenuName,
            binding: {
                "command": "addon-reload",
                "id"     : me._addon.id,
            }
        };

        menuNode.addChild("item").setValues(data);
        fgcommand("gui-redraw");

        me._printLog("the menu item \"", ReloadMenu.RELOAD_MENU_LABEL, "\" has been added.");
    },

    #
    # Remove "Dev Reload" menu item from our add-on menu.
    #
    # @return void
    #
    removeMenu: func() {
        var menuNode = me._getMenuNode();
        if (menuNode == nil) {
            me._printLog("menu node not found");
            return;
        }

        var item = me._getMenuItem(menuNode);
        if (item == nil) {
            me._printLog("menu item already doesn't exist");
            return;
        }

        item.remove();
        fgcommand("gui-redraw");

        me._printLog("the menu item \"", ReloadMenu.RELOAD_MENU_LABEL, "\" has been removed.");
    },

    #
    # Get node with addon menu or nil if not found.
    #
    # @return ghost|nil
    #
    _getMenuNode: func() {
        foreach (var menu; props.globals.getNode("/sim/menubar/default").getChildren("menu")) {
            var name = menu.getChild("label");
            if (name != nil and name.getValue() == ReloadMenu.MAIN_MENU_LABEL) {
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
            if (name != nil and name.getValue() == me._reloadMenuName) {
                return item;
            }
        }

        return nil;
    },
};
