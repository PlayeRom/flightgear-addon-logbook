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
# Airport class
#
var Airport = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        return { parents: [Airport] };
    },

    #
    # Get the ICAO code of the nearest airport.
    #
    # @param  double  maxDistance  In meters
    # @return string  ICAO code or empty
    #
    getNearestIcao: func(maxDistance) {
        var distance = me._getNearestAirportDistanceM();
        if (distance != nil and distance.distanceM < maxDistance) {
            return distance.icao;
        }

        return "";
    },

    #
    # Get nearest airport distance in meters.
    #
    # @return hash|nil  Hash with distanceM (in meters) to the nearest airport as icao, or nil if none.
    #
    _getNearestAirportDistanceM: func() {
        var nearestAirport = airportinfo();
        if (nearestAirport != nil) {
            var aircraftCoord = geo.aircraft_position();
            var airportCoord = geo.Coord.new().set_latlon(nearestAirport.lat, nearestAirport.lon);
            return {
                'distanceM' : airportCoord.distance_to(aircraftCoord),
                'icao'      : nearestAirport.id,
            };
        }

        return nil;
    },
};
