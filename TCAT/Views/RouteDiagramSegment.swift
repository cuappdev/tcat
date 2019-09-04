//
//  RouteDiagramSegment.swift
//  TCAT
//
//  Created by Omar Rasheed on 5/23/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit

class RouteDiagramSegment: UIView {

    private var stopDot: Circle!
    private var stopLabel: UILabel!
    private var icon: UIView?
    private var routeLine: RouteLine?
    private var stayOnBusCoverUpView: UIView?

    private let busIconType: BusIconType = .directionSmall
    private let busIconCornerRadius: CGFloat = BusIconType.directionSmall.cornerRadius

    init(for direction: Direction, prev: RouteDiagramSegment?, isWalkingRoute: Bool, index: Int, isDestination: Bool, travelDistance: Double) {
        super.init(frame: .zero)
        // if route is not walking route and if on first stop in route, will have travel distance in stop label
        stopLabel = getStopLabel(withName: direction.name, withStayOnBusForTranfer: direction.stayOnBusForTransfer, withDistance: !isWalkingRoute && index == 0 ? travelDistance : nil)
        stopDot = getStopDot(fromDirection: direction, withWalkingRoute: isWalkingRoute, isDestination: isDestination)
        if !isDestination {
            icon = getIcon(fromDirection: direction, withDistance: isWalkingRoute && index == 0 ? travelDistance : nil)
            routeLine = getRouteLine(fromDirection: direction, withWalkingRoute: isWalkingRoute)

            addSubview(icon!)
            addSubview(routeLine!)
        }

        addSubview(stopLabel)
        addSubview(stopDot)
    }

    func setupConstraints(prev: RouteDiagramSegment?, isLastDirection: Bool) {
        let circleCenterXLeadingInset: CGFloat = 69.5
        var spaceBtnIconAndRouteLine: CGFloat {
            let spaceBtnBusIconAndRouteLine: CGFloat = 19.5
            let spaceBtnWalkIconAndRouteLine: CGFloat = 38
            let spaceBtnWalkWithDistanceIconAndRouteLine: CGFloat = 24

            return self.icon is UIImageView ? spaceBtnWalkIconAndRouteLine : (self.icon is WalkWithDistanceIcon ? spaceBtnWalkWithDistanceIconAndRouteLine : spaceBtnBusIconAndRouteLine)
        }
        var spaceBtnIconAndSuperview: CGFloat {
            let spaceBtnWalkIconAndSuperview: CGFloat = 20

            return self.icon is UIImageView ? spaceBtnWalkIconAndSuperview : (self.icon is BusIcon ? 0 : 8.5)
        }
        let spaceBtnStopDotCenterXAndStopLabel: CGFloat = 26

        if let icon = icon, let routeLine = routeLine {
            icon.snp.makeConstraints { make in
                if let prev = prev, let prevIcon = prev.icon {
                    make.centerX.equalTo(prevIcon)
                } else {
                    make.leading.equalToSuperview().inset(spaceBtnIconAndSuperview)
                }
                make.centerY.equalTo(routeLine)
            }

            routeLine.snp.makeConstraints { make in
                make.centerX.equalTo(stopDot)
                make.top.equalTo(stopDot.snp.bottom).offset(-1)
                make.width.equalTo(routeLine.intrinsicContentSize.width)
                make.height.equalTo(routeLine.intrinsicContentSize.height + 2)
            }
        } else {
            stopLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }

        stopDot.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalTo(snp.leading).offset(circleCenterXLeadingInset)
            make.size.equalTo(stopDot.intrinsicContentSize)
        }

