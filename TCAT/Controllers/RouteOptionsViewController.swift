//
//  RouteOptionsViewController.swift
//  TCAT
//
//  Created by Monica Ong on 2/12/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON
import DZNEmptyDataSet
import NotificationBannerSwift
import Crashlytics
import Pulley
import Intents
import FutureNova

enum SearchBarType: String {
    case from, to
}

struct BannerInfo {
    let title: String
    let style: BannerStyle
}

enum RequestAction {
    case showAlert(title: String, message: String, actionTitle: String)
    case showError(bannerInfo: BannerInfo, payload: GetRoutesErrorPayload)
    case hideBanner
}

class RouteOptionsViewController: UIViewController {

    // MARK: Search bar vars

    var searchBarView: SearchBarView?
    var locationManager: CLLocationManager!
    var currentLocation: CLLocationCoordinate2D?
    var searchType: SearchBarType = .to
    var searchTimeType: SearchType = .leaveNow
    var searchFrom: Place?
    var searchTo: Place?
    var searchTime: Date?
    var showRouteSearchingLoader: Bool = false

    // MARK: View vars

    let mediumTapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    var routeSelection: RouteSelectionView!
    var datePickerView: DatePickerView!
    var datePickerOverlay: UIView!
    var routeResults: UITableView!
    var refreshControl: UIRefreshControl!

    let navigationBarTitle: String = Constants.Titles.routeOptions
    let routeResultsTitle: String = Constants.Titles.routeResults

    // MARK: Data vars

    var routes: [[Route]] = []

    /// Returns routes from each section in order
    var allRoutes: [Route] {
        return routes.flatMap { $0 }
    }
    var timers: [Int: Timer] = [:]

    // MARK: Reachability vars

    let reachability: Reachability? = Reachability(hostname: Endpoint.config.host ?? "")
    private let networking: Networking = URLSession.shared.request

