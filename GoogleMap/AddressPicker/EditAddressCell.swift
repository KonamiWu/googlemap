//
//  EditAddressCell.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/12.
//
import UIKit

class EditAddressCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    
    override func awakeFromNib() {
        imageView.image = UIImage.themed("ic_favorite_edit")
    }
}
