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
    # return me
    #
    new: func () {
        return { parents: [Airport] };
    },

    #
    # Get the ICAO code of the nearest airport.
    #
    # double maxDistance - in meters
    # return string - ICAO code or empty
    #
    getNearestIcao: func(maxDistance) {
        var distance = me.getNearestAirportDistanceM();
        if (distance != nil and distance.distanceM < maxDistance) {
            return distance.icao;
        }

        return "";
    },

    #
    # Get nearest airport distance in meters.
    #
    # return hash with distanceM (in meters) to the nearest airport as icao, or nil if none.
    #
    getNearestAirportDistanceM: func() {
        var icao = getprop("/sim/airport/closest-airport-id");
        if (icao != nil and icao != "") {
            var airport = airportinfo(icao);
            if (airport != nil) {
                var aircraftCoord = geo.aircraft_position();
                var airportCoord = geo.Coord.new().set_latlon(airport.lat, airport.lon);
                return {
                    'distanceM' : airportCoord.distance_to(aircraftCoord),
                    'icao'      : icao,
                };
            }
        }

        return nil;
    },
};
