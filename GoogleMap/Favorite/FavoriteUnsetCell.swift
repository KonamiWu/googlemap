//
//  FavoriteUnsetCell.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/19.
//

import UIKit

class FavoriteUnsetCell: UITableViewCell {
    @IBOutlet var containerView: UIView!
    @IBOutlet var addContainerView: UIView!
    @IBOutlet var typeImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    
    var addAction: (() -> Void)?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        containerView.backgroundColor = .appSurface2
        containerView.layer.cornerRadius = 30
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .appPlaceholder
        
        addressLabel.font = .systemFont(ofSize: 12)
        addressLabel.textColor = .appPlaceholder
        
        addContainerView.backgroundColor = .appWhite
        addContainerView.layer.cornerRadius = addContainerView.bounds.height / 2
        
        addButton.setTitle("add".localized, for: .normal)
        addButton.setTitleColor(.appStatic, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        addButton.backgroundColor = .clear
    }
    
    @IBAction private func addButtonAction() {
        addAction?()
    }
}
