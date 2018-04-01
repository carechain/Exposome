//
// Created by Jake Lin on 9/2/15.
// Copyright (c) 2015 Jake Lin. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData
import SwiftyJSON

struct OpenWeatherMapService: WeatherServiceProtocol {
  fileprivate let urlPath = "http://api.openweathermap.org/data/2.5/weather"
  var managedObjectContext: NSManagedObjectContext? = nil

  func retrieveWeatherInfo(_ location: CLLocation, completionHandler: @escaping WeatherCompletionHandler) {
    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfig)

    guard let url = generateRequestURL(location) else {
      let error = SWError(errorCode: .urlError)
      completionHandler(nil, error)
      return
    }

    guard managedObjectContext != nil else {
        print("NSManagedObjectContext == nil")
        let error = SWError(errorCode: .invalidContext)
        completionHandler(nil, error)
        return
    }

    let task = session.dataTask(with: url) { (data, response, error) in
      // Check network error
      guard error == nil else {
        let error = SWError(errorCode: .networkRequestFailed)
        completionHandler(nil, error)
        return
      }
      
      // Check JSON serialization error
      guard let data = data else {
        let error = SWError(errorCode: .jsonSerializationFailed)
        completionHandler(nil, error)
        return
      }

      guard let json = try? JSON(data: data) else {
        let error = SWError(errorCode: .jsonParsingFailed)
        completionHandler(nil, error)
        return
      }

      //print("json:", json)
      // Get temperature, location and icon and check parsing error
      guard let tempDegrees = json["main"]["temp"].double,
        let pressure = json["main"]["pressure"].double,
        let humidity = json["main"]["humidity"].double,
        let windspeed = json["wind"]["speed"].double,
        let weatherCondition = json["weather"][0]["id"].int,
        let iconString = json["weather"][0]["icon"].string else {
          let error = SWError(errorCode: .jsonParsingFailed)
          completionHandler(nil, error)
          return
        }
        let weather = Weather(context: self.managedObjectContext!) as Weather
        weather.atmosphere = Double(round(100*pressure/1013.0)/100)  as NSNumber
        weather.humidity = humidity as NSNumber
        let tempCelsius = round(tempDegrees - 273.15)
        //let tempFarenheit = round(tempDegrees * 9 / 5 - 459.67)
        weather.temperature = tempCelsius as NSNumber
        if let rain = json["rain"]["3h"].double {
            weather.precipitation = rain
        }
/*
        let formatter = MeasurementFormatter()
        let measurement = Measurement(value: round(tempDegrees - 273.15), unit: UnitTemperature.celsius)
        let localTempString = formatter.string(from: measurement)
        print(localTempString)
        if let temp = Int(localTempString) {
            weather.temperature = NSNumber(value:temp)
        }
 */
        weather.uvindex = 2
        if let winddirection = json["wind"]["deg"].double {
            weather.winddirection = winddirection as NSNumber
        }
        weather.windspeed = windspeed as NSNumber
        weather.condition = Int64(weatherCondition)
        weather.icon = iconString
        completionHandler(weather, nil)
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
    let appId = parameters!["OWMAccessToken"]! as! String

    let latitude = String(location.coordinate.latitude)
    let longitude = String(location.coordinate.longitude)

    components.queryItems = [URLQueryItem(name:"lat", value:latitude),
                             URLQueryItem(name:"lon", value:longitude),
                             URLQueryItem(name:"appid", value:appId)]

    return components.url
  }
}
