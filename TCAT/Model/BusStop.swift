//
//  BusStop.swift
//  TCAT
//
//  Created by Austin Astorga on 3/26/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import CoreLocation

class BusStop: Place {
    var lat: CLLocationDegrees
    var long: CLLocationDegrees
    
    init(name: String, lat: CLLocationDegrees, long: CLLocationDegrees) {
        self.lat = lat
        self.long = long
        
        super.init(name: name)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if (!super.isEqual(object)){
            return false
        }
        
        guard let object = object as? BusStop else {
            return false
        }
        
        return object.lat == lat && object.long == long
    }
    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder) {
        lat = aDecoder.decodeObject(forKey: "latitude") as! CLLocationDegrees
        long = aDecoder.decodeObject(forKey: "longitude") as! CLLocationDegrees
        
        super.init(coder: aDecoder)
    }
    
    public override func encode(with aCoder: NSCoder) {        
        aCoder.encode(self.lat, forKey: "latitude")
        aCoder.encode(self.long, forKey: "longitude")
        
        super.encode(with: aCoder)
    }
}