        stopLabel.snp.makeConstraints { make in
            make.leading.equalTo(stopDot.snp.centerX).offset(spaceBtnStopDotCenterXAndStopLabel)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(stopDot)
        }
    }

    // MARK: Get data from route ojbect

    private func getStopLabel(withName name: String, withStayOnBusForTranfer stayOnBusForTranfer: Bool, withDistance distance: Double?) -> UILabel {
        let yPos: CGFloat = 101
        let rightSpaceFromSuperview: CGFloat = 16
        let width: CGFloat = UIScreen.main.bounds.width - yPos - rightSpaceFromSuperview

        let stopLabel = UILabel()
        // allow for multi-line label for long stop names
        stopLabel.allowsDefaultTighteningForTruncation = true
        stopLabel.lineBreakMode = .byWordWrapping
        stopLabel.numberOfLines = 0

        let stopNameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.getFont(.regular, size: 14.0),
            .foregroundColor: Colors.primaryText
        ]
        let stopName = NSMutableAttributedString(string: name, attributes: stopNameAttrs)

        if let distance = distance {

            let testStopLabel = getTestStopLabel(withName: name)
            let testDistanceLabel = getTestDistanceLabel(withDistance: distance)

            var addLinebreak = false
            if testStopLabel.frame.width + testDistanceLabel.frame.width > width {
                addLinebreak = true
            }

            let travelDistanceAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.getFont(.regular, size: 12.0),
                .foregroundColor: Colors.metadataIcon
            ]

            let travelDistance = NSMutableAttributedString(string: addLinebreak ? "\n\(distance.roundedString) away" : " \(distance.roundedString) away", attributes: travelDistanceAttrs)
            stopName.append(travelDistance)
        }

        if stayOnBusForTranfer {
            let stayOnBusAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.getFont(.regular, size: 12.0),
                .foregroundColor: Colors.metadataIcon
            ]
            let stayOnBus = NSMutableAttributedString(string: "\nStay on board", attributes: stayOnBusAttrs)
            stopName.append(stayOnBus)
        }

        stopLabel.attributedText = stopName

        return stopLabel
    }

    private func getTestStopLabel(withName name: String) -> UILabel {
        let testStopLabel = UILabel()
        testStopLabel.font = .getFont(.regular, size: 14.0)
        testStopLabel.textColor = Colors.primaryText
        testStopLabel.text = name
        testStopLabel.sizeToFit()

        return testStopLabel
    }

    private func getTestDistanceLabel(withDistance distance: Double) -> UILabel {
        let testDistanceLabel = UILabel()
        testDistanceLabel.font = .getFont(.regular, size: 12.0)
        testDistanceLabel.textColor = Colors.metadataIcon
        testDistanceLabel.text = " \(distance.roundedString) away"
        testDistanceLabel.sizeToFit()

        return testDistanceLabel
    }

    private func isStopLabelOneLine(_ stopLabel: UILabel) -> Bool {
        let oneLineStopLabel = getStopLabel(withName: "Testing", withStayOnBusForTranfer: false, withDistance: 0.0)

        return stopLabel.intrinsicContentSize.height <= oneLineStopLabel.intrinsicContentSize.height
    }

    private func getStopDot(fromDirection direction: Direction, withWalkingRoute isWalkingRoute: Bool, isDestination: Bool) -> Circle {
        var pin: Circle

        if direction.type == .walk {
            if isDestination {
                let framedGreyCircle = Circle(size: .medium, style: .bordered, color: Colors.metadataIcon)
                framedGreyCircle.backgroundColor = Colors.white
                pin = framedGreyCircle
            } else {
                let solidGreyCircle = Circle(size: .small, style: .solid, color: Colors.metadataIcon)
                pin = solidGreyCircle
            }
        } else {
            if isDestination {
                if isWalkingRoute {
                    // walking route destination should always be grey no matter what direction type
                    let framedGreyCircle = Circle(size: .medium, style: .bordered, color: Colors.metadataIcon)
                    framedGreyCircle.backgroundColor = Colors.white
                    pin = framedGreyCircle
                } else {
                    let framedBlueCircle = Circle(size: .medium, style: .bordered, color: Colors.tcatBlue)
                    framedBlueCircle.backgroundColor = Colors.white
                    pin = framedBlueCircle
                }
            } else {
                let solidBlueCircle = Circle(size: .small, style: .solid, color: Colors.tcatBlue)
                pin = solidBlueCircle
            }
        }

        return pin
    }

    private func getIcon(fromDirection direction: Direction, withDistance distance: Double?) -> UIView {
        if let distance = distance {
            return WalkWithDistanceIcon(withDistance: distance)
        }

        switch direction.type {

        case .depart:
            let busNum = direction.routeNumber
            let busIcon = BusIcon(type: busIconType, number: busNum)
            return busIcon

        default:
            let walkIcon = UIImageView(image: #imageLiteral(resourceName: "walk"))
            walkIcon.contentMode = .scaleAspectFit
            walkIcon.tintColor = Colors.metadataIcon
            return walkIcon
        }
    }

    private func getRouteLine(fromDirection direction: Direction, withWalkingRoute isWalkingRoute: Bool) -> RouteLine {

        let isStopLabelSingleLine = isStopLabelOneLine(stopLabel)

        if isWalkingRoute {
            let greyRouteLine = isStopLabelSingleLine ? SolidLine(color: Colors.metadataIcon) : SolidLine(overrideHeight: RouteLine.extendedHeight, color: Colors.metadataIcon)

            return greyRouteLine
        }

        switch direction.type {
        case .depart:
            let solidBlueRouteLine = isStopLabelSingleLine ? SolidLine(color: Colors.tcatBlue) : SolidLine(overrideHeight: RouteLine.extendedHeight, color: Colors.tcatBlue)

            return solidBlueRouteLine

        default:
            let dashedGreyRouteLine = isStopLabelSingleLine ? DottedLine(color: Colors.metadataIcon) : DottedLine(overrideHeight: RouteLine.extendedHeight, color: Colors.metadataIcon)

            return dashedGreyRouteLine
        }
    }

    func calculateHeight() -> CGFloat {
        if let routeLine = routeLine {
            return routeLine.intrinsicContentSize.height + stopDot.intrinsicContentSize.height
        } else {
            return stopLabel.intrinsicContentSize.height
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
