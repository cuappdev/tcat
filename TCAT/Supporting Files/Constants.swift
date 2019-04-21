//
//  Constants.swift
//  TCAT
//
//  Created by Monica Ong on 9/16/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit

/// App-wide constants
struct Constants {

    /// The phrases used for alerts
    struct Alerts {

        struct GeneralActions {
            static let settings = "Settings"
            static let cancel = "Cancel"
            static let dontRemind = "Don't Remind Me Again"
        }

        struct AlertsRequestFailure {
            static let title = "Couldn't Fetch Service Alerts"
            static let message = "There was an error fetching service alerts. Please retry again."
            static let action = "OK"
        }

        struct LocationPermissions {
            static let title =  Constants.Alerts.LocationDisabled.title
            static let message = "Tap Settings to change your location permissions, or continue using a limited version of the app."
        }

        struct LocationDisabled {
            static let title = "Location Services Disabled"
            static let message = "The app won't be able to use your current location without permission. Tap Settings to turn on Location Services."
            static let settings = Constants.Alerts.GeneralActions.settings
            static let cancel = Constants.Alerts.GeneralActions.cancel
            static let dontRemind = Constants.Alerts.GeneralActions.dontRemind
        }

        struct LocationEnable {
            static let title = Constants.Alerts.LocationDisabled.title
            static let message = "You need to enable Location Services in Settings"
            static let settings = Constants.Alerts.GeneralActions.settings
            static let cancel = Constants.Alerts.GeneralActions.cancel
        }

        struct MagicBus {
            static let title = "Be-beep be-beep!"
            static let message = "says the TCAT bus."
            static let action = "✨📚🚌"
        }

        struct EmailFailure {
            static let title = "Couldn't Send Email"
            static let message = "To send your message with device logs, please add an email account in Settings > Accounts & Passwords > Add Account. You can also contact us at \(Constants.App.contactEmailAddress) to send feedback."
            static let emailSettings = "Email Settings"
            static let copyEmail = "Copy Address to Clipboard"
            static let cancel = Constants.Alerts.GeneralActions.cancel
        }

        struct Teleportation {
            static let title = "You're here!"
            static let message = "You have arrived at your destination. Thank you for using our TCAT Teleporation™ feature (beta)."
            static let action = "😐😒🙄"
        }

        struct OutOfRange {
            static let title = "Location Out Of Range"
            static let message = "Try looking for another route with start and end locations closer to Tompkins County."
            static let action = "OK"
        }

        struct MaxFavorites {
            static let title = "Maximum Number of Favorites"
            static let message = "To add more favorites, please swipe left and delete one first."
            static let action = "Got It!"
        }

        struct GooglePlacesFailure {
            static let title = "Couldn't Fetch Place Information"
            static let message = "We ran into an issue fetching the coordinates of the selected location. Please try again later."
            static let action = "OK"
        }
    }

    struct App {
        /// The App Store Identifier used in App Store links
        static let storeIdentifier = "\(1290883721)"

        /// The link of the application in the App Store
        static let appStoreLink = "https://itunes.apple.com/app/id\(storeIdentifier)"

        /// The app version within the App Store (e.g. "1.4.2") [String value of `CFBundleShortVersionString`]
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"

        /// Developer email address to direct contact inquiries and emails toward
        static let contactEmailAddress = "ithacatransit@cornellappdev.com"

        // Twitter screen name
        static let twitterHandle = "IthacaTransit"

        /// Link to Google Forms for Feedback
        // static let feedbackLink = "https://goo.gl/forms/jYejUtVccVQ3UHH12"
    }

    /// Banner titles
    struct Banner {
        static let noInternetConnection = "No internet connection"
        static let trackingLater = "Tracking available near departure time"
        static let cannotConnectLive = "Cannot connect to live tracking"
        static let noLiveTrackingForRoutes = "No live tracking available for routes."
        static let noLiveTrackingForRoute = "No live tracking available for Route"
        static let cantConnectServer = "Could not connect to server"
        static let routeCalculationError = "Route calculation error. Please retry."
    }

    struct BusUserData {
        static let actualCoordinates = "actualCoords"
        static let indicatorCoordinates = "indicatorCoords"
        static let vehicleID = "vehicleID"
    }

    /// The phrases used for buttons throughout the app
    struct Buttons {
        static let back = "Back"
        static let cancel = "Cancel"
        static let done = "Done"
        static let retry = "Retry"
        static let share = "Share"
    }

    /// Cell identifiers
    struct Cells {
        static let placeIdentifier = "PlaceTableViewCell"

        static let addFavoriteIdentifier = "AddFavorite"
        static let seeAllStopsIdentifier = "SeeAllStops"

        static let currentLocationIdentifier = "CurrentLocation"
        static let smallDetailCellIdentifier = "SmallCell"
        static let largeDetailCellIdentifier = "LargeCell"
        static let busStopDetailCellIdentifier = "BusStopCell"

        static let informationCellIdentifier = "InformationCell"

        static let notificationsIdentifier = "NotificationsCell"
    }

    /// The empty state messages
    struct EmptyStateMessages {
        // Error messages
        static let couldntGetStops = "Couldn't Get Stops"
        static let locationNotFound = "Location Not Found"
        static let noNetworkConnection = "No Network Connection"
        static let noRoutesFound = "No Routes Found"
        static let noActiveAlerts = "No Active Service Alerts"

        // Other empty state messages
        static let lookingForRoutes = "Looking For Routes..."
    }

