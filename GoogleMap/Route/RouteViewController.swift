//
//  RouteViewController.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/17.
//

import UIKit
import CoreLocation
import GoogleNavigation
import Combine

class RouteViewController: UIViewController {
    @IBOutlet private var myLocationContainerView: UIView!
    @IBOutlet private var myLocationLabel: UILabel!
    @IBOutlet private var myLocationImageView: UIImageView!
    @IBOutlet private var bottomView: UIView!
    @IBOutlet private var bottomViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var timeLabel: UILabel!
    @IBOutlet private var distanceLabel: UILabel!
    @IBOutlet private var directionButton: UIButton!
    @IBOutlet private var exitButton: UIButton!
    @IBOutlet private var exitContainerView: UIView!
    private var cancellables: Set<AnyCancellable> = []
    private let viewModel = RouteViewModel()
    private let formatter = DateFormatter()
    var destination: CLLocationCoordinate2D?
    var travelMode = GMSNavigationTravelMode.driving
    var myLocation: CLLocationCoordinate2D?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        
        let map = viewModel.mapView
        map.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(map, at: 0)
        NSLayoutConstraint.activate([map.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     map.topAnchor.constraint(equalTo: view.topAnchor),
                                     map.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     map.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        if let destination {
            viewModel.startNavigation(destination: destination, travelMode: travelMode)
        }
    }
    
    private func setupUI() {
        let mapView = NavigationService.shared.mapView
        mapView.padding.bottom = bottomView.bounds.height
        mapView.delegate = self
        myLocationContainerView.alpha = 0
        myLocationContainerView.backgroundColor = .appSurface1
        myLocationContainerView.layer.shadowColor = UIColor.appWhite.cgColor
        myLocationContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        myLocationContainerView.layer.shadowRadius = 2
        myLocationContainerView.layer.cornerRadius = 16
        myLocationImageView.image = UIImage.themed("ic_my_location")
        
        myLocationLabel.text = "re_center".localized
        myLocationLabel.textColor = .appStatic
        bottomView.backgroundColor = .appSurface1
        bottomView.layer.cornerRadius = 30
        bottomView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomViewBottomConstraint.constant = -bottomView.bounds.height
        
        directionButton.layer.cornerRadius = directionButton.bounds.height / 2
        directionButton.backgroundColor = .appCaption
        directionButton.setImage(UIImage.themed("ic_direction"), for: .normal)
        
        exitContainerView.backgroundColor = .appRed
        exitContainerView.layer.cornerRadius = exitButton.bounds.height / 2
        exitButton.layer.cornerRadius = exitButton.bounds.height / 2
        exitButton.setTitleColor(.appWhite, for: .normal)
        exitButton.setAttributedTitle(NSAttributedString(string: "exit".localized, attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .bold),
                                                                                    .foregroundColor: UIColor.appWhite
                                                                                   ]), for: .normal)
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = .current
        
        if let myLocation {
            viewModel.setInitialCameraPosition(coordinate: myLocation)
        }
    }
    
    private func bind() {
        Publishers.CombineLatest3(viewModel.$remainingTimeSec, viewModel.$remainingDistanceMeters, viewModel.$eta).receive(on: DispatchQueue.main).sink { [weak self] in
            guard let self, let time = $0, let distance = $1, let eta = $2 else { return }
            if bottomViewBottomConstraint.constant == -bottomView.bounds.height {
                bottomViewBottomConstraint.constant = 0
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
            let timeString: NSMutableAttributedString
            let hours = Int(time) / 3600
            let minutes = (Int(time) % 3600) / 60
            let bigTimeAttributes: [NSAttributedString.Key : Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.appStatic]
            
            let smallTimeAttributes: [NSAttributedString.Key : Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.appStatic]
            
            let distanceAttributes: [NSAttributedString.Key : Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.appGrey02]
            
            if hours > 0 {
                timeString = NSMutableAttributedString(string: String(format: "%d ", hours),
                                                    attributes: bigTimeAttributes)
                timeString.append(NSAttributedString(string: "route_remaining_hours".localized + " ", attributes: smallTimeAttributes))
                if minutes > 0 {
                    timeString.append(NSMutableAttributedString(string: String(format: "%d ", minutes),
                                                                attributes: bigTimeAttributes))
                    timeString.append(NSAttributedString(string: "route_remaining_minutes".localized, attributes: smallTimeAttributes))
                }
            } else {
                timeString = NSMutableAttributedString(string: String(format: "%d ", minutes),
                                                    attributes: bigTimeAttributes)
                timeString.append(NSAttributedString(string: "route_remaining_minutes".localized, attributes: smallTimeAttributes))
            }
            
            let distanceString: NSMutableAttributedString
            let kms = Float(distance) / 1000
            if kms > 0 {
                let formatter = NumberFormatter()
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 1
                let kmsString = formatter.string(from: NSNumber(value: kms)) ??  String(format: "%.1f", kms)
                let formattedString = String(format: "%@ km", kmsString)
                distanceString = NSMutableAttributedString(string: formattedString,
                                                    attributes: distanceAttributes)
            } else {
                distanceString = NSMutableAttributedString(string: "\(distance) m",
                                                    attributes: distanceAttributes)
            }
            distanceString.append(NSAttributedString(string: " · ", attributes: distanceAttributes))
            
            let dateString = NSAttributedString(string: formatter.string(from: eta), attributes: distanceAttributes)
            distanceString.append(dateString)
            
            timeLabel.attributedText = timeString
            distanceLabel.attributedText = distanceString
            
        }.store(in: &cancellables)
    }
    
    @IBAction private func directionAction() {
        let vc = UIStoryboard(name: "Route", bundle: .main).instantiateViewController(withIdentifier: "DirectionViewController") as! DirectionViewController
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction private func exitAction() {
        viewModel.stopNavigation()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func recenterAction() {
        guard let location = NavigationService.shared.mapView.myLocation else {
            return
        }
        let position = GMSMutableCameraPosition(target: location.coordinate, zoom: 14)
        NavigationService.shared.mapView.animate(to: position)
        UIView.animate(withDuration: 0.3) {
            self.myLocationContainerView.alpha = 0
        }
        NavigationService.shared.mapView.cameraMode = .following
    }
}

extension RouteViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        print("gesturegesturegesturegesture")
        guard mapView.navigator?.isGuidanceActive ?? false else { return }
        if gesture {
            UIView.animate(withDuration: 0.3) {
                self.myLocationContainerView.alpha = 1
            }
        }
    }
}
