//
//  AdressPickAddressPickerViewControllererViewController.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/11.
//

import UIKit
import Combine
import CoreLocation
import GoogleNavigation

protocol AddressPickerViewControllerdelegate: AnyObject {
    func didSelectDestination(address: Address)
    func didClearDestination()
    func didSelectMode(_ mode: GMSNavigationTravelMode)
    func didClickStart(location: CLLocationCoordinate2D)
    func didSelectHome()
    func didSelectCompany()
    func didSelectEdit()
    func didClickMyLocation()
}

class AddressPickerViewController: UIViewController {
    private enum State {
        case collapsed
        case expanded
    }
    
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var grabView: UIView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var addressInputView: AddressInputView!
    @IBOutlet private var spaceView: UIView!
    @IBOutlet private var marginView: UIView!
    @IBOutlet private var addressContainerView: UIView!
    @IBOutlet private var routeContainerView: UIView!
    @IBOutlet private var indicatorView: IndicatorView!
    @IBOutlet private var startButton: UIButton!
    @IBOutlet private var timeLabel: UILabel!
    @IBOutlet private var myLocationButton: UIButton!
    
    @IBOutlet private var walkingImageView: UIImageView!
    @IBOutlet private var motorcycleImageView: UIImageView!
    @IBOutlet private var drivingImageView: UIImageView!
    @IBOutlet private var walkingLabel: UILabel!
    @IBOutlet private var motorcycleLabel: UILabel!
    @IBOutlet private var drivingLabel: UILabel!
    
    @IBOutlet private var addressInputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private var marginViewHeightConstraint: NSLayoutConstraint!
    
    private var containerViewBottomConstraint: NSLayoutConstraint!
    private var cancellables = Set<AnyCancellable>()
    private var addressInputViewExpandHeight: CGFloat = 130
    private var addressInputViewCollapseHeight: CGFloat = 0
    
    private let collapseAddressHeight: CGFloat = 185
    private var collapseRouteHeight: CGFloat = 350
    private let viewModel = AddressPickerViewModel()
    private var panPreviousY: CGFloat = 0
    private var state: State = .expanded
    private var animationDuration: TimeInterval = 0.5
    private var isFirst = true
    private var isFirstAppear = true
    private var isPanning: Bool = false
    private var collapseAddressDistance: CGFloat = 0
    private var collapseRouteDistance: CGFloat = 0
    private var pan: UIPanGestureRecognizer?
    private var timer: Timer?
    
    var drawerHeight: CGFloat {
        containerView.frame.minY
    }
    
    weak var delegate: AddressPickerViewControllerdelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirst {
            isFirst = false
            collapseRouteHeight += view.safeAreaInsets.bottom
            collapseAddressDistance = containerView.bounds.height - collapseAddressHeight + view.safeAreaInsets.bottom - 30
            collapseRouteDistance = containerView.bounds.height - collapseRouteHeight + view.safeAreaInsets.bottom - 30
            containerViewTopConstraint.constant = collapseAddressDistance
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppear {
            isFirstAppear = false
            addressInputView.focus()
        }
    }
    
    private func setupUI() {
        addressInputView.backgroundColor = .appSurface1
        addressInputView.delegate = self
        addressInputViewCollapseHeight = addressInputViewHeightConstraint.constant
        addressInputView.setProgress(0)
        containerView.backgroundColor = .appSurface1
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.appWhite.cgColor
        containerView.layer.cornerRadius = 30
        containerView.clipsToBounds = true
        grabView.backgroundColor = .appCaption
        grabView.layer.cornerRadius = grabView.bounds.height / 2
        spaceView.backgroundColor = .appSurface1
        tableView.separatorColor = .appWhite
        marginView.backgroundColor = .appWhite
        tableView.backgroundColor = .appSurface1
        
        walkingImageView.image = UIImage.themed("ic_route_type_walking_active")
        motorcycleImageView.image = UIImage.themed("ic_route_type_motorcycle_deactive")
        drivingImageView.image = UIImage.themed("ic_route_type_driving_deactive")
        walkingLabel.text = "walking".localized
        motorcycleLabel.text = "motorcycle".localized
        drivingLabel.text = "driving".localized
        startButton.setTitle("start".localized, for: .normal)
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        pan.delaysTouchesBegan = false
        self.pan = pan
        containerView.addGestureRecognizer(pan)
        
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        startButton.backgroundColor = .appPrimary
        startButton.layer.cornerRadius = 16
        
        marginView.backgroundColor = .appWhite
        indicatorView.delegate = self
        
        myLocationButton.setImage(UIImage.themed("ic_my_location"), for: .normal)
        myLocationButton.backgroundColor = .appSurface1
        myLocationButton.layer.cornerRadius = 16
        myLocationButton.layer.borderWidth = 2
        myLocationButton.layer.borderColor = UIColor.appWhite.cgColor
        myLocationButton.addTarget(self, action: #selector(myLocationButtonAction), for: .touchUpInside)
    }
    
    private func bind() {
        viewModel.$availableAddresses.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self else { return }
            
            tableView.reloadData()
        }.store(in: &cancellables)
    }
    
