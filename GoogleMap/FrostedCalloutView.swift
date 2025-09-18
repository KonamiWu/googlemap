//
//  FrostedCalloutView.swift
//  GoogleMap
//
//  Created by Konami on 2025/9/2.
//

import UIKit

final class FrostedCalloutView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        layer.masksToBounds = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 10
        blurView.clipsToBounds = true
        addSubview(blurView)
        
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -6)
        ])
        
        alpha = 0
    }
    
    func setText(_ text: String) {
        label.text = text
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func place(at screenPoint: CGPoint) {
        let target = label.systemLayoutSizeFitting(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        let w = target.width + 20
        let h = target.height + 12
        
        frame = CGRect(x: screenPoint.x - w/2, y: screenPoint.y - h - 16 - 32, width: w, height: h)
        blurView.frame = bounds
        
        if alpha == 0 {
            UIView.animate(withDuration: 0.12) {
                self.alpha = 1
            }
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.15) {
            self.alpha = 0
        }
    }
}
