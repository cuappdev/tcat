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
            static let cancel = "Cancel"
            static let dontRemind = "Don't Remind Me Again"
            static let settings = "Settings"
        }

        struct AlertsRequestFailure {
            static let action = "OK"
            static let message = "There was an error fetching service alerts. Please retry again."
            static let title = "Couldn't Fetch Service Alerts"
        }

        struct LocationPermissions {
            static let message = "Tap Settings to change your location permissions, or continue using a limited version of the app."
            static let title =  Constants.Alerts.LocationDisabled.title
        }

        struct LocationDisabled {
            static let cancel = Constants.Alerts.GeneralActions.cancel
            static let dontRemind = Constants.Alerts.GeneralActions.dontRemind
            static let message = "The app won't be able to use your current location without permission. Tap Settings to turn on Location Services."
            static let settings = Constants.Alerts.GeneralActions.settings
            static let title = "Location Services Disabled"
        }

        struct LocationEnable {
            static let cancel = Constants.Alerts.GeneralActions.cancel
            static let message = "You need to enable Location Services in Settings"
            static let settings = Constants.Alerts.GeneralActions.settings
            static let title = Constants.Alerts.LocationDisabled.title
        }

        struct MagicBus {
            static let action = "✨📚🚌"
            static let message = "says the TCAT bus."
            static let title = "Be-beep be-beep!"
        }

        struct EmailFailure {
            static let cancel = Constants.Alerts.GeneralActions.cancel
            static let copyEmail = "Copy Address to Clipboard"
            static let emailSettings = "Email Settings"
            static let message = "To send your message with device logs, please add an email account in Settings > Accounts & Passwords > Add Account. You can also contact us at \(Constants.App.contactEmailAddress) to send feedback."
            static let title = "Couldn't Send Email"
        }

        struct Teleportation {
            static let action = "😐😒🙄"
            static let message = "You have arrived at your destination. Thank you for using our TCAT Teleporation™ feature (beta)."
            static let title = "You're here!"
        }

        struct OutOfRange {
            static let action = "OK"
            static let message = "Try looking for another route with start and end locations closer to Tompkins County."
            static let title = "Location Out Of Range"
        }

        struct MaxFavorites {
            static let action = "Got It!"
            static let message = "To add more favorites, please click edit and delete one first."
            static let title = "Maximum Number of Favorites"
        }

        struct PlacesFailure {
            static let action = "OK"
            static let message = "We ran into an issue fetching the coordinates of the selected location. Please try again later."
            static let title = "Couldn't Fetch Place Information"
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

        /// Twitter screen name
        static let twitterHandle = "IthacaTransit"
    }

    /// Banner titles
    struct Banner {
        static let cannotConnectLive = "Cannot connect to live tracking"
        static let cantConnectServer = "Could not connect to server"
        static let noInternetConnection = "No internet connection"
        static let noLiveTrackingForRoute = "No live tracking available for Route"
        static let noLiveTrackingForRoutes = "No live tracking available for routes."
        static let routeCalculationError = "Route calculation error. Please retry."
        static let trackingLater = "Tracking available near departure time"
    }

    struct BusUserData {
        static let actualCoordinates = "actualCoords"
        static let indicatorCoordinates = "indicatorCoords"
        static let vehicleID = "vehicleID"
    }

    /// The phrases used for buttons throughout the app
    struct Buttons {
        static let add = "Add"
        static let back = "Back"
        static let cancel = "Cancel"
        static let clear = "Clear"
        static let done = "Done"
        static let retry = "Retry"
        static let share = "Share"
    }

    /// Cell identifiers
    struct Cells {
        static let placeIdentifier = "PlaceTableViewCell"
        static let routeOptionsCellIdentifier = "RouteCell"

        static let busStopDetailCellIdentifier = "BusStopDetailCell"
        static let generalCellIdentifier = "GeneralCell"
        static let largeDetailCellIdentifier = "LargeDetailCell"
        static let notificationToggleCellIdentifier = "NotificationToggleCell"
        static let smallDetailCellIdentifier = "SmallDetailCell"

        static let informationCellIdentifier = "InformationCell"
    }

    /// The empty state messages
    struct EmptyStateMessages {
        /// Error messages
        static let couldntGetStops = "Couldn't Get Stops"
        static let locationNotFound = "Location Not Found"
        static let noActiveAlerts = "No Active Service Alerts"
        static let noNetworkConnection = "No Network Connection"
        static let noRoutesFound = "No Routes Found"

        /// Other empty state messages
        static let lookingForRoutes = "Looking For Routes..."
    }

    /// The routes for each of our endpoints
    struct Endpoints {
        static let alerts = "/alerts"
        static let allStops = "/allStops"
        static let applePlaces = "/applePlaces"
        static let appleSearch = "/appleSearch"
        static let busLocations = "/tracking"
        static let delay = "/delay"
        static let delays = "/delays"
        static let getRoutes = "/route"
        static let multiRoute = "/multiroute"
        static let placeIDCoordinates = "/placeIDCoordinates"
        static let routeSelected = "/routeSelected"
    }

    struct Footers {
        static let emptyFooterView = "RouteDetailEmptyFooterView"
        static let phraseLabelFooterView = "RouteDetailPhraseLabelFooterView"
    }

    /// The phrases used in InformationViewController
    struct InformationView {
        static let appDevDescription = "An Engineering Project Team\nat Cornell University"
        static let madeBy = "Made by Cornell App Development"
        static let magicSchoolBus = "Ride on the Magic School Bus"
        static let moreApps = "More Apps"
        static let onboarding = "Show Onboarding"
        static let sendFeedback = "Send Feedback"
        static let serviceAlerts = "Service Alerts"
        static let website = "Visit Our Website"
    }

    /// The phrases used in onboarding
    struct Onboarding {
        /// Title label phrases
        static let bestFeatures = "All the best features. All in one app."
        static let favorites = "Your Favorites."
        static let liveTracking = "Live Tracking."
        static let searchAnywhere = "Search Anywhere."
        static let welcome = "Welcome to Ithaca Transit."

        /// Detail label messages
        static let favoritesMessage = "All of your favorite destinations are just one tap away."
        static let liveTrackingMessage = "Know exactly where your bus is and when it will be there."
        static let searchAnywhereMessage = "From Ithaca Mall to Taughannock Falls, search any location and get there fast."
        static let welcomeMessage = "A beautiful and simple end-to-end navigation app for TCAT. Made by AppDev."

        /// Button labels
        static let begin = "BEGIN"
        static let dismiss = "Dismiss"
    }

    /// General phrases used throughout the app
    struct General {
        static let affectedRoutes = "Affected Routes"
        static let currentLocation = "Current Location"
        static let datepickerArriveBy = "Arrive By"
        static let datepickerLeaveAt = "Leave At"
        static let datepickerLeaveNow = "Leave Now"
        static let destination = "your destination"
        static let favoritesPlaceholder = "Search any destination"
        static let firstFavorite = "Add Your First Favorite!"
        static let fromSearchBarPlaceholder = "Choose starting point..."
        static let searchForDestination = "Search for a destination"
        static let searchPlaceholder = "Where to?"
        static let seeAllStops = "See All Stops"
        static let tapHere = "Tap Here"
        static let toSearchBarPlaceholder = "Choose destination..."
    }

    struct Map {
        static let minZoom: Float = 12
        static let directionZoom: Float = 17 // Use when zooming in on a direction in routeDetailsVC
        static let startingLat = 42.446179 // Latitude of the center point of TCAT's range which it services
        static let startingLong = -76.485070 // Longitude of the center point of TCAT's range which it services
        static let defaultZoom: Float = 15.5 // Use as initial zoom on homeMapVC
        static let maxZoom: Float = 25
        static let searchRadius = 24140
    }

    struct Notification {
        static let arrivalNotification = "is arriving"
        static let beforeBoardingConfirmation = "You will receive notifications 10 min before boarding time"
        static let delayConfirmation = "You will receive notifications for delays in"
        static let delayNotification = "has been delayed to"
        static let notifyBeforeBoarding = "Notify me 10 min before boarding"
        static let notifyDelay = "Notify me about delays"
    }

    struct SearchBar {
        static let searchField = "searchField"
        static let cancelButton = "cancelButton"
    }

    struct TableHeaders {
        static let favoriteDestinations = "Favorite Destinations"
        static let recentSearches = "Recent Searches"

        static let boardingSoon = "Boarding Soon"
        static let boardingSoonFromNearby = "Boarding Soon from Nearby Stops"
        static let noAvailableRoutes = "No Available Routes"
        static let walking = "By Walking"

        static let highPriority = "High Priority"
        static let lowPriority = "Low Priority"
        static let mediumPriority = "Medium Priority"
        static let noPriority = "Other"
    }

    /// The titles of controllers
    struct Titles {
        static let aboutUs = "About Us"
        static let allStops = "All Stops"
        static let favorite = "Add Favorite"
        static let favorites = "Add Favorites"
        static let routeDetails = "Route Details"
        static let routeOptions = "Route Options"
        static let routeResults = "Route Results"
        static let serviceAlerts = "TCAT Service Alerts"
    }

    struct TodayExtension {
        /// cell identifiers
        static let contentCellIdentifier = "todayExtensionCell"
        static let errorCellIdentifier = "errorCell"
        static let loadingCellIdentifier = "loadingCell"

        /// cell strings
        static let locationOutOfRange = "Location Out of Range"
        static let noRoutesAvailable = "No routes available to "
        static let openIthacaTransit = "Open Ithaca Transit to view favorite shortcuts."
        static let unableToLoad = "Unable to Load Routes"
    }

    struct UserDefaults {
        static let appLaunchCount = "appLaunchCount"
        static let group = "group.tcat"
        static let onboardingShown = "onboardingShown"
        static let showLocationAuthReminder = "locationAuthReminder"
        static let uid = "uid"
        static let version = "version"

        /// True if the current card has been dismissed by user
        static let allBusStops = "allBusStops"
        static let favorites = "favorites"
        static let promotionDismissed = "promotionDismissed"
        static let recentSearch = "recentSearch"
        static let servicedRoutes = "servicedRoutes"
        static let whatsNewCardVersion = "whatsNewVersion"
        static let whatsNewDismissed = "whatsNewDismissed"
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
            /// Calculated by converting latitudeMidpoint to radians and multuplying by oneLatDegree
            /// https://gis.stackexchange.com/questions/142326/calculating-longitude-length-in-miles
            /// let oneLatDegree = 69.172
            /// let latitudeMidpoint = 42.470588059
            /// let oneMileInLatitude = 1 / 69.172
            /// let oneMileInLongitude = 1 / 51.2738554594
            /// Conversion: 1º / x mi

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