    @objc private func panAction(_ gesture: UIPanGestureRecognizer) {
        let expandConstant: CGFloat = 0
        let collapseConstant: CGFloat = viewModel.destination == nil ? collapseAddressDistance : collapseRouteDistance
        let current = gesture.location(in: view).y
        switch gesture.state {
            case .began:
                isPanning = true
                panPreviousY = current
                view.endEditing(true)
            case .changed:
                let diff = current - panPreviousY
                panPreviousY = current
            
                if containerViewTopConstraint.constant + diff < expandConstant {
                    containerViewTopConstraint.constant = expandConstant
                }
                if containerViewTopConstraint.constant + diff > collapseConstant {
                    containerViewTopConstraint.constant = collapseConstant
                } else {
                    containerViewTopConstraint.constant += diff
                }
                layout()
            default:
                let velocity = gesture.velocity(in: containerView)
                let springVelocity = abs(velocity.y) / 1000.0
            
                if velocity.y > 1000 {
                    collapse(initialVelocity: springVelocity)
                } else if velocity.y < -1000 {
                    addressExpand(initialVelocity: springVelocity)
                } else {
                    if containerView.frame.minY > containerView.bounds.height / 4 {
                        collapse(initialVelocity: springVelocity)
                    } else if containerView.frame.minY < containerView.bounds.height / 4 {
                        addressExpand(initialVelocity: springVelocity)
                    } else {
                        if state == .expanded {
                            addressExpand(initialVelocity: springVelocity)
                        } else {
                            collapse(initialVelocity: springVelocity)
                        }
                    }
                }
        }
    }
    
    private func layout() {
        let distance = viewModel.destination == nil ? collapseAddressDistance : collapseRouteDistance
        let progress = 1 - containerViewTopConstraint.constant / distance
        
        marginViewHeightConstraint.constant = 2 * progress
        
        if viewModel.destination == nil {
            addressContainerView.alpha = 1
            routeContainerView.alpha = 0
            addressInputViewHeightConstraint.constant = addressInputViewCollapseHeight + (addressInputViewExpandHeight - addressInputViewCollapseHeight) * progress
            addressInputView.setProgress(progress)
        } else {
            containerViewLeadingConstraint.constant = 16 * (1 - progress)
            containerViewTrailingConstraint.constant = 16 * (1 - progress)
            addressContainerView.alpha = progress
            routeContainerView.alpha = 1 - progress
        }
    }
    
    
    private func animateValue(current: CGFloat, target: CGFloat, factor: CGFloat = 0.15) -> CGFloat {
        let threshold: CGFloat = 0.01
        
        if abs(current - target) < threshold {
            return target
        } else {
            return current + (target - current) * factor
        }
    }
    
    private func collapse(initialVelocity: CGFloat? = nil) {
        if viewModel.destination == nil {
            addressCollapse(initialVelocity: initialVelocity)
        } else {
            setRoute(initialVelocity: initialVelocity)
        }
    }
    
