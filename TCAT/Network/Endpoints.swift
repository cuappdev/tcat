//
//  Network+Endpoints.swift
//  TCAT
//
//  Created by Austin Astorga on 4/6/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import Foundation
import CoreLocation
import FutureNova

extension Endpoint {

    static func setupEndpointConfig() {

        //
        // Schemes
        //

        // Release - Uses main production server for Network requests.
        // Debug - Uses development server for Network requests.

        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String else {
            fatalError("Could not find SERVER_URL in Info.plist!")
        }
        Endpoint.config.scheme = "https"
        Endpoint.config.host = baseURL
        Endpoint.config.commonPath = "/api/v2"
    }

    static func getAllStops() -> Endpoint {
        return Endpoint(path: Constants.Endpoints.allStops)
    }

    static func getAlerts() -> Endpoint {
        return Endpoint(path: Constants.Endpoints.alerts)
    }

    static func getRoutes(start: Place,
                          end: Place,
                          time: Date,
                          type: SearchType) -> Endpoint? {
        guard
            let startLat = start.latitude,
            let startLong = start.longitude,
            let endLat = end.latitude,
            let endLong = end.longitude
            else {
                print("[Network] getRoutes() No Valid Coordinates")
                return nil
        }
        let uid = sharedUserDefaults?.string(forKey: Constants.UserDefaults.uid)
        let body = GetRoutesBody(arriveBy: type == .arriveBy, end: "\(endLat),\(endLong)", start: "\(startLat),\(startLong)", time: time.timeIntervalSince1970, destinationName: end.name, originName: start.name, uid: uid)

        return Endpoint(path: Constants.Endpoints.getRoutes, body: body)
    }

    static func getRequestURL(start: Place,
                              end: Place,
                              time: Date,
                              type: SearchType) -> String {
        let path = "route"
        let arriveBy = (type == .arriveBy)
        let endStr = "\(String(describing: end.latitude)),\(String(describing: end.longitude))"
        let startStr =  "\(String(describing: start.latitude)),\(String(describing: start.longitude))"
        let time = time.timeIntervalSince1970

        return  "\(String(describing: Endpoint.config.host))\(path)?arriveBy=\(arriveBy)&end=\(endStr)&start=\(startStr)&time=\(time)&destinationName=\(end.name)&originName=\(start.name)"
    }

    static func getMultiRoutes(startCoord: CLLocationCoordinate2D,
                               time: Date,
                               endCoords: [String],
                               endPlaceNames: [String]) -> Endpoint {
        let body = MultiRoutesBody(start: "\(startCoord.latitude),\(startCoord.longitude)", time: time.timeIntervalSince1970, end: endCoords, destinationNames: endPlaceNames)
        return Endpoint(path: Constants.Endpoints.multiRoute, body: body)

    }

    static func getSearchResults(searchText: String) -> Endpoint {
        let body = SearchResultsBody(query: searchText)
        return Endpoint(path: Constants.Endpoints.searchResults, body: body)
    }

    static func routeSelected(routeId: String) -> Endpoint {
        // Add unique identifier to request
        let uid = sharedUserDefaults?.string(forKey: Constants.UserDefaults.uid)

        let body = RouteSelectedBody(routeId: routeId, uid: uid)
        return Endpoint(path: Constants.Endpoints.routeSelected, body: body)
    }

    static func getBusLocations(_ directions: [Direction]) -> Endpoint {
        let departDirections = directions.filter { $0.type == .depart && $0.tripIdentifiers != nil }

        var locationsInfo: [BusLocationsInfo] = []
        for direction in departDirections {
            // The id of the location, or bus stop, the bus needs to get to

            let stopID = direction.stops.first?.id ?? "-1"
            locationsInfo.append(BusLocationsInfo(stopId: stopID, routeId: String(direction.routeNumber), tripIdentifiers: direction.tripIdentifiers!))
        }

        let body = GetBusLocationsBody(data: locationsInfo)
        return Endpoint(path: Constants.Endpoints.busLocations, body: body)
    }

    static func getDelay(tripId: String, stopId: String) -> Endpoint {
        let queryItems = GetDelayBody(stopId: stopId, tripId: tripId).toQueryItems()
        return Endpoint(path: Constants.Endpoints.delay, queryItems: queryItems)
    }

    static func getDelayUrl(tripId: String, stopId: String) -> String {
        let path = "delay"

        return "\(String(describing: Endpoint.config.host))\(path)?stopID=\(stopId)&tripID=\(tripId)"
    }

}
