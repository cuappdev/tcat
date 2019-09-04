//
//  HomeOptionsCard.swift
//  TCAT
//
//  Created by Omar Rasheed on 3/23/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import CoreLocation
import FutureNova
import GoogleMaps
import SnapKit
import UIKit

protocol HomeOptionsCardDelegate: class {
    func updateSize()
    func getCurrentLocation() -> CLLocation?
    func presentFavoritesTVC()
    func openInformationScreen()
}

class HomeOptionsCardViewController: UIViewController {

    weak var delegate: HomeOptionsCardDelegate?

    private let infoButton = UIButton(type: .infoLight)
    var searchBar: UISearchBar!
    private var searchBarSeparator: UIView!
    var tableView: UITableView!

    var currentLocation: CLLocation? { return delegate?.getCurrentLocation() }
    private let networking: Networking = URLSession.shared.request
    private var searchResultsSection: Section!
    var timer: Timer?

    let headerHeight: CGFloat = 42
    private let infoButtonAnimationDuration = 0.1
    var isNetworkDown = false
    private var keyboardHeight: CGFloat = 0
    private let maxFavoritesCount = 2
    private let maxHeaderCount: CGFloat = 2
    private let maxRecentsCount = 2
    private let maxRowCount: CGFloat = 5
    private let maxScreenCoverage: CGFloat = 3/5
    private let maxSeparatorCount: CGFloat = 1
    private let searchBarHeight: CGFloat = 54
    private let searchBarSeparatorHeight: CGFloat = 1
    private let searchBarTopOffset: CGFloat = 3 // Add top offset to search bar so that the search bar text is vertically centered.
    private let tableViewRowHeight: CGFloat = 50

    /** Height of the card when collapsed. This includes just searchbar height and any extra padding/spacing */
    var collapsedHeight: CGFloat {
        return searchBarHeight + searchBarSeparatorHeight + searchBarTopOffset
    }

    /** Returns the height of a card that would contain two favorites and two recent searches. */
    private var maxCardHeight: CGFloat {
        let totalRowHeight = tableViewRowHeight * maxRowCount
        let totalHeaderHeight = headerHeight * maxHeaderCount
        let totalSeparatorHeight = HeaderView.separatorViewHeight * maxSeparatorCount
        return totalRowHeight + totalHeaderHeight + totalSeparatorHeight + collapsedHeight
    }

    /** Returns the maximum height of the options card given the size of the phone. If the usual
     max height would make the card get covered by the keyboard, then we adjust it to be smaller.
     Otherwise, we keep it at the maximum height. */
    private var adjustedMaxCardHeight: CGFloat {
        let openScreenSpace = UIScreen.main.bounds.height - HomeMapViewController.optionsCardInset.top - keyboardHeight - 20
        return min(maxCardHeight, openScreenSpace)
    }

    var recentLocations: [Place] = [] {
        didSet {
            if recentLocations.count > maxRecentsCount {
                recentLocations = Array(recentLocations.prefix(maxRecentsCount))
            }
            if !isNetworkDown {
                createDefaultSections()
            }
        }
    }
    var favorites: [Place] = [] {
        didSet {
            if favorites.count > maxFavoritesCount {
                favorites = Array(favorites.prefix(maxFavoritesCount))
            }
            if !isNetworkDown {
                createDefaultSections()
            }
        }
    }
    var sections: [Section] = [] {
        didSet {
            tableView.reloadData()
            DispatchQueue.main.async {
                self.delegate?.updateSize()
            }
        }
    }

