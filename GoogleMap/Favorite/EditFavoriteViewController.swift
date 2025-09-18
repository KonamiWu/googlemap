//
//  EditFavoriteViewController.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/18.
//
import UIKit
import Combine

class EditFavoriteViewController: UIViewController {
    enum FavoriteType {
        case home
        case company
    }
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var textContainer: UIView!
    @IBOutlet private var backButton: UIButton!
    @IBOutlet private var typeImageView: UIImageView!
    @IBOutlet private var textField: UITextField!
    @IBOutlet private var tableView: UITableView!
    
    private var cancellables: Set<AnyCancellable> = []
    private let viewModel = EditFavoriteViewModel()
    
    var favoriteType: FavoriteType = .home
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
    
    private func setupUI() {
        view.backgroundColor = .appSurface1
        textContainer.backgroundColor = .appWhite
        textContainer.layer.cornerRadius = textContainer.bounds.height / 2
        backButton.setImage(UIImage.themed("ic_nav_back"), for: .normal)
        let placeholderString: String
        switch favoriteType {
        case .company:
            typeImageView.image = UIImage.themed("ic_favorite_company_active")
            placeholderString = "favorite_company_placeholder".localized
        case .home:
            typeImageView.image = UIImage.themed("ic_favorite_home_active")
            placeholderString = "favorite_home_placeholder".localized
        }
        textField.textColor = .appStatic
        textField.font = .systemFont(ofSize: 14, weight: .medium)
        textField.attributedPlaceholder = NSAttributedString(string: placeholderString,
                                                             attributes: [.foregroundColor: UIColor.appPlaceholder,
                                                                          .font: UIFont.systemFont(ofSize: 14, weight: .regular)])
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func bind() {
        viewModel.$availableAddresses.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self else { return }
            
            tableView.reloadData()
        }.store(in: &cancellables)
    }
    
    @IBAction private func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }
        viewModel.updateKeyword(text)
    }
}

extension EditFavoriteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.availableAddresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath) as! AddressCell
        cell.typeImageView.image = UIImage.themed("ic_map_destination_item")
        cell.primaryLabel.text = viewModel.availableAddresses[indexPath.row].primaryText
        cell.subtitlesLabel.text = viewModel.availableAddresses[indexPath.row].secondaryText
        cell.contentView.backgroundColor = .appSurface1

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let address = viewModel.availableAddresses[indexPath.row]
        
        switch favoriteType {
            case .home:
                UserDefaults.standard.homeAddress = address
            case .company:
                UserDefaults.standard.companyAddress = address
        }
        
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
}

extension EditFavoriteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
