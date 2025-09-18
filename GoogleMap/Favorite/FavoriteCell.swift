//
//  FavoriteCell.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/19.
//
import UIKit

class FavoriteCell: UITableViewCell {
    @IBOutlet var containerView: UIView!
    @IBOutlet var editContainerView: UIView!
    @IBOutlet var typeImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var editButton: UIButton!
    
    var editAction: (() -> Void)?
    var deleteAction: (() -> Void)?
    
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
        titleLabel.textColor = .appStatic
        
        addressLabel.font = .systemFont(ofSize: 12)
        addressLabel.textColor = .appGrey02
        
        deleteButton.setImage(UIImage.themed("ic_favorite_delete"), for: .normal)
        deleteButton.backgroundColor = .appWhite
        deleteButton.layer.cornerRadius = deleteButton.bounds.height / 2
        
        editButton.setTitleColor(.appStatic, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        editButton.setTitle("edit".localized, for: .normal)
        
        editContainerView.backgroundColor = .appWhite
        editContainerView.layer.cornerRadius = editContainerView.bounds.height / 2
    }
    
    @IBAction private func editButtonAction() {
        editAction?()
    }
    
    @IBAction private func deleteButtonAction() {
        deleteAction?()
    }
}