    private func addressExpand(initialVelocity: CGFloat? = nil) {
        state = .expanded
        addressInputViewHeightConstraint.constant = addressInputViewExpandHeight
        marginViewHeightConstraint.constant = 2
        containerViewTopConstraint.constant = 0
        containerViewBottomConstraint.isActive = false
        containerViewHeightConstraint.isActive = true
        containerViewLeadingConstraint.constant = 0
        containerViewTrailingConstraint.constant = 0
        addressInputView.expand()
        
        if let initialVelocity {
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: initialVelocity,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: {
                    self.view.layoutIfNeeded()
                    self.addressContainerView.alpha = 1
                    self.routeContainerView.alpha = 0
                    self.myLocationButton.alpha = 0
                },
                completion: nil
            )
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.view.layoutIfNeeded()
                self.addressContainerView.alpha = 1
                self.routeContainerView.alpha = 0
                self.myLocationButton.alpha = 0
            }
        }
    }
    
    private func addressCollapse(initialVelocity: CGFloat? = nil) {
        state = .collapsed
        addressInputViewHeightConstraint.constant = addressInputViewCollapseHeight
        marginViewHeightConstraint.constant = 0
        containerViewTopConstraint.constant = collapseAddressDistance
        containerViewBottomConstraint.isActive = false
        containerViewHeightConstraint.isActive = true
        containerViewLeadingConstraint.constant = 0
        containerViewTrailingConstraint.constant = 0
        addressInputView.collapse()
        
        if let initialVelocity {
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: initialVelocity,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: {
                    self.addressContainerView.alpha = 1
                    self.routeContainerView.alpha = 0
                    self.myLocationButton.alpha = 1
                    self.view.layoutIfNeeded()
                },
                completion: nil
            )
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.addressContainerView.alpha = 1
                self.routeContainerView.alpha = 0
                self.myLocationButton.alpha = 1
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func setRoute(initialVelocity: CGFloat? = nil) {
        state = .collapsed
        containerViewTopConstraint.constant = collapseRouteDistance
        containerViewHeightConstraint.isActive = false
        containerViewBottomConstraint.isActive = true
        containerViewLeadingConstraint.constant = 16
        containerViewTrailingConstraint.constant = 16
        addressInputViewHeightConstraint.constant = addressInputViewExpandHeight
        addressInputView.expand()
        
        if let initialVelocity {
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: initialVelocity,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: {
                    self.addressContainerView.alpha = 0
                    self.routeContainerView.alpha = 1
                    self.myLocationButton.alpha = 0
                    self.view.layoutIfNeeded()
                },
                completion: nil
            )
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.addressContainerView.alpha = 0
                self.routeContainerView.alpha = 1
                self.myLocationButton.alpha = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func setDestination(address: Address) {
        addressInputView.setDestinationAddress(address.primaryText)
        viewModel.destination = address
        setRoute()
    }
    
    func setRouteTimeInfo(hours: Int, minutes: Int, kilometers: Int, meters: Int) {
        let result = NSMutableAttributedString()
        let bigTimeAttributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor.appStatic]
        
        let smallTimeAttributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.appStatic]
        
        if hours > 0 {
            result.append(NSAttributedString(string: "\(hours)", attributes: bigTimeAttributes))
            let hourString = String(format: " %@ ", "route_remaining_hours".localized)
            result.append(NSAttributedString(string: hourString, attributes: smallTimeAttributes))
        }
        
        if minutes > 0 {
            let minuteString = String(format: "%@ ", "route_remaining_minutes".localized)
            result.append(NSAttributedString(string: "\(minutes) ", attributes: bigTimeAttributes))
            result.append(NSAttributedString(string: minuteString, attributes: smallTimeAttributes))
        }
        
        result.append(NSAttributedString(string: " (", attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                                                   .foregroundColor: UIColor.appGrey02]))
        if kilometers > 0 {
            result.append(NSAttributedString(string: "\(kilometers) Km ", attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                                                                   .foregroundColor: UIColor.appGrey02]))
        }
        
        if meters > 0 {
            result.append(NSAttributedString(string: "\(meters) m", attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                                                                   .foregroundColor: UIColor.appGrey02]))
        }
        
        
        result.append(NSAttributedString(string: ")", attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                                                               .foregroundColor: UIColor.appGrey02]))
        
        timeLabel.attributedText = result
    }
 
    func cleanRouteInfo() {
        timeLabel.text = ""
    }
    
    @IBAction private func startAction() {
        if let location = viewModel.destination?.coordinate {
            delegate?.didClickStart(location: location)
        }
    }
    
    @objc private func myLocationButtonAction() {
        delegate?.didClickMyLocation()
    }
}

