//
//  SavedAddressCell.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/12.
//

import UIKit

class SavedAddressCell: UICollectionViewCell {
    @IBOutlet var containerView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dividerView: UIView!
    override func awakeFromNib() {
        containerView.backgroundColor = .appSurface1
        dividerView.backgroundColor = .appGrey01
        titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = .appStatic
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
