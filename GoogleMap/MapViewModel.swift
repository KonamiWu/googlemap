//
//  ViewModel.swift
//  GoogleMap
//
//  Created by Konami on 2025/9/2.
//

import Combine
import GoogleMaps
import GooglePlaces
import CoreLocation
import GoogleNavigation

class MapViewModel: NSObject {
    @Published private(set) var myLocation: CLLocationCoordinate2D?
    @Published private(set) var myHeading: CLLocationDegrees = 0
    
    private(set) var cameraSubject = PassthroughSubject<GMSCameraPosition, Never>()
    private(set) var routeInfoUpdate = PassthroughSubject<Void, Never>()
    private(set) var path: GMSPath?
    private(set) var polylines: [GMSPolyline] = []
    private(set) var hours: Int = 0
    private(set) var minutes: Int = 0
    private(set) var kilometers: Int = 0
    private(set) var meters: Int = 0
    
    private let locationManager = CLLocationManager()
    private var didSetInitialCamera = false
    var mode = GMSNavigationTravelMode.walking {
        didSet {
            checkRoute()
        }
    }
    
    var startLocation: CLLocationCoordinate2D? {
        didSet {
            checkRoute()
        }
    }
    var destinationLocation: CLLocationCoordinate2D? {
        didSet {
            checkRoute()
        }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func checkRoute() {
        guard let startLocation, let destinationLocation else {
            polylines.forEach {
                $0.map = nil
            }
            return
        }
        
        let modeString: String
        switch mode {
        case .walking:
            modeString = "walking"
        case .twoWheeler:
            modeString = "motorcycle"
        default:
            modeString = "driving"
        }
        
        let key = "AIzaSyB6p2cXCv73A0IcldS3jHXAHiBc7UFbotQ"
        let urlStr = "https://maps.googleapis.com/maps/api/directions/json?origin=\(startLocation.latitude),\(startLocation.longitude)&destination=\(destinationLocation.latitude),\(destinationLocation.longitude)&mode=\(modeString)&key=\(key)"

        guard let url = URL(string: urlStr) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let routes = json["routes"] as? [[String: Any]],
                  let first = routes.first,
                  let legs = first["legs"] as? [[String: Any]],
                  let firstLeg = legs.first,
                  let distance = firstLeg["distance"] as? [String: Any],
                  let duration = firstLeg["duration"] as? [String: Any],
                  let polyline = first["overview_polyline"] as? [String: Any],
                  let points = polyline["points"] as? String else { return }

            
            polylines.forEach {
                $0.map = nil
            }
            path = GMSPath(fromEncodedPath: points)
            let outerLine = GMSPolyline(path: path)
            outerLine.strokeColor = .appPrimary.withAlphaComponent(0.4)
            outerLine.strokeWidth = 8
            
            let innerLine = GMSPolyline(path: path)
            innerLine.strokeColor = .appPrimary
            innerLine.strokeWidth = 4
            
            polylines = [outerLine, innerLine]
            
            let distanceMeters = distance["value"] as? Double ?? 0
            let durationSeconds = duration["value"] as? Double ?? 0
            hours = Int(durationSeconds) / 3600
            minutes = (Int(durationSeconds) % 3600) / 60
            kilometers = Int(distanceMeters) / 1000
            meters = Int(distanceMeters) % 1000
            
            routeInfoUpdate.send()
        }.resume()
    }
    
    func fetchAddressWith(coordinate: CLLocationCoordinate2D) async -> Address? {
        return await withCheckedContinuation { continuation in
            let geocoder = GMSGeocoder()
            geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
                if let error = error {
                    print("Geocoder error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let result = response?.firstResult() else {
                    print("No address found, fallback to Places")
                    Task {
                        let result = await self.lookupNearbyPlace(coordinate)
                        continuation.resume(returning: result)
                    }
                    return
                }
                guard let formattedAddress =  result.lines?.joined(separator: " ") else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let secondaryText =
                    result.thoroughfare ??
                    result.locality ??
                    result.administrativeArea ??
                    ""

                let address = Address(primaryText: formattedAddress,
                                                secondaryText: secondaryText,
                                                coordinate: coordinate)
                continuation.resume(returning: address)
            }
        }
    }

    private func lookupNearbyPlace(_ coordinate: CLLocationCoordinate2D) async -> Address? {
        return await withCheckedContinuation { continuation in
            let fields: GMSPlaceField = [.name, .formattedAddress]
            GMSPlacesClient.shared().findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: fields, callback: { places, error in
                guard error == nil, let place = places?.first?.place else {
                    continuation.resume(returning: nil)
                    return
                }
                guard let formattedAddress = place.formattedAddress else {
                    continuation.resume(returning: nil)
                    return
                }
                print("Nearby place: \(place.name ?? ""), \(place.formattedAddress ?? "")")
                
                let address = Address(primaryText: formattedAddress,
                                      secondaryText: place.name ?? "",
                                                coordinate: coordinate)
                continuation.resume(returning: address)
            })
        }
    }
}


extension MapViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                if !didSetInitialCamera {
                    didSetInitialCamera = true
                    setCamera(to: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), zoom: 14)
                }
            case .notDetermined:
                break
            @unknown default:
                break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !didSetInitialCamera, let location = locations.last else { return }
//        guard let location = locations.last else { return }
        didSetInitialCamera = true
        setCamera(to: location.coordinate, zoom: 16)
        myLocation = location.coordinate
        if startLocation == nil {
            startLocation = location.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !didSetInitialCamera {
            didSetInitialCamera = true
            setCamera(to: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), zoom: 14)
        }
        print("❌ Location error:", error.localizedDescription)
    }
    
    func setCamera(to coord: CLLocationCoordinate2D, zoom: Float = 16) {
        let camera = GMSCameraPosition(latitude: coord.latitude, longitude: coord.longitude, zoom: zoom)
        
        cameraSubject.send(camera)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        myHeading = newHeading.trueHeading
    }
}
