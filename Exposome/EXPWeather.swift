//
//  Event.swift
//  Exposome
//
//  Created by Johan Sellström on 2018-03-30.
//  Copyright © 2018 Arthur Knopper. All rights reserved.
//

import Foundation
import CoreData

class EXPWeather: NSManagedObject  {
    let atmosphere: Double = 0
    let temperature: Double = 0
    let humidity: Double = 0
    let windvelocity: Double = 0
    let winddirection: Double = 0
    init(atmosphere: Double, temperature: Double, humidity: Double, windvelocity: Double, winddirection: Double) {
        super.init(context: NSManagedObjectContext())
        self.atmosphere = atmosphere
        self.temperature = temperature
        self.humidity = humidity
        self.windvelocity = windvelocity
        self.winddirection = winddirection
    }
}
