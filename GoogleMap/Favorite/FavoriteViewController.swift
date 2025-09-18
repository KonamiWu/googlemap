//
//  FavoriteViewController.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/18.
//
import UIKit

class FavoriteViewController: UIViewController {
    @IBOutlet private var navBackButton: UIButton!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .appSurface1
        navBackButton.setImage(UIImage.themed("ic_nav_back_clear"), for: .normal)
        titleLabel.text = "nav_title_favorite".localized
    }
    
    private func addAction(type: EditFavoriteViewController.FavoriteType) {
        let vc = UIStoryboard(name: "Favorite", bundle: .main).instantiateViewController(withIdentifier: "EditFavoriteViewController") as! EditFavoriteViewController
        vc.favoriteType = type
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteAction(type: EditFavoriteViewController.FavoriteType) {
        switch type {
        case .home:
            UserDefaults.standard.homeAddress = nil
        case .company:
            UserDefaults.standard.companyAddress = nil
        }
        tableView.reloadData()
    }
    
    @IBAction private func backAction() {
        navigationController?.popViewController(animated: true)
    }
}

extension FavoriteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if let home = UserDefaults.standard.homeAddress {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell") as! FavoriteCell
                cell.typeImageView.image = UIImage.themed("ic_favorite_home_active")
                cell.titleLabel.text = "home".localized
                cell.addressLabel.text = home.secondaryText
                cell.editAction = { [weak self] in
                    guard let self else { return }
                    addAction(type: .home)
                }
                cell.deleteAction = { [weak self] in
                    guard let self else { return }
                    deleteAction(type: .home)
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteUnsetCell") as! FavoriteUnsetCell
                cell.typeImageView.image = UIImage.themed("ic_favorite_home_deactive")
                cell.titleLabel.text = "home".localized
                cell.addressLabel.text = "unset".localized
                cell.addAction = { [weak self] in
                    guard let self else { return }
                    addAction(type: .home)
                }
                return cell
            }
        } else {
            if let companyAddress = UserDefaults.standard.companyAddress {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell") as! FavoriteCell
                cell.typeImageView.image = UIImage.themed("ic_favorite_company_active")
                cell.titleLabel.text = "company".localized
                cell.addressLabel.text = companyAddress.primaryText
                cell.editAction = { [weak self] in
                    guard let self else { return }
                    addAction(type: .company)
                }
                cell.deleteAction = { [weak self] in
                    guard let self else { return }
                    deleteAction(type: .company)
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteUnsetCell") as! FavoriteUnsetCell
                cell.typeImageView.image = UIImage.themed("ic_favorite_company_deactive")
                cell.titleLabel.text = "company".localized
                cell.addressLabel.text = "unset".localized
                cell.addAction = { [weak self] in
                    guard let self else { return }
                    addAction(type: .company)
                }
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            if UserDefaults.standard.homeAddress == nil {
                return 83
            } else {
                return UITableView.automaticDimension
            }
        } else {
            if UserDefaults.standard.companyAddress == nil {
                return 83
            } else {
                return UITableView.automaticDimension
            }
        }
    }
}


