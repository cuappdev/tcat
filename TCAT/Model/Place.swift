//
//  Place.swift
//  TCAT
//
//  Created by Monica Ong on 8/31/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import CoreLocation

enum PlaceType: String, Codable {
    case busStop, googlePlace, unknown
}

@objc(Place) class Place: NSObject, Codable {

    var name: String
    var type: PlaceType

    // Additional description of the place (e.g. address, "Bus Stop")
    private var placeDescription: String?

    // Metadata related to the place (e.g. Google Place ID)
    var placeIdentifier: String?

    var latitude: Double?
    var longitude: Double?

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case placeDescription = "detail"
        case placeIdentifier = "placeID"
        case latitude = "lat"
        case longitude = "long"
    }

    init(name: String) {
        self.name = name
        self.type = .unknown
    }
    /// Initializer for Google Places
    convenience init(name: String, placeDescription: String = "", placeIdentifier: String = "") {
        self.init(name: name)
        self.placeDescription = placeDescription
        self.placeIdentifier = placeIdentifier
    }

    /// Initializer for any type of location.
    convenience init(name: String, latitude: Double, longitude: Double) {
        self.init(name: name)
        self.type = .unknown
        self.latitude = latitude
        self.longitude = longitude
    }

    // MARK: Functions

    override var description: String {
        let exception = name == Constants.General.firstFavorite
        return (type == .googlePlace || exception) ? (placeDescription ?? "") : ("Bus Stop")
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Place else {
            return false
        }
        if let identifier = object.placeIdentifier {
            return identifier == placeIdentifier
        }
        return object.name == name
    }

    class func filterAllStops(allStops: [Place]) -> [Place] {

        // Create dictionary of all pulled stops
        let crossReference = allStops.reduce(into: [String: [Place]]()) {
            $0[$1.name, default: []].append($1)
        }

        // Create an array of all stops that are non duplicates by name
        var nonDuplicateStops = crossReference.filter {$1.count == 1}.map { (_, value) -> Place in
            return value.first!
        }

        // Create an array of all stops that are duplicates by name
        let duplicates = crossReference.filter { $1.count > 1 }

        // Begin filtering stops with same names
        duplicates.keys.forEach { key in
            if
                let currentBusStops = duplicates[key],
                let first = currentBusStops.first,
                let second = currentBusStops.last
            {
                guard
                    let firstLat = first.latitude, let firstLong = first.longitude,
                    let secondLat = second.latitude, let secondLong = second.longitude
                    else { return }
                let firstStopLocation = CLLocation(latitude: firstLat, longitude: firstLong)
                let secondStopLocation = CLLocation(latitude: secondLat, longitude: secondLong)

                let distanceBetween = firstStopLocation.distance(from: secondStopLocation)

                if distanceBetween < Constants.Values.maxDistanceBetweenStops {
                    // If stops are too close to each other, combine into a new stop with averaged location and add to list
                    let middleCoordinate = firstStopLocation.coordinate.middleLocationWith(location: secondStopLocation.coordinate)
                    let middleBusStop = Place(name: first.name, latitude: middleCoordinate.latitude, longitude: middleCoordinate.longitude)
                    nonDuplicateStops.append(middleBusStop)
                } else {
                    // If not, add directly to the final list to be returned as data
                    nonDuplicateStops.append(contentsOf: [first, second])
                }
            }
        }

        // Sort in alphabetical order
        let sortedStops = nonDuplicateStops.sorted(by: {$0.name.uppercased() < $1.name.uppercased()})
        return sortedStops
    }
}
