//
//  WellButton.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/12.
//

import UIKit

class WellButton: UIButton {
    var tapAreaInsets: UIEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if bounds.contains(point) {
            return true
        }
        
        let extendedBounds = bounds.inset(by: tapAreaInsets)
        
        return extendedBounds.contains(point)
    }
}
