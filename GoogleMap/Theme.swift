//
//  Style.swift
//  TestAnimation
//
//  Created by KONAMI on 2025/9/10.
//

import UIKit

enum AppTheme {
    case light
    
    var primary: UIColor {
        switch self {
        case .light: return UIColor(hex: "#0ADFC6")
        }
    }

    var primaryLight: UIColor {
        switch self {
        case .light: return UIColor(hex: "#98ECE0")
        }
    }

    var surface1: UIColor {
        switch self {
        case .light: return UIColor(hex: "#F6F6F6")
        }
    }

    var surface2: UIColor {
        switch self {
        case .light: return UIColor(hex: "#EFEFEF")
        }
    }
    
    var staticColor: UIColor {
        switch self {
        case .light: return UIColor(hex: "#303030")
        }
    }

    var placeholder: UIColor {
        switch self {
        case .light: return UIColor(hex: "#A2ACB0")
        }
    }

    var caption: UIColor {
        switch self {
        case .light: return UIColor(hex: "#C3C3C3")
        }
    }

    var line: UIColor {
        switch self {
        case .light: return UIColor(hex: "#F2F2F2")
        }
    }

    var white: UIColor {
        switch self {
        case .light: return UIColor(hex: "#FFFFFF")
        }
    }

    var red: UIColor {
        switch self {
        case .light: return UIColor(hex: "#FFA8A9")
        }
    }

    var grey01: UIColor {
        switch self {
        case .light: return UIColor(hex: "#989898")
        }
    }

    var grey02: UIColor {
        switch self {
        case .light: return UIColor(hex: "#7C7C7C")
        }
    }
}

private class ThemeManager {
    static let shared = ThemeManager()

    private init() {}

    var currentTheme: AppTheme = .light {
        didSet {
            NotificationCenter.default.post(name: .themeChanged, object: nil)
        }
    }
    
}
extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }

        var rgb: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    private static var theme: AppTheme {
            ThemeManager.shared.currentTheme
        }

        static var appPrimary: UIColor      { theme.primary }
        static var appPrimaryLight: UIColor { theme.primaryLight }
        static var appSurface1: UIColor     { theme.surface1 }
        static var appSurface2: UIColor     { theme.surface2 }
        static var appStatic: UIColor       { theme.staticColor }
        static var appPlaceholder: UIColor  { theme.placeholder }
        static var appCaption: UIColor      { theme.caption }
        static var appLine: UIColor         { theme.line }
        static var appWhite: UIColor        { theme.white }
        static var appRed: UIColor          { theme.red }
        static var appGrey01: UIColor       { theme.grey01 }
        static var appGrey02: UIColor       { theme.grey02 }
}

extension UIImage {
    static func themed(_ baseName: String) -> UIImage? {
        switch ThemeManager.shared.currentTheme {
        case .light:
            return UIImage(named: "\(baseName)_light")
        }
    }
}
