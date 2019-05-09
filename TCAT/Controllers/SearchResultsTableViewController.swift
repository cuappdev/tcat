//
//  SearchResultsTableViewController.swift
//  TCAT
//
//  Created by Austin Astorga on 3/5/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation
import DZNEmptyDataSet
import Crashlytics
import FutureNova

protocol DestinationDelegate: class {
    func didSelectPlace(place: Place)
}

protocol SearchBarCancelDelegate: class {
    func didCancel()
}

class SearchResultsTableViewController: UITableViewController {

    let locationManager = CLLocationManager()

    var currentLocation: Place?
    weak var destinationDelegate: DestinationDelegate?
    weak var searchBarCancelDelegate: SearchBarCancelDelegate?
    var timer: Timer?
    var searchBar: UISearchBar?
    var recentSearchesSection: Section!
    var seeAllStopsSection: Section!
    var searchResultsSection: Section!
    var currentLocationSection: Section!
    var favoritesSection: Section!
    var recentLocations: [Place] = []
    var favorites: [Place] = []
    var initialTableViewIndexMinY: CGFloat!
    var isKeyboardVisible = false
    var shouldShowCurrentLocation = true
    var returningFromAllStopsTVC = false
    var returningFromAllStopsBusStop: Place?
    private let networking: Networking = URLSession.shared.request

    var sections: [Section] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Subscribe to Keyboard Notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)

        // Set Up TableView
        tableView.register(GeneralTableViewCell.self, forCellReuseIdentifier: Constants.Cells.seeAllStopsIdentifier)
        tableView.register(GeneralTableViewCell.self, forCellReuseIdentifier: Constants.Cells.currentLocationIdentifier)
        tableView.register(PlaceTableViewCell.self, forCellReuseIdentifier: Constants.Cells.placeIdentifier)
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = Colors.primaryText
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = Colors.backgroundWash
        tableView.showsVerticalScrollIndicator = false
        tableView.reloadData()

        // Set Up LocationManager
        locationManager.delegate = self

        // Fetch RecentLocation and Favorites
        recentLocations = SearchTableViewManager.shared.retrievePlaces(for: Constants.UserDefaults.recentSearch)
        favorites = SearchTableViewManager.shared.retrievePlaces(for: Constants.UserDefaults.favorites)

        // Set Up Sections For TableView
        seeAllStopsSection = Section(type: .seeAllStops, items: [])
        recentSearchesSection = Section(type: .recentSearches, items: recentLocations)
        favoritesSection = Section(type: .favorites, items: favorites)
        searchResultsSection = Section(type: .searchResults, items: [])
        if let currentLocation = currentLocation {
            currentLocationSection = Section(type: .currentLocation, items: [currentLocation])
        }

        sections = createSections()
        searchBar?.becomeFirstResponder()
        searchBar?.tintColor = Colors.black

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar?.sizeToFit()
        searchBar?.tintColor = Colors.primaryText
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldShowCurrentLocation {
            locationManager.requestLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func createSections() -> [Section] {
        var allSections: [Section] = []
        if currentLocationSection != nil {
            allSections.append(currentLocationSection)
        }
        allSections.append(favoritesSection)
        allSections.append(recentSearchesSection)
        allSections.append(seeAllStopsSection)
        return allSections.filter { !$0.items.isEmpty }
    }

    private func getSearchResults (searchText: String) -> Future<Response<[Place]>> {
        return networking(Endpoint.getSearchResults(searchText: searchText)).decode()
    }

    /* Keyboard Functions */
    @objc func keyboardWillShow(_ notification: Notification) {
        isKeyboardVisible = true
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        isKeyboardVisible = false
    }

    /* TableView Methods */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section].type {
        case .recentSearches:
            return recentLocations.count
        case .favorites:
            return favorites.count
        default:
            return sections[section].items.count
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = HeaderView()

        switch sections[section].type {
        case .recentSearches:
            header.setupView(labelText: Constants.TableHeaders.recentSearches, buttonType: .clear)
        case .favorites:
            header.setupView(labelText: Constants.TableHeaders.favoriteDestinations, buttonType: .add)
        case .seeAllStops, .searchResults:
            return nil
        default:
            break
        }

        return header
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section].type {
        case .favorites, .recentSearches: return 50
        default: return 24
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var didSelectAllStops = false
        let allStopsTVC = AllStopsTableViewController()

        if sections[indexPath.section].type == .seeAllStops {
            didSelectAllStops = true
            allStopsTVC.allStops = SearchTableViewManager.shared.getAllStops()
            allStopsTVC.unwindAllStopsTVCDelegate = self
        } else {
            let place = sections[indexPath.section].items[indexPath.row]
            if place.latitude == 0.0 && place.longitude == 0.0 {
                showLocationDeniedAlert()
                return
            }
            destinationDelegate?.didSelectPlace(place: place)
        }

        definesPresentationContext = false
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar?.endEditing(true)

        if didSelectAllStops {
            if let parentIsSearch = self.parent?.isKind(of: UISearchController.self), parentIsSearch {
                let navController = self.parent?.presentingViewController?.navigationController
                navController?.delegate = self
                navController?.pushViewController(allStopsTVC, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell!

        if sections[indexPath.section].type == .currentLocation {
            cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.currentLocationIdentifier) as? GeneralTableViewCell
        } else if sections[indexPath.section].type == .seeAllStops {
            cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.seeAllStopsIdentifier) as? GeneralTableViewCell
        } else {
            guard let placeCell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.placeIdentifier) as? PlaceTableViewCell
                else { return cell }
            placeCell.place = sections[indexPath.section].items[indexPath.row]
            cell = placeCell
        }

        cell.layoutSubviews()

        return cell
    }

}

