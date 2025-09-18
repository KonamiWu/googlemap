import Foundation
import Combine
import CoreLocation
import GoogleMaps
import GoogleNavigation
import GooglePlaces

class NavigationState: ObservableObject {
    @Published var isGuidanceActive = false
    @Published var travelMode: GMSNavigationTravelMode = .driving
    @Published var destination: CLLocationCoordinate2D?
    @Published var origin: CLLocationCoordinate2D?
    @Published var currentStep: NavStep?
    @Published var remainingSteps: [NavStep] = []
    @Published var remainingDistanceMeters: Double?
    @Published var remainingTimeSec: TimeInterval?
    @Published var navState: GMSNavigationNavState = .unknown
    @Published var eta: Date?
    @Published var status: GMSRouteStatus?
    @Published var errorMessage: String?
}

protocol NavigationCapability {
    var state: NavigationState { get }
    var mapView: GMSMapView? { get }
    func start(destination: CLLocationCoordinate2D)
    func start(destination: String)
    func stop()
}

public struct NavStep {
    public let instruction: String
    public let maneuver: GMSNavigationManeuver?
    public let maneuverImage: UIImage?
}

class NavigationService: NSObject {
    let state = NavigationState()
    let mapView = GMSMapView()
    private var cancellables = Set<AnyCancellable>()
    private var locationUpdated = PassthroughSubject<Void, Never>()
    private var isNavigating = false
    private var navigator: GMSNavigator? {
        return mapView.navigator
    }
    
    override init() {
        super.init()
        
        mapView.isMyLocationEnabled = false
        mapView.isNavigationEnabled = false
        mapView.settings.myLocationButton = true
        mapView.navigator?.add(self)
        
        mapView.settings.navigationHeaderInstructionsTextColor = .appStatic
        mapView.settings.navigationHeaderNextStepTextColor = .appGrey02
        mapView.settings.navigationHeaderLargeManeuverIconColor = .appPrimary
        mapView.settings.navigationHeaderSmallManeuverIconColor = .appGrey02
        mapView.settings.navigationHeaderPrimaryBackgroundColor = .appSurface1
        mapView.settings.navigationHeaderSecondaryBackgroundColor = .appSurface2
        mapView.settings.navigationHeaderBackgroundAlpha = 0.95
        mapView.settings.isNavigationFooterEnabled = false
        
        mapView.settings.navigationHeaderInstructionsFirstRowFont = .systemFont(ofSize: 24, weight: .semibold)
        mapView.settings.navigationHeaderNextStepFont = .systemFont(ofSize: 16, weight: .medium)
    }
    
    func start(destination: CLLocationCoordinate2D) {
        guard let destWaypoint = GMSNavigationWaypoint(location: destination, title: "Destination") else {
            state.status = .noRouteFound
            return
        }
        
        mapView.isMyLocationEnabled = true
        mapView.isNavigationEnabled = true
        
        mapView.roadSnappedLocationProvider?.add(self)
        mapView.roadSnappedLocationProvider?.startUpdatingLocation()
        
        locationUpdated.receive(on: DispatchQueue.main).sink { [weak self] in
            guard let self else { return }
            guard let navigator = navigator else {
                state.status = .internalError
                return
            }
            
            let options = GMSNavigationMutableRoutingOptions()
            options.routingStrategy = .defaultBest
            print("state.travelMode = \(state.travelMode), rawValue = \(state.travelMode.rawValue)")
            mapView.travelMode = state.travelMode
            navigator.setDestinations([destWaypoint], routingOptions: options) { [weak self] in
                guard let self else { return }
                state.status = $0
                
                if $0 == .OK {
                    navigator.isGuidanceActive = true
                } else {
                    navigator.isGuidanceActive = false
                    stop()
                }
                
                switch $0 {
                    case .OK:
                        print("✅ 導航開始成功")
                    case .noRouteFound:
                        print("❗️找不到路線，請檢查起終點位置或交通模式")
                    case .networkError:
                        print("❗️網路連線問題，請檢查網路狀態")
                    case .quotaExceeded:
                        print("❗️API 配額已用完")
                    default:
                        print("❗️導航啟動失敗，status = \($0.rawValue)")
                }
            }
        }.store(in: &cancellables)
    }
    
    func start(destination address: String) {
        
        let placesClient = GMSPlacesClient.shared()
        let filter = GMSAutocompleteFilter()
        
        placesClient.findAutocompletePredictions(fromQuery: address, filter: filter, sessionToken: nil) { [weak self] predictions, error in
            
            guard let self else { return }
            
            if let _ = error {
                state.status = .internalError
                return
            }
            
            guard let placeID = predictions?.first?.placeID else {
                state.status = .internalError
                return
            }
            
            let fields = [GMSPlaceProperty.coordinate.rawValue]
            let request = GMSFetchPlaceRequest(placeID: placeID, placeProperties: fields, sessionToken: nil)
            
            placesClient.fetchPlace(with: request) { [weak self] place, error in
                guard let self else { return }
                if let error = error {
                    print("❗️取回地點失敗: \(error.localizedDescription)")
                    state.status = .internalError
                    return
                }
                
                guard let coordinate = place?.coordinate else {
                    print("❗️找不到地點座標")
                    state.status = .internalError
                    return
                }
                
                start(destination: coordinate)
                state.status = .internalError
            }
        }
    }
    
    func stop() {
        cancellables.removeAll()
        mapView.roadSnappedLocationProvider?.stopUpdatingLocation()
        mapView.isMyLocationEnabled = false
        mapView.isNavigationEnabled = false
        
        navigator?.clearDestinations()
        navigator?.isGuidanceActive = false
        state.currentStep = nil
        state.remainingSteps = []
        state.remainingDistanceMeters = nil
        state.remainingTimeSec = nil
        state.eta = nil
        state.navState = .unknown
        isNavigating = false
    }
}

extension NavigationService: GMSNavigatorListener {
    
    public func navigatorDidChangeRoute(_ navigator: GMSNavigator) {
        
    }
    
    public func navigator(_ navigator: GMSNavigator, didUpdateRemainingTime time: TimeInterval) {
        state.remainingTimeSec = time
        if let t = state.remainingTimeSec {
            state.eta = Date().addingTimeInterval(t)
        }
    }
    
    public func navigator(_ navigator: GMSNavigator, didUpdateRemainingDistance distance: CLLocationDistance) {
        state.remainingDistanceMeters = distance
    }
    
    public func navigator(_ navigator: GMSNavigator, didArriveAt waypoint: GMSNavigationWaypoint) {

    }
    
    public func navigator(_ navigator: GMSNavigator, didUpdate navInfo: GMSNavigationNavInfo) {
        if let currentStep = navInfo.currentStep {
            let option = GMSNavigationStepInfoImageOptions()
            option.maneuverImageSize = GMSNavigationManeuverImageSize.square48
            
            let image = currentStep.maneuverImage(with: option)
            self.state.currentStep = NavStep(instruction: currentStep.fullInstructionText, maneuver: currentStep.maneuver, maneuverImage: image)
        }
        
        state.remainingSteps = navInfo.remainingSteps.map {
            let image = $0.maneuverImage(with: nil)
            
            return NavStep(instruction: $0.fullInstructionText, maneuver: $0.maneuver, maneuverImage: image)
        }
    }
}

extension NavigationService: GMSRoadSnappedLocationProviderListener {
    func locationProvider(_ locationProvider: GMSRoadSnappedLocationProvider, didUpdate location: CLLocation) {
        guard !isNavigating else { return }
        guard location.horizontalAccuracy > 0,
              CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        isNavigating = true
        locationUpdated.send()
    }
}
