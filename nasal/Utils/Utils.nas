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
# Utils static methods.
#
var Utils = {
    #
    # Check that file already exists.
    # From FG 2024.x we have io.exists() but for older versions we have to write it ourselves.
    #
    # @param  string  path
    # @return bool
    #
    fileExists: func(path) {
        return io.stat(path) != nil;
    },

    #
    # Remove all quotes from given text and return a new text without quotes
    #
    # @param  string  text
    # @return string
    #
    removeQuotes: func(text) {
        return string.replace(text, '"', '');
    },

    #
    # @return bool  Return true if running on FG version 2024.x and later
    #
    isFG2024Version: func {
        return g_FGVersion.greaterThanOrEqual('2024.1.1');
    },

    #
    # Return true when Storage is using SQLite instead of CSV file
    #
    # @return bool
    #
    isUsingSQLite: func {
        return Utils.isFG2024Version();
    },

    #
    # Check if the given string contains a space
    #
    # @param  string  text
    # @return bool
    #
    isSpace: func(text) {
        var parts = split(' ', text);
        return size(parts) > 1;
    },

    #
    # Convert decimal hours to hours:minutes:seconds, e.g. 1.5 -> 1:30
    #
    # @param  double|string  decimalHours
    # @return string
    #
    decimalHoursToHuman: func(decimalHours) {
        var hours = math.floor(decimalHours);
        var fractionalPart = decimalHours - hours;

        var minutes = math.floor(fractionalPart * 60);
        var seconds = math.floor((fractionalPart * 60 - minutes) * 60);

        return sprintf('%d:%02.0f:%02.0f', hours, minutes, seconds);
    },

    #
    # Open URL or path in the system browser or file explorer.
    #
    # @param  hash  params  Parameters for open-browser command, can be 'path' or 'url'.
    # @return void
    #
    openBrowser: func(params) {
        fgcommand('open-browser', props.Node.new(params));
    },

    #
    # @param  func  function
    # @param  vector|nil  params  Vector of function params.
    # @param  hash|nil  obj  Function context.
    # @return bool  Return true if given function was called without errors (die).
    #
    tryCatch: func(function, params = nil, obj = nil) {
        var errors = [];
        params = params or [];
        call(function, params, obj, errors);

        return !size(errors);
    },

    #
    # Encode URL the given string.
    #
    # @param  string  str
    # @return string
    #
    urlEncode: func(str) {
        var result = '';
        var allowed = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~';
        var count = size(str);

        for (var i = 0; i < count; i += 1) {
            var char = str[i];

            if (find(chr(char), allowed) == -1) {
                result ~= '%' ~ sprintf('%02X', char);
            } else {
                result ~= chr(char);
            }
        }

        return result;
    },
};
