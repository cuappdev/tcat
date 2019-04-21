//
//  RouteTableViewCell.swift
//  TCAT
//
//  Created by Monica Ong on 2/13/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import SwiftyJSON
import TRON

protocol TravelDistanceDelegate: NSObjectProtocol {
    func travelDistanceUpdated(withDistance distance: Double)
}

class RouteTableViewCell: UITableViewCell {

    // MARK: Data vars

    static let identifier: String = "routeCell"
    private let fileName: String = "RouteTableViewCell"
    var route: Route?

    // MARK: Log vars

    var rowNum: Int?

    // MARK: View vars

    var timesStackView: UIStackView
    var travelTimeLabel: UILabel

    var departureStackView: UIStackView
    var departureTimeLabel: UILabel
    var arrowImageView: UIImageView

    var liveStackView: UIStackView
    var liveLabel: UILabel
    var liveIndicatorView: LiveIndicator
    var stretchyFillerView: UIView

    var verticalStackView: UIStackView
    var topBorder: UIView
    var routeDiagram: RouteDiagram
    var funMessage: UILabel
    var bottomBorder: UIView
    var cellSeparator: UIView

    // MARK: Spacing vars

    let leftMargin: CGFloat =  16
    let topMargin: CGFloat = 16
    let bottomMargin: CGFloat = 16
    let rightMargin: CGFloat = 12

    let cellBorderHeight: CGFloat = 0.75
    let cellSeparatorHeight: CGFloat = 6.0

    let spaceBtnDepartureElements: CGFloat = 4
    let arrowImageViewHeight: CGFloat = 11.5
    let arrowImageViewWidth: CGFloat = 6

