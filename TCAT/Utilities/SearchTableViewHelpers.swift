//
//  SearchTableViewHelpers.swift
//  TCAT
//
//  Created by Austin Astorga on 5/8/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import Foundation
import DZNEmptyDataSet

let encoder = JSONEncoder()
let decoder = JSONDecoder()

struct Section {
    let type: SectionType
    var items: [Place]
}

enum SectionType {
    case recentSearches
    case seeAllStops
    case searchResults
    case currentLocation
    case favorites
}

class SearchTableViewManager {

    static let shared = SearchTableViewManager()
    private var allStops: [Place]?

    private init() {}

    func getAllStops() -> [Place] {
        if let stops = allStops {
            // Check if not empty so that an empty array isn't returned
            if !stops.isEmpty {
                return stops
            }
        }
        let stops = getAllBusStops()
        allStops = stops
        return stops
    }

    private func getAllBusStops() -> [Place] {
        if let allBusStops = userDefaults.value(forKey: Constants.UserDefaults.allBusStops) as? Data,
            var busStopArray = try? decoder.decode([Place].self, from: allBusStops) {
            // Check if empty so that an empty array isn't returned
            if !busStopArray.isEmpty {
                // TODO: Move to backend
                // Creating "fake" bus stop to remove Google Places central Collegetown location choice
                let collegetownStop = Place(name: "Collegetown", latitude: 42.442558, longitude: -76.485336)
                busStopArray.append(collegetownStop)
                return busStopArray
            }
        }
        return [Place]()
    }

    func retrievePlaces(for key: String) -> [Place] {
        if key == Constants.UserDefaults.favorites {
            if let storedPlaces = sharedUserDefaults?.value(forKey: key) as? Data,
                let favorites = try? decoder.decode([Place].self, from: storedPlaces) {
                return favorites
            }

        } else if
            let storedPlaces = userDefaults.value(forKey: key) as? Data,
            let places = try? decoder.decode([Place].self, from: storedPlaces)
        {
            return places
        }
        return [Place]()
    }

    //returns the rest so we don't have to re-unarchive it
    func deleteFavorite(favorite: Place, allFavorites: [Place]) -> [Place] {
        var newFavoritesList: [Place] = []
        for item in allFavorites {
            if favorite.isEqual(item) {
                continue
            } else {
                newFavoritesList.append(item)
            }
        }

        do {
            let data = try encoder.encode(newFavoritesList)
            sharedUserDefaults?.set(data, forKey: Constants.UserDefaults.favorites)
            AppShortcuts.shared.updateShortcutItems()
        } catch let error {
            print(error)
        }
        return newFavoritesList
    }

    // Returns the rest so we don't have to re-unarchive it
    func deleteRecent(recent: Place, allRecents: [Place]) -> [Place] {
        let newRecentsList = allRecents.filter { !recent.isEqual($0) }
        do {
            let data = try encoder.encode(newRecentsList)
            userDefaults.set(data, forKey: Constants.UserDefaults.recentSearch)
        } catch let error {
            print(error)
        }

        return newRecentsList
    }

    // Clears recent searches
    func deleteAllRecents() {
        let newRecents = [Place]()
        do {
            let data = try encoder.encode(newRecents)
            userDefaults.set(data, forKey: Constants.UserDefaults.recentSearch)
        } catch let error {
            print(error)
        }
    }

    /// Possible Keys: Constants.UserDefaults (.recentSearch | .favorites)
    func insertPlace(for key: String, place: Place, bottom: Bool = false) {

        // Could replace with an enum
        let limit = key == Constants.UserDefaults.favorites ? 5 : 8

        // Ensure duplicates aren't added
        var places = retrievePlaces(for: key).filter { (savedPlace) -> Bool in
            return !savedPlace.isEqual(place)
        }

        places = bottom ? places + [place] : [place] + places

        if places.count > limit { places.remove(at: places.count - 1) }

        do {
            let data = try encoder.encode(places)
            if key == Constants.UserDefaults.favorites {
                sharedUserDefaults?.set(data, forKey: key)
            } else {
                userDefaults.set(data, forKey: key)
            }
            AppShortcuts.shared.updateShortcutItems()
        } catch let error {
            print(error)
        }

        if key == Constants.UserDefaults.favorites {
            let payload = FavoriteAddedPayload(name: place.name)
            Analytics.shared.log(payload)
        }
    }

    func sectionIndexesForBusStop() -> [String: Int] {
        var sectionIndexDictionary: [String: Int] = [:]
        let allStops = SearchTableViewManager.shared.getAllStops()
        var currentChar: Character = Character("+")
        var currentIndex = 0
        for busStop in allStops {
            if let firstChar = busStop.name.capitalized.first {
                if currentChar != firstChar {
                    sectionIndexDictionary["\(firstChar)"] = currentIndex
                    currentChar = firstChar
                }
                currentIndex += 1
            }
        }
        return sectionIndexDictionary
    }

}

/// MARK: DZNEmptyDataSet DataSource

// To be eventuallt removed and replaced with recent searches
extension SearchResultsTableViewController: DZNEmptyDataSetSource {
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -80
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "emptyPin")
    }

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: Constants.EmptyStateMessages.locationNotFound,
                                  attributes: [.foregroundColor: Colors.metadataIcon])
    }
}
