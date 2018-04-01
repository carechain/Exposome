//
// Created by Jake Lin on 9/2/15.
// Copyright (c) 2015 Jake Lin. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData
import SwiftyJSON

typealias BreezometerCompletionHandler = (Pollen?, Environment?, SWError?) -> Void

protocol BreezometerServiceProtocol {
    func retrieveAirQualityInfo(_ location: CLLocation, completionHandler: @escaping BreezometerCompletionHandler)
}

struct BreezometerService: BreezometerServiceProtocol  {

  fileprivate let urlPath = "https://api.breezometer.com/baqi/"
  var managedObjectContext: NSManagedObjectContext? = nil

  func retrieveAirQualityInfo(_ location: CLLocation, completionHandler: @escaping BreezometerCompletionHandler) {
    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfig)

    guard managedObjectContext != nil else {
        print("NSManagedObjectContext == nil")
        let error = SWError(errorCode: .invalidContext)
        completionHandler(nil, nil, error)
        return
    }

    guard let url = generateRequestURL(location) else {
      let error = SWError(errorCode: .urlError)
      completionHandler(nil, nil, error)
      return
    }

    let task = session.dataTask(with: url) { (data, response, error) in
      // Check network error
      guard error == nil else {
        let error = SWError(errorCode: .networkRequestFailed)
        completionHandler(nil,nil, error)
        return
      }
      
      // Check JSON serialization error
      guard let data = data else {
        let error = SWError(errorCode: .jsonSerializationFailed)
        completionHandler(nil,nil, error)
        return
      }

      guard let json = try? JSON(data: data) else {
        let error = SWError(errorCode: .jsonParsingFailed)
        completionHandler(nil,nil, error)
        return
      }

        /*
 json: {
 "random_recommendations" : {
 "health" : "There is no real danger for people with health sensitivities. Just keep an eye out for changes in air quality for the next few hours",
 "sport" : "You can go on a run - just keep your nose open for any changes!",
 "inside" : "The amount of pollutants in the air is noticeable, but still there is no danger to your health - It is recommended to continue monitoring changes in the coming hours",
 "outside" : "It's still OK to go out and enjoy a stroll, just pay attention for changes in air quality",
 "children" : "You should supervise your children in the coming hours and monitor changes in air quality"
 },
 "dominant_pollutant_canonical_name" : "pm10",
 "breezometer_description" : "Fair air quality",
 "data_valid" : true,
 "country_description" : "Good air quality",
 "country_aqi_prefix" : "",
 "key_valid" : true,
 "country_aqi" : 37,
 "dominant_pollutant_text" : {
 "main" : "The dominant pollutant is inhalable particulate matter (PM10).",
 "effects" : "Particles enter the lungs and cause local and systemic inflammation in the respiratory system & heart, thus cause cardiovascular and respiratory diseases such as asthma and bronchitis.",
 "causes" : "Main sources are natural dust, smoke and pollen."
 },
 "country_name" : "United States",
 "dominant_pollutant_description" : "Inhalable particulate matter (<10µm)",
 "breezometer_color" : "#96D62B",
 "breezometer_aqi" : 67,
 "country_color" : "#00E400",
 "datetime" : "2018-04-01T09:00:00"
 }*/

      // Get temperature, location and icon and check parsing error
      guard let airQuality = json["breezometer_aqi"].double
         else {
          let error = SWError(errorCode: .jsonParsingFailed)
            completionHandler(nil,nil, error)
          return
        }
        let environment = Environment(context: self.managedObjectContext!)
        environment.air = 100.0 - airQuality
        environment.water = 0.0
        environment.soil = 0.0
        let pollen = Pollen(context: self.managedObjectContext!)
        pollen.pollen1 = "Oak"
        pollen.value1 = 0.0
        pollen.pollen2 = "Birch"
        pollen.value2 = 0.0
        pollen.pollen3 = "Grass"
        pollen.value3 = 0.0

        completionHandler(pollen ,environment, nil)
    }

    task.resume()
  }

  fileprivate func generateRequestURL(_ location: CLLocation) -> URL? {
    guard var components = URLComponents(string:urlPath) else {
      return nil
    }

    // get appId from Info.plist
    let filePath = Bundle.main.path(forResource: "Info", ofType: "plist")!
    let parameters = NSDictionary(contentsOfFile:filePath)
    let appId = parameters!["BreezometerToken"]! as! String

    let latitude = String(location.coordinate.latitude)
    let longitude = String(location.coordinate.longitude)

    components.queryItems = [URLQueryItem(name:"lat", value:latitude),
                             URLQueryItem(name:"lon", value:longitude),
                             URLQueryItem(name:"key", value:appId)]

    return components.url
  }
}