    let spaceBtnLiveElements: CGFloat = 4

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        departureTimeLabel = UILabel()
        arrowImageView = UIImageView(image: #imageLiteral(resourceName: "side-arrow"))
        departureStackView = UIStackView(arrangedSubviews: [departureTimeLabel, arrowImageView])

        travelTimeLabel = UILabel()
        timesStackView = UIStackView(arrangedSubviews: [travelTimeLabel, departureStackView])

        liveLabel = UILabel()
        liveIndicatorView = LiveIndicator(size: .small, color: .clear)
        stretchyFillerView = UIView()
        liveStackView = UIStackView(arrangedSubviews: [liveLabel, liveIndicatorView, stretchyFillerView])

        topBorder = UIView()
        routeDiagram = RouteDiagram()
        funMessage = UILabel()
        bottomBorder = UIView()
        cellSeparator = UIView()
        verticalStackView = UIStackView(arrangedSubviews: [timesStackView, liveStackView, routeDiagram])

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        styleTopBorder()
        styleVerticalStackView()
        styleBottomBorder()
        styleCellSeparator()

        contentView.addSubview(topBorder)
        contentView.addSubview(verticalStackView)
        contentView.addSubview(bottomBorder)
        contentView.addSubview(cellSeparator)

        activateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Style

    private func styleVerticalStackView() {
        verticalStackView.axis = .vertical
        verticalStackView.layoutMargins = UIEdgeInsets.init(top: topMargin, left: leftMargin, bottom: bottomMargin, right: rightMargin)
        verticalStackView.isLayoutMarginsRelativeArrangement = true

        styleTimesStackView()
        styleLiveStackView()
        // styleFunMessage()
    }

    private func styleTimesStackView() {
        timesStackView.axis = .horizontal
        timesStackView.alignment = .center

        travelTimeLabel.font = .getFont(.semibold, size: 16)
        travelTimeLabel.textColor = Colors.primaryText

        styleDepartureStackView()
    }

    private func styleDepartureStackView() {
        departureStackView.axis = .horizontal
        departureStackView.spacing = spaceBtnDepartureElements

        departureTimeLabel.font = .getFont(.semibold, size: 14)
        departureTimeLabel.textColor = Colors.primaryText
        arrowImageView.tintColor = Colors.metadataIcon
    }

    private func styleLiveStackView() {
        //  make stretchyFillerView’s horizontal content-hugging priority is lower than the label’s so it stretches to fill extra space
        stretchyFillerView.setContentHuggingPriority(liveLabel.contentHuggingPriority(for: .horizontal) - 1, for: .horizontal)

        liveStackView.axis = .horizontal
        liveStackView.alignment = .lastBaseline
        liveStackView.spacing = spaceBtnLiveElements

        liveLabel.font = .getFont(.semibold, size: 14)
    }

    private func styleFunMessage() {
        funMessage.font = .getFont(.semibold, size: 12)
        funMessage.textColor = .lightGray
    }

    private func styleTopBorder() {
        topBorder.backgroundColor = Colors.dividerTextField
    }

    private func styleBottomBorder() {
        bottomBorder.backgroundColor = Colors.dividerTextField
    }

    private func styleCellSeparator() {
        cellSeparator.backgroundColor = Colors.backgroundWash
    }

    // MARK: Add subviews

    func addRouteDiagramSubviews() {
        routeDiagram.addSubviews()
    }

    // MARK: Activate constraints

    func activateRouteDiagramConstraints() {
        routeDiagram.activateConstraints()
    }

    private func activateConstraints() {
        setTranslatesAutoresizingMaskIntoConstraints()
        setDebugIdentifiers()

        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: contentView.topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: cellBorderHeight),
            topBorder.bottomAnchor.constraint(equalTo: verticalStackView.topAnchor)
        ])

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor)
        ])

        NSLayoutConstraint.activate([
            bottomBorder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: cellBorderHeight),
            bottomBorder.bottomAnchor.constraint(equalTo: cellSeparator.topAnchor)
        ])

        NSLayoutConstraint.activate([
            cellSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cellSeparator.heightAnchor.constraint(equalToConstant: cellSeparatorHeight),
            cellSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            arrowImageView.heightAnchor.constraint(equalToConstant: arrowImageViewHeight),
            arrowImageView.widthAnchor.constraint(equalToConstant: arrowImageViewWidth),
            arrowImageView.centerYAnchor.constraint(equalTo: departureTimeLabel.centerYAnchor)
        ])
    }

    private func setTranslatesAutoresizingMaskIntoConstraints() {
        let subviews = [timesStackView, travelTimeLabel,
                        departureStackView, departureTimeLabel, arrowImageView,
                        liveStackView, liveLabel, liveIndicatorView, stretchyFillerView,
                        verticalStackView, topBorder, routeDiagram, funMessage, bottomBorder, cellSeparator]

        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    }

    /// For debugging constraint errors
    private func setDebugIdentifiers() {
        timesStackView.accessibilityIdentifier = "timesStackView"
        travelTimeLabel.accessibilityIdentifier = "travelTimeLabel"

        departureStackView.accessibilityIdentifier = "departureStackView"
        departureTimeLabel.accessibilityIdentifier = "departureTimeLabel"
        arrowImageView.accessibilityIdentifier = "arrowImageView"

        liveStackView.accessibilityIdentifier = "liveStackView"
        liveLabel.accessibilityIdentifier = "liveLabel"
        liveIndicatorView.accessibilityIdentifier = "liveIndicatorView"
        stretchyFillerView.accessibilityIdentifier = "stretchyFillerView"

        verticalStackView.accessibilityIdentifier = "verticalStackView"
        topBorder.accessibilityIdentifier = "topBorder"
        routeDiagram.accessibilityIdentifier = "routeDiagram"
        bottomBorder.accessibilityIdentifier = "bottomBorder"
        cellSeparator.accessibilityIdentifier = "cellSeparator"
    }

    // MARK: Get Data

    private func getDepartureAndArrivalTimes(fromRoute route: Route) -> (departureTime: Date, arrivalTime: Date) {
        if let firstDepartDirection = route.getFirstDepartRawDirection(), let lastDepartDirection = route.getLastDepartRawDirection() {
            return (departureTime: firstDepartDirection.startTime, arrivalTime: lastDepartDirection.endTime)
        }

        return (departureTime: route.departureTime, arrivalTime: route.arrivalTime)
    }

    private func getDelayState(fromRoute route: Route) -> DelayState {
        if let firstDepartDirection = route.getFirstDepartRawDirection() {

            let departTime = firstDepartDirection.startTime

            if let delay = firstDepartDirection.delay {

                let delayedDepartTime = departTime.addingTimeInterval(TimeInterval(delay))
                // Our live tracking only updates once every 30 seconds, so we want to show buses that are delayed by < 120 as on time in order to be more accurate about the status of slightly delayed buses. This way riders get to a bus stop earlier rather than later when trying to catch such buses.
                if Time.compare(date1: departTime, date2: delayedDepartTime) == .orderedAscending { // bus is delayed
                    if (delayedDepartTime >= Date() || delay >= 120) {
                        return .late(date: delayedDepartTime)
                    } else { // delay < 120
                        return .onTime(date: departTime)
                    }
                } else { // bus is not delayed
                    return .onTime(date: departTime)
                }

            } else {

                return .noDelay(date: departTime)

            }

        }

        return .noDelay(date: route.departureTime)

    }

    // MARK: Reuse

    override func prepareForReuse() {
        routeDiagram.prepareForReuse()

        hideLiveElements(animate: false)
    }

    // MARK: Set Data

    func setData(route: Route, rowNum: Int) {
        self.route = route
        self.rowNum = rowNum

        let (departureTime, arrivalTime) = getDepartureAndArrivalTimes(fromRoute: route)
        setTravelTime(withDepartureTime: departureTime, withArrivalTime: arrivalTime)

        setDepartureTimeAndLiveElements(withRoute: route)

        routeDiagram.setData(withDirections: route.rawDirections, withTravelDistance: route.travelDistance, withWalkingRoute: route.isRawWalkingRoute())

        // setFunMessage()
    }

    private func setDepartureTimeAndLiveElements(withRoute route: Route) {
        let isWalkingRoute = route.isRawWalkingRoute()

        if isWalkingRoute {
            setDepartureTimeToWalking()
            return
        }

        let delayState = getDelayState(fromRoute: route)
        setDepartureTime(withStartTime: Date(), withDelayState: delayState)
        setLiveElements(withDelayState: delayState)
    }

    private func setFunMessage() {
        funMessage.text = "Howdy! Here's a fun message! :)"
    }

    @objc func updateLiveElementsWithDelay() {
        if let route = route,
            let direction = route.getFirstDepartRawDirection(),
            let tripId = direction.tripIdentifiers?.first,
            let stopId = direction.stops.first?.id {

            Network.getDelay(tripId: tripId, stopId: stopId).performCollectingTimeline { (response) in
                switch response.result {
                case .success(let delayResponse):
                    guard (delayResponse.data != nil), let delay = delayResponse.data else {
                        self.setDepartureTimeAndLiveElements(withRoute: route)
                        return
                    }

                    let isNewDelayValue = (route.getFirstDepartRawDirection()?.delay != delay)
                    if isNewDelayValue {
                        JSONFileManager.shared.logDelayParemeters(timestamp: Date(), stopId: stopId, tripId: tripId)
                        JSONFileManager.shared.logURL(timestamp: Date(), urlName: "Delay requestUrl", url: Network.getDelayUrl(tripId: tripId, stopId: stopId))
                        if let data = response.data {
                            do { try JSONFileManager.shared.saveJSON(JSON.init(data: data), type: .delayJSON(rowNum: self.rowNum ?? -1)) } catch let error {
                                let fileName = "RouteTableViewCell"
                                let line = "\(fileName) \(#function): \(error.localizedDescription)"
                                print(line)
                            }
                        }
                    }

                    let departTime = direction.startTime
                    let delayedDepartTime = departTime.addingTimeInterval(TimeInterval(delay))

                    let isLateDelay = (Time.compare(date1: delayedDepartTime, date2: departTime) == .orderedDescending)
                    if isLateDelay {
                        let delayState = DelayState.late(date: delayedDepartTime)
                        self.setDepartureTime(withStartTime: Date(), withDelayState: delayState)
                        self.setLiveElements(withDelayState: delayState)
                    } else {
                        let delayState = DelayState.onTime(date: departTime)
                        self.setDepartureTime(withStartTime: Date(), withDelayState: delayState)
                        self.setLiveElements(withDelayState: delayState)
                    }

                    route.getFirstDepartRawDirection()?.delay = delay

                case .failure(let networkError):
                    if let error = networkError as? APIError<Error> {
                        print("\(self.fileName) \(#function) error: \(error.errorDescription ?? "") Request url: \(error.request?.url?.absoluteString ?? "")")
                        self.setDepartureTimeAndLiveElements(withRoute: route)
                    }
                }
            }
        } else {
            if let route = route {
                self.setDepartureTimeAndLiveElements(withRoute: route)
            }
        }
    }

    private func setLiveElements(withDelayState delayState: DelayState) {

        switch delayState {

        case .late(date: let delayedDepartureTime):
            liveLabel.textColor = Colors.lateRed
            liveLabel.text = "Late - \(Time.timeString(from: delayedDepartureTime))"
            liveIndicatorView.setColor(to: Colors.lateRed)
            if liveStackView.isHidden {
                showLiveElements()
            }

        case .onTime(date: _):
            liveLabel.textColor = Colors.liveGreen
            liveLabel.text = "On Time"
            liveIndicatorView.setColor(to: Colors.liveGreen)
            if liveStackView.isHidden {
                showLiveElements()
            }

        case .noDelay(date: _):
            if !liveStackView.isHidden {
                hideLiveElements(animate: true)
            }

        }

    }

    private func showLiveElements() {
        UIView.animate(withDuration: 0.3) {
            self.liveStackView.isHidden = false
        }
    }

    private func hideLiveElements(animate: Bool) {
        if animate {
            UIView.animate(withDuration: 0.3) {
                self.liveStackView.isHidden = true
            }
        } else {
            self.liveStackView.isHidden = true
        }
    }

    private func setDepartureTime(withStartTime startTime: Date, withDelayState delayState: DelayState) {

        switch delayState {

        case .late(date: let departureTime):
            let boardTime = Time.timeString(from: startTime, to: departureTime)
            departureTimeLabel.text = boardTime == "0 min" ? "Board now" : "Board in \(boardTime)"

            departureTimeLabel.textColor = Colors.lateRed

        case .onTime(date: let departureTime):
            let boardTime = Time.timeString(from: startTime, to: departureTime)
            departureTimeLabel.text = boardTime == "0 min" ? "Board now" : "Board in \(boardTime)"

            departureTimeLabel.textColor = Colors.liveGreen

        case .noDelay(date: let departureTime):
            let boardTime = Time.timeString(from: startTime, to: departureTime)
            departureTimeLabel.text = boardTime == "0 min" ? "Board now" : "Board in \(boardTime)"

            departureTimeLabel.textColor = Colors.primaryText

        }

        arrowImageView.tintColor = Colors.primaryText
    }

    private func setTravelTime(withDepartureTime departureTime: Date, withArrivalTime arrivalTime: Date) {
        travelTimeLabel.text = "\(Time.timeString(from: departureTime)) - \(Time.timeString(from: arrivalTime))"
    }

    private func setDepartureTimeToWalking() {
        departureTimeLabel.text = "Directions"
        departureTimeLabel.textColor = Colors.metadataIcon
        arrowImageView.tintColor = Colors.metadataIcon
    }

}
