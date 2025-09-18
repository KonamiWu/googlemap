//
//  AddressInputView.swift
//  TestAnimation
//
//  Created by KONAMI on 2025/9/10.
//
import UIKit

protocol AddressInputViewDelegate: AnyObject {
    func addressInputViewDidBeginEditing(_ textField: UITextField)
    func addressInputViewDidEndEditing(_ textField: UITextField)
    func textFieldDidChange(_ textField: UITextField)
    func didClearDestination()
}

class AddressInputView: UIView {
    private let topView = UIView()
    private let bottomView = UIView()
    private let topImageContainer = UIView()
    private let bottomImageContainer = UIView()
//    private let divider = UIView()
    
    private let startUILabel = UILabel()
    private let destinationTextField = UITextField()
    private let dotImageView = UIImageView(image: UIImage.themed("ic_map_my_location_input"))
    private let destinationActiveDotImageView = UIImageView(image: UIImage.themed("ic_map_target_input_active"))
    private let destinationDeactiveDotImageView = UIImageView(image: UIImage.themed("ic_map_target_input_deactive"))
    private let topClearButton = WellButton()
    private let bottomClearButton = WellButton()
    private var progress: CGFloat = 0
    
    private var topViewHeightConstraint: NSLayoutConstraint!
//    private var dividerTrailingConstraint: NSLayoutConstraint!
//    private var dividerCenterYConstraint: NSLayoutConstraint!
    private var topImageContainerLeadingConstraint: NSLayoutConstraint!
    private let imageContainerWidth: CGFloat = 40
    private let dividerTrailing: CGFloat = 16
    private var originalHeight: CGFloat = 0
    private var dashLayer = CAShapeLayer()
    
    private let addressTextSize: CGFloat = 14
    private var dashColor: UIColor = .appPlaceholder
    private var dashLength: CGFloat = 4
    private var gapLength: CGFloat = 2
    private var thickness: CGFloat = 1
    private var dashPadding: CGFloat = 8
    private var timer: Timer?
    
    private var manualAnimation: Bool = true
    private var startAddress: String?
    private var destinationAddress: String?
    
    weak var delegate: AddressInputViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
//        divider.backgroundColor = .appLine
        dashLayer.strokeColor = UIColor.appPlaceholder.cgColor
        clipsToBounds = true
        
        destinationDeactiveDotImageView.alpha = 0
        destinationActiveDotImageView.alpha = 1
        
        topView.clipsToBounds = true
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.backgroundColor = .appSurface1
        addSubview(topView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = .appSurface1
        addSubview(bottomView)
        topClearButton.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(topClearButton)
        bottomClearButton.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(bottomClearButton)
        
        topImageContainer.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(topImageContainer)
        NSLayoutConstraint.activate([
            topImageContainer.topAnchor.constraint(equalTo: topView.topAnchor),
            topImageContainer.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            topImageContainer.widthAnchor.constraint(equalToConstant: imageContainerWidth)
        ])
        topImageContainerLeadingConstraint = topImageContainer.leadingAnchor.constraint(equalTo: topView.leadingAnchor)
        topImageContainerLeadingConstraint.isActive = true
        
        dotImageView.translatesAutoresizingMaskIntoConstraints = false
        topImageContainer.addSubview(dotImageView)
        NSLayoutConstraint.activate([
            dotImageView.centerXAnchor.constraint(equalTo: topImageContainer.centerXAnchor),
            dotImageView.centerYAnchor.constraint(equalTo: topImageContainer.centerYAnchor)
        ])
        
        startUILabel.isUserInteractionEnabled = false
        startUILabel.text = "your_location".localized
        startUILabel.font = .systemFont(ofSize: addressTextSize)
        startUILabel.translatesAutoresizingMaskIntoConstraints = false
        startUILabel.textColor = .appStatic
        topView.addSubview(startUILabel)
        
        
        NSLayoutConstraint.activate([
            startUILabel.leadingAnchor.constraint(equalTo: topImageContainer.trailingAnchor),
//            startUILabel.topAnchor.constraint(equalTo: topView.topAnchor),
            startUILabel.trailingAnchor.constraint(equalTo: topClearButton.leadingAnchor),
            startUILabel.centerYAnchor.constraint(equalTo: topView.centerYAnchor)
//            startUILabel.bottomAnchor.constraint(equalTo: topView.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            topClearButton.centerYAnchor.constraint(equalTo: topView.centerYAnchor),
            topClearButton.trailingAnchor.constraint(equalTo: topView.trailingAnchor, constant: -16),
            topClearButton.widthAnchor.constraint(equalToConstant: 20),
            topClearButton.heightAnchor.constraint(equalToConstant: 20),
        ])
        topClearButton.setImage(UIImage.themed("ic_clear_address"), for: .normal)
        topClearButton.isHidden = true
        
        NSLayoutConstraint.activate([
            bottomView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            topView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topView.topAnchor.constraint(equalTo: topAnchor),
            topView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topView.heightAnchor.constraint(equalTo: bottomView.heightAnchor, multiplier: 1)
        ])
        
        bottomImageContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(bottomImageContainer)
        NSLayoutConstraint.activate([
            bottomImageContainer.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor),
            bottomImageContainer.topAnchor.constraint(equalTo: bottomView.topAnchor),
            bottomImageContainer.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
            bottomImageContainer.widthAnchor.constraint(equalToConstant: imageContainerWidth)
        ])
        
        destinationActiveDotImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomImageContainer.addSubview(destinationActiveDotImageView)
        NSLayoutConstraint.activate([
            destinationActiveDotImageView.centerXAnchor.constraint(equalTo: bottomImageContainer.centerXAnchor),
            destinationActiveDotImageView.centerYAnchor.constraint(equalTo: bottomImageContainer.centerYAnchor)
        ])
        
        destinationDeactiveDotImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomImageContainer.addSubview(destinationDeactiveDotImageView)
        NSLayoutConstraint.activate([
            destinationDeactiveDotImageView.centerXAnchor.constraint(equalTo: bottomImageContainer.centerXAnchor),
            destinationDeactiveDotImageView.centerYAnchor.constraint(equalTo: bottomImageContainer.centerYAnchor)
        ])
        
        destinationTextField.font = .systemFont(ofSize: addressTextSize, weight: .medium)
        destinationTextField.delegate = self
        destinationTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        destinationTextField.returnKeyType = .done
        destinationTextField.translatesAutoresizingMaskIntoConstraints = false
        destinationTextField.textColor = .appStatic
        destinationTextField.attributedPlaceholder = NSAttributedString(string: "route_destination_placeholder".localized, attributes: [.foregroundColor: UIColor.appPlaceholder, .font: UIFont.systemFont(ofSize: 14)])
        bottomView.addSubview(destinationTextField)
        
