//
//  Extension.swift
//  TestAnimation
//
//  Created by KONAMI on 2025/9/11.
//

import UIKit

extension UserDefaults {
    private enum Keys {
        static let savedAddresses = "savedAddresses"
        static let homeAddress    = "homeAddress"
        static let companyAddress = "companyAddress"
        static let history        = "historyAddresses"
        static let areTermsAndConditionsAccepted = "areTermsAndConditionsAccepted"
    }

    var areTermsAndConditionsAccepted: Bool {
        get {
            bool(forKey: Keys.areTermsAndConditionsAccepted)
        }
        set {
            set(newValue, forKey: Keys.areTermsAndConditionsAccepted)
        }
    }
    
    var savedAddresses: [SavedAddress] {
        get {
            guard let data = data(forKey: Keys.savedAddresses) else { return [] }
            return (try? JSONDecoder().decode([SavedAddress].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.savedAddresses)
            }
        }
    }

    func addAddress(_ address: SavedAddress) {
        var current = savedAddresses
        current.append(address)
        savedAddresses = current
    }

    func removeAddress(named name: String) {
        savedAddresses = savedAddresses.filter { $0.name != name }
    }

    func clearAddresses() {
        removeObject(forKey: Keys.savedAddresses)
    }

    // Home
    var homeAddress: Address? {
        get {
            guard let data = data(forKey: Keys.homeAddress) else { return nil }
            return try? JSONDecoder().decode(Address.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.homeAddress)
            } else {
                removeObject(forKey: Keys.homeAddress)
            }
        }
    }

    // Company
    var companyAddress: Address? {
        get {
            guard let data = data(forKey: Keys.companyAddress) else { return nil }
            return try? JSONDecoder().decode(Address.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.companyAddress)
            } else {
                removeObject(forKey: Keys.companyAddress)
            }
        }
    }

    // 歷史紀錄
    var history: [Address] {
        get {
            guard let data = data(forKey: Keys.history) else { return [] }
            return (try? JSONDecoder().decode([Address].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.history)
            }
        }
    }

    func addHistory(_ address: Address) {
        var current = history
        current.insert(address, at: 0)
        history = current
    }

    func clearHistory() {
        removeObject(forKey: Keys.history)
    }
}



// MARK: - String Localization
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        let format = NSLocalizedString(self, comment: "")
        return String(format: format, arguments: arguments)
    }
}
