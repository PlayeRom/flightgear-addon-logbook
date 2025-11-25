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

Log.alertSuccess('Loaded by include -> /nasal/Dev/DevEnv');

#
# Class for handle .env file.
# This is for development purposes only.
#
var DevEnv = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func {
        var obj = { parents: [DevEnv] };

        obj._variables = std.Hash.new();
        obj._readEnvFile();

        return obj;
    },

    #
    # Check if variable exist.
    #
    # @param  string  key  Variable name.
    # @return bool
    #
    hasKey: func(key) {
        return me._variables.contains(key);
    },

    #
    # Get value of variable.
    #
    # @param  string  key  Variable name.
    # @return scalar|nil
    #
    getValue: func(key) {
        if (!me.hasKey(key)) {
            return nil;
        }

        return me._variables.get(key);
    },

    #
    # Get boolean  value of variable.
    #
    # @param  string  key  Variable name.
    # @return bool
    #
    getBoolValue: func(key) {
        var value = me.getValue(key);
        if (value == true or value == false) {
            return value;
        }

        return false;
    },

    #
    # Try to read .env file. If file exist ten build variable hash.
    #
    # @return bool  True if success.
    #
    _readEnvFile: func {
        var envFilePath = os.path.new(g_Addon.basePath ~ '/.env');
        if (!envFilePath.exists()) {
            return false;
        }

        var content = io.readfile(envFilePath.realpath);

        var lines = split("\n", content);

        foreach (var line; lines) {
            line = me._cutComment(line);

            var pair = split('=', line);
            if (size(pair) == 2) {
                key = string.trim(pair[0]);
                value = string.trim(pair[1]);

                Log.alert('read .env file: ', key, '=', value);

                me._variables.set(key, me._convertValue(value));
            }
        }

        return true;
    },

    #
    # Remove comments from line. Comment start by # character.
    #
    # @param  string  line
    # @return string
    #
    _cutComment: func(line) {
        line = string.trim(line);
        var pos = find('#', line);
        if (pos == -1) {
            return line;
        }

        return substr(line, 0, pos);
    },

    #
    # Convert known string values ​​to their scalar representation.
    #
    # @param  string  value
    # @return scalar
    #
    _convertValue: func(value) {
        value = me._removeQuotes(value);
        var valueUc = string.uc(value);

        if (valueUc == 'TRUE')      return true;
        if (valueUc == 'FALSE')     return false;
        if (isnum(valueUc))         return num(valueUc);
        if (valueUc == 'LOG_ALERT') return LOG_ALERT;
        if (valueUc == 'LOG_WARN')  return LOG_WARN;
        if (valueUc == 'LOG_INFO')  return LOG_INFO;
        if (valueUc == 'LOG_DEBUG') return LOG_DEBUG;
        if (valueUc == 'LOG_BULK')  return LOG_BULK;
        # TODO: add more conversion here if needed

        return value; # return string as default
    },

    #
    # Remove leading and trailing quotes from string.
    #
    # @param  string  value
    # @return string
    #
    _removeQuotes: func(value) {
        var length = size(value);

        if (length >= 2
            and value[0] == `"`
            and value[-1] == `"`
        ) {
            return substr(value, 1, length - 2);
        }

        return value;
    },
};