    var banner: StatusBarNotificationBanner? {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    var cellUserInteraction = true

    // MARK: Spacing vars

    let estimatedRowHeight: CGFloat = 115

    // MARK: Print vars

    private let fileName: String = "RouteOptionsVC"

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Colors.backgroundWash

        edgesForExtendedLayout = []

        title = navigationBarTitle

        setupRouteSelection()
        setupSearchBar()
        setupDatePicker()
        setupRouteResultsTableView()
        setupEmptyDataSet()

        view.addSubview(routeSelection)
        view.addSubview(datePickerOverlay)
        view.sendSubviewToBack(datePickerOverlay)
        view.addSubview(routeResults)
        view.addSubview(datePickerView) // so datePicker can go ontop of other views

        setRouteSelectionView(withDestination: searchTo)
        setupLocationManager()

        // assume user wants to find routes that leave at current time and set datepicker accordingly
        searchTime = Date()
        if let searchTime = searchTime {
            routeSelection.setDatepicker(withDate: searchTime, withSearchTimeType: searchTimeType)
        }

        searchForRoutes()

        // Check for 3D Touch availability
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        routeResults.register(RouteTableViewCell.self, forCellReuseIdentifier: RouteTableViewCell.identifier)
        setupReachability()

        // Reload data to activate timers again
        if !routes.isEmpty {
            routeResults.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if #available(iOS 11, *) {
            addHeightToDatepicker(20) // add bottom padding to date picker for iPhone X
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Takedown reachability
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
        // Remove banner
        banner?.dismiss()
        banner = nil
        // Deactivate and remove timers
        timers.values.forEach { $0.invalidate() }
        timers = [:]
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return banner != nil ? .lightContent : .default
    }

    // MARK: Route Selection view

    private func setupRouteSelection() {
        // offset for -12 for larger views, get rid of black space
        routeSelection = RouteSelectionView(frame: CGRect(x: 0, y: -12, width: view.frame.width, height: 150))
        routeSelection.backgroundColor = Colors.white
        var newRSFrame = routeSelection.frame
        newRSFrame.size.height =  routeSelection.lineWidth + routeSelection.searcbarView.frame.height + routeSelection.lineWidth + routeSelection.datepickerButton.frame.height
        routeSelection.frame = newRSFrame

        routeSelection.toSearchbar.addTarget(self, action: #selector(self.searchingTo), for: .touchUpInside)
        routeSelection.fromSearchbar.addTarget(self, action: #selector(self.searchingFrom), for: .touchUpInside)
        routeSelection.datepickerButton.addTarget(self, action: #selector(self.showDatePicker), for: .touchUpInside)
        routeSelection.swapButton.addTarget(self, action: #selector(self.swapFromAndTo), for: .touchUpInside)
    }

    private func setRouteSelectionView(withDestination destination: Place?) {
        routeSelection.fromSearchbar.setTitle(Constants.General.fromSearchBarPlaceholder, for: .normal)
        routeSelection.toSearchbar.setTitle(destination?.name ?? "", for: .normal)
    }

    @objc func swapFromAndTo(sender: UIButton) {
        //Swap data
        let searchFromOld = searchFrom
        searchFrom = searchTo
        searchTo = searchFromOld

        //Update UI
        routeSelection.fromSearchbar.setTitle(searchFrom?.name ?? "", for: .normal)
        routeSelection.toSearchbar.setTitle(searchTo?.name ?? "", for: .normal)

        searchForRoutes()

        // Analytics
        let payload = RouteOptionsSettingsPayload(description: "Swapped To and From")
        Analytics.shared.log(payload)

    }

    // MARK: Search bar

    private func setupSearchBar() {
        searchBarView = SearchBarView()
        searchBarView?.resultsViewController?.destinationDelegate = self
        searchBarView?.resultsViewController?.searchBarCancelDelegate = self
        searchBarView?.searchController?.searchBar.sizeToFit()
        self.definesPresentationContext = true
        hideSearchBar()
    }

    @objc func searchingTo(sender: UIButton? = nil) {
        searchType = .to
        presentSearchBar()
        let payload = RouteOptionsSettingsPayload(description: "Searching To Tapped")
        Analytics.shared.log(payload)
    }

    @objc func searchingFrom(sender: UIButton? = nil) {
        searchType = .from
        searchBarView?.resultsViewController?.shouldShowCurrentLocation = true
        presentSearchBar()
        let payload = RouteOptionsSettingsPayload(description: "Searching From Tapped")
        Analytics.shared.log(payload)
    }

    func presentSearchBar() {
        var placeholder = ""
        var searchBarText = ""

        switch searchType {

        case .from:

            if
                let startingDestinationName = searchFrom?.name,
                startingDestinationName != Constants.General.currentLocation &&
                startingDestinationName != Constants.General.fromSearchBarPlaceholder
            {
                searchBarText = startingDestinationName
            }
            placeholder = Constants.General.fromSearchBarPlaceholder

        case .to:

            if
                let endingDestinationName = searchTo?.name,
                endingDestinationName != Constants.General.currentLocation
            {
                searchBarText = endingDestinationName
            }
            placeholder = Constants.General.toSearchBarPlaceholder

        }

        if let textFieldInsideSearchBar = searchBarView?.searchController?.searchBar.value(forKey: "searchField") as? UITextField {
            textFieldInsideSearchBar.attributedPlaceholder = NSAttributedString(string: placeholder) // make placeholder invisible
            textFieldInsideSearchBar.text = searchBarText
        }

        showSearchBar()
    }

    private func dismissSearchBar() {
        searchBarView?.searchController?.dismiss(animated: true, completion: nil)
    }

    // Variable to remember back button when hiding
    var backButton: UIBarButtonItem?

    private func hideSearchBar() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = nil
        } else {
            navigationItem.titleView = nil
        }
        if let backButton = backButton {
            navigationItem.setLeftBarButton(backButton, animated: false)
        }
        navigationItem.hidesBackButton = false
        searchBarView?.searchController?.isActive = false
    }

    private func showSearchBar() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchBarView?.searchController
        } else {
            navigationItem.titleView = searchBarView?.searchController?.searchBar
        }
        backButton = navigationItem.leftBarButtonItem
        navigationItem.setLeftBarButton(nil, animated: false)
        navigationItem.hidesBackButton = true
        searchBarView?.searchController?.isActive = true
    }

    /// Fetch coordinates, store in place, return updated place
    func fetchCoordinates(place: Place, completion: @escaping (_ place: Place?) -> Void) {
        if place.latitude == nil || place.longitude == nil {
            CoordinateVisitor.getCoordinates(for: place) { (latitude, longitude, error) in
                if error != nil {
                    self.requestDidFinish(perform: [
                        .showError(bannerInfo: BannerInfo(title: Constants.Banner.routeCalculationError, style: .danger),
                                   payload: GetRoutesErrorPayload(type: "Nil Place Coordinates",
                                                                  description: "Place(s) don't have coordinates. (didSelectPlace)",
                                                                  url: nil))
                        ])
                    completion(nil)
                } else {
                    place.latitude = latitude
                    place.longitude = longitude
                    completion(place)
                }
            }
        }
    }

    func resetAndShowCurrentlyLoading() {
        showRouteSearchingLoader = true
        self.hideRefreshControl()

        routes = []
        timers = [:]
        routeResults.contentOffset = .zero
        routeResults.reloadData()
    }

    func searchForRoutes() {

        if
            let searchFrom = searchFrom,
            let searchTo = searchTo,
            let time = searchTime
        {

            resetAndShowCurrentlyLoading()

            switch searchType {
            case .from:
                routeSelection.fromSearchbar.setTitle(searchFrom.name, for: .normal)
            case .to:
                routeSelection.toSearchbar.setTitle(searchTo.name, for: .normal)
            }

            // If don't have coordinates, fetch and restart process
            if searchFrom.latitude == nil || searchFrom.longitude == nil {
                fetchCoordinates(place: searchFrom) { (optionalPlace) in
                    guard let place = optionalPlace else { return }
                    self.searchFrom = place
                    self.searchForRoutes()
                }
                return
            }
            if searchTo.latitude == nil || searchTo.longitude == nil {
                fetchCoordinates(place: searchTo) { (optionalPlace) in
                    guard let place = optionalPlace else { return }
                    self.searchTo = place
                    self.searchForRoutes()
                }
                return
            }

            // Prepare feedback on Network request
            mediumTapticGenerator.prepare()

            JSONFileManager.shared.logSearchParameters(timestamp: Date(), startPlace: searchFrom, endPlace: searchTo, searchTime: time, searchTimeType: searchTimeType)

            // MARK: Search For Routes Errors

            if searchFrom.name == searchTo.name {
                // The same location is passed in for start and end locations
                requestDidFinish(perform: [.showAlert(title: Constants.Alerts.Teleportation.title,
                                                      message: Constants.Alerts.Teleportation.message,
                                                      actionTitle: Constants.Alerts.Teleportation.action)])
                return
            }

            guard let areValidCoordinates = self.checkPlaceCoordinates(startPlace: searchFrom, endPlace: searchTo) else {
                // Place(s) don't have coordinates assigned
                self.requestDidFinish(perform: [
                    .showError(bannerInfo: BannerInfo(title: Constants.Banner.routeCalculationError, style: .danger),
                               payload: GetRoutesErrorPayload(type: "Nil Place Coordinates",
                                                              description: "Place(s) don't have coordinates. (areValidCoordinates)", url: nil))
                    ])
                return
            }

            if !areValidCoordinates {
                // Coordinates are out of range.
                let title = Constants.Alerts.OutOfRange.title
                let message = Constants.Alerts.OutOfRange.message
                let actionTitle = Constants.Alerts.OutOfRange.action

                self.requestDidFinish(perform: [
                    .showAlert(title: title, message: message, actionTitle: actionTitle),
                    .showError(bannerInfo: BannerInfo(title: title, style: .warning),
                               payload: GetRoutesErrorPayload(type: title, description: message, url: nil))
                    ])
                return
            }

            // MARK: Search for Routes Data Request
            if let result =  getRoutes(start: searchFrom, end: searchTo, time: time, type: self.searchTimeType) {
                result.observe(with: { [weak self] result in
                    guard let `self` = self else { return }
                    DispatchQueue.main.async {
                        let requestURL = Endpoint.getRequestURL(start: searchFrom, end: searchTo, time: time, type: self.searchTimeType)
                        self.processRequest(result: result, requestURL: requestURL, endPlace: searchTo)
                    }
                })
            }

            // Donate GetRoutes intent
            if #available(iOS 12.0, *) {
                let intent = GetRoutesIntent()
                intent.searchTo = searchTo.name
                if let latitude = searchTo.latitude, let longitude = searchTo.longitude {
                    intent.latitude = String(describing: latitude)
                    intent.longitude = String(describing: longitude)
                }
                intent.suggestedInvocationPhrase = "Find bus to \(searchTo.name)"
                let interaction = INInteraction(intent: intent, response: nil)
                interaction.donate(completion: { (error) in
                    guard let error = error else { return }
                    print("Intent Donation Error: \(error.localizedDescription)")
                })
            }

        }

    }

