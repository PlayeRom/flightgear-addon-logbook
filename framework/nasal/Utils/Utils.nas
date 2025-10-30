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
