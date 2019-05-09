//
//  TodayViewController.swift
//  Today Extension
//
//  Created by Yana Sang on 12/1/18.
//  Copyright © 2018 cuappdev. All rights reserved.
//

import UIKit
import NotificationCenter
import SnapKit
import CoreLocation
import FutureNova

@objc(TodayViewController) class TodayViewController: UIViewController, NCWidgetProviding {

    var routesTable: UITableView = UITableView()
    var favorites: [String] = []
    var coordinates: [String] = []
    var routes: [Route?] = []

    var didFetchRoutes: Bool = false
    var numberOfFavorites: Int = 0

    var locationManager: CLLocationManager!
    var currentLocation: CLLocationCoordinate2D?
    var invalidLocation: Bool = false

    let cellHeight: CGFloat = 110.0
    
    private let networking: Networking = URLSession.shared.request

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Endpoint.setupEndpointConfig()

        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = .compact
        } else {
            // Fallback on earlier versions
        }

        setUpLocation()
        setUpRoutesTableView()
        view.addSubview(routesTable)
        createConstraints()

        favorites = TodayExtensionManager.shared.retrieveFavoritesNames()
        coordinates = TodayExtensionManager.shared.retrieveFavoritesCoordinates()
        numberOfFavorites = favorites.count

        searchForRoutes()
    }

    func searchForRoutes() {
        if numberOfFavorites > 0, let start = currentLocation {
            if (!checkValidCoordinates(location: start)) {
                invalidLocation = true
                routesTable.reloadData()
            } else {
                getMultiRoutes(startCoord: start, time: Date(), endCoords: coordinates, endPlaceNames: favorites).observe { [weak self] result in
                    guard let `self` = self else { return }
                    DispatchQueue.main.async {
                        switch result {
                        case .value(let response):
                            self.routes = response.data
                            self.rearrangeRoutes()
                            self.didFetchRoutes = true
                            if #available(iOSApplicationExtension 10.0, *) {
                                self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
                            } else {
                                // Fallback on earlier versions
                            }
                            self.routesTable.reloadData()
                        case .error(let error):
                            self.processRequestError(error: error)
                        }
                    }
                }
            }
        }
    }
    
    private func getMultiRoutes(startCoord: CLLocationCoordinate2D,
                                time: Date,
                                endCoords: [String],
                                endPlaceNames: [String]) -> Future<Response<[Route?]>> {
        return networking(Endpoint.getMultiRoutes(startCoord: startCoord, time: time, endCoords: endCoords, endPlaceNames: endPlaceNames)).decode()
    }

    func processRequestError(error: Error) {
        let title = "Network Failure: \((error as NSError?)?.domain ?? "No Domain")"
        let description = (error.localizedDescription) + ", " + ((error as NSError?)?.description ?? "n/a")

        routes = []
        print("Error Title: \(title)")
        print("Error Description: \(description)")
    }

    /// Called in response to the user tapping the “Show More” or “Show Less” buttons
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let expanded = activeDisplayMode == .expanded
        preferredContentSize = expanded ? CGSize(width: maxSize.width, height: cellHeight * CGFloat(numberOfFavorites)) : maxSize
        routesTable.reloadData()
    }

    func createConstraints() {
        routesTable.snp.makeConstraints { make in
            let largeCells = CGFloat(116.0 * 2)
            let normalCells = cellHeight * 3
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(largeCells + normalCells)
        }
    }

    /// Re-orders routes so that walking-only routes are at the end of the list of routes. Modifies the list of favorites and coordinates coorespondingly.
    func rearrangeRoutes() {
        var nonNilRoutes = [Route?]()
        var nonNilFavorites = [String]()
        var nonNilCoordinates = [String]()

        var nilRoutes = [Route?]()
        var nilFavorites = [String]()
        var nilCoordinates = [String]()

        routes.enumerated().forEach { (index, route) in
            if route?.directions.first(where: { $0.type == .depart }) != nil {
                nonNilRoutes.append(route)
                nonNilFavorites.append(favorites[index])
                nonNilCoordinates.append(coordinates[index])
            } else {
                nilRoutes.append(route)
                nilFavorites.append(favorites[index])
                nilCoordinates.append(coordinates[index])
            }
        }

        if (nonNilRoutes.count > 0) {
            favorites = nonNilFavorites
            coordinates = nonNilCoordinates
            routes = nonNilRoutes
            numberOfFavorites = nonNilFavorites.count
        } else {
            favorites = nilFavorites
            coordinates = nilCoordinates
            routes = nilRoutes
            numberOfFavorites = nilFavorites.count
        }
    }
}

