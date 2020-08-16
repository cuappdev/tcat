//
//  RouteDetailTableView.swift
//  TCAT
//
//  Created by Matthew Barker on 2/12/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit

class SmallDetailTableViewCell: UITableViewCell {

    private var iconView: DetailIconView!
    private let titleLabel = UILabel()
    private let hairline = UIView()

    private var iconViewFrame: CGRect = CGRect()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        titleLabel.font = .getFont(.regular, size: 14)
        titleLabel.textColor = Colors.primaryText
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)

        setupConstraints()
    }

    func configure(for direction: Direction, isFirstStep: Bool, isLastStep: Bool) {
        iconView = DetailIconView(for: direction, isFirstStep: isFirstStep, isLastStep: isLastStep)
        contentView.addSubview(iconView)

        hairline.backgroundColor = Colors.tableViewSeparator
        contentView.addSubview(hairline)

        // Hide hairline for last SmallDetailTVC so it's not next to NotificationToggleTVC hairline
        if isLastStep {
            hairline.isHidden = true
        }

        formatTitleLabel(for: direction)

        setupConfigDependentConstraints()
    }

    private func formatTitleLabel(for direction: Direction) {
        let titleLabelBoldFont: UIFont = .getFont(.semibold, size: 14)

        if direction.type == .arrive {
            // Arrive Direction
            titleLabel.attributedText = direction.name.bold(in: direction.locationNameDescription,
                                                            from: titleLabel.font,
                                                            to: titleLabelBoldFont)
        } else {
            // Walk Direction
            var walkString = direction.locationNameDescription
            if direction.travelDistance > 0 {
                walkString += " (\(direction.travelDistance.roundedString))"
            }
            titleLabel.attributedText = direction.name.bold(in: walkString,
                                                            from: titleLabel.font,
                                                            to: titleLabelBoldFont)
        }
    }

    private func setupConfigDependentConstraints() {
        let detailIconViewWidth = 114
        let titleLabelLeadingOffset = 6

        iconView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(detailIconViewWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(titleLabelLeadingOffset)
        }

        hairline.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    private func setupConstraints() {
        let titleLabelTrailingInset = 20
        let titleLabelHeight = 20

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(titleLabelTrailingInset)
            make.height.equalTo(titleLabelHeight)
        }
    }

    override func prepareForReuse() {
        iconView.removeFromSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
