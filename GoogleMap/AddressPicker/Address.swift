//
//  Address.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/12.
//
import CoreLocation

struct Address: Codable {
    private struct CodableCoordinate: Codable {
        let latitude: Double
        let longitude: Double

        init(_ coordinate: CLLocationCoordinate2D) {
            latitude = coordinate.latitude
            longitude = coordinate.longitude
        }

        var clCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    let primaryText: String
    let secondaryText: String
    let coordinate: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey {
        case primaryText
        case secondaryText
        case coordinate
    }

    init(primaryText: String, secondaryText: String, coordinate: CLLocationCoordinate2D) {
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.coordinate = coordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primaryText = try container.decode(String.self, forKey: .primaryText)
        secondaryText = try container.decode(String.self, forKey: .secondaryText)
        let codableCoord = try container.decode(CodableCoordinate.self, forKey: .coordinate)
        coordinate = codableCoord.clCoordinate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primaryText, forKey: .primaryText)
        try container.encode(secondaryText, forKey: .secondaryText)
        try container.encode(CodableCoordinate(coordinate), forKey: .coordinate)
    }
}