extension TodayViewController: UITableViewDataSource, UITableViewDelegate {
    private func setUpRoutesTableView() {
        routesTable.delegate = self
        routesTable.dataSource = self
        routesTable.register(TodayExtensionCell.self, forCellReuseIdentifier: Constants.TodayExtension.contentCellIdentifier)
        routesTable.register(TodayExtensionErrorCell.self, forCellReuseIdentifier: Constants.TodayExtension.errorCellIdentifier)
        routesTable.register(LoadingTableViewCell.self, forCellReuseIdentifier: Constants.TodayExtension.loadingCellIdentifier)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if #available(iOSApplicationExtension 10.0, *) {
            let isCompact = extensionContext?.widgetActiveDisplayMode == .compact
            if (isCompact || favorites.isEmpty || routes.isEmpty || !didFetchRoutes) {
                // if: in compact mode, no favorites added, failed to load routes, or in loading state
                return 1
            } else {
                return numberOfFavorites
            }
        } else {
            // Fallback on earlier versions
            return 0
        }

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (invalidLocation) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TodayExtension.errorCellIdentifier, for: indexPath) as! TodayExtensionErrorCell
            cell.mainLabel.text = Constants.TodayExtension.locationOutOfRange
            cell.selectionStyle = .none
            return cell
        }
        
        if (numberOfFavorites != 0) { // if number of favorites = 0
            if (routes.isEmpty) { // no routes yet
                if (didFetchRoutes) { // tried to get routes, but none retrieved
                    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TodayExtension.errorCellIdentifier, for: indexPath) as! TodayExtensionErrorCell
                    cell.mainLabel.text = Constants.TodayExtension.unableToLoad
                    cell.selectionStyle = .none
                    return cell
                } else { // still fetching routes
                    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TodayExtension.loadingCellIdentifier, for: indexPath) as! LoadingTableViewCell
                    cell.selectionStyle = .none
                    return cell
                }
            }
            // have routes!! 
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TodayExtension.contentCellIdentifier, for: indexPath) as! TodayExtensionCell
            routes[indexPath.row]?.formatDirections(start: Constants.General.currentLocation, end: favorites[indexPath.row])

            let topPadding = CGFloat((indexPath.row == 0) ? 8.0 : 2.0)
            let bottomPadding = CGFloat((indexPath.row == numberOfFavorites - 1) ? 8.0 : 2.0)
            cell.configure(route: routes[indexPath.row], destination: favorites[indexPath.row], top: topPadding, bottom: bottomPadding)
            cell.selectionStyle = .none
            return cell
        }

        // else: favorites = 0
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TodayExtension.errorCellIdentifier, for: indexPath) as! TodayExtensionErrorCell
        cell.mainLabel.text = Constants.TodayExtension.openIthacaTransit
        cell.mainLabel.font = .getFont(.medium, size: 14.0)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var stringURL: String = "ithaca-transit://"

        if numberOfFavorites != 0 {
            let latLong = coordinates[indexPath.row].components(separatedBy: ",")
            let latitude = latLong[0]
            let longitude = latLong[1]
            let destination = favorites[indexPath.row]

            stringURL += "getRoutes?lat=\(latitude)&long=\(longitude)&stopName=\(destination)"
        }

        if
            let url = stringURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let convertedURL = URL(string: url) {
            extensionContext?.open(convertedURL, completionHandler: nil)
        }

    }

}

extension TodayViewController: CLLocationManagerDelegate {

    private func setUpLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = manager.location else {
            return
        }

        if currentLocation == nil {
            currentLocation = location.coordinate
            searchForRoutes()
        }
    }
    
    /// Returns whether location is valid, checking country extremes.
    func checkValidCoordinates(location: CLLocationCoordinate2D) -> Bool {
        
        let validLatitude = location.latitude <= Constants.Values.RouteBorders.northBorder &&
            location.latitude >= Constants.Values.RouteBorders.southBorder
        
        let validLongitude = location.longitude <= Constants.Values.RouteBorders.eastBorder &&
            location.longitude >= Constants.Values.RouteBorders.westBorder
        
        return validLatitude && validLongitude
    }

}
