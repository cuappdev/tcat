//
//  Network+Models.swift
//  TCAT
//
//  Created by Austin Astorga on 4/6/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import CoreLocation
import Foundation
import SwiftyJSON

// MARK: - Request Bodies
internal struct ApplePlacesBody: Codable {
    let query: String
    let places: [Place]
}

internal struct GetRoutesBody: Codable {
    let arriveBy: Bool
    let end: String
    let start: String
    let time: Double
    let destinationName: String
    let originName: String
    let uid: String?
}

internal struct MultiRoutesBody: Codable {
    let start: String
    let time: Double
    let end: [String]
    let destinationNames: [String]
}

internal struct PlaceIDCoordinatesBody: Codable {
    let placeID: String
}

internal struct SearchResultsBody: Codable {
    let query: String
}

internal struct RouteSelectedBody: Codable {
    let routeId: String
    let uid: String?
}

internal struct GetBusLocationsBody: Codable {
    var data: [BusLocationsInfo]
}

internal struct BusLocationsInfo: Codable {
    let stopID: String
    let routeID: String
    let tripIdentifiers: [String]
}

class RouteSectionsObject: Codable {
    var fromStop: [Route]
    var boardingSoon: [Route]
    var walking: [Route]
}

internal struct GetDelayBody: Codable {

    let stopID: String
    let tripID: String

    func toQueryItems() -> [URLQueryItem] {
        return [URLQueryItem(name: "stopID", value: stopID), URLQueryItem(name: "tripID", value: tripID)]
    }

}

internal struct Trip: Codable {
    let stopID: String
    let tripID: String
}

internal struct TripV3: Codable {
    let stopId: String
    let tripId: String
}

internal struct TripBody: Codable {
    var data: [Trip]
}

internal struct TripBodyV3: Codable {
    var data: [TripV3]
}

internal struct Delay: Codable {
    let tripID: String
    let delay: Int?
}

internal struct DelayV3: Codable {
    let tripId: String
    let delay: Int?
}

// Response
struct Response<T: Codable>: Codable {
    var success: Bool
    var data: T
}
