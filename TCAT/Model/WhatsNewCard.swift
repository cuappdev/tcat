//
//  WhatsNewCard.swift
//  TCAT
//
//  Created by Matt Barker on 3/6/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit

struct WhatsNewCard: Codable {

    // MARK: What's New Card Data

    static let newFeature = WhatsNewCard(
        label: "New in Ithaca Transit",
        title: "Today Extension Widget",
        description: "View live bus routes to your favorite places at a glance. Tap Edit in Notification Center and add Ithaca Transit to get started.",
        primaryActionTitle: "Dismiss",
        primaryActionHandler: nil,
        secondaryActionTitle: nil,
        secondaryActionHandler: nil
    )

    static let promotion = WhatsNewCard(
        label: "Cornell App Development",
        title: "Support Transit on Giving Day",
        description: "Donate to Cornell AppDev to help Transit improve routes, maintain live tracking, and more! Donations are accepted until 11:59 PM today.",
        primaryActionTitle: "Give",
        primaryActionHandler: { (_) in
            actionLinkHandler(webLink: "https://givingday.cornell.edu/campaigns/cu-app-development", appLink: nil, completion: nil)
         },
        secondaryActionTitle: nil,
        secondaryActionHandler: nil
    )

    /// Giving Day: Is today Thursday, 3/14 in Ithaca?
    static func isPromotionActive() -> Bool {
        let now = Date()

        var sharedComponent = DateComponents()
        sharedComponent.year = 2019
        sharedComponent.month = 3
        sharedComponent.day = 14
        sharedComponent.timeZone = TimeZone(abbreviation: "EST")

        var startDateComponent = sharedComponent
        startDateComponent.hour = 0
        startDateComponent.minute = 0
        startDateComponent.second = 0
        guard let startDate = Calendar.current.date(from: startDateComponent) else {
            return false
        }

        var endDateComponent = sharedComponent
        endDateComponent.hour = 23
        endDateComponent.minute = 59
        endDateComponent.second = 59
        guard let endDate = Calendar.current.date(from: endDateComponent) else {
            return false
        }

        return startDate < now && now < endDate
    }

    // MARK: Upcoming Updates

    // Twitter Update

    // var title = "@IthacaTransit on Twitter"
    // var description = "Follow our new Twitter account for schedule changes, app statuses, and promotions!",

    // var appLink = "twitter://user?screen_name=IthacaTransit"
    // var webLink = "https://twitter.com/IthacaTransit"

    // MARK: Main Descriptions

    /// This is the small blue label above the main title. Will be entirely uppercased in UI.
    var label: String

    /// The bolded main title of the card describing the update feature.
    var title: String

    /// A succinct description of the update feature.
    var description: String

    // MARK: Primary Button - Blue, Bolded

    // IMPORTANT: At least ONE action title *must* be set to create a button. It can be either for primary or secondary.

    /// The title of the primary button. If doesn't exist, make nil to hide button.
    var primaryActionTitle: String?

    /// The function to perform in the app when an action is selected.
    var primaryActionHandler: ((_: HomeMapViewController) -> Void)?
    // MARK: Secondary Button - Gray, Regular

    /// The title of the secondary button. If doesn't exist, make nil to hide button.
    var secondaryActionTitle: String?

    /// The function to perform in the app when an action is selected.
    var secondaryActionHandler: ((_: HomeMapViewController) -> Void)?

    /// Codable support
    enum CodingKeys: String, CodingKey {
        case label
        case title
        case description
    }

    // MARK: Functions

    /// Open a website or app link if an action is selected.
    static func actionLinkHandler(webLink: String?, appLink: String?, completion: (() -> Void)?) {
        if let link = webLink {
            open(link, optionalAppLink: appLink) {
                completion?()
            }
        } else {
            completion?()
        }
    }

    /// Helpfer function to open web or app links.
    private static func open(_ link: String, optionalAppLink: String?, linkOpened: @escaping () -> Void) {
        if
            let appLink = optionalAppLink,
            let appURL = URL(string: appLink),
            UIApplication.shared.canOpenURL(appURL)
        {
            // Open link in an installed app.
            UIApplication.shared.open(appURL, options: [:]) { _ in
                linkOpened()
            }
        } else if let webURL = URL(string: link) {
            // Open link in Safari.
            UIApplication.shared.open(webURL, options: [:]) { _ in
                linkOpened()
            }
        }
    }

    func isEqual(to compared: WhatsNewCard) -> Bool {
        return compared.title == self.title && compared.description == self.description
    }
}
