//
//  EditFavoriteViewModel.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/18.
//


import Combine
import GooglePlaces
import CoreLocation
import GoogleNavigation

class EditFavoriteViewModel: NSObject {
    @Published private(set) var availableAddresses: [Address] = []
    
    private var originalHistoryAddress = UserDefaults.standard.history
    private let placesClient = GMSPlacesClient.shared()
    private var cancellables = Set<AnyCancellable>()
    private let keywordSubject = PassthroughSubject<String, Never>()
    
    override init() {
        super.init()
        bindKeyword()
    }

    func updateKeyword(_ keyword: String) {
        keywordSubject.send(keyword)
    }

    private func bindKeyword() {
        keywordSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.isEmpty {
                    availableAddresses = []
                } else {
                    let token = GMSAutocompleteSessionToken()
                    fetchPrediction(keyword: text, sessionToken: token)
                }
            }.store(in: &cancellables)
    }

    private func fetchPrediction(keyword: String, sessionToken: GMSAutocompleteSessionToken) {
        availableAddresses = []
        let filter = GMSAutocompleteFilter()
        if let code = Locale.current.region?.identifier {
            filter.countries = [code]
            filter.regionCode = code
        }
        
        placesClient.findAutocompletePredictions(
            fromQuery: keyword,
            filter: filter,
            sessionToken: sessionToken
        ) { [weak self] predictions, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Places API error: \(error.localizedDescription)")
                return
            }
            
            guard let predictions = predictions, !predictions.isEmpty else {
                print("No predictions found")
                return
            }

            Task {
                var result: [Address] = []
                for prediction in predictions {
                    if let place = await self.fetchPlace(placeID: prediction.placeID, sessionToken: sessionToken) {
                        let placeFormattedAddress = place.formattedAddress
                        let predictionPrimaryText = prediction.attributedPrimaryText.string
                        
                        result.append(Address(
                            primaryText: placeFormattedAddress ?? predictionPrimaryText,
                            secondaryText: predictionPrimaryText,
                            coordinate: place.coordinate)
                        )
                    }
                }
                self.availableAddresses = result
            }
        }
    }
    
    private func fetchPlace(placeID: String, sessionToken: GMSAutocompleteSessionToken) async -> GMSPlace? {
        let property: [GMSPlaceProperty] = [.name, .coordinate, .formattedAddress, .placeID]
        let propertyString: [String] = property.map { $0.rawValue }
        
        let request = GMSFetchPlaceRequest(
            placeID: placeID,
            placeProperties: propertyString,
            sessionToken: sessionToken
        )
        
        return await withCheckedContinuation { continuation in
            placesClient.fetchPlace(with: request) { place, error in
                guard let place else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: place)
            }
        }
    }
}
