//
//  RouteDetailViewController.swift
//  TCAT
//
//  Created by Matthew Barker on 2/11/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import CoreLocation
import FutureNova
import GoogleMaps
import MapKit
import NotificationBannerSwift
import Pulley
import SwiftyJSON
import UIKit

class RouteDetailContentViewController: UIViewController {

    var drawerDisplayController: RouteDetailDrawerViewController?

    /// Keep track of statuses of bus routes throughout view life cycle
    var noDataRouteList: [Int] = []

    var bounds = GMSCoordinateBounds()
    var busIndicators = [GMSMarker]()
    var buses = [GMSMarker]()
    var currentLocation: CLLocationCoordinate2D?
    var directions: [Direction] = []
    /// Number of seconds to wait before auto-refreshing live tracking network call call, timed with live indicator
    var liveTrackingNetworkRefreshRate: Double = LiveIndicator.interval * 1.0
    var liveTrackingNetworkTimer: Timer?
    private var locationManager = CLLocationManager()
    var mapView: GMSMapView!
    private let networking: Networking = URLSession.shared.request
    private var paths: [Path] = []
    private var route: Route!
    private var routeOptionsCell: RouteTableViewCell?

    private var banner: StatusBarNotificationBanner? {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private let mapPadding: CGFloat = 80
    private let markerRadius: CGFloat = 8

    /// Initalize RouteDetailViewController. Be sure to send a valid route, otherwise
    /// dummy data will be used. The directions parameter have logical assumptions,
    /// such as ArriveDirection always comes after DepartDirection.
    init(route: Route, currentLocation: CLLocationCoordinate2D?, routeOptionsCell: RouteTableViewCell?) {
        super.init(nibName: nil, bundle: nil)
        self.routeOptionsCell = routeOptionsCell
        initializeRoute(route, currentLocation)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up Location Manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Set up Share button
        let shareButton = UIBarButtonItem(image: #imageLiteral(resourceName: "share"), style: .plain, target: self, action: #selector(shareRoute))
        shareButton.tintColor = Colors.primaryText
        guard let routeDetailViewController = self.parent as? RouteDetailViewController else { return }
        routeDetailViewController.navigationItem.setRightBarButton(shareButton, animated: true)

        // Debug Function
        // createDebugBusIcon()

        // Draw route
        drawMapRoute()
    }

    /// Construct Directions based on Route and parse Waypoint / Path data
    func initializeRoute(_ route: Route, _ currentLocation: CLLocationCoordinate2D?) {
        self.route = route
        self.directions = route.directions
        self.currentLocation = currentLocation

        let isWalkingRoute = directions.reduce(true) { $0 && $1.type == .walk }
        // Plot the paths of all directions
        for (directionIndex, direction) in directions.enumerated() {
            var waypoints: [Waypoint] = []
            for (pathIndex, point) in direction.path.enumerated() {
                let isStop: Bool = direction.type != .walk
                var isTypeSet = false
                var type: WaypointType = .none

                // First Direction
                if directionIndex == 0 {
                    if pathIndex == 0 && (currentLocation == nil || isWalkingRoute) { // First Waypoint
                        type = .origin
                        isTypeSet = true
                    } else if pathIndex == direction.path.count - 1 { // Fast waypoint
                        type = directions.count == 1 ? .destination : (isStop ? .bus : .none)
                        isTypeSet = true
                    }
                }

                // Last Direction
                if !isTypeSet && directionIndex == directions.count - 1 {
                    if pathIndex == 0 { // First Waypoint
                        type = isStop ? .bus : .none
                        isTypeSet = true
                    } else if pathIndex == direction.path.count - 1 { // Last Waypoint
                        type = .destination
                        isTypeSet = true
                    }
                }

                // First & Last Bus Segments
                if !isTypeSet && direction.type == .depart && (pathIndex == 0 || pathIndex == direction.path.count - 1) {
                    type = .bus
                    isTypeSet = true
                }

                let waypoint = Waypoint(lat: point.latitude, long: point.longitude, wpType: type, isStop: isStop)
                waypoints.append(waypoint)
            }

            let path = direction.type == .walk ? WalkPath(waypoints) : BusPath(waypoints)
            paths.append(path)
        }

        drawerDisplayController = RouteDetailDrawerViewController(route: route)
    }

    // MARK: - Status Bar Functions

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return banner != nil ? .lightContent : .default
    }

    /// Show banner if no other status banner exists; turns status bar light
    private func showBanner(_ message: String, status: BannerStyle) {
        hideBanner()
        self.banner = StatusBarNotificationBanner(title: message, style: status)

        // Change default colors for specific banners
        if status == .info {
            self.banner?.backgroundColor = Colors.dividerTextField
        }

        self.banner?.autoDismiss = false
        self.banner?.dismissOnTap = true
        self.banner?.show(queuePosition: .front, on: navigationController)
    }

    /// Dismisses and removes banner; turns status bar back to default
    func hideBanner() {
        self.banner?.dismiss()
        self.banner = nil
    }

    // MARK: - Network Calls

    private func busLocations(_ directions: [Direction]) -> Future<Response<[BusLocation]>> {
        return networking(Endpoint.getBusLocations(directions)).decode()
    }

    /// Fetch live-tracking information for the first direction's bus route.
    /// Handles connection issues with banners. Animated indicators. 
    @objc func getBusLocations() {
        let directionsAreValid = route.directions.reduce(true) { (result, direction) in
            if direction.type == .depart {
                return result && direction.routeNumber > 0 && direction.tripIdentifiers != nil
            } else {
                return true
            }
        }
        if !directionsAreValid {
            printClass(context: "\(#function)", message: "Directions are not valid")
            let payload = NetworkErrorPayload(
                location: "\(self) Get Bus Locations",
                type: "Invalid Directions",
                description: "Directions are not valid")
            Analytics.shared.log(payload)
            return
        }

        busLocations(route.directions).observe { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .value(let response):
                    if response.data.isEmpty {
                        // Reset banner in case transitioned from Error to Online - No Bus Locations
                        self.hideBanner()
                    }
                    self.parseBusLocationsData(data: response.data)
                case .error(let error):
                    self.printClass(context: "\(#function) error", message: error.localizedDescription)
                    if let banner = self.banner, !banner.isDisplaying {
                        self.showBanner(Constants.Banner.cannotConnectLive, status: .danger)
                    }
                    let payload = NetworkErrorPayload(
                        location: "\(self) Get Bus Locations",
                        type: "\((error as NSError).domain)",
                        description: error.localizedDescription)
                    Analytics.shared.log(payload)
                }
            }
        }
        // Bounce any visible indicators
        bounceIndicators()
    }

    private func parseBusLocationsData(data: [BusLocation]) {
        data.forEach { busLocation in
            switch busLocation.dataType {
            case .noData:
                if !self.noDataRouteList.contains(busLocation.routeId) {
                    self.noDataRouteList.append(busLocation.routeId)
                }
            case .invalidData:
                if let previouslyUnavailableRoute = self.noDataRouteList.firstIndex(of: busLocation.routeId) {
                    self.noDataRouteList.remove(at: previouslyUnavailableRoute)
                }
                if self.noDataRouteList.isEmpty {
                    self.hideBanner()
                }
                self.showBanner(Constants.Banner.trackingLater, status: .info)

            case .validData:
                if let previouslyUnavailableRoute = self.noDataRouteList.firstIndex(of: busLocation.routeId) {
                    self.noDataRouteList.remove(at: previouslyUnavailableRoute)
                }
                if self.noDataRouteList.isEmpty {
                    self.hideBanner()
                }
                self.setBusLocation(busLocation)
            }
        }
    }

    /// Update the map with new busLocations, adding or replacing based on vehicleID.
    /// If `validTripIDs` is passed in, only buses that match the tripID will be drawn.
    /// The input includes every bus associated with a certain line. Any visible indicators
    /// are also animated.
    private func setBusLocation(_ bus: BusLocation) {
        // New bus coordinates
        let busCoords = CLLocationCoordinate2D(latitude: bus.latitude, longitude: bus.longitude)
        let existingBus = buses.first(where: {
//            return getUserData(for: $0, key: Constants.BusUserData.vehicleID) as? Int == bus.vehicleID
            return getUserData(for: $0, key: Constants.BusUserData.vehicleID) as? String == bus.vehicleId
        })

        if let newBus = existingBus { // If bus is already on map, update and animate change
            let latencyConstant = 0.25 // Allow time to receive new live bus request

            CATransaction.begin()
            CATransaction.setAnimationDuration(liveTrackingNetworkRefreshRate + latencyConstant)

            newBus.appearAnimation = .none

//            updateUserData(for: newBus, with: [
//                Constants.BusUserData.actualCoordinates: busCoords,
//                Constants.BusUserData.vehicleID: bus.vehicleID
//                ])
            updateUserData(for: newBus, with: [
                Constants.BusUserData.actualCoordinates: busCoords,
                Constants.BusUserData.vehicleID: bus.vehicleId
            ])

            // Position
            newBus.position = busCoords

            CATransaction.commit()
        } else { // Otherwise, add bus to map
            guard let iconView = bus.iconView as? BusLocationView else { return }
            let marker = GMSMarker(position: busCoords)
            marker.appearAnimation = .pop
            marker.iconView = iconView

//            updateUserData(for: marker, with: [
//                Constants.BusUserData.actualCoordinates: busCoords,
//                Constants.BusUserData.vehicleID: bus.vehicleID
//                ])
            updateUserData(for: marker, with: [
                Constants.BusUserData.actualCoordinates: busCoords,
                Constants.BusUserData.vehicleID: bus.vehicleId
            ])

            setIndex(of: marker, with: .bussing)
            marker.map = mapView
            buses.append(marker)
        }

        // Update bus indicators (if map not moved)
        mapView.delegate?.mapView?(mapView, didChange: mapView.camera)
    }

    /// Animate any visible indicators
    private func bounceIndicators() {
        for indicator in busIndicators {
            guard let originalFrame = indicator.iconView?.frame else { continue }
            guard let originalTransform = indicator.iconView?.transform else { continue }
            let insetValue = originalFrame.size.width / 24
            indicator.iconView?.transform = CGAffineTransform(scaleX: insetValue, y: insetValue)
            UIView.animate(withDuration: LiveIndicator.duration * 2, delay: 0, usingSpringWithDamping: 1,
                           initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                            indicator.iconView?.transform = originalTransform
            })
        }
    }

    // MARK: - Share Function
    @objc func shareRoute() {
        presentShareSheet(from: view, for: route, with: routeOptionsCell?.getImage())
    }

    func calculatePlacement(position: CLLocationCoordinate2D, view: UIView) -> CLLocationCoordinate2D? {
        let padding: CGFloat = 16
        let bounds = mapView.projection.visibleRegion()
        let isPartiallyRevealed = (parent as? RouteDetailViewController)?.drawerPosition == .partiallyRevealed
        var topOffset: Double {
            let origin = mapView.projection.coordinate(for: CGPoint(x: 0, y: 0)).latitude
            let withHeight = mapView.projection.coordinate(for: CGPoint(x: 0, y: view.frame.size.height)).latitude
            return origin - withHeight
        }
        var sideOffset: Double {
            let origin = mapView.projection.coordinate(for: CGPoint(x: 0, y: 0)).latitude
            let withHeight = mapView.projection.coordinate(for: CGPoint(x: view.frame.size.width, y: 0)).latitude
            return abs(origin - withHeight)
        }
        var bottomOffset: Double {
            let constant = isPartiallyRevealed ? UIScreen.main.bounds.height / 2 - mapView.padding.bottom : 0
            let origin = mapView.projection.coordinate(for: CGPoint(x: 0, y: 0)).latitude
            let withHeight = mapView.projection.coordinate(for: CGPoint(x: 0, y: constant + view.frame.size.height)).latitude
            return origin - withHeight
        }
        let top = bounds.farLeft.latitude - topOffset
        let bottom = bounds.nearRight.latitude + bottomOffset
        let left = bounds.nearLeft.longitude - sideOffset
        let right = bounds.nearRight.longitude + sideOffset
        let pastTopEdge = position.latitude > top
        let pastBottomEdge = position.latitude < bottom
        let pastLeftEdge = position.longitude < left
        let pastRightEdge = position.longitude > right

        // Set coordinate to most extreme on-screen map point if off screen
        var newPosition = position
        if pastRightEdge { newPosition.longitude = right }
        if pastLeftEdge { newPosition.longitude = left }
        if pastBottomEdge { newPosition.latitude = bottom }
        if pastTopEdge { newPosition.latitude = top }

        // Convert coordinate to point and adjust based on frame and padding
        // The actual point is at the maxY and centerX of the view
        var point = mapView.projection.point(for: newPosition)
        if pastRightEdge { point.x -= (view.frame.size.width / 2) + padding }
        if pastLeftEdge { point.x += (view.frame.size.width / 2) + padding }
        if pastTopEdge { point.y += padding - (view.frame.size.height / 2) }
        if pastBottomEdge { point.y -= padding + (isPartiallyRevealed ? 0 : view.frame.size.height) }

        // If no change needed, return nil.
        if pastRightEdge || pastLeftEdge || pastTopEdge || pastBottomEdge {
            return mapView.projection.coordinate(for: point)
        } else {
            return nil
        }
    }

    func calculateBearing(from marker: CLLocationCoordinate2D, to location: CLLocationCoordinate2D) -> Double {
        func degreesToRadians(_ degrees: Double) -> Double {
            return degrees * .pi / 180
        }

        func radiansToDegrees(_ radians: Double) -> Double {
            return radians * 180 / .pi
        }

        let lat1 = degreesToRadians(location.latitude)
        let lon1 = degreesToRadians(location.longitude)
        let lat2 = degreesToRadians(marker.latitude)
        let lon2 = degreesToRadians(marker.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return (radiansToDegrees(radiansBearing) + 360).truncatingRemainder(dividingBy: 360)

    }

    // MARK: - Map Functions

    /// Centers map around all waypoints in routePaths, and animates the map
    func centerMapOnOverview(drawerPreviewing: Bool = false) {
        if drawerPreviewing {
            let bottomOffset: CGFloat = (UIScreen.main.bounds.height / 2) - (mapPadding / 2) - view.safeAreaInsets.bottom
            let edgeInsets = UIEdgeInsets(top: mapPadding / 2, left: mapPadding / 2, bottom: bottomOffset, right: mapPadding / 2)
            mapView.animate(with: GMSCameraUpdate.fit(bounds, with: edgeInsets))
        } else {
            mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: mapPadding))
        }
    }

    func centerMap(on direction: Direction, isOverviewOfPath: Bool = false, drawerPreviewing: Bool = false) {
        let path = GMSMutablePath()
        if isOverviewOfPath {
            direction.path.forEach { loc in path.add(loc) }
        } else {
            path.add(direction.startLocation)
        }
        let bounds = GMSCoordinateBounds(path: path)
        let update = GMSCameraUpdate.fit(bounds, withPadding: mapPadding)
        mapView.animate(with: update)
        if !isOverviewOfPath {
            mapView.animate(toZoom: Constants.Map.directionZoom)
        }
    }

    func setIndex(of marker: GMSMarker, with waypointType: WaypointType) {
        marker.zIndex = {
            switch waypointType {
            case .bus: return 1
            case .walk: return 1
            case .origin: return 3
            case .destination: return 3
            case .stop: return 1
            case .walking: return 0
            // For live bus icon / indicators
            case .bussing: return 999 // large constant to place above other elements
            default: return 0
            }
        }()
    }

    /// Draw all waypoints initially for all paths in [Path] or [[CLLocationCoordinate2D]], plus fill bounds
    private func drawMapRoute() {
        for path in paths {
            path.traveledPolyline.map = mapView
            path.map = mapView
            for waypoint in path.waypoints {
                let marker = GMSMarker(position: waypoint.coordinate)
                marker.iconView = waypoint.iconView
                marker.map = mapView
                setIndex(of: marker, with: waypoint.wpType)
                bounds = bounds.includingCoordinate(waypoint.coordinate)
            }
        }
    }

    func getDrawerDisplayController() -> RouteDetailDrawerViewController? {
        return drawerDisplayController
    }

    required convenience init(coder aDecoder: NSCoder) {
        guard let route = aDecoder.decodeObject(forKey: "route") as? Route
            else { fatalError("init(coder:) has not been implemented") }

        self.init(route: route, currentLocation: nil, routeOptionsCell: nil)
    }

}
