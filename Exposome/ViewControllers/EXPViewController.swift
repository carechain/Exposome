//
//  ViewController.swift
//  IOS9DrawRouteMapKitTutorial
//
//  Created by Arthur Knopper on 09/02/16.
//  Copyright © 2016 Arthur Knopper. All rights reserved.
//

import UIKit
import MapKit
import HealthKit
import HealthKitUI
import CoreData

class EXPViewController: UIViewController, MKMapViewDelegate {
    // State
    var locationManager:CLLocationManager?
    var managedObjectContext: NSManagedObjectContext? = nil
    var events:[Event]?
    var lastEvent:Event?
    var weatherService = EXPOpenWeatherMapService()
    var airQualityService = EXPBreezometerService()

    // UI
    @IBOutlet weak var weatherIcon: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var firstRingView: HKActivityRingView!
    @IBOutlet weak var secondRingView: HKActivityRingView!
    @IBOutlet weak var thirdRingView: HKActivityRingView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var atmosphereLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var windspeedLabel: UILabel!
    @IBOutlet weak var precipitationLabel: UILabel!
    let dateFormatter = DateFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()
        managedObjectContext = self.persistentContainer.viewContext
        weatherService.managedObjectContext = managedObjectContext
        airQualityService.managedObjectContext = managedObjectContext
        // Sync events
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
            events = try managedObjectContext?.fetch(request) as? [Event]
            let numEvents = (events?.count)!
            stepper.minimumValue = 0.0
            stepper.maximumValue = Double(numEvents-1)
            // Setup for location polling
            if numEvents > 0 {
                lastEvent = events?.last
                updateDisplay(numEvents-1)
                stepper.value = stepper.maximumValue
            }
            setupLocation()
       } catch {
            fatalError("Failed to fetch events: \(error)")
        }

        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.mapType = .satellite

        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    
    func updateDisplay(_ step: Int) {
        //print("\(step) (\(self.stepper.maximumValue))")
        var step = step
        let numEvents = (self.events?.count)!
        if step > numEvents - 1 {
            step = numEvents - 1
        }
        if step < 0 {
            step = 0
        }
        //print("\(step) (\(self.stepper.maximumValue))")
        let event = self.events![step]
        let annotation = annotate(event)

        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.showAnnotations([annotation], animated: true )
        self.addressLabel.text = event.address
        let date = event.creationDate!
        self.dateLabel.text = dateFormatter.string(from: date)

        updateWeather(weather: event.weather)
        updatePollen(pollen: event.pollen)
        updateEnvironment(environment: event.environment)
        updateHabitat(habitat: event.habitat)
    }

    func updateWeather(weather: Weather?) {
        guard let weather = weather else { return}
        self.temperatureLabel.text = String( describing: weather.temperature!) + "\u{f03c}"
        self.precipitationLabel.text = String( describing: weather.precipitation) + " mm"
        self.humidityLabel.text = String(describing: weather.humidity!) + "%"
        self.atmosphereLabel.text = String(describing:weather.atmosphere!) + " atm"
        self.windspeedLabel.text = String( describing: weather.windspeed!) + " m/s"
        if let iconString = weather.icon {
            print(iconString)
            let weatherIcon = EXPWeatherIcon(condition: Int(weather.condition), iconString: iconString)
            print(weatherIcon.iconText)
            self.weatherIcon.text = weatherIcon.iconText
        }
    }
    func updatePollen(pollen: Pollen?) {
        guard let pollen = pollen else { return}
        setRing(ring: 0, red: pollen.value1, redLabel: pollen.pollen1!, green: pollen.value2, greenLabel: pollen.pollen2!, blue: pollen.value3, blueLabel: pollen.pollen3!)
    }
    func updateEnvironment(environment: Environment?) {
        guard let environment = environment else { return}
        setRing(ring: 1, red: environment.air, redLabel: "Air", green: environment.water, greenLabel: "Water", blue: environment.soil, blueLabel: "Soil")
    }
    func updateHabitat(habitat: Habitat?) {
        guard let habitat = habitat else { return}
        setRing(ring: 2, red: habitat.stress, redLabel: "Stress", green: habitat.noise, greenLabel: "Noise", blue: habitat.hazard, blueLabel: "Hazard")
    }
    func setRing(ring: Int, red: Double, redLabel: String, green: Double, greenLabel: String, blue: Double, blueLabel: String)
    {
        var ringView: HKActivityRingView
        switch ring {
        case 0:
            ringView = self.firstRingView
        case 1:
            ringView = self.secondRingView
        case 2:
            ringView = self.thirdRingView
        default:
            return
        }
        let summary = HKActivitySummary()
        summary.activeEnergyBurned = HKQuantity(unit: HKUnit.joule(), doubleValue: red)
        summary.activeEnergyBurnedGoal = HKQuantity(unit: HKUnit.joule(), doubleValue: 100.0)

        summary.appleExerciseTime = HKQuantity(unit: HKUnit.hour(), doubleValue: green)
        summary.appleExerciseTimeGoal = HKQuantity(unit: HKUnit.hour(), doubleValue: 100.0)

        summary.appleStandHours = HKQuantity(unit: HKUnit.count(), doubleValue: blue)
        summary.appleStandHoursGoal = HKQuantity(unit: HKUnit.count(), doubleValue: 100.0)

        DispatchQueue.main.async {
            ringView.setActivitySummary(summary, animated: true)
        }
    }
    func annotate(_ event: Event) -> MKPointAnnotation {
        let loc = CLLocationCoordinate2D(latitude: event.latitude as! CLLocationDegrees, longitude: event.longitude as! CLLocationDegrees)
        let placemark = MKPlacemark(coordinate: loc, addressDictionary: nil)
        let annotation = MKPointAnnotation()
        annotation.title = event.address
        if let location = placemark.location {
            annotation.coordinate = location.coordinate
        }
        return annotation
    }

     @IBAction func sequenceValue(_ sender: Any) {
        let stepper = sender as! UIStepper
        let step = Int(stepper.value)
        print("sequenceValue ", step)
        updateDisplay(step)
    }
    func randomizer() -> Double {
        return Double(arc4random_uniform(100))
    }
    func setupLocation() {
        DispatchQueue.main.async { [unowned self] in
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest

            //kCLLocationAccuracyBest
            while !CLLocationManager.locationServicesEnabled() {
                print("Request Authorization")
                self.locationManager?.requestAlwaysAuthorization()
            }
            print("Start Updating Location")
            self.locationManager?.requestAlwaysAuthorization()
            self.locationManager?.startUpdatingLocation()
            self.locationManager?.allowsBackgroundLocationUpdates = true
            if self.lastEvent != nil {
                self.locationManager?.allowDeferredLocationUpdates(untilTraveled: 1000, timeout: 3600)
                print("allowDeferredLocationUpdates")
            }
         }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Locations")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () -> Bool{
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
               // fatalError("Unresolved error \(nserror), \(nserror.userInfo)")

                print("Unresolved error \(nserror), \(nserror.userInfo)")
                return false
            }
            return true
        }
        return false
    }
}