extension AddressPickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.savedAddress.count + 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < collectionView.numberOfItems(inSection: 0) - 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SavedAddressCell", for: indexPath) as! SavedAddressCell
            if indexPath.item == 0 {
                cell.imageView.image = UIImage.themed("ic_map_home")
                cell.titleLabel.text = "home".localized
            } else if indexPath.item == 1 {
                cell.imageView.image = UIImage.themed("ic_map_company")
                cell.titleLabel.text = "company".localized
            } else {
                cell.imageView.image = UIImage.themed("ic_map_start")
                cell.titleLabel.text = viewModel.savedAddress[indexPath.item - 2].name
            }
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "EditAddressCell", for: indexPath) as! EditAddressCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            delegate?.didSelectHome()
        } else if indexPath.row == 1 {
            delegate?.didSelectCompany()
        } else {
            delegate?.didSelectEdit()
        }
    }
}

extension AddressPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return viewModel.historyAddress.count
        } else {
            return viewModel.availableAddresses.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath) as! AddressCell
        if indexPath.section == 0 {
            cell.typeImageView.image = UIImage.themed("ic_map_history_item")
            cell.primaryLabel.text = viewModel.historyAddress[indexPath.row].primaryText
            cell.subtitlesLabel.text = viewModel.historyAddress[indexPath.row].secondaryText
        } else {
            cell.typeImageView.image = UIImage.themed("ic_map_destination_item")
            cell.primaryLabel.text = viewModel.availableAddresses[indexPath.row].primaryText
            cell.subtitlesLabel.text = viewModel.availableAddresses[indexPath.row].secondaryText
        }
        cell.contentView.backgroundColor = .appSurface1

        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 && !viewModel.historyAddress.isEmpty {
            let view = UIView()
            view.backgroundColor = .appSurface1
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "history".localized
            label.textColor = .appGrey01
            label.font = .systemFont(ofSize: 14)
            view.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
            return view
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let address = viewModel.historyAddress[indexPath.row]
            viewModel.destination = address
            addressInputView.setDestinationAddress(address.primaryText)
            delegate?.didSelectDestination(address: address)
            setRoute()
        } else {
            let address = viewModel.availableAddresses[indexPath.row]
            viewModel.destination = address
            addressInputView.setDestinationAddress(address.primaryText)
            delegate?.didSelectDestination(address: address)
            setRoute()
        }
        view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && !viewModel.historyAddress.isEmpty {
            return 40
        }
        
        return 0
    }
}

extension AddressPickerViewController: AddressInputViewDelegate {
    func addressInputViewDidBeginEditing(_ textField: UITextField) {
        addressExpand()
    }
    
    func addressInputViewDidEndEditing(_ textField: UITextField) {

    }
    
    func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }
        viewModel.updateKeyword(text)
    }
    
    func didClearDestination() {
        viewModel.destination = nil
        delegate?.didClearDestination()
        if state == .expanded {
            addressExpand()
        } else {
            addressCollapse()
        }
    }
}

extension AddressPickerViewController: IndicatorViewDelegate {
    func indicatorView(didSelectAt index: Int) {
        if index == 0 {
            walkingImageView.image = UIImage.themed("ic_route_type_walking_active")
            motorcycleImageView.image = UIImage.themed("ic_route_type_motorcycle_deactive")
            drivingImageView.image = UIImage.themed("ic_route_type_driving_deactive")
            walkingLabel.textColor = .appPrimary
            motorcycleLabel.textColor = .appCaption
            drivingLabel.textColor = .appCaption
            delegate?.didSelectMode(.walking)
        } else if index == 1 {
            walkingImageView.image = UIImage.themed("ic_route_type_walking_deactive")
            motorcycleImageView.image = UIImage.themed("ic_route_type_motorcycle_active")
            drivingImageView.image = UIImage.themed("ic_route_type_driving_deactive")
            walkingLabel.textColor = .appCaption
            motorcycleLabel.textColor = .appPrimary
            drivingLabel.textColor = .appCaption
            delegate?.didSelectMode(.twoWheeler)
        } else {
            walkingImageView.image = UIImage.themed("ic_route_type_walking_deactive")
            motorcycleImageView.image = UIImage.themed("ic_route_type_motorcycle_deactive")
            drivingImageView.image = UIImage.themed("ic_route_type_driving_active")
            walkingLabel.textColor = .appCaption
            motorcycleLabel.textColor = .appCaption
            drivingLabel.textColor = .appPrimary
            delegate?.didSelectMode(.driving)
        }
    }
}
