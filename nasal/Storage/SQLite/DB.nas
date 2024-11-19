#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Facade for sqlite to have DB handler in one place
#
var DB = {
    # Static members

    _handler: nil,

    # Static methods

    #
    # Open DB connection
    #
    # @param  string  file  SQLite file with path
    # @return ghost  SQLite handler
    #
    open: func(file) {
        DB.close();

        DB._handler = sqlite.open(file);

        return DB._handler;
    },

    #
    # Close DB connection
    #
    # @return void
    #
    close: func() {
        if (DB._handler != nil) {
            sqlite.close(DB._handler);
            DB._handler = nil;
        }
    },

    #
    # Prepare a query
    #
    # @param  string  query
    # @return ghost  Statement
    #
    prepare: func(query) {
        return sqlite.prepare(DB._handler, query);
    },

    #
    # Execute a query
    #
    # @param  args  First argument must be a query, next optional values
    # @return vector
    #
    exec: func() {
        return call(sqlite.exec, [DB._handler] ~ arg);
    },

    #
    # Finalize statement
    #
    # @param  ghost  stmt  Statement to finalize
    # @return void
    #
    finalize: func(stmt) {
        sqlite.finalize(stmt);
    },
};