    init(delegate: HomeOptionsCardDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
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

    private func setupTableView() {
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
        tableView.register(GeneralTableViewCell.self, forCellReuseIdentifier: Constants.Cells.generalCellIdentifier)
        view.addSubview(tableView)
    }

    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.placeholder = Constants.General.searchPlaceholder
        searchBar.delegate = self
        searchBar.searchBarStyle = .default
        searchBar.returnKeyType = .search
        searchBar.barTintColor = .white
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBar.layer.borderWidth = 1

        if let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField,
            let searchView = textFieldInsideSearchBar.leftView as? UIImageView {
            textFieldInsideSearchBar.backgroundColor = Colors.white
            searchView.image = #imageLiteral(resourceName: "search-large")
        }

        // Add horizontal offset so that placeholder text is aligned with bus stop names and all stops
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 8, vertical: 0)
        view.addSubview(searchBar)
    }

    private func setupInfoButton() {
        infoButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 0)
        infoButton.contentVerticalAlignment = .center
        infoButton.tintColor = .black
        infoButton.addTarget(self, action: #selector(openInformationScreen), for: .touchUpInside)
        view.addSubview(infoButton)
    }

    private func setupSearchBarSeparator() {
        searchBarSeparator = UIView()
        searchBarSeparator.backgroundColor = Colors.backgroundWash
        view.addSubview(searchBarSeparator)
    }

    private func setupConstraints() {
        let infoButtonSize = CGSize.init(width: 30, height: 38)
        let infoButtonTrailinginset = 16

        infoButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(searchBar).offset(-searchBarTopOffset / 2)
            make.trailing.equalToSuperview().inset(infoButtonTrailinginset)
            make.size.equalTo(infoButtonSize)
        }

        searchBar.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().inset(searchBarTopOffset)
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

    func createDefaultSections() {
        var allSections: [Section] = []
        let recentSearchesSection = Section.recentSearches(items: recentLocations)
        var favoritesSection = Section.favorites(items: favorites)
        if favoritesSection.isEmpty {
            let addFavorites = Place(
                name: Constants.General.firstFavorite,
                placeDescription: Constants.General.tapHere)
            addFavorites.type = .busStop // Special exception to make pin blue for favorite!
            favoritesSection = Section.favorites(items: [addFavorites])
        }
        allSections.append(favoritesSection)
        allSections.append(recentSearchesSection)
        allSections.append(Section.seeAllStops)
        sections = allSections.filter { !$0.isEmpty || $0 == Section.seeAllStops }
    }

    private func tableViewContentHeight() -> CGFloat {
        return sections.reduce(0) { (result, section) -> CGFloat in
            var sectionHeaderHeight: CGFloat = 0
            switch section {
            case .favorites, .recentSearches: sectionHeaderHeight = headerHeight
            case .seeAllStops: sectionHeaderHeight = HeaderView.separatorViewHeight
            default: break
            }
            let rowCount = section == .seeAllStops ? 1 : section.getItems().count // TODO: Find better way to represent sections
            return sectionHeaderHeight + tableViewRowHeight * CGFloat(rowCount) + result
        }
    }

    /// Decide whether to show full card or just searchBar
    func calculateCardHeight() -> CGFloat {
        if searchBar.isFirstResponder {
            let contentHeight = tableViewContentHeight() + collapsedHeight
            return min(contentHeight, adjustedMaxCardHeight)
        } else { return collapsedHeight }
    }

    func updatePlaces() {
        recentLocations = Global.shared.retrievePlaces(for: Constants.UserDefaults.recentSearch)
        favorites = Global.shared.retrievePlaces(for: Constants.UserDefaults.favorites)
    }

    func animateInInfoButton() {
        UIView.animate(withDuration: infoButtonAnimationDuration) {
            self.infoButton.alpha = 1

            self.searchBar.snp.remakeConstraints { (make) in
                make.leading.equalToSuperview()
                make.top.equalToSuperview().inset(self.searchBarTopOffset)
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
                make.leading.equalToSuperview()
                make.top.equalToSuperview().inset(self.searchBarTopOffset)
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
        delegate?.presentFavoritesTVC()
    }

    /* Open information screen */
    @objc private func openInformationScreen() {
        delegate?.openInformationScreen()
    }

    /* Get Search Results */
    @objc func getPlaces(timer: Timer) {
        if let userInfo = timer.userInfo as? [String: String],
            let searchText = userInfo["searchText"],
            !searchText.isEmpty {
            getSearchResults(searchText: searchText).observe { [weak self] result in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .value(let response):
                        self.searchResultsSection = Section.searchResults(items: response.data)
                        self.tableView.contentOffset = .zero
                        self.sections = [self.searchResultsSection]
                    default: break
                    }
                }
            }
        } else {
            createDefaultSections()
        }
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        keyboardHeight = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
