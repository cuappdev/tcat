//
//  HomeOptionsCardViewController+Extensions.swift
//  TCAT
//
//  Created by Omar Rasheed on 8/29/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import Reachability
import UIKit

// MARK: VC Life Cycle setup
extension HomeOptionsCardViewController {
    override func loadView() {
        view = RoundShadowedView(cornerRadius: 10)
    }

    override func viewWillAppear(_ animated: Bool) {
        // Update searchbar attributes
        if let textFieldInsideSearchBar = searchBar.value(forKey: Constants.SearchBar.searchField) as? UITextField,
            let searchView = textFieldInsideSearchBar.leftView as? UIImageView {
            textFieldInsideSearchBar.backgroundColor = Colors.white
            searchView.image = #imageLiteral(resourceName: "search-large")
        }
        searchBar.placeholder = Constants.General.searchPlaceholder
        searchBar.text = nil

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        updatePlaces()
        createDefaultSections()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: Search Bar Delegate
extension HomeOptionsCardViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.placeholder = Constants.General.searchPlaceholder
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.endEditing(true)
        searchBar.text = nil
        animateInInfoButton()
        createDefaultSections()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.returnKeyType = searchText.isEmpty ? .default : .search
        searchBar.setShowsCancelButton(true, animated: true)
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(getPlaces), userInfo: ["searchText": searchText], repeats: false)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        if let cancelButton = searchBar.value(forKey: Constants.SearchBar.cancelButton) as? UIButton {
            cancelButton.setTitleColor(Colors.tcatBlue, for: .normal)
        }

        searchBar.placeholder = nil
        animateOutInfoButton()
        if view.frame.height == collapsedHeight {
            if let searchText = searchBar.text,
                searchText.isEmpty {
                createDefaultSections()
            } else {
                tableView.reloadData()
                DispatchQueue.main.async {
                    self.delegate?.updateSize()
                }
            }
        }
    }
}

// MARK: HeaderView Delegate
extension HomeOptionsCardViewController: HeaderViewDelegate {
    func displayFavoritesTVC() {
        if favorites.count < 2 {
            presentFavoritesTVC()
        } else {
            let title = Constants.Alerts.MaxFavorites.title
            let message = Constants.Alerts.MaxFavorites.message
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let done = UIAlertAction(title: Constants.Alerts.MaxFavorites.action, style: .default)
            alertController.addAction(done)
            present(alertController, animated: true, completion: nil)
        }
    }

    func clearRecentSearches() {
        Global.shared.deleteAllRecents()
        recentLocations = []
        createDefaultSections()
    }
}

// MARK: MapView Delegate
extension HomeOptionsCardViewController: HomeMapViewDelegate {
    func reachabilityChanged(connection: Reachability.Connection) {
        switch connection {
        case .none:
            isNetworkDown = true
            searchBar.isUserInteractionEnabled = false
            sections = []
        case .cellular, .wifi:
            isNetworkDown = false
            createDefaultSections()
            searchBar.isUserInteractionEnabled = true
        }
    }

    func mapViewWillMove() {
        if let searchBarText = searchBar.text,
            searchBarText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.searchBarCancelButtonClicked(self.searchBar)
        } else {
            searchBar.resignFirstResponder()
            DispatchQueue.main.async {
                self.delegate?.updateSize()
            }
        }
    }
}

// MARK: TableView DataSource
extension HomeOptionsCardViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .seeAllStops: return 1
        case .recentSearches: return recentLocations.count
        case .favorites: return favorites.isEmpty ? 1 : favorites.count
        case .searchResults: return sections[section].getItems().count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sections[indexPath.section] == .seeAllStops {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.generalCellIdentifier) as? GeneralTableViewCell
                else { return UITableViewCell() }
            cell.configure(for: .seeAllStops)
            return cell
        }
            // Favorites (including Add First Favorite!), Recent Searches
        else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.placeIdentifier) as? PlaceTableViewCell
                else { return UITableViewCell() }
            cell.configure(for: sections[indexPath.section].getItems()[indexPath.row])
            return cell
        }
    }
}

// MARK: TableView Delegate
extension HomeOptionsCardViewController: UITableViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let searchBarText = searchBar.text,
            searchBarText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchBar.placeholder = Constants.General.searchPlaceholder
            searchBar.endEditing(true)
            searchBar.text = nil
        }
        searchBar.setShowsCancelButton(false, animated: true)
        animateInInfoButton()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .favorites, .recentSearches: return headerHeight
        case .seeAllStops: return HeaderView.separatorViewHeight
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header: HeaderView!

        switch sections[section] {
        case .recentSearches:
            header = HeaderView(labelText: Constants.TableHeaders.recentSearches, buttonType: .clear, separatorVisible: true, delegate: self)
        case .favorites:
            header = HeaderView(labelText: Constants.TableHeaders.favoriteDestinations, buttonType: .add, delegate: self)
        case .seeAllStops:
            header = HeaderView(separatorVisible: true)
        case .searchResults:
            return nil
        default: break
        }

        return header
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let section = sections[indexPath.section]
        switch section {
        case .favorites:
            if !section.isEmpty, section.getItems()[0].name != Constants.General.firstFavorite {
                return .delete
            } else {
                return .none
            }
        case .recentSearches: return .delete
        default: return .none
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch sections[indexPath.section] {
            case .favorites:
                let place = sections[indexPath.section].getItems()[indexPath.row]
                favorites = Global.shared.deleteFavorite(favorite: place, allFavorites: favorites)
                createDefaultSections()
            case .recentSearches:
                let place = sections[indexPath.section].getItems()[indexPath.row]
                recentLocations = Global.shared.deleteRecent(recent: place, allRecents: recentLocations)
                createDefaultSections()
            default: break
            }

        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let routeOptionsViewController = RouteOptionsViewController()
        routeOptionsViewController.didReceiveCurrentLocation(currentLocation)
        let allStopsTableViewConroller = AllStopsTableViewController()
        var didSelectAllStops = false
        var shouldPushViewController = true

        if sections[indexPath.section] == .seeAllStops {
            didSelectAllStops = true
        } else {
            let place = sections[indexPath.section].getItems()[indexPath.row]
            if place.name == Constants.General.firstFavorite {
                shouldPushViewController = false
                presentFavoritesTVC()
            } else {
                routeOptionsViewController.searchTo = place
                Global.shared.insertPlace(for: Constants.UserDefaults.recentSearch, place: place)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.endEditing(true)

        if shouldPushViewController {
            let vcToPush = didSelectAllStops ? allStopsTableViewConroller : routeOptionsViewController
            navigationController?.pushViewController(vcToPush, animated: true)
        }
    }
}
