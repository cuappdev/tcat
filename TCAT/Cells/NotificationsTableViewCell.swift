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
    var showLiveElements: Bool = true
    var departureStop: String = ""

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
            make.leading.equalToSuperview().inset(inset)
            make.trailing.lessThanOrEqualToSuperview().inset(inset)
            // make.height.equalTo(16.0)
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
        activeSwitch.transform = CGAffineTransform(scaleX: 0.675, y: 0.675)
        contentView.addSubview(activeSwitch)
        activeSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-4)
        }

        contentView.addSubview(departureLabel)
        departureLabel.snp.makeConstraints { make in
            make.leading.equalTo(busIcon.snp.trailing).offset(inset)
            make.trailing.equalTo(activeSwitch.snp.leading).offset(-2)
            make.top.equalTo(busIcon)
        }

        contentView.addSubview(liveLabel)
        contentView.addSubview(liveIndicator)
        if showLiveElements {
            liveLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(inset)
                make.leading.equalTo(departureLabel)
            }

            liveIndicator.snp.makeConstraints { make in
                let offset: CGFloat = 6.0

                make.centerY.equalTo(liveLabel.snp.centerY)
                make.leading.equalTo(liveLabel.snp.trailing).offset(offset)
                make.height.equalTo(liveIndicator.intrinsicContentSize.height)
            }
        }
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
        departureLabel.font = UIFont.getFont(.regular, size: 14.0)
        departureLabel.textColor = Colors.black
        departureLabel.numberOfLines = 2
        departureLabel.lineBreakMode = .byWordWrapping

        let normalText = "Depart from "
        let normalAttrs = [NSAttributedString.Key.font: UIFont.getFont(.regular, size: 14.0)]
        let string = NSMutableAttributedString(string: normalText, attributes: normalAttrs)

        // let boldText = departureStop
        let boldText  = "Schwartz Performing Arts Center"
        let boldAttrs = [NSAttributedString.Key.font: UIFont.getFont(.semibold, size: 14.0)]
        let boldString = NSMutableAttributedString(string: boldText, attributes: boldAttrs)

        string.append(boldString)

        departureLabel.attributedText = string
    }

    func setUpLiveElements() {
        liveLabel.font = .getFont(.medium, size: 14.0)
        liveLabel.textColor = Colors.liveGreen
        liveLabel.text = "Board in 5 min"

        liveIndicator.setColor(to: Colors.liveGreen)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