// MARK: ScrollView Delegate
extension SearchResultsTableViewController {

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cancelButton = searchBar?.value(forKey: "_cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }

    func showLocationDeniedAlert() {
        let alertController = UIAlertController(title: Constants.Alerts.LocationEnable.title,
                                                message: Constants.Alerts.LocationEnable.message,
                                                preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: Constants.Alerts.LocationEnable.settings, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                      options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
                                      completionHandler: nil)
        }
        let cancelAction = UIAlertAction(title: Constants.Alerts.LocationEnable.cancel, style: .cancel, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: {
            self.tableView.deselectRow(at: IndexPath(row: 0, section: 0), animated: true)
        })
    }
}

// MARK: Search Bar Delegate
extension SearchResultsTableViewController: UISearchBarDelegate, UISearchResultsUpdating {

    @objc func getPlaces(timer: Timer) {
        let searchText = (timer.userInfo as! [String: String])["searchText"]!
        if !searchText.isEmpty {
            getSearchResults(searchText: searchText).observe { [weak self] result in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .value(let response):
                        self.searchResultsSection = Section(type: .searchResults, items: response.data)
                        self.sections = self.searchResultsSection.items.isEmpty ? [] : [self.searchResultsSection]
                        if !self.sections.isEmpty {
                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                        }
                    default: break
                    }
                }
            }
        } else {
            sections = createSections()
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        if !sections.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        searchController.searchResultsController?.view.isHidden = false
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // tableViewIndexController.setHidden(true, animated: false)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBarCancelDelegate?.didCancel()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.2,
                                     target: self,
                                     selector: #selector(getPlaces),
                                     userInfo: ["searchText": searchText],
                                     repeats: false)
    }
}

extension SearchResultsTableViewController: UnwindAllStopsTVCDelegate {
    func dismissSearchResultsVC(place: Place) {
        returningFromAllStopsBusStop = place
        returningFromAllStopsTVC = true
    }
}

// MARK: - Location Manager Delegates
extension SearchResultsTableViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let currentLocationPlace = Place(name: Constants.General.currentLocation,
                                             latitude: location.coordinate.latitude,
                                             longitude: location.coordinate.longitude)
            currentLocationSection = Section(type: .currentLocation, items: [currentLocationPlace])
            sections = createSections()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("SearchResultsTableVC CLLocationManager didFailWithError: \(error)")
        // This means they dont have location services enabled. We catch this.
        if error._code == CLError.denied.rawValue {
            let currentLocationPlace = Place(name: Constants.General.currentLocation, latitude: 0.0, longitude: 0.0)
            currentLocationSection = Section(type: .currentLocation, items: [currentLocationPlace])
            sections = createSections()
        }
    }
}

// MARK: Navigation Controller Delegate
extension SearchResultsTableViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if returningFromAllStopsTVC, let place = returningFromAllStopsBusStop {
            destinationDelegate?.didSelectPlace(place: place)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
