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
# A class add multi-key command to reload add-on.
# This is for development purposes only.
#
var DevReloadMultiKey = {
    #
    # Add multi-key command to reload add-on.
    #
    # @param  string|nil  command  Multi-key command string.
    # @return bool
    #
    addMultiKeyCmd: func(command) {
        command = me._validateCommand(command);
        if (command == nil) {
            return false;
        }

        var path = "/input/keyboard/multikey";

        for (var i = 0; i < size(command); i += 1) {
            Log.alert("DevReloadMultiKey, adding multi-key: ", chr(command[i]), " = ", command[i]);

            path ~= "/key[" ~ command[i] ~ "]";
            setprop(path ~ "/name", chr(command[i]));
        }

        setprop(path ~ "/exit", "");
        setprop(path ~ "/binding/command", "addon-reload");
        setprop(path ~ "/binding/id", g_Addon.id);

        fgcommand("nasal-reload", props.Node.new({
            module: "multikey",
        }));

        return true;
    },

    #
    # Validate command string.
    #
    # @param  string|nil  command  Command string.
    # @return string|nil  Return validated command string or nil if invalid.
    #
    _validateCommand: func(command) {
        if (command == nil or size(command) == 0) {
            return nil;
        }

        command = me._removeColon(command);
        if (size(command) < 3) {
            Log.alert("DevReloadMultiKey, command \"", command, "\" must be at least 3 characters long");
            return nil;
        }

        if (string.isdigit(command[0])) {
            Log.alert("DevReloadMultiKey, command \"", command, "\" cannot start with a number");
            return nil;
        }

        if (!me._isAlphanumeric(command)) {
            Log.alert("DevReloadMultiKey, command \"", command, "\" must be alphanumeric");
            return nil;
        }

        return command;
    },

    #
    # Remove leading colon from command string.
    #
    # @param  string  command  Command string.
    # @return string  Command string without leading colon.
    #
    _removeColon: func(command) {
        if (command[0] == `:`) {
            return substr(command, 1);
        }

        return command;
    },

    #
    # Check if command string is alphanumeric.
    #
    # @param  string  command  Command string.
    # @return string  Return true if command is alphanumeric, false otherwise.
    #
    _isAlphanumeric: func(command) {
        for (var i = 0; i < size(command); i += 1) {
            if (!string.isalnum(command[i])) {
                return false;
            }
        }

        return true;
    },
};