    private func getRoutes(start: Place,
                           end: Place,
                           time: Date,
                           type: SearchType) -> Future<Response<RouteSectionsObject>>? {
        if let endpoint = Endpoint.getRoutes(start: start, end: end, time: time, type: type) {
            return networking(endpoint).decode()
        } else { return nil }
    }

    private func routeSelected(routeId: String) {
        networking(Endpoint.routeSelected(routeId: routeId)).observe { [weak self] result in
            guard self != nil else { return }
            DispatchQueue.main.async {
                switch result {
                case .value:
                    print("[RouteOptionsViewController] Route Selected - Success")
                case .error(let error):
                    print("[RouteOptionsViewController] Route Selected - Error:", error)
                }
            }
        }
    }
    func processRequest(result: Result<Response<RouteSectionsObject>>, requestURL: String, endPlace: Place) {
        JSONFileManager.shared.logURL(timestamp: Date(), urlName: "Route requestUrl", url: requestURL)

        switch result {
        case .value(let response):

            // Save to JSONFileManager
            if let data = try? JSONEncoder().encode(response) {
                do { try JSONFileManager.shared.saveJSON(JSON.init(data: data), type: .routeJSON) } catch let error {
                    let fileName = "RouteOptionsViewController"
                    let line = "\(fileName) \(#function): \(error.localizedDescription)"
                    print(line)
                }
            }
            // Parse sections of routes
            [response.data.fromStop, response.data.boardingSoon, response.data.walking]
                .forEach { (routeSection) in
                    routeSection.forEach { (route) in
                        route.formatDirections(start: self.searchFrom?.name, end: self.searchTo?.name)
                    }
                    // Allow for custom display in search results for fromStop.
                    // We want to display a [] if a bus stop is the origin and doesn't exist
                    if !routeSection.isEmpty || self.searchFrom?.type == .busStop {
                        self.routes.append(routeSection)
                    }

            }
            self.requestDidFinish(perform: [.hideBanner])
        case .error(let error):
            self.processRequestError(error: error, requestURL: requestURL)
        }
        let payload = DestinationSearchedEventPayload(destination: endPlace.name, requestUrl: requestURL)
        Analytics.shared.log(payload)
    }

