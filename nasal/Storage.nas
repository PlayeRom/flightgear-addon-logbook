#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Storage facade class to save logbook data
#
var Storage = {
    #
    # Constructor
    #
    # @param hash addon - addons.Addon object
    # @param hash filters - Filters object
    # @return me
    #
    new: func(addon, filters) {
        var me = {
            parents : [Storage],
            addon   : addon,
            filters : filters,
            handler : StorageCsv.new(addon, filters),
        };

        return me;
    },

    #
    # Store log data to logbook file
    #
    # @param hash logData - LogData object
    # @param bool onlyIO - Set true for execute only I/O operation on the file, without rest of stuff
    # @return void
    #
    saveData: func(logData, onlyIO = 0) {
        me.handler.saveData(logData, onlyIO);
    },

    #
    # @param hash file - file handler
    # @param hash logData - LogData object
    # @return void
    #
    saveItem: func(file, logData) {
        me.handler.saveItem(file, logData);
    },

    #
    # @return void
    #
    loadAllData: func() {
        me.handler.loadAllData();
    },

    #
    # @param hash objCallback - owner object of callback function
    # @param func callback - callback function called on finish
    # @param int start - Start index counting from 0 as a first row of data
    # @param int count - How many rows should be returned
    # @param bool withHeaders
    # @return void
    #
    loadDataRange: func(objCallback, callback, start, count, withHeaders) {
        me.handler.loadDataRange(objCallback, callback, start, count, withHeaders);
    },

    #
    # @param int rowIndex - where 0 = first data row, not header row
    # @param string header
    # @param string value
    # @return bool - Return true if successful
    #
    editData: func(rowIndex, header, value) {
        return me.handler.editData(rowIndex, header, value);
    },

    #
    # Get total number of rows in CSV file (excluded headers row)
    #
    # @return int
    #
    getTotalLines: func() {
        return me.handler.getTotalLines();
    },

    #
    # Get vector with headers names
    #
    # @return vector
    #
    getHeadersData: func() {
        return me.handler.getHeadersData();
    },

    #
    # Get vector of data row by given index of row
    #
    # @param int index
    # @return hash|nil
    #
    getLogData: func(index) {
        return me.handler.getLogData(index);
    },

    #
    # @param int index - Index to delete
    # @return bool
    #
    deleteLog: func(index) {
        return me.handler.deleteLog(index);
    },
};
