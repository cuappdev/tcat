//
//  ServiceAlertTableViewCell.swift
//  TCAT
//
//  Created by Omar Rasheed on 12/7/18.
//  Copyright © 2018 cuappdev. All rights reserved.
//

import UIKit
import SnapKit

class ServiceAlertTableViewCell: UITableViewCell {

    static let identifier: String = "serviceAlertCell"
    private let fileName: String = "serviceAlertTableViewCell"
    var alert: ServiceAlert?
    var rowNum: Int!

    let borderInset = 16
    let busIconSpacing = 10
    var maxIconsPerRow: Int {
        let iconWidth = Int(BusIconType.directionSmall.width)
        let screenWidth = Int(UIScreen.main.bounds.width)
        let totalConstraintInset = borderInset * 2

        return (screenWidth - totalConstraintInset + busIconSpacing) / (iconWidth + busIconSpacing)
    }

    var timeSpanLabel: UILabel!
    var descriptionLabel: UILabel!
    var affectedRoutesLabel: UILabel!
    var affectedRoutesStackView: UIStackView?
    var topSeparator: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupTimeSpanLabel()
        setupDescriptionLabel()
    }

    func setData() {
        if let fromDate = alert?.fromDate, let toDate = alert?.toDate {
            timeSpanLabel.text = formatTimeString(fromDate, toDate: toDate)
        }

        descriptionLabel.text = alert?.message
        if let routes = alert?.routes, !routes.isEmpty {
            setupAffectedRoutesStackView()
            setupaffectedRoutesLabel()
        }

        if rowNum > 0 {
            setupTopSeparator()
        }
    }

    private func setupTimeSpanLabel() {

        timeSpanLabel = UILabel()
        timeSpanLabel.numberOfLines = 0
        timeSpanLabel.font = .getFont(.semibold, size: 18)
        timeSpanLabel.textColor = Colors.primaryText

        contentView.addSubview(timeSpanLabel)
    }

    private func setupDescriptionLabel() {

        descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .getFont(.regular, size: 14)
        descriptionLabel.textColor = Colors.primaryText

        contentView.addSubview(descriptionLabel)
    }

    private func setupaffectedRoutesLabel() {

        affectedRoutesLabel = UILabel()
        affectedRoutesLabel.font = .getFont(.semibold, size: 18)
        affectedRoutesLabel.textColor = Colors.primaryText
        affectedRoutesLabel.text = Constants.General.affectedRoutes

        contentView.addSubview(affectedRoutesLabel)
    }

    private func setupAffectedRoutesStackView() {

        if var routes = alert?.routes, !routes.isEmpty {
            affectedRoutesStackView = UIStackView()
            for _ in 0..<rowCount() {
                var subviews = [BusIcon]()
                for _ in 0..<maxIconsPerRow where !routes.isEmpty {
                    let route = routes.removeFirst()
                    subviews.append(BusIcon(type: .directionSmall, number: route))
                }
                let rowStackView = UIStackView(arrangedSubviews: subviews)
                rowStackView.axis = .horizontal
                rowStackView.spacing = 10
                rowStackView.alignment = .leading
                affectedRoutesStackView?.addArrangedSubview(rowStackView)
            }
        }

        guard let stackView = affectedRoutesStackView else { return }
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.spacing = 10
        contentView.addSubview(stackView)
    }

    private func setupTopSeparator() {

        topSeparator = UIView()
        topSeparator?.backgroundColor = Colors.backgroundWash

        contentView.addSubview(topSeparator!)
    }

    func descriptionLabelConstraints(topConstraint: UIView) {
        descriptionLabel.snp.remakeConstraints { (make) in
            if topConstraint == contentView {
                make.top.equalToSuperview().inset(borderInset)
            } else {
                make.top.equalTo(topConstraint.snp.bottom).offset(12)
            }
            make.leading.trailing.equalToSuperview().inset(borderInset)
            if let text = descriptionLabel.text {
                let width = contentView.frame.width - (CGFloat)(2 * borderInset)
                let heightValue = ceil(text.heightWithConstrainedWidth(width: width, font: descriptionLabel.font))
                make.height.equalTo(ceil(heightValue))
            } else {
                make.height.equalTo(descriptionLabel.intrinsicContentSize.height)
            }
        }
    }

    func timeSpanLabelConstraints(topConstraint: UIView) {
        timeSpanLabel.snp.remakeConstraints { (make) in
            if topConstraint == contentView {
                make.top.equalToSuperview().inset(borderInset)
            } else {
                make.top.equalTo(topConstraint.snp.bottom).offset(12)
            }
            make.leading.trailing.equalToSuperview().inset(borderInset)
            make.height.equalTo(timeSpanLabel.intrinsicContentSize.height)
        }
    }

    func topSeparatorConstraints() {
        if let topSeparator = topSeparator {
            topSeparator.snp.remakeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(8)
            }
        }
    }

    override func updateConstraints() {
        if let topSeparator = topSeparator, timeSpanLabel.isDescendant(of: contentView) {
            // Both topSeparator and timeSpanLabel exist
            topSeparatorConstraints()
            timeSpanLabelConstraints(topConstraint: topSeparator)
            descriptionLabelConstraints(topConstraint: timeSpanLabel)
        } else if timeSpanLabel.isDescendant(of: contentView) {
            // Only timeSpanLabel, no topSeparator
            timeSpanLabelConstraints(topConstraint: contentView)
            descriptionLabelConstraints(topConstraint: timeSpanLabel)
        } else if let topSeparator = topSeparator {
            // Only topSeparator, no timeSpanLabel
            topSeparatorConstraints()
            descriptionLabelConstraints(topConstraint: topSeparator)
        } else {
            // Neither
            descriptionLabelConstraints(topConstraint: contentView)
        }

        if let stackView = affectedRoutesStackView {
            // When both a separator view and stackView are required
            affectedRoutesLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(descriptionLabel)
                make.top.equalTo(descriptionLabel.snp.bottom).offset(24)
                make.width.equalTo(affectedRoutesLabel.intrinsicContentSize.width)
                make.height.equalTo(affectedRoutesLabel.intrinsicContentSize.height)
            }
            stackView.snp.remakeConstraints { (make) in
                make.top.equalTo(affectedRoutesLabel.snp.bottom).offset(8)
                make.leading.equalTo(descriptionLabel)
                make.trailing.bottom.equalToSuperview().inset(borderInset)
            }
        } else {
            descriptionLabel.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview().inset(borderInset)
            }
        }
        super.updateConstraints()
    }

    private func formatTimeString(_ fromDate: String, toDate: String) -> String {

        let newformatter = DateFormatter()
        newformatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sZZZZ"
        newformatter.locale = Locale(identifier: "en_US_POSIX")

        let fromDate = newformatter.date(from: fromDate)
        let toDate = newformatter.date(from: toDate)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE M/d"

        if let unWrappedFromDate = fromDate, let unWrappedToDate = toDate {
            let formattedFromDate = formatter.string(from: unWrappedFromDate)
            let formattedToDate = formatter.string(from: unWrappedToDate)

            return "\(formattedFromDate) - \(formattedToDate)"
        }

        timeSpanLabel.removeFromSuperview()
        return "Time: Unknown"
    }

    private func rowCount() -> Int {
        guard let routes = alert?.routes else { return 0 }
        if routes.count > maxIconsPerRow {
            let addExtra = routes.count % maxIconsPerRow > 0 ? 1 : 0
            let rowCount = routes.count / maxIconsPerRow

            return rowCount + addExtra
        } else {
            return 1
        }
    }

    private func getDayOfWeek(_ today: Date) -> Int? {
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: today)
        return weekDay
    }

    override func prepareForReuse() {
        if let stackView = affectedRoutesStackView {
            stackView.removeFromSuperview()
        }

        affectedRoutesStackView = nil

        if let routesLabel = affectedRoutesLabel {
            routesLabel.removeFromSuperview()
        }

        affectedRoutesLabel = nil
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