    func processRequestError(error: Error, requestURL: String) {
        let title = "Network Failure: \((error as NSError?)?.domain ?? "No Domain")"
        let description = (error.localizedDescription) + ", " + ((error as NSError?)?.description ?? "n/a")

        routes = []
        timers = [:]
        requestDidFinish(perform: [
            .showError(bannerInfo: BannerInfo(title: Constants.Banner.cantConnectServer, style: .danger),
                       payload: GetRoutesErrorPayload(type: title, description: description, url: requestURL))
        ])
    }

    /// Returns whether coordinates are valid, checking country extremes. Returns nil if places don't have coordinates.
    func checkPlaceCoordinates(startPlace: Place, endPlace: Place) -> Bool? {

        guard
            let startCoordLatitude = startPlace.latitude,
            let startCoordLongitude = startPlace.longitude,
            let endCoordLatitude = endPlace.latitude,
            let endCoordLongitude = endPlace.longitude
            else {
                return nil
        }

        let latitudeValues = [startCoordLatitude, endCoordLatitude]
        let longitudeValues  = [startCoordLongitude, endCoordLongitude]

        let validLatitudes = latitudeValues.reduce(true) { (result, latitude) -> Bool in
            return result && latitude <= Constants.Values.RouteBorders.northBorder &&
                latitude >= Constants.Values.RouteBorders.southBorder
        }

        let validLongitudes = longitudeValues.reduce(true) { (result, longitude) -> Bool in
            return result && longitude <= Constants.Values.RouteBorders.eastBorder &&
                longitude >= Constants.Values.RouteBorders.westBorder
        }

        return validLatitudes && validLongitudes
    }

    func requestDidFinish(perform actions: [RequestAction]) {

        for action in actions {

            switch action {

            case .showAlert(title: let title, message: let message, actionTitle: let actionTitle):
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: actionTitle, style: .cancel, handler: nil)
                alertController.addAction(action)
                present(alertController, animated: true, completion: nil)

            case .showError(bannerInfo: let bannerInfo, payload: let payload):
                banner = StatusBarNotificationBanner(title: bannerInfo.title, style: bannerInfo.style)
                banner?.autoDismiss = false
                banner?.dismissOnTap = true
                banner?.show(queuePosition: .front, on: navigationController)

                Analytics.shared.log(payload)

            case .hideBanner:
                banner?.dismiss()
                banner = nil
                NotificationBannerQueue.default.removeAll()
                mediumTapticGenerator.impactOccurred()

            }

        }

