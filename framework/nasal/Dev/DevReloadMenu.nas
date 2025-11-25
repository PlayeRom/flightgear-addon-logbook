#
# Framework Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

Log.success('Loaded by include -> /nasal/Dev/DevReloadMenu');

#
# A class that adds a "Dev Reload" item to the add-on menu to reload the add-on's Nasal code.
# This is for development purposes only.
#
var DevReloadMenu = {
    #
    # Constants:
    #
    _RELOAD_MENU_LABEL: 'Dev Reload',

    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = { parents: [DevReloadMenu] };

        obj._reloadMenuName = g_Addon.id ~ '-dev-reload';

        obj._mainMenuLabel = obj._getMainMenuLabel();

        return obj;
    },

    #
    # Get main menu label for this add-on, read from /addon-menubar-items.xml file.
    #
    # @return string
    #
    _getMainMenuLabel: func {
        var menuNode = io.read_properties(g_Addon.basePath ~ '/addon-menubar-items.xml');
        if (menuNode == nil) {
            return 'none';
        }

        var menuBarItems = menuNode.getChild('menubar-items');
        if (menuBarItems == nil) {
            return 'none';
        }

        var menu = menuBarItems.getChild('menu');
        if (menu == nil) {
            return 'none';
        }

        var label = menu.getChild('label');
        if (label == nil) {
            return 'none';
        }

        return label.getValue();
    },

    #
    # Add "Dev Reload" menu item to our add-on menu.
    #
    # @return void
    #
    addMenu: func {
        var menuNode = me._getMenuNode();
        if (menuNode == nil) {
            Log.alertWarning('menu node not found');
            return;
        }

        if (me._isMenuItemExists(menuNode)) {
            Log.alertWarning('menu item already exist');
            return;
        }

        var data = {
            label  : me._RELOAD_MENU_LABEL,
            name   : me._reloadMenuName,
            binding: {
                command: 'addon-reload',
                id     : g_Addon.id,
            }
        };

        menuNode.addChild('item').setValues(data);
        fgcommand('gui-redraw');

        Log.alertSuccess('the menu item "', me._RELOAD_MENU_LABEL, '" has been added.');
    },

    #
    # Remove "Dev Reload" menu item from our add-on menu.
    #
    # @return void
    #
    removeMenu: func {
        var menuNode = me._getMenuNode();
        if (menuNode == nil) {
            Log.alertWarning('menu node not found');
            return;
        }

        var item = me._getMenuItem(menuNode);
        if (item == nil) {
            return;
        }

        item.remove();
        fgcommand('gui-redraw');

        Log.alertSuccess('the menu item "', me._RELOAD_MENU_LABEL, '" has been removed.');
    },

    #
    # Get node with addon menu or nil if not found.
    #
    # @return ghost|nil
    #
    _getMenuNode: func {
        foreach (var menu; props.globals.getNode('/sim/menubar/default').getChildren('menu')) {
            var name = menu.getChild('label');
            if (name != nil and name.getValue() == me._mainMenuLabel) {
                return menu;
            }
        }

        return nil;
    },

    #
    # Prevent to add menu item more than once, e.g. after reload the sim by <Shift-Esc>.
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
        foreach (var item; menuNode.getChildren('item')) {
            var name = item.getChild('name');
            if (name != nil and name.getValue() == me._reloadMenuName) {
                return item;
            }
        }

        return nil;
    },
};