    struct Footers {
        static let emptyFooterView = "RouteDetailEmptyFooterView"
        static let phraseLabelFooterView = "RouteDetailPhraseLabelFooterView"
    }

    /// The phrases used in InformationViewController
    struct InformationView {
        static let onboarding = "Show Onboarding"
        static let sendFeedback = "Send Feedback"
        static let moreApps = "More Apps"
        static let website = "Visit Our Website"
        static let madeBy = "Made by Cornell App Development"
        static let appDevDescription = "An Engineering Project Team\nat Cornell University"
        static let magicSchoolBus = "Ride on the Magic School Bus"
        static let notifications = "Notifications"
        static let serviceAlerts = "Service Alerts"
    }

    /// The phrases used in onboarding
    struct Onboarding {
        // Title label phrases
        static let welcome = "Welcome to Ithaca Transit."
        static let liveTracking = "Live Tracking."
        static let searchAnywhere = "Search Anywhere."
        static let favorites = "Your Favorites."
        static let bestFeatures = "All the best features. All in one app."

        // Detail label messages
        static let welcomeMessage = "A beautiful and simple end-to-end navigation app for TCAT. Made by AppDev."
        static let liveTrackingMessage = "Know exactly where your bus is and when it will be there."
        static let searchAnywhereMessage = "From Ithaca Mall to Taughannock Falls, search any location and get there fast."
        static let favoritesMessage = "All of your favorite destinations are just one tap away."

        // Button labels
        static let begin = "BEGIN"
        static let dismiss = "Dismiss"
    }

    /// General phrases used throughout the app
    struct General {
        static let firstFavorite = "Add Your First Favorite!"
        static let tapHere = "Tap Here"
        static let searchPlaceholder = "Where to?"
        static let favoritesPlaceholder = "Search any destination"
        static let fromSearchBarPlaceholder = "Choose starting point..."
        static let toSearchBarPlaceholder = "Choose destination..."
        static let datepickerLeaveNow = "Leave Now"
        static let searchForDestination = "Search for a destination"
        static let currentLocation = "Current Location"
        static let destination = "your destination"
        static let affectedRoutes = "Affected Routes"
        static let seeAllStops = "See All Stops"
    }

    struct TableHeaders {
        static let recentSearches = "Recent Searches"
        static let favoriteDestinations = "Favorite Destinations"
        static let highPriority = "High Priority"
        static let mediumPriority = "Medium Priority"
        static let lowPriority = "Low Priority"
        static let noPriority = "Other"
    }

    /// The titles of controllers
    struct Titles {
        static let aboutUs = "About Us"
        static let allStops = "All Stops"
        static let favorite = "Add Favorite"
        static let favorites = "Add Favorites"
        static let notifications = "Notifications"
        static let routeDetails = "Route Details"
        static let routeOptions = "Route Options"
        static let routeResults = "Route Results"
        static let serviceAlerts = "TCAT Service Alerts"
    }

    struct TodayExtension {
        // cell identifiers
        static let contentCellIdentifier = "todayExtensionCell"
        static let errorCellIdentifier = "errorCell"
        static let loadingCellIdentifier = "loadingCell"

        // cell strings
        static let locationOutOfRange = "Location Out of Range"
        static let noRoutesAvailable = "No routes available to "
        static let openIthacaTransit = "Open Ithaca Transit to view favorite shortcuts."
        static let unableToLoad = "Unable to Load Routes"
    }

    struct UserDefaults {
        static let group = "group.tcat"
        static let version = "version"
        static let appLaunchCount = "appLaunchCount"
        static let onboardingShown = "onboardingShown"
        static let showLocationAuthReminder = "locationAuthReminder"
        static let uid = "uid"

        /// True if the current card has been dismissed by user
        static let whatsNewDismissed = "whatsNewDismissed"
        static let recentSearch = "recentSearch"
        static let allBusStops = "allBusStops"
        static let favorites = "favorites"
        static let servicedRoutes = "servicedRoutes"
        static let whatsNewCardVersion = "whatsNewVersion"
        static let promotionDismissed = "promotionDismissed"
    }

    struct Values {
        static let maxDistanceBetweenStops = 160.0
        static let fuzzySearchMinimumValue = 75

        /// The most extreme points of TCAT Routes
        struct RouteMaxima {

            /// Max Latitude Value
            static let north: Double = 42.61321283145329
            /// Max Longitude Value
            static let east: Double = -76.28125469914926
            /// Min Latitude Value
            static let south: Double = 42.32796328578829
            /// Min Longitude Value
            static let west: Double = -76.67690943302259
        }

        /// The borders to use for valid TCAT bus service area
        struct RouteBorders {
            // Calculated by converting latitudeMidpoint to radians and multuplying by oneLatDegree
            // https://gis.stackexchange.com/questions/142326/calculating-longitude-length-in-miles
            // let oneLatDegree = 69.172
            // let latitudeMidpoint = 42.470588059
            // let oneMileInLatitude = 1 / 69.172
            // let oneMileInLongitude = 1 / 51.2738554594
            // Conversion: 1º / x mi

            /// Max Latitude Value
            static let northBorder: Double = 42.61321283145329 + (1 / 69.172)
            /// Max Longitude Value
            static let eastBorder: Double = -76.28125469914926 + (1 / 51.2738554594)
            /// Min Latitude Value
            static let southBorder: Double = 42.32796328578829 - (1 / 69.172)
            /// Min Longitude Value
            static let westBorder: Double = -76.67690943302259 - (1 / 51.2738554594)
        }
    }

}