        showRouteSearchingLoader = false
        routeResults.reloadData()
    }

    // MARK: Date Picker

    private func setupDatePicker() {
        setupDatePickerView()
        setupDatePickerOverlay()
    }

    private func setupDatePickerView() {
        datePickerView = DatePickerView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 254))

        datePickerView.positionSubviews()
        datePickerView.addSubviews()

        datePickerView.cancelButton.addTarget(self, action: #selector(self.dismissDatePicker), for: .touchUpInside)
        datePickerView.doneButton.addTarget(self, action: #selector(self.saveDatePickerDate), for: .touchUpInside)
    }

    private func setupDatePickerOverlay() {
        datePickerOverlay = UIView(frame: CGRect(x: 0, y: -12, width: view.frame.width, height: view.frame.height + 12)) // 12 for sliver that shows up when click datepicker immediately after transition from HomeVC
        datePickerOverlay.backgroundColor = Colors.black
        datePickerOverlay.alpha = 0

        datePickerOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissDatePicker)))
    }

    private func addHeightToDatepicker(_ height: CGFloat) {
        let oldFrame = datePickerView.frame
        let newFrame = CGRect(x: oldFrame.minX, y: oldFrame.minY, width: oldFrame.width, height: oldFrame.height + height)

        datePickerView.frame = newFrame
    }

    @objc func showDatePicker(sender: UIButton) {

        view.bringSubviewToFront(datePickerOverlay)
        view.bringSubviewToFront(datePickerView)

        // set up date on datepicker view
        if let time = searchTime {
            datePickerView.setDatepickerDate(date: time)
        }

        datePickerView.setDatepickerTimeType(searchTimeType: searchTimeType)

        UIView.animate(withDuration: 0.5) {
            self.datePickerView.center.y = self.view.frame.height - (self.datePickerView.frame.height/2)
            self.datePickerOverlay.alpha = 0.6 // darken screen when pull up datepicker
        }

        let payload = RouteOptionsSettingsPayload(description: "Date Picker Accessed")
        Analytics.shared.log(payload)

    }

    @objc func dismissDatePicker(sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.datePickerView.center.y = self.view.frame.height + (self.datePickerView.frame.height/2)
            self.datePickerOverlay.alpha = 0.0
        }, completion: { (_) in
            self.view.sendSubviewToBack(self.datePickerOverlay)
            self.view.sendSubviewToBack(self.datePickerView)
        })
    }

    @objc func saveDatePickerDate(sender: UIButton) {

        let date = datePickerView.getDate()
        searchTime = date

        let typeToSegmentControlElements = datePickerView.typeToSegmentControlElements
        let timeTypeSegmentControl = datePickerView.timeTypeSegmentedControl
        let leaveNowSegmentControl = datePickerView.leaveNowSegmentedControl

        var buttonTapped = ""

        // Get selected time type
        if leaveNowSegmentControl.selectedSegmentIndex == typeToSegmentControlElements[.leaveNow]!.index {
            searchTimeType = .leaveNow
            buttonTapped = "Leave Now Tapped"
        } else if timeTypeSegmentControl.selectedSegmentIndex == typeToSegmentControlElements[.arriveBy]!.index {
            searchTimeType = .arriveBy
            buttonTapped = "Arrive By Tapped"
        } else {
            searchTimeType = .leaveAt
            buttonTapped = "Leave At Tapped"
        }

        routeSelection.setDatepicker(withDate: date, withSearchTimeType: searchTimeType)

        dismissDatePicker(sender: sender)

        searchForRoutes()

        let payload = RouteOptionsSettingsPayload(description: buttonTapped)
        Analytics.shared.log(payload)

    }

    // MARK: Reachability

    private func setupReachability() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(notification:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability?.startNotifier()
        } catch {
            print("\(fileName) \(#function): Could not start reachability notifier")
        }
    }

    @objc func reachabilityChanged(notification: Notification) {
        if let reachability = notification.object as? Reachability {

            // Dismiss current banner, if any
            banner?.dismiss()
            banner = nil

            switch reachability.connection {
            case .none:
                banner = StatusBarNotificationBanner(title: Constants.Banner.noInternetConnection, style: .danger)
                banner?.autoDismiss = false
                banner?.show(queuePosition: .front, bannerPosition: .top, on: navigationController)
                setUserInteraction(to: false)
            case .cellular, .wifi:
                setUserInteraction(to: true)
            }
        }
    }

    private func setUserInteraction(to userInteraction: Bool) {
        cellUserInteraction = userInteraction

        for cell in routeResults.visibleCells {
            setCellUserInteraction(cell, to: userInteraction)
        }

        routeSelection.isUserInteractionEnabled = userInteraction
    }

    private func setCellUserInteraction(_ cell: UITableViewCell?, to userInteraction: Bool) {
        cell?.isUserInteractionEnabled = userInteraction
        cell?.selectionStyle = .none // userInteraction ? .default : .none
    }

    // MARK: Refresh Control

    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isHidden = true

        if #available(iOS 10.0, *) {
            routeResults.refreshControl = refreshControl
        } else {
            routeResults.addSubview(refreshControl)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if refreshControl.isRefreshing {
            // Update leave now time in pull to refresh
            if searchTimeType == .leaveNow {
                let now = Date()
                searchTime = now
                routeSelection.setDatepicker(withDate: now, withSearchTimeType: searchTimeType)
            }
            searchForRoutes()
        }
    }

    func hideRefreshControl() {
        if #available(iOS 10.0, *) {
            routeResults.refreshControl?.endRefreshing()
        } else {
            refreshControl.endRefreshing()
        }
    }

    // MARK: RouteDetailViewController

    func createRouteDetailViewController(from indexPath: IndexPath) -> RouteDetailViewController? {

        let route = routes[indexPath.section][indexPath.row]
        var routeDetailCurrentLocation = currentLocation
        if searchTo?.name != Constants.General.currentLocation && searchFrom?.name != Constants.General.currentLocation {
            routeDetailCurrentLocation = nil // If route doesn't involve current location, don't pass along for view.
        }

        let routeOptionsCell = routeResults.cellForRow(at: indexPath) as? RouteTableViewCell

        let contentViewController = RouteDetailContentViewController(route: route,
                                                                     currentLocation: routeDetailCurrentLocation,
                                                                     routeOptionsCell: routeOptionsCell)

        guard let drawerViewController = contentViewController.drawerDisplayController else {
            return nil
        }
        return RouteDetailViewController(contentViewController: contentViewController,
                                         drawerViewController: drawerViewController)
    }
}