extension EXPViewController: CLLocationManagerDelegate {
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("pause")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        for userLocation in locations {

            if lastEvent == nil ||  (lastEvent != nil && abs((lastEvent?.creationDate?.timeIntervalSinceNow)!) >  TimeInterval(900) ) {
                print("Create event")
                let event = Event(context: self.managedObjectContext!) as Event
                event.creationDate = userLocation.timestamp
                event.latitude = userLocation.coordinate.latitude as NSNumber
                event.longitude = userLocation.coordinate.longitude as NSNumber

                let habitat = Habitat(context: self.managedObjectContext!) as Habitat
                //habitat.stress = randomizer()
                //habitat.noise = randomizer()
                //habitat.hazard = randomizer()
                event.habitat = habitat

                CLGeocoder().reverseGeocodeLocation(userLocation) { (placemarks, error) in
                    //print("placemarks \(String(describing: placemarks))")
                    if error == nil && (placemarks?.count)! > 0 {
                        let placemark = placemarks![0]
                        if let addressDict = placemark.addressDictionary {
                            //print(addressDict)
                            if let city = addressDict["City"] as? String {
                                event.address = city
                            }
                            self.airQualityService.retrieveAirQualityInfo(userLocation) { (pollen, environment, error) in
                                if let error = error {
                                    print("Air Quality Service error", error)
                                    return
                                }
                                guard let pollen = pollen, let environment = environment  else {
                                    return
                                }
                                event.environment = environment
                                event.pollen = pollen
                                //print(pollen, environment)
                                self.weatherService.retrieveWeatherInfo(userLocation) { (weather, error) -> Void in
                                    DispatchQueue.main.async(execute: {
                                        if let error = error {
                                            print("Weather Service error", error)
                                            return
                                        }
                                        guard let weather = weather else {
                                            return
                                        }
                                        event.weather = weather
                                        //print(weather)
                                        if self.saveContext() {
                                            self.events?.append(event)
                                            self.lastEvent = event
                                            let lastIndex = (self.events?.count)!-1
                                            self.stepper.maximumValue = Double(lastIndex)
                                            self.updateDisplay(lastIndex)
                                        }
                                    })
                                }
                            }
                        }
                    } else {
                        print("Placemarks error \(String(describing: error))")
                    }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(String(describing: error))")
    }

}


