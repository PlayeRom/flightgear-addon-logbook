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
# Storage facade class to save logbook data to CSV or SQLite, depend of FG version
#
var Storage = {
    #
    # Constructor
    #
    # @param  hash  filters  Filters object
    # @param  hash  columns  Columns object
    # @return me
    #
    new: func(filters, columns) {
        var me = {
            parents       : [Storage],
            _isUsingSQLite: Utils.isUsingSQLite(),
        };

        # TODO: drop support for StorageCsv when 2024 will be widely used
        me._handler = me._isUsingSQLite
            ? StorageSQLite.new(filters, columns)
            : StorageCsv.new(filters, columns);

        if (me._isUsingSQLite) {
            gui.menuEnable("logbook-addon-export-csv", true);
        }

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._handler.del();
    },

    #
    # @return True if Storage is working on SQLite DB, if on a CSV file then false
    # Use Utils.isUsingSQLite() instead
    #
    # isStorageSQLite: func() {
    #     return me._handler.parents[0] == StorageSQLite;
    # },

    #
    # Store log data to logbook file/DB
    #
    # @param  hash  logData  LogData object
    # @param  int  id|nill  Record ID for SQLite storage
    # @param  bool  onlyIO  Set true for execute only I/O operation on the file,
    #                       without rest of stuff (used only for CSV recovery)
    # @return void
    #
    saveLogData: func(logData, id = nil, onlyIO = 0) {
        me._handler.saveLogData(logData, id, onlyIO);
    },

    #
    # @param hash handler|nil - file/db handler, if nil the internal storage handler will be used
    # @param hash logData - LogData object
    # @return void
    #
    addItem: func(logData, handler = nil) {
        me._handler.addItem(logData, handler);
    },

    #
    # @param  hash  logData  LogData object
    # @param  int  id  Record ID
    # @return void
    #
    updateItem: func(logData, id) {
        if (me._isUsingSQLite) {
            me._handler.updateItem(logData, id);
        }
    },

    #
    # @return void
    #
    loadAllData: func() {
        me._handler.loadAllData();
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
        me._handler.loadDataRange(objCallback, callback, start, count, withHeaders);
    },

    #
    # @param  int  id  Record ID in table for SQLite or row index in CSV file where 0 = first data row, not header row
    # @param  string  columnName
    # @param  string  value
    # @return bool  Return true if successful
    #
    editData: func(id, columnName, value) {
        return me._handler.editData(id, columnName, value);
    },

    #
    # Get total number of rows in CSV file (excluded headers row)
    #
    # @return int
    #
    getTotalLines: func() {
        return me._handler.getTotalLines();
    },

    #
    # Get vector of data row by given index of row
    #
    # @param int index
    # @return hash|nil
    #
    getLogData: func(index) {
        return me._handler.getLogData(index);
    },

    #
    # @param int index - Index to delete
    # @return bool
    #
    deleteLog: func(index) {
        return me._handler.deleteLog(index);
    },

    #
    # Export logbook from SQLite to CSV file
    #
    # @return void
    #
    exportToCsv: func() {
        if (me._isUsingSQLite) {
            me._handler.exportToCsv();
        }
        else {
            gui.popupTip("This option is available only for version 2024.1 and later");
        }
    },
};