// MARK: Previewing Delegate
extension RouteOptionsViewController: UIViewControllerPreviewingDelegate {

    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let point = sender.location(in: routeResults)
            if let indexPath = routeResults.indexPathForRow(at: point), let cell = routeResults.cellForRow(at: indexPath) {
                let route = routes[indexPath.section][indexPath.row]
                presentShareSheet(from: view, for: route, with: cell.getImage())
            }
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let point = view.convert(location, to: routeResults)

        guard
            let indexPath = routeResults.indexPathForRow(at: point),
            let cell = routeResults.cellForRow(at: indexPath) as? RouteTableViewCell,
            let routeDetailViewController = createRouteDetailViewController(from: indexPath)
            else {
                return nil
        }

        routeDetailViewController.preferredContentSize = .zero
        routeDetailViewController.isPeeking = true
        cell.transform = .identity
        previewingContext.sourceRect = routeResults.convert(cell.frame, to: view)

        let payload = RouteResultsCellPeekedPayload()
        Analytics.shared.log(payload)

        return routeDetailViewController
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        (viewControllerToCommit as? RouteDetailViewController)?.isPeeking = false
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}

// MARK: SearchBarCancelDelegate
extension RouteOptionsViewController: SearchBarCancelDelegate {
    func didCancel() {
        hideSearchBar()
    }
}

// MARK: Destination Delegate
extension RouteOptionsViewController: DestinationDelegate {
    func didSelectPlace(place: Place) {

        switch searchType {
        case .from:
            searchFrom = place
        case .to:
            searchTo = place
        }

        if place.name != Constants.General.currentLocation && place.name != Constants.General.firstFavorite {
            SearchTableViewManager.shared.insertPlace(for: Constants.UserDefaults.recentSearch, place: place)
        }

        hideSearchBar()
        dismissSearchBar()
        searchForRoutes()

        let payload: Payload = PlaceSelectedPayload(name: place.name, type: place.type)
        Analytics.shared.log(payload)
    }
}

// MARK: Location Manager Delegate
extension RouteOptionsViewController: CLLocationManagerDelegate {

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("\(fileName) \(#function): \(error.localizedDescription)")

