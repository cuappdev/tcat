//
//  Endpoints.swift
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
        Endpoint.config.commonPath = "/api/v3"
    }

    static func getAllStops() -> Endpoint {
        return Endpoint(path: Constants.Endpoints.allStops)
    }

    static func getAlerts() -> Endpoint {
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
        return Endpoint(path: "/api/v2\(Constants.Endpoints.getRoutes)", body: body, useCommonPath: false)
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
        return Endpoint(path: "/api/v2\(Constants.Endpoints.multiRoute)", body: body, useCommonPath: false)
    }

    static func getAppleSearchResults(searchText: String) -> Endpoint {
        let body = SearchResultsBody(query: searchText)
        return Endpoint(path: Constants.Endpoints.appleSearch, body: body)
    }

    static func updateApplePlacesCache(searchText: String, places: [Place]) -> Endpoint {
        let body = ApplePlacesBody(query: searchText, places: places)
        return Endpoint(path: Constants.Endpoints.applePlaces, body: body)
    }

    static func routeSelected(routeId: String) -> Endpoint {
        // Add unique identifier to request
        let uid = sharedUserDefaults?.string(forKey: Constants.UserDefaults.uid)

        let body = RouteSelectedBody(routeId: routeId, uid: uid)
        return Endpoint(path: "/api/v2\(Constants.Endpoints.routeSelected)", body: body, useCommonPath: false)
    }

    static func getBusLocations(_ directions: [Direction]) -> Endpoint {
        let departDirections = directions.filter { $0.type == .depart && $0.tripIdentifiers != nil }

        let locationsInfo = departDirections.flatMap { direction -> [BusLocationsInfo] in
            return getBusLocationsInfo(direction: direction)
        }

        let body = GetBusLocationsBody(data: locationsInfo)
        return Endpoint(path: Constants.Endpoints.busLocations, body: body)
    }

    // Returns an array of BusLocationsInfo elements, each corresponding to the direction's tripIdentifiers
    static private func getBusLocationsInfo(direction: Direction) -> [BusLocationsInfo] {
        guard let tripIds = direction.tripIdentifiers else {
            return []
        }

        let locationsInfo = tripIds.map({ tripId -> BusLocationsInfo in
            return BusLocationsInfo(routeId: String(direction.routeNumber), tripId: tripId)
        })

        return locationsInfo
    }

    // Utilizes the /delays endpoint, only passing in the single trip of interest
    static func getDelay(tripID: String, stopID: String) -> Endpoint {
        let trip = Trip(stopId: stopID, tripId: tripID)
        let body = TripBody(data: [trip])
        return Endpoint(path: Constants.Endpoints.delays, body: body)
    }

    static func getAllDelays(trips: [Trip]) -> Endpoint {
        let body = TripBody(data: trips)
        return Endpoint(path: Constants.Endpoints.delays, body: body)
    }

}
