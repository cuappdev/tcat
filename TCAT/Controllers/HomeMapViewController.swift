//
//  HomeMapViewController.swift
//  TCAT
//
//  Created by Omar Rasheed on 3/23/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import CoreLocation
import FutureNova
import GoogleMaps
import Reachability
import SnapKit
import UIKit

protocol HomeMapViewDelegate: class {
    func mapViewWillMove()
    func reachabilityChanged(connection: Reachability.Connection)
}

class HomeMapViewController: UIViewController {

    static let optionsCardInset = UIEdgeInsets.init(top: UIScreen.main.bounds.height / 10, left: 20, bottom: 0, right: 20)

    private var loadingView = UIView()
    private var mapView: GMSMapView!

    private var bounds = GMSCoordinateBounds()
    private var currentLocation: CLLocation?
    private weak var delegate: HomeMapViewDelegate?
    private var locationManager = CLLocationManager()
    private var optionsCardVC: HomeOptionsCardViewController!

    private let loadingIndicatorSize = CGSize.init(width: 40, height: 40)
    private let userDefaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupOptionsCard()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkReviewAndRequestLocation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.alpha = 1
    }

    private func setupMapView() {
        // Set mapView with settings
        let camera = GMSCameraPosition.camera(withLatitude: Constants.Map.startingLat, longitude: Constants.Map.startingLong, zoom: 15.5)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.paddingAdjustmentBehavior = .never // handled by code
        mapView.setMinZoom(Constants.Map.minZoom, maxZoom: Constants.Map.maxZoom)
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.settings.tiltGestures = false
        mapView.settings.indoorPicker = false
        mapView.isBuildingsEnabled = false
        mapView.isIndoorEnabled = false
        mapView.padding = .init(top: 0, left: 0, bottom: 10, right: 10)

        let northEast = CLLocationCoordinate2D(latitude: Constants.Values.RouteMaxima.north, longitude: Constants.Values.RouteMaxima.east)
        let southWest = CLLocationCoordinate2D(latitude: Constants.Values.RouteMaxima.south, longitude: Constants.Values.RouteMaxima.west)
        let panBounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        mapView.cameraTargetBounds = panBounds

        self.mapView = mapView
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupOptionsCard() {
        optionsCardVC = HomeOptionsCardViewController(delegate: self)
        add(optionsCardVC)
        delegate = optionsCardVC
    }

    private func setupConstraints() {
        optionsCardVC.view.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(HomeMapViewController.optionsCardInset)
            make.height.equalTo(optionsCardVC.calculateCardHeight())
        }
    }

    /// Show a temporary loading screen
    func showLoadingScreen() {
        loadingView.backgroundColor = Colors.backgroundWash
        view.addSubview(loadingView)

        loadingView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }

        let indicator = LoadingIndicator()
        loadingView.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(loadingIndicatorSize)
        }

    }

    func removeLoadingScreen() {
        loadingView.removeFromSuperview()
        checkReviewAndRequestLocation()
    }

    private func checkReviewAndRequestLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        StoreReviewHelper.checkAndAskForReview()
    }
}

// MARK: Location Delegate
extension HomeMapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        if status == .denied {
            let alertTitle = Constants.Alerts.LocationDisabled.title
            let alertMessage = Constants.Alerts.LocationDisabled.message
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: Constants.Alerts.LocationDisabled.settings, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }

            if let showReminder = userDefaults.value(forKey: Constants.UserDefaults.showLocationAuthReminder) as? Bool {
                if showReminder {
                    let dontRemindAgainAction = UIAlertAction(title: Constants.Alerts.LocationDisabled.cancel, style: .default) { _ in
                        self.userDefaults.set(false, forKey: Constants.UserDefaults.showLocationAuthReminder)
                    }
                    alertController.addAction(dontRemindAgainAction)
                    alertController.addAction(settingsAction)
                    alertController.preferredAction = settingsAction
                    present(alertController, animated: true)
                }
                return
            }
            userDefaults.set(true, forKey: Constants.UserDefaults.showLocationAuthReminder)
            let cancelAction = UIAlertAction(title: Constants.Alerts.LocationDisabled.cancel, style: .default, handler: nil)
            alertController.addAction(cancelAction)
            alertController.addAction(settingsAction)
            alertController.preferredAction = settingsAction
            present(alertController, animated: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
        }
    }

}

extension HomeMapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        delegate?.mapViewWillMove()
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        delegate?.mapViewWillMove()
    }
}

extension HomeMapViewController: HomeOptionsCardDelegate {
    func presentFavoritesTVC() {
        let favoritesTVC = FavoritesTableViewController()
        let navVC = CustomNavigationController(rootViewController: favoritesTVC)
        present(navVC, animated: true)
    }

    func openInformationScreen() {
        let infoVC = InformationViewController()
        let navVC = CustomNavigationController(rootViewController: infoVC)
        present(navVC, animated: true)
    }

    func getCurrentLocation() -> CLLocation? { return currentLocation }

    func updateSize() {
        let newCardHeight = optionsCardVC.calculateCardHeight()
        if newCardHeight != optionsCardVC.view.frame.height {
            UIView.animate(withDuration: 0.2) {
                self.optionsCardVC.view.snp.updateConstraints { make in
                    make.height.equalTo(newCardHeight)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension HomeMapViewController: ReachabilityDelegate {
    func reachabilityChanged(connection: Reachability.Connection) {
        delegate?.reachabilityChanged(connection: connection)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