        if error._code == CLError.denied.rawValue {
            locationManager.stopUpdatingLocation()

            let alertController = UIAlertController(title: Constants.Alerts.LocationPermissions.title, message: Constants.Alerts.LocationPermissions.message, preferredStyle: .alert)

            let settingsAction = UIAlertAction(title: Constants.Alerts.GeneralActions.settings, style: .default) { (_) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }

            guard let showReminder = userDefaults.value(forKey: Constants.UserDefaults.showLocationAuthReminder) as? Bool else {

                userDefaults.set(true, forKey: Constants.UserDefaults.showLocationAuthReminder)

                let cancelAction = UIAlertAction(title: Constants.Alerts.GeneralActions.cancel, style: .default, handler: nil)
                alertController.addAction(cancelAction)

                alertController.addAction(settingsAction)
                alertController.preferredAction = settingsAction

                present(alertController, animated: true)

                return
            }

            if !showReminder {
                return
            }

            let dontRemindAgainAction = UIAlertAction(title: Constants.Alerts.GeneralActions.dontRemind, style: .default) { (_) in
                userDefaults.set(false, forKey: Constants.UserDefaults.showLocationAuthReminder)
            }
            alertController.addAction(dontRemindAgainAction)

            alertController.addAction(settingsAction)
            alertController.preferredAction = settingsAction

            present(alertController, animated: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didReceiveCurrentLocation(manager.location)
    }

    func didReceiveCurrentLocation(_ location: CLLocation?) {
        currentLocation = location?.coordinate

        searchBarView?.resultsViewController?.currentLocation?.latitude = currentLocation?.latitude
        searchBarView?.resultsViewController?.currentLocation?.longitude = currentLocation?.longitude

        if searchFrom?.name == Constants.General.currentLocation {
            searchFrom?.latitude = currentLocation?.latitude
            searchFrom?.longitude = currentLocation?.longitude
        }

        if searchTo?.name == Constants.General.currentLocation {
            searchTo?.latitude = currentLocation?.latitude
            searchTo?.longitude = currentLocation?.longitude
        }

        // If haven't selected start location, set to current location
        if let coordinates = currentLocation, searchFrom == nil {
            let currentLocation = Place(name: Constants.General.currentLocation,
                                        latitude: coordinates.latitude,
                                        longitude: coordinates.longitude)
            searchFrom = currentLocation
            searchBarView?.resultsViewController?.currentLocation = currentLocation
            routeSelection.fromSearchbar.setTitle(currentLocation.name, for: .normal)
            searchForRoutes()
        }
    }

}

// MARK: TableView DataSource
extension RouteOptionsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return routes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: RouteTableViewCell.identifier, for: indexPath) as? RouteTableViewCell

        if cell == nil {
            cell = RouteTableViewCell(style: .default, reuseIdentifier: RouteTableViewCell.identifier)
        }

        cell?.setData(route: routes[indexPath.section][indexPath.row], rowNum: indexPath.row)

        // Activate timers
        let timerDoesNotExist = (timers[indexPath.row] == nil)
        if timerDoesNotExist {
            timers[indexPath.row] = Timer.scheduledTimer(timeInterval: 5.0, target: cell!, selector: #selector(RouteTableViewCell.updateLiveElementsWithDelay), userInfo: nil, repeats: true)
        }

        cell?.addRouteDiagramSubviews()
        cell?.activateRouteDiagramConstraints()

        // Add share action for long press gestures on non 3D Touch devices
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        cell?.addGestureRecognizer(longPressGestureRecognizer)

        setCellUserInteraction(cell, to: cellUserInteraction)

        return cell!
    }

}

// MARK: TableView Delegate
extension RouteOptionsViewController: UITableViewDelegate {

    private func setupRouteResultsTableView() {
        let height = view.frame.height - routeSelection.frame.height - (navigationController?.navigationBar.frame.height ?? 0)
        let frame = CGRect(x: 0, y: routeSelection.frame.maxY, width: view.frame.width, height: height)
        routeResults = UITableView(frame: frame, style: .grouped)
        routeResults.delegate = self
        routeResults.allowsSelection = true
        routeResults.dataSource = self
        routeResults.separatorStyle = .none
        routeResults.backgroundColor = Colors.backgroundWash
        routeResults.alwaysBounceVertical = true //so table view doesn't scroll over top & bottom
        routeResults.showsVerticalScrollIndicator = false

        // so can have dynamic height cells
        routeResults.estimatedRowHeight = estimatedRowHeight
        routeResults.rowHeight = UITableView.automaticDimension

        setupRefreshControl()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        locationManager.stopUpdatingLocation()
        if let routeDetailViewController = createRouteDetailViewController(from: indexPath) {
            let payload = RouteResultsCellTappedEventPayload()
            Analytics.shared.log(payload)
            let routeId = routes[indexPath.section][indexPath.row].routeId
            routeSelected(routeId: routeId)
            navigationController?.pushViewController(routeDetailViewController, animated: true)
        }
    }

