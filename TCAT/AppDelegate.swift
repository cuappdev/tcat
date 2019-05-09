//
//  AppDelegate.swift
//  TCAT
//
//  Created by Kevin Greer on 9/7/16.
//  Copyright © 2016 cuappdev. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Fabric
import Crashlytics
import SafariServices
import WhatsNewKit
import UserNotifications

// This is used for app-specific preferences
let userDefaults = UserDefaults.standard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let encoder = JSONEncoder()
    let userDataInits: [(key: String, defaultValue: Any)] = [
        (key: Constants.UserDefaults.onboardingShown, defaultValue: false),
        (key: Constants.UserDefaults.recentSearch, defaultValue: [Any]()),
        (key: Constants.UserDefaults.favorites, defaultValue: [Any]())
    ]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Set Up Google Services
        FirebaseApp.configure()
        GMSServices.provideAPIKey(Keys.googleMaps.value)
        GMSPlacesClient.provideAPIKey(Keys.googlePlaces.value)
        
        // Update shortcut items
        AppShortcuts.shared.updateShortcutItems()

        // Set Up Analytics
        #if !DEBUG
            Crashlytics.start(withAPIKey: Keys.fabricAPIKey.value)
        #endif

        // Log basic information
        let payload = AppLaunchedPayload()
        Analytics.shared.log(payload)
        setupUniqueIdentifier()
        JSONFileManager.shared.deleteAllJSONs()

        for (key, defaultValue) in userDataInits {
            if userDefaults.value(forKey: key) == nil {
                if key == Constants.UserDefaults.favorites {
                    sharedUserDefaults?.set(defaultValue, forKey: key)
                } else {
                    userDefaults.set(defaultValue, forKey: key)
                }
            }
            else if key == Constants.UserDefaults.favorites && sharedUserDefaults?.value(forKey: key) == nil {
                sharedUserDefaults?.set(userDefaults.value(forKey: key), forKey: key)
            }
        }

        // Track number of app opens for Store Review prompt
        StoreReviewHelper.incrementAppOpenedCount()

        // Debug - Always Show Onboarding
        // userDefaults.set(false, forKey: Constants.UserDefaults.onboardingShown)

        getBusStops()

        // Initalize first view based on context
        let showOnboarding = !userDefaults.bool(forKey: Constants.UserDefaults.onboardingShown)
        let rootVC = showOnboarding ? OnboardingViewController(initialViewing: true) : HomeViewController()
        let navigationController = showOnboarding ? OnboardingNavigationController(rootViewController: rootVC) :
            CustomNavigationController(rootViewController: rootVC)
        
        // v1.3 Data Migration
        if
            VersionStore.shared.savedAppVersion <= WhatsNew.Version(major: 1, minor: 2, patch: 1),
            let homeViewController = rootVC as? HomeViewController
        {
            print("Begin Data Migration")
            homeViewController.showLoadingScreen()
            migrationToNewPlacesModel { (success, errorDescription) in
                homeViewController.removeLoadingScreen()
                print("Data Migration Complete - Success: \(success), Error: \(errorDescription ?? "n/a")")
                let payload = DataMigrationOnePointThreePayload(success: success, errorDescription: errorDescription)
                Analytics.shared.log(payload)
            }
        }

        // Register for Push Notifications
        registerForPushNotifications()

        // Initalize window without storyboard
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = navigationController
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleShortcut(item: shortcutItem)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: Helper Functions
    
    /// Convert BusStop and PlaceResult models to new unified Place model.
    func migrationToNewPlacesModel(completion: @escaping (_ success: Bool, _ errorDescription: String?) -> Void) {
        
        // "See All Stops" and App Shortcuts data is handled automatically
    
        let dispatchGroup = DispatchGroup()
        
        var success = true
        var description: String?
        
        // Favorites Data
        let favoritesKey = Constants.UserDefaults.favorites
        
        if
            let storedPlaces = userDefaults.value(forKey: favoritesKey) as? Data,
            let favorites = NSKeyedUnarchiver.unarchiveObject(with: storedPlaces) as? [Any]
        {
            // This will only fire on legacy verisions and models
            dispatchGroup.enter()
            convertDataToPlaces(data: favorites) { (places, error) in
                if let encodedObject = try? self.encoder.encode(places), error == nil {
                    userDefaults.set(encodedObject, forKey: favoritesKey)
                } else {
                    success = false
                    description = "Favorites Conversion Failed: \(error ?? "Encoder")"
                    print("[AppDelegate] dataMigration favorites", error ?? "Encoder")
                }
                dispatchGroup.leave()
            }
        }
        
        // Recent Searches Data
        let recentSearchesKey = Constants.UserDefaults.recentSearch
        
        if
            let storedPlaces = userDefaults.value(forKey: recentSearchesKey) as? Data,
            let recents = NSKeyedUnarchiver.unarchiveObject(with: storedPlaces) as? [Any]
        {
            //  This will only fire on legacy versions and models
            dispatchGroup.enter()
            convertDataToPlaces(data: recents) { (places, error) in
                if let encodedObject = try? self.encoder.encode(places), error == nil {
                    userDefaults.set(encodedObject, forKey: recentSearchesKey)
                } else {
                    success = false
                    description = "Recent Searches Conversion Failed: \(error ?? "Encoder")"
                    print("[AppDelegate] dataMigration recentSearches", error ?? "Encoder")
                }
                dispatchGroup.leave()
            }
        }
        
        // Could show loading UI / "Updating databse" while this happens
        dispatchGroup.notify(queue: .main) {
            completion(success, description)
        }

    }
    
    func convertDataToPlaces(data: [Any], completion: @escaping (_ places: [Place], _ error: String?) -> Void) {
        var places = [Place]()
        
        for item in data {
            
            var optionalPlace: Place?
            
            // Unwrap `Any` to `BusStop` or `PlaceResult`
            if let busStop = item as? BusStop {
                optionalPlace = Place(name: busStop.name, latitude: busStop.lat, longitude: busStop.long)
                optionalPlace?.type = .busStop
            }
            
            if let placeResult = item as? PlaceResult {
                optionalPlace = Place(name: placeResult.name, placeDescription: placeResult.detail, placeIdentifier: placeResult.placeID)
                optionalPlace?.type = .googlePlace
            }
            
            guard let place = optionalPlace else {
                completion(places, "Unable to retrieve busStop or placeResult data.")
                return
            }
            
            if place.type == .googlePlace {
                CoordinateVisitor.getCoordinates(for: place) { (latitude, longitude, error) in
                    if error != nil {
                        completion(places, "\(place.name): Unable to get Google Place coordinates")
                    } else {
                        place.latitude = latitude
                        place.longitude = longitude
                        places.append(place)
                    }
                    if places.count == data.count {
                        completion(places, nil)
                    }
                }
            } else {
                places.append(place)
                if places.count == data.count {
                    completion(places, nil)
                }
            }
            
        } // end for loop
        
    }
    
    /// Creates and sets a unique identifier. If the device identifier changes, updates it.
    func setupUniqueIdentifier() {
        if
            let uid = UIDevice.current.identifierForVendor?.uuidString,
            uid != sharedUserDefaults?.string(forKey: Constants.UserDefaults.uid)
        {
            sharedUserDefaults?.set(uid, forKey: Constants.UserDefaults.uid)
        }
    }
    
    func handleShortcut(item: UIApplicationShortcutItem) {
        let optionsVC = RouteOptionsViewController()
        if let shortcutData = item.userInfo as? [String: Data] {
            guard
                let place = shortcutData["place"],
                let destination = try? decoder.decode(Place.self, from: place)
            else {
                print("[AppDelegate] Unable to access shortcutData['place']")
                return
            }
            optionsVC.searchTo = destination
            if let navController = window?.rootViewController as? CustomNavigationController {
                navController.pushViewController(optionsVC, animated: false)
            }
            let payload = HomeScreenQuickActionUsedPayload(name: destination.name)
            Analytics.shared.log(payload)
        }
    }

    /* Get all bus stops and store in userDefaults */
    func getBusStops() {
        Network.getAllStops().perform(withSuccess: { allBusStopsRequest in
            let allBusStops = allBusStopsRequest.data
            if allBusStops.isEmpty {
                self.handleGetAllStopsError()
            } else {
                let encodedObject = try? JSONEncoder().encode(allBusStops)
                userDefaults.set(encodedObject, forKey: Constants.UserDefaults.allBusStops)
            }
        }, failure: { error in
            print("getBusStops error:", error.localizedDescription)
            self.handleGetAllStopsError()
        })
    }

    func showWhatsNew(items: [WhatsNew.Item]) {
        let whatsNew = WhatsNew(
            title: "WhatsNewKit",
            // The features you want to showcase
            items: items
        )
        // Initialize WhatsNewViewController with WhatsNew
        let whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew
        )

        // Present it 🤩
        UIApplication.shared.keyWindow?.presentInApp(whatsNewViewController)
    }

    /// Present an alert indicating bus stops weren't fetched.
    func handleGetAllStopsError() {
        let title = "Couldn't Fetch Bus Stops"
        let message = "The app will continue trying on launch. You can continue to use the app as normal."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        UIApplication.shared.keyWindow?.presentInApp(alertController)
    }

    /// Open the app when opened via URL scheme
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    
        // URLs for testing
        // BusStop: ithaca-transit://getRoutes?lat=42.442558&long=-76.485336&stopName=Collegetown
        // PlaceResult: ithaca-transit://getRoutes?lat=42.44707979999999&long=-76.4885196&destinationName=Hans%20Bethe%20House

        let rootVC = HomeViewController()
        let navigationController = CustomNavigationController(rootViewController: rootVC)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        if url.absoluteString.contains("getRoutes") { // siri URL scheme
            var latitude: CLLocationDegrees?
            var longitude: CLLocationDegrees?
            var stopName: String?
            let optionsVC = RouteOptionsViewController()

            if
                let lat = items?.filter({ $0.name == "lat" }).first?.value,
                let long = items?.filter({ $0.name == "long" }).first?.value,
                let stop = items?.filter({ $0.name == "stopName" }).first?.value {
                    latitude = Double(lat)
                    longitude = Double(long)
                    stopName = stop
                }

            if let latitude = latitude, let longitude = longitude, let stopName = stopName {
                let place = Place(name: stopName, latitude: latitude, longitude: longitude)
                optionsVC.searchTo = place
                navigationController.pushViewController(optionsVC, animated: false)
                return true
            }
        }

        return false
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        if #available(iOS 12.0, *) {
            if
                let intent = userActivity.interaction?.intent as? GetRoutesIntent,
                let latitude = intent.latitude,
                let longitude = intent.longitude,
                let searchTo = intent.searchTo,
                let stopName = searchTo.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let url = URL(string: "ithaca-transit://getRoutes?lat=\(latitude)&long=\(longitude)&stopName=\(stopName)")
            {
                UIApplication.shared.open(url, options: [:]) { (didComplete) in
                    let intentDescription = userActivity.interaction?.intent.intentDescription ?? "No Intent Description"
                    let payload = SiriShortcutUsedPayload(didComplete: didComplete,
                                                               intentDescription: intentDescription,
                                                               locationName: stopName)
                    Analytics.shared.log(payload)
                }
                return true
            }
        }
        return false
    }

}

extension UIWindow {

    /// Find the visible view controller in the root navigation controller and present passed in view controlelr.
    func presentInApp(_ viewController: UIViewController) {
        (rootViewController as? UINavigationController)?.visibleViewController?.present(viewController, animated: true)
    }

}

// MARK: - Push Notifications
extension AppDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
        // Convert deviceToken to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }

    /// Register for Push Notifications
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
        }
    }

    /// Check current notification settings
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
