//
//  HomeOptionsCard.swift
//  TCAT
//
//  Created by Omar Rasheed on 3/23/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit
import CoreLocation
import DZNEmptyDataSet
import FutureNova
import GoogleMaps
import SnapKit

protocol HomeOptionsCardDelegate {
    func updateSize()
    func getCurrentLocation() -> CLLocation?
}

class HomeOptionsCardViewController: UIViewController {

    var delegate: HomeOptionsCardDelegate?

    var currentLocation: CLLocation? { return delegate?.getCurrentLocation() }
    var tableView: UITableView!
    var searchBar: UISearchBar!
    let infoButton = UIButton(type: .infoLight)
    var searchBarSeparator: UIView!
    var timer: Timer?
    var searchResultsSection: Section!
    private let networking: Networking = URLSession.shared.request

    var loadingIndicator: LoadingIndicator?
    var isLoading: Bool { return loadingIndicator != nil }
    var isNetworkDown = false
    let searchBarHeight: CGFloat = 54
    let searchBarSeparatorHeight: CGFloat = 1
    let headerHeight: CGFloat = 42
    let tableViewRowHeight: CGFloat = 50
    let maxRowCount: CGFloat = 5
    let maxHeaderCount: CGFloat = 2
    let maxSeparatorCount: CGFloat = 1
    let maxScreenCoverage: CGFloat = 3/5
    let infoButtonAnimationDuration = 0.1
    let maxRecentsCount = 2
    let maxFavoritesCount = 2

    /** Returns the height of a card that would contain two favorites and two recent searches.
     This is the height that we will cap all optionCards at, regardless of the phone. */
    var maxCardHeight: CGFloat {
        let totalRowHeight = tableViewRowHeight * maxRowCount
        let totalHeaderHeight = headerHeight * maxHeaderCount
        let totalSeparatorHeight = HeaderView.separatorViewHeight * maxSeparatorCount
        return totalRowHeight + totalHeaderHeight + searchBarHeight + totalSeparatorHeight
    }

    /** Checks to see if the bottom of the card at maximum height would cover more than the maxScreenCoverage */
    var isDynamicSearchBar: Bool {
        return maxCardHeight > (UIScreen.main.bounds.height*maxScreenCoverage - HomeMapViewController.optionsCardInset.top)
    }
    var recentLocations: [Place] = [] {
        didSet {
            if recentLocations.count > maxRecentsCount {
                recentLocations = Array(recentLocations.prefix(maxRecentsCount))
            }
            if !isNetworkDown {
                sections = createSections()
            }
        }
    }
    var favorites: [Place] = [] {
        didSet {
            if favorites.count > maxFavoritesCount {
                favorites = Array(favorites.prefix(maxFavoritesCount))
            }
            if !isNetworkDown {
                sections = createSections()
            }
        }
    }
    var sections: [Section] = [] {
        didSet {
            tableView.reloadData()
            delegate?.updateSize()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupInfoButton()
        setupSearchBarSeparator()
        setupSearchBar()
        setupConstraints()
        updatePlaces()
    }

    func setupTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = view.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = tableViewRowHeight
        tableView.register(PlaceTableViewCell.self, forCellReuseIdentifier: Constants.Cells.placeIdentifier)
        tableView.register(GeneralTableViewCell.self, forCellReuseIdentifier: Constants.Cells.seeAllStopsIdentifier)
        view.addSubview(tableView)
    }