    /// Different header text based on variable data results (see designs)
    func headerTitles(section: Int) -> String? {
        if routes.count == 3 {
            switch section {
            case 1:
                if (routes.first?.isEmpty ?? false) {
                    return Constants.TableHeaders.boardingSoon
                } else {
                    return Constants.TableHeaders.boardingSoonFromNearby
                }
            case 2: return Constants.TableHeaders.walking
            default: return nil
            }
        } else {
            switch section {
            case 1: return Constants.TableHeaders.walking
            default: return nil
            }
        }
    }

    func isEmptyHeaderView(section: Int) -> Bool {
         return section == 0 && searchFrom?.type == .busStop && routes.first?.isEmpty ?? false
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let containerView = UIView()
        let label = UILabel()

        // Special centered message alerting no fromStop routes (first in 2D routes array)
        if isEmptyHeaderView(section: section) {
            label.text = Constants.TableHeaders.noAvailableRoutes + " from \(searchFrom?.name ?? "Starting Bus Stop")."
            label.font = .getFont(.regular, size: 14)
            label.textAlignment = .center
            label.textColor = Colors.secondaryText

            containerView.addSubview(label)

            label.snp.makeConstraints { (make) in
                make.centerX.centerY.equalToSuperview()
            }
        } else {
            label.text = headerTitles(section: section)
            label.font = .getFont(.regular, size: 12)
            label.textColor = Colors.secondaryText

            containerView.addSubview(label)

            label.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
            }
        }

        return containerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isEmptyHeaderView(section: section) {
            return 60
        } else {
            return UIFont.getFont(.regular, size: 12).lineHeight
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let tableViewPadding: CGFloat = 12
        return UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: tableViewPadding))
    }

}

// MARK: DZNEmptyDataSet
extension RouteOptionsViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    private func setupEmptyDataSet() {
        routeResults.emptyDataSetSource = self
        routeResults.emptyDataSetDelegate = self
        routeResults.tableFooterView = UIView()
        routeResults.contentOffset = .zero
    }

    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {

        let customView = UIView()
        var symbolView = UIView()

        if showRouteSearchingLoader {
            symbolView = LoadingIndicator()
        } else {
            let imageView = UIImageView(image: #imageLiteral(resourceName: "noRoutes"))
            imageView.contentMode = .scaleAspectFit
            symbolView = imageView
        }

        let retryButton = UIButton()
        retryButton.setTitle(Constants.Buttons.retry, for: .normal)
        retryButton.setTitleColor(Colors.tcatBlue, for: .normal)
        retryButton.titleLabel?.font = .getFont(.regular, size: 16.0)
        retryButton.addTarget(self, action: #selector(tappedRetryButton), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.font = .getFont(.regular, size: 18.0)
        titleLabel.textColor = Colors.metadataIcon
        titleLabel.text = showRouteSearchingLoader ? Constants.EmptyStateMessages.lookingForRoutes : Constants.EmptyStateMessages.noRoutesFound
        titleLabel.sizeToFit()

        customView.addSubview(symbolView)
        customView.addSubview(titleLabel)
        if !showRouteSearchingLoader {
            customView.addSubview(retryButton)
        }

        symbolView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            let offset = navigationController?.navigationBar.frame.height ?? 0 + routeSelection.frame.height
            make.centerY.equalToSuperview().offset((showRouteSearchingLoader ? -20 : -60)+(-offset/2))
            make.width.height.equalTo(showRouteSearchingLoader ? 40 : 180)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(symbolView.snp.bottom).offset(10)
            make.centerX.equalTo(symbolView.snp.centerX)
        }

        if !showRouteSearchingLoader {
            retryButton.snp.makeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
                make.centerX.equalTo(titleLabel.snp.centerX)
                make.height.equalTo(16)
            }
        }

        return customView
    }

    @objc func tappedRetryButton(button: UIButton) {
        showRouteSearchingLoader = true
        routeResults.reloadData()
        let delay = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
            self.searchForRoutes()
        }
    }

    // Don't allow pull to refresh in empty state -- want users to use the retry button
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    // Allow for touch in empty state
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
