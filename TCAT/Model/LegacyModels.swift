//
//  Legacy Models: BusStop & PlaceResult
//  TCAT
//

import UIKit
import CoreLocation

class BusStop: NSObject, NSCoding {

    var name: String
    var lat: CLLocationDegrees
    var long: CLLocationDegrees

    private let nameKey = "name"
    private let latKey = "latitude"
    private let longKey = "longitude"

    init(name: String, lat: CLLocationDegrees, long: CLLocationDegrees) {
        self.lat = lat
        self.long = long
        self.name = name
    }

    override func isEqual(_ object: Any?) -> Bool {
        if !super.isEqual(object) {
            return false
        }

        guard let object = object as? BusStop else {
            return false
        }

        return object.lat == lat && object.long == long
    }

    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObject(forKey: nameKey) as! String
        lat = aDecoder.decodeDouble(forKey: latKey)
        long = aDecoder.decodeDouble(forKey: longKey)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: nameKey)
        aCoder.encode(self.lat, forKey: latKey)
        aCoder.encode(self.long, forKey: longKey)
    }

}

class PlaceResult: NSObject, NSCoding {

    var name: String
    var detail: String
    var placeID: String

    private let nameKey = "name"
    private let detailKey = "detail"
    private let placeIDKey = "placeID"

    init(name: String, detail: String, placeID: String) {
        self.detail = detail
        self.placeID = placeID
        self.name = name
    }

    override func isEqual(_ object: Any?) -> Bool {
        if !super.isEqual(object) {
            return false
        }

        guard let object = object as? PlaceResult else {
            return false
        }

        return object.placeID == placeID
    }

    // MARK: Print
    override var description: String {
        return "PlaceResult(name: \(name), detail: \(detail), placeId: \(placeID))"
    }

    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        detail = (aDecoder.decodeObject(forKey: detailKey) as? String) ?? ""
        placeID = (aDecoder.decodeObject(forKey: placeIDKey) as? String) ?? ""
        name = (aDecoder.decodeObject(forKey: nameKey) as? String) ?? ""
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.detail, forKey: detailKey)
        aCoder.encode(self.placeID, forKey: placeIDKey)
        aCoder.encode(self.name, forKey: nameKey)
    }

}
