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

#
# Class to handle listeners.
#
var Listeners = {
    #
    # Constants for type parameter:
    #
    ON_CHANGE_ONLY : 0, # Triggered only when value has been changed.
    ON_WRITE_ALWAYS: 1, # Triggered always on write, event if value has not been changed.
    ON_CHILD_CHANGE: 2, # Triggered always, event if child properties has been changed.

    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = { parents: [Listeners] };

        obj._listeners = std.Vector.new();

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func {
        me.clear();
    },

    #
    # Add new listener.
    #
    # @param  string|props.Node  node
    # @param  func  code  Callback function.
    # @param  bool  init  If set to true, the listener will additionally be triggered when it is created.
    #                     This argument is optional and defaults to false.
    # @param  int  type  Integer specifying the listener's behavior.
    #                    0 means that the listener will only trigger when the property is changed.
    #                    1 means that the trigger will always be triggered when the property is written to.
    #                    2 will mean that the listener will be triggered even if child properties are modified.
    #                    This argument is optional and defaults to 1.
    # @return int  Listener handler.
    #
    add: func(node, code, init = 0, type = 1) {
        var handler = setlistener(node, code, init, type);
        me._listeners.append(handler);

        return handler;
    },

    #
    # Returns the number of listeners added.
    #
    # @return int
    #
    size: func {
        return me._listeners.size();
    },

    #
    # Remove listener by given handler.
    #
    # @param  int  Listener handler.
    # @return void
    #
    remove: func(handler) {
        if (me._listeners.contains(handler)) {
            removelistener(handler);
            me._listeners.remove(handler);
        }
    },

    #
    # Remove all listeners added to me._listeners vector.
    #
    # @return void
    #
    clear: func {
        foreach (var listener; me._listeners.vector) {
            # If this file is loaded into the `__addon[id]__` namespace, FG will
            # call removelistener on our listeners automatically during unload.
            # Therefore this removelistener will throw an error on the console,
            # so we intercept it with the `call()` method.
            call(removelistener, [listener], var errors = []);

            foreach (var error; errors) {
                if (error == 'removelistener() with invalid listener id') {
                    # Don't display an error that the lister has already been deleted.
                    break;
                }

                Log.error(error);
            }
        }

        me._listeners.clear();
    },
};
