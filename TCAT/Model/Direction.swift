//
//  Direction.swift
//  TCAT
//
//  Created by Monica Ong on 2/12/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SwiftyJSON

/* To get string version of Bound
 * let inbound: String = Bound.inbound.rawValue  //"inbound"
 * let outbound: String = Bound.inbound.rawValue //"outbound"
 */
enum Bound: String {
    case inbound, outbound
}

/// An enum for the type of direction
enum DirectionType: String {
    case walk, depart, arrive, other
}

class LocationObject: NSObject {
    
    /// The name of the location
    var name: String
    
    /// The latitude coordinate of the location
    var latitude: Double
    
    /// The longitude coordinate of the location
    var longitude: Double
    
    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// The coordinates of the location.
    var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
    
}

class Direction: NSObject, NSCopying {

    var type: DirectionType

    /**
        General description for the direction.
     
        - walk: The description of the place / location the user is walking to
        - depart: The name of the bus stop where the bus is departing from
        - arrive: The name of the bus stop where the user gets off the bus
     */
    var name: String

    /// The starting location associated with the direction
    var startLocation: CLLocationCoordinate2D
    
    /// The starting location associated with the direction
    var endLocation: CLLocationCoordinate2D

    /// The starting time (UTC) associated with the direction. Format: `"yyyy-MM-dd'T'HH:mm:ssZZZZ"`
    var startTime: Date
    
    /// The starting time (UTC) associated with the direction Format: `"yyyy-MM-dd'T'HH:mm:ssZZZZ"`
    var endTime: Date

    /// The corresponding path of the direction
    var path: [CLLocationCoordinate2D]
    
    /// The total distance of the direction, in meters.
    var travelDistance: Double = 0

    /// The number representing the bus route.
    var routeNumber: Int = 0
    
    /// An array of bus stop locations on the bus route, excluding the departure and arrival stop. Empty if `type != .depart`.
    var stops: [LocationObject]
    
    // MARK: Initalizers

    required init (
        type: DirectionType,
        name: String,
        startLocation: CLLocationCoordinate2D,
        endLocation: CLLocationCoordinate2D,
        startTime: Date,
        endTime: Date,
        path: [CLLocationCoordinate2D],
        routeNumber: Int = 0,
        stops: [LocationObject] = []
    ) {
        self.type = type
        self.name = name
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.startTime = startTime
        self.path = path
        self.endTime = endTime
        self.routeNumber = routeNumber
        self.stops = stops
    }

    convenience init(name: String? = nil) {

        let blankLocation = CLLocation()
        let blankTime = Date()

        self.init(
            type: .arrive,
            name: name ?? "",
            startLocation: blankLocation.coordinate,
            endLocation: blankLocation.coordinate,
            startTime: blankTime,
            endTime: blankTime,
            path: []
        )

    }

    convenience init(from json: JSON) {
        
        self.init()
        
        type = {
            switch json["type"].stringValue {
            case "walk" : return .walk
            case "depart" : return .depart
            default: return .other
            }
        }()
        
        name = json["name"].stringValue
        startTime = json["startTime"].parseDate()
        endTime = json["endTime"].parseDate()
        startLocation = json["startLocation"].parseCoordinates()
        endLocation = json["endLocation"].parseCoordinates()
        travelDistance = json["distance"].doubleValue
        routeNumber = json["routeNumber"].int ?? 0
        stops = json["stops"].arrayValue.map { $0.parseLocationObject() }
        
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return Swift.type(of: self).init(
            type: type,
            name: name,
            startLocation: startLocation,
            endLocation: endLocation,
            startTime: startTime,
            endTime: endTime,
            path: path
        )
    }


    // MARK: Descriptions

    /// Returns custom description for locationName based on DirectionType
    var locationNameDescription: String {
        switch type {

        case .depart:
            return "at \(name)"

        case .arrive:
            return "Debark at \(name)"

        case .walk:
            return "Walk to \(name)"

        case .other:
            return name

        }
    }
    
    override var debugDescription: String {
        return """
        {
            type: \(type),
            name: \(name),
            startTime: \(startTime),
            endTime: \(endTime),
            startLocation: \(startLocation),
            endLocation: \(endLocation),
            stops: \(stops),
            distance: \(travelDistance),
            locationNameDescription: \(locationNameDescription),
            stops: \(stops)
        }
        """
    }
    
    // MARK: Functions
    
    /// Convert distance from meters to miles
    var travelDistanceInMiles: Double {
        let numberOfMetersInMile = 1609.34
        var conversion = travelDistance / numberOfMetersInMile
        let numberOfPlaces = travelDistance >= 10 ? 0 : 1
        return conversion.roundToPlaces(places: numberOfPlaces)
    }

    /// Returns readable start time (e.g. 7:49 PM)
    var startTimeDescription: String {
        return timeDescription(startTime)
    }

    /// Returns readable end time (e.g. 7:49 PM)
    var endTimeDescription: String {
        return timeDescription(endTime)
    }

    private func timeDescription(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
}
