//
//  RouteDetailDrawerViewController+Extensions.swift
//  TCAT
//
//  Created by Omar Rasheed on 5/14/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import NotificationBannerSwift
import Pulley
import UIKit

// MARK: - Gesture Recognizers and Interaction-Related Functions
extension RouteDetailDrawerViewController: UIGestureRecognizerDelegate {

    /// Animate detailTableView depending on context, centering map
    @objc func summaryTapped(_ sender: UITapGestureRecognizer? = nil) {

        if let drawer = self.parent as? RouteDetailViewController {
            switch drawer.drawerPosition {
            case .collapsed, .partiallyRevealed:
                if selectedDirection != nil {
                    drawer.setDrawerPosition(position: .collapsed, animated: true)
                } else {
                    drawer.setDrawerPosition(position: .open, animated: true)
                }
            case .open:
                drawer.setDrawerPosition(position: .collapsed, animated: true)
            default: break
            }
        }
    }

}

extension RouteDetailDrawerViewController: LargeDetailTableViewDelegate {

    func toggleCellExpansion(on cell: LargeDetailTableViewCell) {
        toggleCellExpansion(for: cell)
    }

}

extension RouteDetailDrawerViewController: NotificationToggleTableViewDelegate {

    func displayNotificationBanner(type: NotificationBannerType) {
        guard let direction = getFirstDirection() else { return }
        FloatingNotificationBanner(
            customView: NotificationBannerView(
                busAttachment: getBusIconImageAsTextAttachment(for: direction.routeNumber),
                type: type
            )
        ).show(
            queue: NotificationBannerQueue(maxBannersOnScreenSimultaneously: 1),
            on: navigationController
        )
    }

    private func getBusIconImageAsTextAttachment(for busNumber: Int) -> NSTextAttachment {
        let busIconTextSpacing: CGFloat = 5

        // Instantiate busIconView off screen to later turn into UIImage
        let busIconView = BusIcon(type: .blueBannerSmall, number: busNumber)

        let busIconFrame = CGRect(
            x: 0,
            y: 0,
            width: busIconView.intrinsicContentSize.width + busIconTextSpacing * 2,
            height: busIconView.intrinsicContentSize.height
        )

        // Create container to add padding on sides
        let containerView = UIView(frame: busIconFrame)
        containerView.isOpaque = false
        view.addSubview(containerView)
        containerView.addSubview(busIconView)
        busIconView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(busIconTextSpacing)
            make.top.bottom.equalToSuperview()
        }

        // Create NSTextAttachment with the busIcon as a UIImage
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = containerView.getImage()

        // Lower the textAttachment to be centered within the text
        var frame = containerView.frame
        frame.origin.y -= 7
        iconAttachment.bounds = frame

        // Remove the container as it is no longer needed
        containerView.removeFromSuperview()

        return iconAttachment
    }

}

extension RouteDetailDrawerViewController: PulleyDrawerViewControllerDelegate {

    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return bottomSafeArea + summaryView.frame.height
    }

    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return UIScreen.main.bounds.height / 2
    }

    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        // Center map on drawer change
        switch drawer.drawerPosition {
        case .collapsed, .partiallyRevealed:
            guard let contentViewController = drawer.primaryContentViewController as? RouteDetailContentViewController
                else { return }
            if let direction = selectedDirection {
                if direction.type == .walk {
                    contentViewController.centerMap(on: direction, isOverviewOfPath: true)
                } else {
                    contentViewController.centerMap(on: direction)
                }
                selectedDirection = nil
            } else {
                contentViewController.centerMapOnOverview(drawerPreviewing: drawer.drawerPosition == .partiallyRevealed)
            }
        default: break
        }
    }

    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        // Manage cover view hiding drawer when collapsed
        if distance == collapsedDrawerHeight(bottomSafeArea: bottomSafeArea) {
            safeAreaCover.alpha = 1.0
        } else {
            if safeAreaCover.alpha == 1 {
                UIView.animate(withDuration: 0.25, animations: {
                    self.safeAreaCover.alpha = 0.0
                })
            }
        }
    }

    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .partiallyRevealed, .open]
    }

}

extension RouteDetailDrawerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]

        switch section.items[indexPath.row] {
        case .busStop(let busStop):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.busStopDetailCellIdentifier) as? BusStopTableViewCell
                else { return UITableViewCell() }
            cell.configure(for: busStop.name)
            return cell
        case .direction(let direction):
            switch direction.type {
            case .walk, .arrive:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.smallDetailCellIdentifier, for: indexPath) as? SmallDetailTableViewCell
                    else { return UITableViewCell() }
                cell.configure(
                    for: direction,
                    isFirstStep: indexPath.row == 0,
                    isLastStep: indexPath.row == section.items.count - 1
                )
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.largeDetailCellIdentifier) as! LargeDetailTableViewCell
                cell.configure(
                    for: direction,
                    isFirstStep: indexPath.row == 0,
                    isExpanded: expandedDirections.contains(direction),
                    delegate: self
                )
                return cell
            }
        case .notificationType(let type):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.notificationToggleCellIdentifier) as? NotificationToggleTableViewCell
                else { return UITableViewCell() }
            cell.configure(
                for: type,
                isFirst: indexPath.row == 0,
                delegate: self
            )
            return cell
        }
    }
}

extension RouteDetailDrawerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let notificationCellHeight: CGFloat = 70
        let section = sections[indexPath.section]

        switch section.type {
        case .routeDetail:
            if let direction = section.items[indexPath.row].getDirection(),
                    direction.type == .depart || direction.type == .transfer {
                return UITableView.automaticDimension
            } else {
                return RouteDetailCellSize.smallHeight
            }
        case .notification: return notificationCellHeight
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Empty Footer
        let emptyFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Constants.Footers.emptyFooterView) ??
            UITableViewHeaderFooterView(reuseIdentifier: Constants.Footers.emptyFooterView)

        emptyFooterView.contentView.backgroundColor = Colors.white

        // Create Footer for No Data from Live Tracking Footer, if needed
        guard
            let drawer = self.parent as? RouteDetailViewController,
            let contentViewController = drawer.primaryContentViewController as? RouteDetailContentViewController
            else {
                return emptyFooterView
        }

        var message: String?

        if !contentViewController.noDataRouteList.isEmpty {
            if contentViewController.noDataRouteList.count > 1 {
                message = Constants.Banner.noLiveTrackingForRoutes
            } else {
                let routeNumber = contentViewController.noDataRouteList.first!
                message = Constants.Banner.noLiveTrackingForRoute + " " + "\(routeNumber)."
            }
        } else {
            message = nil
        }

        if let message = message,
            sections[section].type == .routeDetail {
            let phraseLabelFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Constants.Footers.phraseLabelFooterView)
                as? PhraseLabelFooterView ?? PhraseLabelFooterView(reuseIdentifier: Constants.Footers.phraseLabelFooterView)
            phraseLabelFooterView.configure(with: message)
            return phraseLabelFooterView
        }

        return emptyFooterView

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]

        if section.type == .routeDetail {
            let direction = section.items[indexPath.row].getDirection()

            selectedDirection = direction

            if let drawer = self.parent as? RouteDetailViewController {
                drawer.setDrawerPosition(position: .collapsed, animated: true)
            }
        }
    }
}
