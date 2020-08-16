//
//  NotificationBannerView.swift
//  TCAT
//
//  Created by HAIYING WENG on 11/13/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit

enum NotificationType {

    case beforeBoarding, delay

    var title: String {
        switch self {
        case .beforeBoarding:
            return Constants.Notification.notifyBeforeBoarding
        case .delay:
            return Constants.Notification.notifyDelay
        }
    }

}

enum NotificationBannerType {

    case beforeBoardingConfirmation, busArriving, busDelay, delayConfirmation

    var bannerColor: UIColor {
        switch self {
        case .beforeBoardingConfirmation, .busArriving, .delayConfirmation:
            return Colors.tcatBlue
        case .busDelay:
            return Colors.lateRed
        }
    }

}

class NotificationBannerView: UIView {

    private let type: NotificationBannerType

    private let notificationLabel = UILabel()
    private let shadowedView = RoundShadowedView(cornerRadius: 10)

    init(busAttachment: NSTextAttachment, type: NotificationBannerType) {
        self.type = type
        super.init(frame: .zero)

        shadowedView.setColor(color: type.bannerColor)
        shadowedView.layer.shadowOpacity = 0.8
        addSubview(shadowedView)

        notificationLabel.attributedText = getNotificationLabelAttributedString(attachment: busAttachment)
        notificationLabel.font = .getFont(.regular, size: 14)
        notificationLabel.textColor = Colors.white
        notificationLabel.lineBreakMode = .byWordWrapping
        notificationLabel.numberOfLines = 0
        shadowedView.addSubview(notificationLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        let notificationLabelInset = 15
        let shadowedViewInset = 6

        notificationLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(notificationLabelInset)
        }

        shadowedView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().inset(shadowedViewInset)
        }
    }

    private func getNotificationLabelAttributedString(attachment: NSTextAttachment) -> NSAttributedString {
        var beginningText: String
        switch type {
        case .beforeBoardingConfirmation:
            beginningText = Constants.Notification.beforeBoardingConfirmation
        case .delayConfirmation:
            beginningText = Constants.Notification.delayConfirmation
        default:
            beginningText = ""
        }

        let notificationText = NSMutableAttributedString(string: beginningText)
        if type == .delayConfirmation {
            notificationText.append(NSAttributedString(attachment: attachment))
        }

        return notificationText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
