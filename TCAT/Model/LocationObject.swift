//
//  LocationObject.swift
//  TCAT
//
//  Created by Matthew Barker on 9/6/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import MapKit
import UIKit

/// Generic location object for locations with identifiers and names
class LocationObject: NSObject, Codable {

    /// The name of the location
    var name: String

    /// The identifier associated with the location
    /// Used mainly for stopID for bus stop locations.
    var id: String

    /// The latitude coordinate of the location
    var latitude: Double

    /// The longitude coordinate of the location
    var longitude: Double

    init(name: String, id: String, latitude: Double, longitude: Double) {
        self.name = name
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
    }

    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "long"
        case name
        case id = "stopID"
    }

    /// Blank init to store name
    convenience init(name: String) {
        self.init(name: name, id: "", latitude: 0.0, longitude: 0.0)
    }

    /// Init without using the `id` parameter
    convenience init(name: String, latitude: Double, longitude: Double) {
        self.init(name: name, id: "", latitude: latitude, longitude: longitude)
    }

    /// The coordinates of the location.
    var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

}
