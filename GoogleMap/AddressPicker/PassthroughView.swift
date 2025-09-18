//
//  PassthroughView.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/12.
//
import UIKit

final class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}
