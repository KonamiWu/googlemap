//
//  RouteViewModel.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/18.
//

import Combine
import Foundation
import CoreLocation
import GoogleNavigation

class RouteViewModel {
    @Published private(set) var remainingDistanceMeters: Int?
    @Published private(set) var remainingTimeSec: Int?
    @Published private(set) var eta: Date? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    private let service = NavigationService.shared
    
    var mapView: GMSMapView {
        service.mapView
    }
    
    init() {
        bind()
    }
    
    private func bind() {
        service.state.$remainingDistanceMeters.sink { [weak self] in
            guard let self, let value = $0 else { return }
            
            remainingDistanceMeters = Int(value)
        }.store(in: &cancellables)
        
        service.state.$remainingTimeSec.sink { [weak self] in
            guard let self, let value = $0 else { return }
            
            remainingTimeSec = Int(value)
        }.store(in: &cancellables)
        
        service.state.$eta.sink { [weak self] in
            guard let self, let value = $0 else { return }
            
            eta = value
        }.store(in: &cancellables)
    }
    
    func startNavigation(destination: CLLocationCoordinate2D, travelMode: GMSNavigationTravelMode) {
        service.state.travelMode = travelMode
        service.start(destination: destination)
    }
    
    func stopNavigation() {
        service.stop()
    }
    
    func setInitialCameraPosition(coordinate: CLLocationCoordinate2D) {
        service.mapView.camera = GMSCameraPosition(target: coordinate, zoom: 15)
    }
}