        NSLayoutConstraint.activate([
            destinationTextField.leadingAnchor.constraint(equalTo: bottomImageContainer.trailingAnchor),
            destinationTextField.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            destinationTextField.trailingAnchor.constraint(equalTo: bottomClearButton.leadingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            bottomClearButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            bottomClearButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -16),
            bottomClearButton.widthAnchor.constraint(equalToConstant: 20),
            bottomClearButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        bottomClearButton.setImage(UIImage.themed("ic_clear_address"), for: .normal)
        bottomClearButton.isHidden = true
        bottomClearButton.addTarget(self, action: #selector(bottomClearAction), for: .touchUpInside)
        
//        divider.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(divider)
//        divider.heightAnchor.constraint(equalToConstant: 2).isActive = true
//        divider.leadingAnchor.constraint(equalTo: topImageContainer.trailingAnchor).isActive = true
//        dividerTrailingConstraint = divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -dividerTrailing)
//        dividerTrailingConstraint.isActive = true
//        dividerCenterYConstraint = divider.centerYAnchor.constraint(equalTo: centerYAnchor)
//        dividerCenterYConstraint.isActive = true
        
        
        dashLayer.lineDashPattern = [NSNumber(value: Float(dashLength)), NSNumber(value: Float(gapLength))]
        dashLayer.lineCap = .butt
        dashLayer.contentsScale = UIScreen.main.scale
        dashLayer.allowsEdgeAntialiasing = false
        layer.addSublayer(dashLayer)
        
//        let topUnderLine = UIView()
//        topUnderLine.backgroundColor = .appStatic
//        topUnderLine.translatesAutoresizingMaskIntoConstraints = false
//        bottomView.addSubview(topUnderLine)
//        NSLayoutConstraint.activate([topUnderLine.leadingAnchor.constraint(equalTo: startUILabel.leadingAnchor),
//                                     topUnderLine.trailingAnchor.constraint(equalTo: startUILabel.trailingAnchor),
//                                     topUnderLine.bottomAnchor.constraint(equalTo: startUILabel.bottomAnchor, constant: 2),
//                                     topUnderLine.heightAnchor.constraint(equalToConstant: 1)])
//        
//        let bottomUnderLine = UIView()
//        bottomUnderLine.backgroundColor = .appStatic
//        bottomUnderLine.translatesAutoresizingMaskIntoConstraints = false
//        bottomView.addSubview(bottomUnderLine)
//        NSLayoutConstraint.activate([bottomUnderLine.leadingAnchor.constraint(equalTo: destinationTextField.leadingAnchor),
//                                     bottomUnderLine.trailingAnchor.constraint(equalTo: destinationTextField.trailingAnchor),
//                                     bottomUnderLine.bottomAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 2),
//                                     bottomUnderLine.heightAnchor.constraint(equalToConstant: 1)])
        
        layout(progress: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if originalHeight == 0 {
            originalHeight = bounds.height
            layer.cornerRadius = originalHeight / 2
            topView.heightAnchor.constraint(equalToConstant: originalHeight).isActive = true
            topViewHeightConstraint = topView.heightAnchor.constraint(equalToConstant: originalHeight)
        }
    }
    
    func focus() {
        destinationTextField.becomeFirstResponder()
    }
    
    func setProgress(_ progress: CGFloat) {
        layout(progress: progress)
        timer?.invalidate()
    }
    
    func setDestinationAddress(_ address: String?) {
        guard let address = address else {
            destinationAddress = nil
            destinationTextField.text = nil
            bottomClearButton.isHidden = true
            return
        }
        destinationAddress = address
        destinationTextField.text = address
        destinationTextField.attributedText = NSAttributedString(string: address, attributes: [NSAttributedString.Key.foregroundColor: UIColor.appStatic, .font: UIFont.systemFont(ofSize: addressTextSize, weight: .medium)])
        bottomClearButton.isHidden = false
    }
    
    func focusDestinationTextField() {
        destinationTextField.becomeFirstResponder()
    }
    
    private func layout(progress: CGFloat) {
        self.progress = progress
//        dividerCenterYConstraint.constant = -(bounds.height * (1 - progress)) / 2
        let dividerWidth = bounds.width - imageContainerWidth - dividerTrailing
//        dividerTrailingConstraint.constant = -dividerWidth / 2 * (1 - progress) - dividerTrailing
        
        topImageContainer.alpha = max((progress - 0.5), 0) * 2
//        divider.alpha = progress
        topView.alpha = max((progress - 0.5), 0) * 2
        
        let path = UIBezierPath()
        let x = dotImageView.center.x
        let topY = convert(dotImageView.frame, from: topImageContainer).maxY
        let bottomY = convert(destinationDeactiveDotImageView.frame, from: bottomImageContainer).minY
        
        let startY = topY + dashPadding
        let endY = bottomY - dashPadding
        dashLayer.opacity = Float(progress)
        if endY > startY {
            path.move(to: CGPoint(x: x, y: startY))
            path.addLine(to: CGPoint(x: x, y: endY))
            dashLayer.path = path.cgPath
        } else {
            dashLayer.path = nil
        }
    }
    
    func expand() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true, block: { [weak self] timer in
            guard let self, progress != 1 else {
                timer.invalidate()
                return
            }
            
            layout(progress: animateValue(current: progress, target: 1))
        })
    }
    
    func collapse() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true, block: { [weak self] timer in
            guard let self, progress != 0 else {
                timer.invalidate()
                return
            }
            
            layout(progress: animateValue(current: progress, target: 0))
        })
    }
    
    
    private func animateValue(current: CGFloat, target: CGFloat, factor: CGFloat = 0.15) -> CGFloat {
        let threshold: CGFloat = 0.01
        
        if abs(current - target) < threshold {
            return target
        } else {
            return current + (target - current) * factor
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        delegate?.textFieldDidChange(textField)
    }
    
    @objc private func bottomClearAction() {
        destinationAddress = nil
        destinationTextField.text = nil
        delegate?.didClearDestination()
        bottomClearButton.isHidden = true
    }
}

extension AddressInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let destinationAddress {
            destinationTextField.text = destinationAddress
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.addressInputViewDidBeginEditing(textField)
    }
}
