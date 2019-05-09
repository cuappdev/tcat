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
import NotificationBannerSwift
import SnapKit
import UIKit

protocol HomeMapViewDelegate {
    func reachabilityChanged(connection: Reachability.Connection)
}

class HomeMapViewController: UIViewController {

    let userDefaults = UserDefaults.standard

    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var loadingView = UIView()
    var bounds = GMSCoordinateBounds()
    var optionsCardVC: HomeOptionsCardViewController!
    var delegate: HomeMapViewDelegate?
    let reachability = Reachability(hostname: Endpoint.config.host ?? "")
    var locationManager = CLLocationManager()
    var banner: StatusBarNotificationBanner? {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    static let optionsCardInset = UIEdgeInsets.init(top: UIScreen.main.bounds.height / 10, left: 20, bottom: 0, right: 20)
    let minZoom: Float = 12
    let defaultZoom: Float = 15.5
    let startingLat = 42.446179
    let startingLong = -76.485070
    let maxZoom: Float = 25
    let loadingIndicatorSize = CGSize.init(width: 40, height: 40)

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return banner != nil ? .lightContent : .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupOptionsCard()
        setupConstraints()
    }

    @objc func reachabilityChanged(_ notification: Notification) {
        guard let reachability = notification.object as? Reachability else {
            return
        }

        // Dismiss current banner or loading indicator, if any
        banner?.dismiss()
        banner = nil

        delegate?.reachabilityChanged(connection: reachability.connection)

        if reachability.connection == .none {
            banner = StatusBarNotificationBanner(title: Constants.Banner.noInternetConnection, style: .danger)
            banner?.autoDismiss = false
            banner?.show(queuePosition: .front, on: navigationController)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true

        // Add Notification Observers
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(_:)),
                                               name: .reachabilityChanged,
                                               object: reachability)
        do {
            try reachability?.startNotifier()
        } catch {
            print("HomeVC viewDidLayoutSubviews: Could not start reachability notifier")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkReviewAndRequestLocation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
        reachability?.stopNotifier()

        // Remove Notification Observers
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)

        // Remove banner and loading indicator
        banner?.dismiss()
        banner = nil
    }

    func setupMapView() {
        // Set mapView with settings
        let camera = GMSCameraPosition.camera(withLatitude: startingLat, longitude: startingLong, zoom: defaultZoom)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.paddingAdjustmentBehavior = .never // handled by code
        mapView.setMinZoom(minZoom, maxZoom: maxZoom)
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

    func setupOptionsCard() {
        optionsCardVC = HomeOptionsCardViewController()
        add(optionsCardVC)
        optionsCardVC.delegate = self
        delegate = optionsCardVC
    }

    func setupConstraints() {
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

    func checkReviewAndRequestLocation() {
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
        optionsCardVC.searchBar.endEditing(true)
    }
}

extension HomeMapViewController: HomeOptionsCardDelegate {
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

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
