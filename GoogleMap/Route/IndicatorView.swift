//
//  IndicatorView.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/15.
//

import UIKit

protocol IndicatorViewDelegate: AnyObject {
    func indicatorView(didSelectAt index: Int)
}

class IndicatorView: UIView {
    private let indicatorLayer = CALayer()
    private(set) var selectedIndex = 0
    private let isFirst: Bool = true
    
    weak var delegate: IndicatorViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func setup() {
        indicatorLayer.cornerRadius = 1
        var i = 0
        subviews.forEach {
            let button = UIButton()
            button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
            button.tag = i
            i += 1
            button.translatesAutoresizingMaskIntoConstraints = false
            $0.addSubview(button)
            NSLayoutConstraint.activate([button.leadingAnchor.constraint(equalTo: $0.leadingAnchor),
                                         button.topAnchor.constraint(equalTo: $0.topAnchor),
                                         button.trailingAnchor.constraint(equalTo: $0.trailingAnchor),
                                         button.bottomAnchor.constraint(equalTo: $0.bottomAnchor)])
        }
        let view = subviews[0]
        indicatorLayer.frame = CGRect(x: view.frame.minX, y: view.frame.maxY - 2, width: view.frame.width, height: 2)
        indicatorLayer.backgroundColor = UIColor.appPrimary.cgColor
        layer.addSublayer(indicatorLayer)
    }
    
    @objc private func buttonAction(sender: UIButton) {
        guard let view = sender.superview else { return }
        delegate?.indicatorView(didSelectAt: sender.tag)
        indicatorLayer.frame = CGRect(x: view.frame.minX, y: view.frame.maxY - 2, width: view.frame.width, height: 2)
    }
}