    func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.placeholder = Constants.General.searchPlaceholder
        searchBar.delegate = self
        searchBar.searchBarStyle = .default
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.backgroundColor = Colors.white
        searchBar.barTintColor = .white
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBar.layer.borderWidth = 1
        view.addSubview(searchBar)
    }

    func setupInfoButton() {
        infoButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 0)
        infoButton.contentVerticalAlignment = .center
        infoButton.tintColor = .black
        infoButton.addTarget(self, action: #selector(openInformationScreen), for: .touchUpInside)
        view.addSubview(infoButton)
    }

    func setupSearchBarSeparator() {
        searchBarSeparator = UIView()
        searchBarSeparator.backgroundColor = Colors.backgroundWash
        view.addSubview(searchBarSeparator)
    }

    func setupConstraints() {
        let infoButtonSize = CGSize.init(width: 30, height: 38)
        let infoButtonTrailinginset = 16

        infoButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(searchBar)
            make.trailing.equalToSuperview().inset(infoButtonTrailinginset)
            make.size.equalTo(infoButtonSize)
        }

        searchBar.snp.makeConstraints { (make) in
            make.leading.top.equalToSuperview()
            make.trailing.equalTo(infoButton.snp.leading)
            make.height.equalTo(searchBarHeight)
        }

        searchBarSeparator.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(searchBar.snp.bottom)
            make.height.equalTo(searchBarSeparatorHeight)
        }

        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(searchBarSeparator.snp.bottom)
        }
    }

    func createSections() -> [Section] {
        var allSections: [Section] = []
        let recentSearchesSection = Section(type: .recentSearches, items: recentLocations)
        let seeAllStops = Place(name: Constants.Cells.seeAllStopsIdentifier)
        let seeAllStopsSection = Section(type: .seeAllStops, items: [seeAllStops])
        var favoritesSection = Section(type: .favorites, items: favorites)
        if favoritesSection.items.isEmpty {
            let addFavorites = Place(
                name: Constants.General.firstFavorite,
                placeDescription: Constants.General.tapHere)
            addFavorites.type = .busStop // Special exception to make pin blue for favorite!
            favoritesSection = Section(type: .favorites, items: [addFavorites])
        }
        allSections.append(favoritesSection)
        allSections.append(recentSearchesSection)
        allSections.append(seeAllStopsSection)
        return allSections.filter { !$0.items.isEmpty || $0.type == .seeAllStops }
    }

    func tableViewContentHeight() -> CGFloat {
        return sections.reduce(0) { (result, section) -> CGFloat in
            var sectionHeaderHeight: CGFloat = 0
            switch section.type {
            case .favorites, .recentSearches: sectionHeaderHeight = headerHeight
            case .seeAllStops: sectionHeaderHeight = HeaderView.separatorViewHeight
            default: break
            }
            return sectionHeaderHeight + tableViewRowHeight * CGFloat(section.items.count) + result
        }
    }

    /// If the screen is too small, decide whether to show full card or just searchBar
    func calculateCardHeight() -> CGFloat {
        if isDynamicSearchBar {
            if searchBar.isFirstResponder {
                return min(tableViewContentHeight() + CGFloat(searchBarHeight), maxCardHeight) + searchBarSeparatorHeight
            } else { return CGFloat(searchBarHeight) + searchBarSeparatorHeight }
        }
        return min(tableViewContentHeight() + searchBarHeight, UIScreen.main.bounds.height * maxScreenCoverage) + searchBarSeparatorHeight
    }

    func updatePlaces() {
        recentLocations = SearchTableViewManager.shared.retrievePlaces(for: Constants.UserDefaults.recentSearch)
        favorites = SearchTableViewManager.shared.retrievePlaces(for: Constants.UserDefaults.favorites)
    }

    func animateInInfoButton() {
        UIView.animate(withDuration: infoButtonAnimationDuration) {
            self.infoButton.alpha = 1

            self.searchBar.snp.remakeConstraints { (make) in
                make.leading.top.equalToSuperview()
                make.trailing.equalTo(self.infoButton.snp.leading)
                make.height.equalTo(self.searchBarHeight)
            }
            self.view.layoutIfNeeded()
        }
    }

    func animateOutInfoButton() {
        UIView.animate(withDuration: infoButtonAnimationDuration) {
            self.infoButton.alpha = 0
            self.searchBar.snp.remakeConstraints { (make) in
                make.leading.top.equalToSuperview()
                make.trailing.equalTo(self.infoButton.snp.trailing)
                make.height.equalTo(self.searchBarHeight)
            }
            self.view.layoutIfNeeded()
        }
    }

    private func getSearchResults(searchText: String) -> Future<Response<[Place]>> {
        return networking(Endpoint.getSearchResults(searchText: searchText)).decode()
    }

    @objc func presentFavoritesTVC(sender: UIButton? = nil) {
        let favoritesTVC = FavoritesTableViewController()
        let navController = CustomNavigationController(rootViewController: favoritesTVC)
        present(navController, animated: true, completion: nil)
    }

    /* Open information screen */
    @objc func openInformationScreen() {
        let informationViewController = InformationViewController()
        let navigationVC = CustomNavigationController(rootViewController: informationViewController)
        present(navigationVC, animated: true)
    }

    /* Get Search Results */
    @objc func getPlaces(timer: Timer) {
        let searchText = (timer.userInfo as! [String: String])["searchText"]!
        if !searchText.isEmpty {
            getSearchResults(searchText: searchText).observe { [weak self] result in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .value(let response):
                        self.searchResultsSection = Section(type: .searchResults, items: response.data)
                        self.tableView.contentOffset = .zero
                        self.sections = [self.searchResultsSection]
                    default: break
                    }
                }
            }
        } else {
            sections = createSections()
        }
    }
}

// MARK: VC Life Cycle setup
extension HomeOptionsCardViewController {
    override func loadView() {
        let customView = RoundShadowedView()
        customView.addRoundedCornersAndShadow()
        view = customView
    }

    override func viewWillAppear(_ animated: Bool) {
        updatePlaces()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeLoadingIndicator()
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
        sections = createSections()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(getPlaces), userInfo: ["searchText": searchText], repeats: false)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.placeholder = nil
        animateOutInfoButton()
        if isDynamicSearchBar {
            sections = createSections()
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.showsCancelButton {
            searchBarCancelButtonClicked(searchBar)
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
        SearchTableViewManager.shared.deleteAllRecents()
        recentLocations = []
        sections = createSections()
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
            sections = createSections()
            searchBar.isUserInteractionEnabled = true
        }
    }
}

