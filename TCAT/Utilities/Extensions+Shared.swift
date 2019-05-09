//
//  UIColor+Shared.swift
//  TCAT
//
//  Created by Annie Cheng on 3/5/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

extension UIColor {

    // Use six-character string of a hex color for initialization
    convenience init(hex: String) {
        let hex = Int(hex, radix: 16)!
        self.init(red: (hex >> 16) & 0xff, green: (hex >> 8) & 0xff, blue: hex & 0xff)
    }

    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

}

extension Double {

    /** Convert distance from meters to proper unit (based on size)
     
     - Huge Distances: 16 mi
     - Medium Distances: 3.2 mi
     - Small Distances: 410 ft (412 ft -> 410 ft)
     
     */
    var roundedString: String {

        let numberOfMetersInMile = 1609.34
        var distanceInMiles = self / numberOfMetersInMile

        switch distanceInMiles {

        case let x where x >= 10:
            return "\(Int(distanceInMiles)) mi"

        case let x where x < 0.1:
            var distanceInFeet = distanceInMiles * 5280
            var temporaryValue = distanceInFeet.roundTo(places: 0) / 10.0
            distanceInFeet = temporaryValue.roundTo(places: 0) * 10.0
            return "\(Int(distanceInFeet)) ft"

        default:
            return "\(distanceInMiles.roundTo(places: 1)) mi"

        }

    }

    /// Rounds the double to decimal places value
    mutating func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return Darwin.round(self * divisor) / divisor
    }

}

extension UIDevice {

    // https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model

    var modelName: String {

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        var identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        let isSimulator = identifier == "i386" || identifier == "x86_64"
        if isSimulator {
            identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"
        }

        let parsedModelName: String = {

            switch identifier {

            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            default:                                        return identifier

            }
        }()

        return isSimulator ? "Simulator: \(parsedModelName)" : parsedModelName

    }

}

extension JSON {

    /// Format date with pattern `"yyyy-MM-dd'T'HH:mm:ssZZZZ"`. Returns current date on error.
    func parseDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        let date = dateFormatter.date(from: self.stringValue) ?? Date.distantPast
        return Time.truncateSeconds(from: date)
    }

    /// Create coordinate object from JSON.
    func parseCoordinates() -> CLLocationCoordinate2D {
        let latitude = self["lat"].doubleValue
        let longitude = self["long"].doubleValue
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Create Bounds object
    func parseBounds() -> Bounds {
        return Bounds(
            minLat: self["minLat"].doubleValue,
            minLong: self["minLong"].doubleValue,
            maxLat: self["maxLat"].doubleValue,
            maxLong: self["maxLong"].doubleValue
        )
    }

    /** Return LocationObject.
     
     `id` is used when bus stops conform to this object.
     Would like a way to extend this class for instances when JSON
     strings are unique to the generic location (e.g. stopID)
     */
    func parseLocationObject() -> LocationObject {
        return LocationObject(
            name: self["name"].stringValue,
            id: self["stopID"].stringValue,
            latitude: self["lat"].doubleValue,
            longitude: self["long"].doubleValue
        )
    }

}

extension CLLocationCoordinate2D: Codable {
    // MARK: CLLocationCoordinate2D+MidPoint
    func middleLocationWith(location: CLLocationCoordinate2D) -> CLLocationCoordinate2D {

        let lon1 = longitude * .pi / 180
        let lon2 = location.longitude * .pi / 180
        let lat1 = latitude * .pi / 180
        let lat2 = location.latitude * .pi / 180
        let dLon = lon2 - lon1
        let x = cos(lat2) * cos(dLon)
        let y = cos(lat2) * sin(dLon)

        let lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) )
        let lon3 = lon1 + atan2(y, cos(lat1) + x)

        let center: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat3 * 180 / .pi, lon3 * 180 / .pi)
        return center
    }

    private enum CodingKeys: String, CodingKey {
        case lat
        case long
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }

    public init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        longitude = try container.decode(Double.self, forKey: .long)
        latitude = try container.decode(Double.self, forKey: .lat)

    }
}

extension DateFormatter {
    static let defaultParser: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return dateFormatter
    }()
}

extension Date {
    static func parseDate(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter.defaultParser
        let date = dateFormatter.date(from: dateString) ?? Date.distantPast
        return Time.truncateSeconds(from: date)
    }
}
