//
//  ViewController.swift
//  TestGoogleMap
//
//  Created by Konami on 2025/9/1.
//

import UIKit
import Combine
import GoogleMaps
import GooglePlaces
import CoreLocation
import GoogleNavigation

final class MapViewController: UIViewController {
    private var cancelables = Set<AnyCancellable>()
    private var mapView: GMSMapView!
    
    private var myMarker = GMSMarker()
    private var destMarker = GMSMarker()
    
    private let markerImage = UIImage.themed("ic_map_marker")
    private let myLocationView = MyLocationView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    private var pickerViewController: AddressPickerViewController?
    private let viewModel = MapViewModel()
    private var isFirst = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        
        if !UserDefaults.standard.areTermsAndConditionsAccepted {
            if !GMSNavigationServices.areTermsAndConditionsAccepted(){
                GMSNavigationServices.showTermsAndConditionsDialogIfNeeded(with: GMSNavigationTermsAndConditionsOptions(companyName: "ThinkAR")) { result in
                    UserDefaults.standard.areTermsAndConditionsAccepted = result
                }
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        if isFirst {
            isFirst = false
            viewModel.startUpdatingLocation()
        }
    }
    
    private func setupUI() {
        navigationController?.navigationBar.isHidden = true
        
        myMarker.iconView = myLocationView
        myMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        destMarker.isDraggable = true
        destMarker.icon = markerImage
        
        mapView = GMSMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.settings.myLocationButton = false
        mapView.settings.compassButton = false
        mapView.delegate = self
        destMarker.map = mapView
        myMarker.map = mapView
        
        view.insertSubview(mapView, at: 0)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let picker = UIStoryboard(name: "AddressPicker", bundle: .main).instantiateViewController(withIdentifier: "AddressPickerViewController") as! AddressPickerViewController
        picker.delegate = self
        picker.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(picker.view)
        NSLayoutConstraint.activate([
            picker.view.topAnchor.constraint(equalTo: view.topAnchor),
            picker.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            picker.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            picker.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        addChild(picker)
        picker.didMove(toParent: self)
        pickerViewController = picker
    }
    private func bind() {
        viewModel.cameraSubject.receive(on: DispatchQueue.main).sink { [weak self] camera in
            guard let self else { return }
            mapView.animate(to: camera)
        }.store(in: &cancelables)
        
        viewModel.$myLocation.receive(on: DispatchQueue.main).sink { [weak self] coordinate in
            guard let self, let coordinate else { return }
            myMarker.position = coordinate
        }.store(in: &cancelables)
        
        viewModel.$myHeading.receive(on: DispatchQueue.main).sink { [weak self] heading in
            guard let self else { return }
            myMarker.rotation = heading
        }.store(in: &cancelables)
        
        viewModel.routeInfoUpdate.receive(on: DispatchQueue.main).sink { [weak self] in
            guard let self else { return }
            
            viewModel.polylines.forEach {
                $0.map = self.mapView
            }
            pickerViewController?.setRouteTimeInfo(hours: viewModel.hours, minutes: viewModel.minutes, kilometers: viewModel.kilometers, meters: viewModel.meters)
            
            guard let path = viewModel.path else { return }
            let bounds = GMSCoordinateBounds(path: path)
            let bottomPadding = pickerViewController?.drawerHeight ?? 0
            let insets = UIEdgeInsets(top: view.safeAreaInsets.top + 40, left: 40, bottom: bottomPadding, right: 40)
            let update = GMSCameraUpdate.fit(bounds, with: insets)
            mapView.animate(with: update)
            
        }.store(in: &cancelables)
    }
}

// MARK: - UITextFieldDelegate
extension MapViewController: AddressPickerViewControllerdelegate {
    func didSelectDestination(address: Address) {
        destMarker.position = address.coordinate
        viewModel.setCamera(to: address.coordinate)
        viewModel.destinationLocation = address.coordinate
    }
    
    func didClearDestination() {
        destMarker.map = nil
        destMarker = GMSMarker()
        destMarker.icon = markerImage
        destMarker.map = mapView
        viewModel.destinationLocation = nil
    }
    
    func didSelectMode(_ mode: GMSNavigationTravelMode) {
        viewModel.mode = mode
    }
    
    func didClickStart(location: CLLocationCoordinate2D) {
        let vc = UIStoryboard(name: "Route", bundle: .main).instantiateViewController(withIdentifier: "RouteViewController") as! RouteViewController
        vc.destination = location
        vc.travelMode = viewModel.mode
        vc.myLocation = viewModel.myLocation
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didSelectHome() {
        if let address = UserDefaults.standard.homeAddress {
            destMarker.position = address.coordinate
            viewModel.setCamera(to: address.coordinate)
            viewModel.destinationLocation = address.coordinate
            pickerViewController?.setDestination(address: address)
            view.endEditing(true)
        } else {
            didSelectEdit()
        }
    }
    
    func didSelectCompany() {
        if let address = UserDefaults.standard.companyAddress {
            destMarker.position = address.coordinate
            viewModel.setCamera(to: address.coordinate)
            viewModel.destinationLocation = address.coordinate
            pickerViewController?.setDestination(address: address)
            view.endEditing(true)
        } else {
            didSelectEdit()
        }
    }
    
    func didSelectEdit() {
        let vc = UIStoryboard(name: "Favorite", bundle: .main).instantiateViewController(withIdentifier: "FavoriteViewController") as! FavoriteViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didClickMyLocation() {
        guard let location = viewModel.myLocation else {
            return
        }
        
        let camera = GMSCameraPosition(latitude: location.latitude, longitude: location.longitude, zoom: 16)
        mapView.animate(to: camera)
    }
}


// MARK: - GMSMapViewDelegate
extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        Task {
            guard let destination = await viewModel.fetchAddressWith(coordinate: coordinate) else { return }
            self.pickerViewController?.setDestination(address: destination)
            viewModel.destinationLocation = coordinate
            destMarker.position = coordinate
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {

        return true
    }
    
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

    }
    
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        Task {
            guard let destinationLocation = await viewModel.fetchAddressWith(coordinate: marker.position) else { return }
            self.pickerViewController?.setDestination(address: destinationLocation)
            viewModel.destinationLocation = marker.position
        }
    }
}