// MARK: TableView DataSource
extension HomeOptionsCardViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section].type {
        case .seeAllStops: return 1
        case .recentSearches: return recentLocations.count
        case .favorites: return favorites.isEmpty ? 1 : favorites.count
        case .searchResults: return sections[section].items.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if sections[indexPath.section].type == .seeAllStops {
            cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.seeAllStopsIdentifier) as? GeneralTableViewCell
        }
            // Favorites (including Add First Favorite!), Recent Searches
        else {
            guard let placeCell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.placeIdentifier) as? PlaceTableViewCell
                else { return cell }
            placeCell.place = sections[indexPath.section].items[indexPath.row]
            cell = placeCell
        }

        cell.layoutSubviews()

        return cell
    }
}

// MARK: TableView Delegate
extension HomeOptionsCardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section].type {
        case .favorites, .recentSearches: return headerHeight
        case .seeAllStops: return HeaderView.separatorViewHeight
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = HeaderView()

        switch sections[section].type {
        case .recentSearches:
            header.setupView(labelText: Constants.TableHeaders.recentSearches, buttonType: .clear, separatorVisible: true)
            header.headerViewDelegate = self
        case .favorites:
            header.setupView(labelText: Constants.TableHeaders.favoriteDestinations, buttonType: .add)
            header.headerViewDelegate = self
        case .seeAllStops:
            header.setupView(separatorVisible: true)
        case .searchResults:
            return nil
        default: break
        }

        return header
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let section = sections[indexPath.section]
        switch section.type {
        case .favorites:
            if !section.items.isEmpty, section.items[0].name != Constants.General.firstFavorite {
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
            switch sections[indexPath.section].type {
            case .favorites:
                let place = sections[indexPath.section].items[indexPath.row]
                favorites = SearchTableViewManager.shared.deleteFavorite(favorite: place, allFavorites: favorites)
                sections = createSections()
            case .recentSearches:
                let place = sections[indexPath.section].items[indexPath.row]
                recentLocations = SearchTableViewManager.shared.deleteRecent(recent: place, allRecents: recentLocations)
                sections = createSections()
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

        if sections[indexPath.section].type == .seeAllStops {
            didSelectAllStops = true
            allStopsTableViewConroller.allStops = SearchTableViewManager.shared.getAllStops()
        } else {
            let place = sections[indexPath.section].items[indexPath.row]
            if place.name == Constants.General.firstFavorite {
                shouldPushViewController = false
                presentFavoritesTVC()
            } else {
                routeOptionsViewController.searchTo = place
                SearchTableViewManager.shared.insertPlace(for: Constants.UserDefaults.recentSearch, place: place)
                routeOptionsViewController.didSelectPlace(place: place)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.endEditing(true)

        let vcToPush = didSelectAllStops ? allStopsTableViewConroller : routeOptionsViewController
        if shouldPushViewController {
            navigationController?.pushViewController(vcToPush, animated: true)
        }
    }
}

// MARK: DZN Empty Data Set Source
extension HomeOptionsCardViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        // If tableview header is hidden, increase offset to center EmptyDataSet view
        return tableView.tableHeaderView == nil ? -80 : (-80 - tableView.contentInset.top)
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        // If loading indicator is being shown, don't display image
        if isLoading { return nil }
        return isNetworkDown ? #imageLiteral(resourceName: "noWifi") : #imageLiteral(resourceName: "noRoutes")
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        // If loading indicator is being shown, don't display description
        if isLoading { return nil }
        let title = isNetworkDown ? Constants.EmptyStateMessages.noNetworkConnection: Constants.EmptyStateMessages.locationNotFound
        return NSAttributedString(string: title, attributes: [.foregroundColor: Colors.metadataIcon])
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        // If loading indicator is being shown, don't display button
        if isLoading { return nil }
        let title = Constants.Buttons.retry
        return NSAttributedString(string: title, attributes: [.foregroundColor: Colors.tcatBlue])
    }

    func setupLoadingIndicator() {
        loadingIndicator = LoadingIndicator()
        if let loadingIndicator = loadingIndicator {
            view.addSubview(loadingIndicator)
            loadingIndicator.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalTo(40)
            }
        }
    }

    func removeLoadingIndicator() {
        loadingIndicator?.removeFromSuperview()
        loadingIndicator = nil
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTap didTapButton: UIButton) {
        setupLoadingIndicator()
        if isLoading {
            tableView.reloadData()

            // Have loading indicator time out after one second
            let delay = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
                // if the empty state is the "Location Not Found" state, clear the text in the search bar
                if !self.isNetworkDown {
                    self.searchBar.text = nil
                    self.searchBar.placeholder = Constants.General.searchPlaceholder
                }
                self.removeLoadingIndicator()
                self.tableView.reloadData()
            }
        }
    }
}
