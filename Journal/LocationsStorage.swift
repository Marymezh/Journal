/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import CoreLocation

class LocationsStorage {
  static let shared = LocationsStorage()
  
  private(set) var locations: [Location]
  private let fileManager = FileManager.default
  private let documentsURL: URL
  
  private init() {
         self.documentsURL = fileManager.temporaryDirectory
         self.locations = []
         
         loadData()
     }
     
     private func loadData() {
         do {
             let locationFilesURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
             let jsonDecoder = JSONDecoder()
             
             self.locations = try locationFilesURLs.compactMap { url in
                 guard !url.absoluteString.contains(".DS_Store") else {
                     return nil
                 }
                 
                 let data = try Data(contentsOf: url)
                 let location = try jsonDecoder.decode(Location.self, from: data)
                 return location
             }.sorted(by: { $0.date < $1.date })
         } catch {
             print("Error initializing: \(error)")
         }
     }
    
  func saveLocationToDisk(_ location: Location) {
    let encoder = JSONEncoder()
    let timestamp = location.date.timeIntervalSince1970
    let fileURL = documentsURL.appendingPathComponent("\(timestamp)")
    do {
      let data = try encoder.encode(location)
      try data.write(to: fileURL)
    } catch {
        print (error.localizedDescription)
    }
    locations.append(location)
    
    NotificationCenter.default.post(name: .newLocationSaved, object: self, userInfo: ["location" : location])
  }
  func saveCLLocation(_ clLocation: CLLocation) {
    let currentDate = Date()
    
    AppDelegate.geoCoder.reverseGeocodeLocation(clLocation) { placemarks, _ in
      guard let placemarks = placemarks else {return}
      if let place = placemarks.first {
        let location = Location(clLocation.coordinate, date: currentDate, descriptionString: "\(place)")
        
        self.saveLocationToDisk(location)
      }
    }
  }
}

extension Notification.Name {
  static let newLocationSaved = Notification.Name("newLocationsSaved")
}

