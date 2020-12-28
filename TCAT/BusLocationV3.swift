//
//  BusLocationV3.swift
//  TCAT
//
//  Created by Yana Sang on 12/27/20.
//  Copyright © 2020 cuappdev. All rights reserved.
//

import MapKit
import UIKit

enum BusDataTypeV3: String, Codable {
    /// Invalid data (e.g. bus trip too far in future)
    case invalidData
    /// No data to show
    case noData
    /// Valid data to show
    case validData
}

class BusLocationV3: NSObject, Codable {

    var dataType: BusDataTypeV3
    var latitude: Double
    var longitude: Double
    var routeId: Int
    var vehicleId: String

    private var _iconView: UIView?

    private enum CodingKeys: String, CodingKey {
        case dataType = "case"
        case latitude
        case longitude
        case routeId
        case vehicleId
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dataType = try container.decode(BusDataTypeV3.self, forKey: .dataType)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        routeId = try Int(container.decode(String.self, forKey: .routeId)) ?? 0
        vehicleId = (try? container.decode(String.self, forKey: .vehicleId)) ?? "0"
    }

    init(
        dataType: BusDataTypeV3,
        latitude: Double,
        longitude: Double,
        routeId: Int,
        vehicleId: String
    ) {
        self.dataType = dataType
        self.latitude = latitude
        self.longitude = longitude
        self.routeId = routeId
        self.vehicleId = vehicleId
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.routeId, forKey: "routeId")
    }

    var iconView: UIView {
        if let iconView = _iconView {
            return iconView
        } else {
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            _iconView = BusLocationView(number: routeId, position: coordinates)
            return _iconView!
        }
    }

//    /// The Int type of routeId. Defaults to 0 if can't cast to Int
//    var routeNumber: Int {
//        return Int(routeId) ?? 0
//    }

}
