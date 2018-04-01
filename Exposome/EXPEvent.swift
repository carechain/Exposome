//
//  Event.swift
//  Exposome
//
//  Created by Johan Sellström on 2018-03-30.
//  Copyright © 2018 Arthur Knopper. All rights reserved.
//

import Foundation
import CoreData

class EXPEvent: NSManagedObject  {
    let address: String = ""
    let creationDate: Date = Date()
    let latitude: Double = 0
    let longitude: Double = 0

    init(address: String , creationDate: Date, latitude: Double, longitude: Double) {
        super.init()
        self.address = address
        self.creationDate = creationDate
        self.latitude = latitude
        self.longitude = longitude
    }
}
