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
//        containerView.layer.borderWidth = 2
//        containerView.layer.borderColor = UIColor.appWhite.cgColor
        containerView.backgroundColor = .appSurface1
        dividerView.backgroundColor = .appGrey01
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }
}
