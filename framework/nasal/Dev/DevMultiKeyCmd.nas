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
# A class for adding multi-key commands.
# This is for development purposes only.
#
var DevMultiKeyCmd = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func {
        var obj = {
            parents: [
                DevMultiKeyCmd,
            ],
        };

        obj._isReloadNeeded = false;

        return obj;
    },

    #
    # Add multi-key command to reload add-on.
    #
    # @param  string|nil  sequence  Multi-key sequence string.
    # @param  bool  withExit
    # @return hash
    #
    addReloadAddon: func(sequence, withExit = 1) {
        var path = me._add(sequence, withExit);
        if (path != nil) {
            setprop(path ~ '/binding/command', 'addon-reload');
            setprop(path ~ '/binding/id', g_Addon.id);
        }

        return me;
    },

    #
    # Add multi-key command to run unit tests.
    #
    # @param  string|nil  sequence  Multi-key sequence string.
    # @param  bool  withExit
    # @return hash
    #
    addRunTests: func(sequence, withExit = 1) {
        var path = me._add(sequence, withExit);
        if (path != nil) {
            setprop(path ~ '/binding/command', 'nasal-test-dir');
            setprop(path ~ '/binding/path', g_Addon.basePath ~ '/tests');
        }

        return me;
    },

    #
    # Reload 'multikey' Nasal module, to finalize multi-key commands.
    #
    # @return bool  Return true if reload has been executed.
    #
    finish: func {
        if (!me._isReloadNeeded) {
            return false;
        }

        fgcommand('nasal-reload', props.Node.new({
            module: 'multikey',
        }));

        return true;
    },

    #
    # Add multi-key command to reload add-on.
    #
    # @param  string|nil  sequence  Multi-key sequence string.
    # @param  bool  withExit
    # @return string|nil
    #
    _add: func(sequence, withExit) {
        sequence = me._validateSequence(sequence);
        if (sequence == nil) {
            return nil;
        }

        var path = '/input/keyboard/multikey';

        for (var i = 0; i < size(sequence); i += 1) {
            path ~= '/key[' ~ sequence[i] ~ ']';
            setprop(path ~ '/name', chr(sequence[i]));
        }

        if (withExit) {
            setprop(path ~ '/exit', '');
        }

        Log.alertSuccess('DevMultiKeyCmd, added multi-key: ', sequence);

        me._isReloadNeeded = true;

        return path;
    },

    #
    # Validate sequence string.
    #
    # @param  string|nil  sequence  Sequence string.
    # @return string|nil  Return validated sequence string or nil if invalid.
    #
    _validateSequence: func(sequence) {
        if (sequence == nil or !isstr(sequence) or size(sequence) == 0) {
            return nil;
        }

        sequence = me._removeColon(sequence);
        if (size(sequence) < 3) {
            Log.alertError('DevMultiKeyCmd, sequence "', sequence, '" must be at least 3 characters long');
            return nil;
        }

        if (string.isdigit(sequence[0])) {
            Log.alertError('DevMultiKeyCmd, sequence "', sequence, '" cannot start with a number');
            return nil;
        }

        if (!me._isAlphanumeric(sequence)) {
            Log.alertError('DevMultiKeyCmd, sequence "', sequence, '" must be alphanumeric');
            return nil;
        }

        return sequence;
    },

    #
    # Remove leading colon from sequence string.
    #
    # @param  string  sequence  sequence string.
    # @return string  sequence string without leading colon.
    #
    _removeColon: func(sequence) {
        if (sequence[0] == `:`) {
            return substr(sequence, 1);
        }

        return sequence;
    },

    #
    # Check if sequence string is alphanumeric.
    #
    # @param  string  sequence  sequence string.
    # @return string  Return true if sequence is alphanumeric, false otherwise.
    #
    _isAlphanumeric: func(sequence) {
        for (var i = 0; i < size(sequence); i += 1) {
            if (!string.isalnum(sequence[i])) {
                return false;
            }
        }

        return true;
    },
};
