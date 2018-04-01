//
//  EXPDataController.swift
//  Exposome
//
//  Created by Johan Sellström on 2018-03-30.
//  Copyright © 2018 Arthur Knopper. All rights reserved.
//
import UIKit
import CoreData
class DataController: NSObject {
    var managedObjectContext: NSManagedObjectContext?
    var persistentContainer: NSPersistentContainer?
    init(completionClosure: @escaping () -> ()) {
        persistentContainer = NSPersistentContainer(name: "DataModel")
        persistentContainer?.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            completionClosure()
        }
    }
}
