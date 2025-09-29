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
# Class for handle .env file.
# This is for development purposes only.
#
var DevEnv = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [DevEnv] };

        me._variables = {};
        me._readEnvFile();

        return me;
    },

    #
    # Check if variable exist.
    #
    # @param  string  key  Variable name.
    # @return bool
    #
    hasKey: func(key) {
        return globals.contains(me._variables, key);
    },

    #
    # Get value of variable.
    #
    # @param  string  key  Variable name.
    # @return mixed
    #
    getValue: func(key) {
        if (!me.hasKey(key)) {
            return nil;
        }

        return me._variables[key];
    },

    #
    # Get boolean  value of variable.
    #
    # @param  string  key  Variable name.
    # @return bool
    #
    getBoolValue: func(key) {
        if (!me.hasKey(key)) {
            return false;
        }

        return me._variables[key];
    },

    #
    # Try to read .env file. If file exist ten build variable hash.
    #
    # @return bool  True if success.
    #
    _readEnvFile: func() {
        var envFilePath = g_Addon.basePath ~ "/.env";
        if (!io.exists(envFilePath)) {
            return false;
        }

        var content = io.readfile(envFilePath);

        var lines = globals.split("\n", content);

        foreach (var line; lines) {
            line = me._cutComment(line);

            var pair = split("=", line);
            if (size(pair) == 2) {
                key = string.trim(pair[0]);
                value = string.trim(pair[1]);

                Log.alert("read .env file: ", key, "=", value);

                me._variables[key] = me._convertValue(value);
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
        var pos = globals.find("#", line);
        if (pos == -1) {
            return line;
        }

        return substr(line, 0, pos);
    },

    #
    # Convert known string values ​​to their scalar representation.
    #
    # @param  string  value
    # @return mixed
    #
    _convertValue: func(value) {
        value = me._removeQuotes(value);
        var valueUc = string.uc(value);

           if (valueUc == "TRUE") return true;
        elsif (valueUc == "FALSE") return false;
        elsif (valueUc == "1") return 1;
        elsif (valueUc == "0") return 0;
        elsif (valueUc == "LOG_ALERT") return LOG_ALERT;
        elsif (valueUc == "LOG_WARN") return LOG_WARN;
        elsif (valueUc == "LOG_INFO") return LOG_INFO;
        elsif (valueUc == "LOG_DEBUG") return LOG_DEBUG;
        elsif (valueUc == "LOG_BULK") return LOG_BULK;
        # TODO: add more here if needed

        return value;
    },

    #
    # Remove leading and trailing quotes from string.
    #
    # @param  string  value
    # @return string
    #
    _removeQuotes: func(value) {
        if (size(value) >= 2
            and value[0] == `"`
            and value[-1] == `"`
        ) {
            return globals.substr(value, 1, size(value) - 2);
        }

        return value;
    },
};
