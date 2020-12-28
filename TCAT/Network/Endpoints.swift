//
//  Network+Endpoints.swift
//  TCAT
//
//  Created by Austin Astorga on 4/6/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import CoreLocation
import Foundation
import FutureNova

extension Endpoint {

    static func setupEndpointConfig() {
        ///
        /// Schemes
        ///

        /// Release - Uses main production server for Network requests.
        /// Debug - Uses development server for Network requests.

        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String else {
            fatalError("Could not find SERVER_URL in Info.plist!")
        }
        #if LOCAL
            Endpoint.config.scheme = "http"
            Endpoint.config.port = 3000
        #else
            Endpoint.config.scheme = "https"
        #endif
        Endpoint.config.host = baseURL
        Endpoint.config.commonPath = "/api/v2"
    }

    static func getAllStops() -> Endpoint {
        Endpoint.config.commonPath = "/api/v2"
        return Endpoint(path: Constants.Endpoints.allStops)
    }

    static func getAlerts() -> Endpoint {
        Endpoint.config.commonPath = "/api/v2"
        return Endpoint(path: Constants.Endpoints.alerts)
    }

    static func getRoutes(
        start: Place,
        end: Place,
        time: Date,
        type: SearchType
    ) -> Endpoint? {
        let uid = sharedUserDefaults?.string(forKey: Constants.UserDefaults.uid)
        let body = GetRoutesBody(
            arriveBy: type == .arriveBy,
            end: "\(end.latitude),\(end.longitude)",
            start: "\(start.latitude),\(start.longitude)",
            time: time.timeIntervalSince1970,
            destinationName: end.name,
            originName: start.name,
            uid: uid
        )
        Endpoint.config.commonPath = "/api/v2"
        return Endpoint(path: Constants.Endpoints.getRoutes, body: body)
    }

    static func getMultiRoutes(
        startCoord: CLLocationCoordinate2D,
        time: Date,
        endCoords: [String],
        endPlaceNames: [String]
    ) -> Endpoint {
        let body = MultiRoutesBody(
            start: "\(startCoord.latitude),\(startCoord.longitude)",
            time: time.timeIntervalSince1970,
            end: endCoords,
            destinationNames: endPlaceNames
        )
        Endpoint.config.commonPath = "/api/v2"
        return Endpoint(path: Constants.Endpoints.multiRoute, body: body)
    }

    static func getPlaceIDCoordinates(placeID: String) -> Endpoint {
        Endpoint.config.commonPath = "/api/v2"
        let body = PlaceIDCoordinatesBody(placeID: placeID)
        return Endpoint(path: Constants.Endpoints.placeIDCoordinates, body: body)
    }

    static func getAppleSearchResults(searchText: String) -> Endpoint {
        Endpoint.config.commonPath = "/api/v2"
        let body = SearchResultsBody(query: searchText)
        return Endpoint(path: Constants.Endpoints.appleSearch, body: body)
    }

    static func updateApplePlacesCache(searchText: String, places: [Place]) -> Endpoint {
        Endpoint.config.commonPath = "/api/v2"
        let body = ApplePlacesBody(query: searchText, places: places)
        return Endpoint(path: Constants.Endpoints.applePlaces, body: body)
    }

    static func routeSelected(routeId: String) -> Endpoint {
        Endpoint.config.commonPath = "/api/v2"
        // Add unique identifier to request
        let uid = sharedUserDefaults?.string(forKey: Constants.UserDefaults.uid)

        let body = RouteSelectedBody(routeId: routeId, uid: uid)
        return Endpoint(path: Constants.Endpoints.routeSelected, body: body)
    }

    static func getBusLocations(_ directions: [Direction]) -> Endpoint {
        Endpoint.config.commonPath = "/api/v3"
        let departDirections = directions.filter { $0.type == .depart && $0.tripIdentifiers != nil }

//        let locationsInfo = departDirections.map { direction -> BusLocationsInfo in
//            // The id of the location, or bus stop, the bus needs to get to
//            let stopID = direction.stops.first?.id ?? "-1"
//            return BusLocationsInfo(stopID: stopID, routeID: String(direction.routeNumber), tripIdentifiers: direction.tripIdentifiers!)
//        }
        let locationsInfo = departDirections.flatMap { direction -> [BusLocationsInfoV3] in
            return getBusLocationsInfo(direction: direction)
        }

        let body = GetBusLocationsBodyV3(data: locationsInfo)
        return Endpoint(path: Constants.Endpoints.busLocations, body: body)
    }

    static private func getBusLocationsInfo(direction: Direction) -> [BusLocationsInfoV3] {
        guard let tripIds = direction.tripIdentifiers else {
            return []
        }

        let locationsInfo = tripIds.map({ tripId -> BusLocationsInfoV3 in
            return BusLocationsInfoV3(routeId: String(direction.routeNumber), tripId: tripId)
        })

        return locationsInfo
    }

    // Utilizes the /delays endpoint, only passing in the single trip of interest
    static func getDelay(tripID: String, stopID: String) -> Endpoint {
        Endpoint.config.commonPath = "/api/v3"
        let trip = TripV3(stopId: stopID, tripId: tripID)
        let body = TripBodyV3(data: [trip])
        return Endpoint(path: Constants.Endpoints.delays, body: body)
    }

    static func getAllDelays(trips: [TripV3]) -> Endpoint {
        Endpoint.config.commonPath = "/api/v3"
        let body = TripBodyV3(data: trips)
        return Endpoint(path: Constants.Endpoints.delays, body: body)
    }

    static func getDelayUrl(tripId: String, stopId: String) -> String {
        Endpoint.config.commonPath = "/api/v2"
        let path = "delay"
        return "\(String(describing: Endpoint.config.host))\(path)?stopID=\(stopId)&tripID=\(tripId)"
    }

}
