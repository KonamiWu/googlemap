//
//  DirectionViewController.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/22.
//

import UIKit
import Combine

class DirectionViewController: UIViewController {
    @IBOutlet private var navView: UIView!
    @IBOutlet private var backButton: UIButton!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var tableView: UITableView!
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .appSurface1
        navView.backgroundColor = .clear
        backButton.setImage(UIImage.themed("ic_nav_back_clear"), for: .normal)
        titleLabel.text = "direction".localized
        titleLabel.textColor = .appStatic
        tableView.backgroundColor = .clear
        tableView.separatorColor = .appWhite
    }
    
    func bind() {
        NavigationService.shared.state.$remainingSteps.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self else { return }
            
            tableView.reloadData()
        }.store(in: &cancellables)
    }
    
    @IBAction private func backAction() {
        navigationController?.popViewController(animated: true)
    }
}

extension DirectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NavigationService.shared.state.remainingSteps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DirectionCell", for: indexPath) as! DirectionCell
        let step = NavigationService.shared.state.remainingSteps[indexPath.row]

        cell.maneuverImageView.image = step.maneuverImage?.withTintColor(.appStatic)
        cell.titleLabel.text = step.instruction
        
        let kilometers = step.distanceMeters / 1000
        let meters = step.distanceMeters % 1000
        var resultString = ""
        
        if kilometers > 0 {
            resultString += String(format: "%d %@ ", kilometers, "direction_kilometers".localized)
        }
        if meters > 0 {
            resultString += String(format: "%d %@", meters, "direction_meters".localized)
        }
        
        cell.distanceLabel.text = resultString
        if indexPath.row == 0 {
            cell.setCurrentStyle()
        } else {
            cell.setRemainingStyle()
        }
        return cell
    }
}

class DirectionCell: UITableViewCell {
    @IBOutlet var containerView: UIView!
    @IBOutlet var maneuverImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var imageViewSize: NSLayoutConstraint!
    
    override func awakeFromNib() {
        containerView.backgroundColor = .clear
        backgroundColor = .clear
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .appStatic
        
        distanceLabel.font = .systemFont(ofSize: 12, weight: .regular)
        distanceLabel.textColor = .appGrey02
    }
    
    func setCurrentStyle() {
        containerView.backgroundColor = .clear
        backgroundColor = .clear
        imageViewSize.constant = 45
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    }
    
    func setRemainingStyle() {
        containerView.backgroundColor = .clear
        backgroundColor = .clear
        imageViewSize.constant = 24
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
    }
}
