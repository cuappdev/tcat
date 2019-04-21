//
//  NotificationsTableViewCell.swift
//  TCAT
//
//  Created by Yana Sang on 4/18/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit
import SnapKit

class NotificationsTableViewCell: UITableViewCell {

    // MARK: Data vars
    var route: Route!
    var busDirection: Direction?

    // MARK: View vars
    var timeLabel = UILabel()
    var busIcon = BusIcon(type: .directionSmall, number: 90)
    var departureLabel = UILabel()
    var activeSwitch = UISwitch()
    var liveLabel = UILabel()
    var liveIndicator = LiveIndicator(size: .small, color: .clear)

    // MARK: Spacing vars
    var inset: CGFloat = 12.0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = Colors.white

        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            let bottom: CGFloat = 76.0

            make.leading.equalToSuperview().inset(inset)
            make.trailing.lessThanOrEqualToSuperview().inset(inset)
            make.height.equalTo(16.0)
            make.top.equalToSuperview().inset(inset)
        }

        contentView.addSubview(busIcon)
        busIcon.snp.makeConstraints { make in
            let top: CGFloat = 11.0
            let bottom: CGFloat = 48.05

            make.leading.equalToSuperview().inset(inset)
            make.top.equalTo(timeLabel.snp.bottom).offset(top)
            make.bottom.equalToSuperview().inset(bottom)
            make.width.equalTo(busIcon.intrinsicContentSize.width)
        }

        activeSwitch.onTintColor = Colors.tcatBlue
        activeSwitch.transform = CGAffineTransform(scaleX: 0.673, y: 0.645)
        contentView.addSubview(activeSwitch)
        activeSwitch.snp.makeConstraints { make in
            let top: CGFloat = 43.0
            let bottom: CGFloat = 43.94
            let leading: CGFloat = 246.0

            make.leading.equalTo(busIcon.snp.trailing).offset(leading)
            make.top.equalToSuperview().inset(top)
            make.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().inset(bottom)
        }

        contentView.addSubview(departureLabel)
        departureLabel.snp.makeConstraints { make in
            let top: CGFloat = 41.0
            let bottom: CGFloat = 34.0

            make.leading.equalTo(busIcon.snp.trailing).offset(inset)
            make.trailing.equalTo(activeSwitch.snp.leading).inset(inset)
            make.top.equalToSuperview().inset(top)
            make.bottom.equalToSuperview().inset(bottom)
        }

//        contentView.addSubview(liveLabel)  -- need ifShowLiveElements
    }

    func configure(route: Route) {
        self.route = route
        if let departDirection = (route.directions.filter { $0.type == .depart }).first {
            busDirection = departDirection
            busIcon = BusIcon(type: .directionSmall, number: departDirection.routeNumber)
        }
    }

    // MARK: Get data
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

    // MARK: Set Up Cell
    func setUpTimeLabel() {
        timeLabel.font = UIFont.getFont(.medium, size: 16.0)
        timeLabel.textColor = Colors.black

//        let (departTime, arriveTime) = getDepartureAndArrivalTimes(fromRoute: route)
//        timeLabel.text = "\(Time.timeString(from: departTime)) - \(Time.timeString(from: arriveTime))"
        timeLabel.text = "1:55 - 2:07 PM"
    }

    func setUpDepartureLabel() {
        departureLabel.font = UIFont.getFont(.regular, size: 16.0)
        departureLabel.textColor = Colors.black
        departureLabel.numberOfLines = 2
        departureLabel.lineBreakMode = .byWordWrapping

        // departureLabel.text = "Depart from \(busDirection?.name ?? "no bus to destination")"
        departureLabel.text = "Depart from Schwartz Performing Arts Center"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
