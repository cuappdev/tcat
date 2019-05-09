//
//  WhatsNewPopupView.swift
//  TCAT
//
//  Created by Omar Rasheed on 9/26/18.
//  Copyright © 2018 cuappdev. All rights reserved.
//

import UIKit
import SnapKit

protocol WhatsNewDelegate: class {
    func getCurrentHomeViewController() -> HomeMapViewController
    func dismissView(card: WhatsNewCard)
}

class WhatsNewHeaderView: UIView {

    weak var whatsNewDelegate: WhatsNewDelegate?
    var card: WhatsNewCard

    /// Whether a promotion is being used for the card
    var isPromotion: Bool

    // e.g. "New In Ithaca Transit" blue label
    var smallHeaderLabel: UILabel!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!

    var buttonContainerView: UIView!
    var dismissButton: UIButton!
    var primaryButton: UIButton?
    var secondaryButton: UIButton?

    private var titleToTop: Constraint?
    private var updateNameToTitle: Constraint?
    private var updateDescToUpdateName: Constraint?
    private var buttonToUpdateDesc: Constraint?
    private var buttonToBottom: Constraint?
    private var updateDescriptionHeight: Constraint?

    let containerPadding = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)

    init(card: WhatsNewCard, isPromotion: Bool = false) {
        self.card = card
        self.isPromotion = isPromotion

        super.init(frame: .zero)
        backgroundColor = Colors.white
        layer.cornerRadius = 16
        clipsToBounds = true

        createWhatsNewHeader()
        createDismissButton()
        createUpdateTitle(title: card.title)
        createUpdateDescription(desc: card.description)
        createButtonContainerView()
        createPrimaryActionButton()
        createSecondaryActionButton()

        setupConstraints()
    }

    func createWhatsNewHeader() {
        smallHeaderLabel = UILabel()
        smallHeaderLabel.text = card.label.uppercased()
        smallHeaderLabel.font = .getFont(.semibold, size: 12)
        smallHeaderLabel.textColor = Colors.tcatBlue

        addSubview(smallHeaderLabel)
    }

    func createDismissButton() {
        dismissButton = LargeTapTargetButton(extendBy: 32)
        dismissButton.setImage(UIImage(named: "x"), for: .normal)
        dismissButton.tintColor = Colors.metadataIcon
        dismissButton.addTarget(self, action: #selector(dismissButtonPressed), for: .touchUpInside)

        addSubview(dismissButton)
    }

    func createUpdateTitle(title: String) {
        titleLabel = UILabel()
        titleLabel.text = card.title
        titleLabel.font = .getFont(.bold, size: 18)

        addSubview(titleLabel)
    }

    func createUpdateDescription(desc: String) {
        descriptionLabel = UILabel()
        descriptionLabel.text = card.description
        descriptionLabel.font = .getFont(.regular, size: 14)
        descriptionLabel.textColor = Colors.metadataIcon
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.isUserInteractionEnabled = true

        addSubview(descriptionLabel)
    }

    func createButtonContainerView() {
        buttonContainerView = UIView()
        addSubview(buttonContainerView)
    }

    func createPrimaryActionButton() {
        guard let title = card.primaryActionTitle else { return }
        let primaryButton = UIButton()
        primaryButton.setTitle(title, for: .normal)
        primaryButton.titleLabel?.font = .getFont(.semibold, size: 14)
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        primaryButton.backgroundColor = Colors.tcatBlue
        primaryButton.setTitleColor(Colors.white, for: .normal)
        primaryButton.layer.cornerRadius = primaryButton.intrinsicContentSize.height / 2
        primaryButton.clipsToBounds = true

        buttonContainerView.addSubview(primaryButton)
        self.primaryButton = primaryButton
    }

    func createSecondaryActionButton() {
        guard let title = card.secondaryActionTitle else { return }
        let secondaryButton = UIButton()
        secondaryButton.setTitle(title, for: .normal)
        secondaryButton.titleLabel?.font = .getFont(.medium, size: 14)
        secondaryButton.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
        secondaryButton.backgroundColor = Colors.metadataIcon
        secondaryButton.setTitleColor(Colors.white, for: .normal)
        secondaryButton.layer.cornerRadius = secondaryButton.intrinsicContentSize.height / 2
        secondaryButton.clipsToBounds = true

        buttonContainerView.addSubview(secondaryButton)

        self.secondaryButton = secondaryButton
    }

    func setupConstraints() {

        let titleToTopPadding: CGFloat = 16

        smallHeaderLabel.snp.makeConstraints { (make) in
            titleToTop = make.top.equalToSuperview().offset(titleToTopPadding).constraint
            make.centerX.equalToSuperview()
            make.height.equalTo(smallHeaderLabel.intrinsicContentSize.height)
            make.width.equalTo(smallHeaderLabel.intrinsicContentSize.width)
        }

        let labelToTitlePadding: CGFloat = 8

        titleLabel.snp.makeConstraints { (make) in
            updateNameToTitle = make.top.equalTo(smallHeaderLabel.snp.bottom).offset(labelToTitlePadding).constraint
            make.centerX.equalToSuperview()
            make.height.equalTo(titleLabel.intrinsicContentSize.height)
            make.width.equalTo(titleLabel.intrinsicContentSize.width)
        }

        let titletoDescriptionPadding: CGFloat = 6
        let descriptionInset: CGFloat = 32

        descriptionLabel.snp.makeConstraints { (make) in
            updateDescToUpdateName = make.top.equalTo(titleLabel.snp.bottom).offset(titletoDescriptionPadding).constraint
            make.leading.trailing.equalToSuperview().inset(descriptionInset)
            if let description = descriptionLabel.text {
                // Take total width and subtract various insets used in layout
                let headerViewCardPadding = containerPadding.left + containerPadding.right
                let widthValue = UIScreen.main.bounds.width - headerViewCardPadding - (descriptionInset * 2)
                let heightValue = ceil(description.heightWithConstrainedWidth(width: widthValue, font: descriptionLabel.font))
                updateDescriptionHeight = make.height.equalTo(ceil(heightValue)).constraint
            }
        }

        let descriptionToButtonPadding: CGFloat = 12
        let buttonToBottomPadding: CGFloat = 16

        buttonContainerView.snp.makeConstraints { (make) in
            buttonToUpdateDesc = make.top.equalTo(descriptionLabel.snp.bottom).offset(descriptionToButtonPadding).constraint
            buttonToBottom = make.bottom.equalToSuperview().inset(buttonToBottomPadding).constraint
            make.centerX.equalToSuperview()
        }

        dismissButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(titleToTopPadding)
            make.right.equalToSuperview().inset(titleToTopPadding)
            make.width.height.equalTo(14)
        }

        // Padding for space between buttons
        let buttonWidthPadding: CGFloat = (secondaryButton != nil) ? 16 : 0
        let buttonWidth: CGFloat = 80

        primaryButton?.snp.makeConstraints { (make) in
            make.centerY.top.bottom.right.equalToSuperview()
            make.width.equalTo(buttonWidth)
            if secondaryButton == nil {
                make.left.equalToSuperview()
            }
        }

        secondaryButton?.snp.makeConstraints { (make) in
            make.centerY.top.bottom.left.equalToSuperview()
            make.width.equalTo(buttonWidth)
            if let primaryButton = primaryButton {
                make.right.equalTo(primaryButton.snp.left).offset(-buttonWidthPadding)
            } else {
                make.right.equalToSuperview()
            }
        }

    }

    func calculateCardHeight() -> CGFloat {
        guard
            let titleToTop = titleToTop,
            let updateNameToTitle = updateNameToTitle,
            let updateDescToUpdateName = updateDescToUpdateName,
            let updateDescriptionHeight = updateDescriptionHeight,
            let actionButtonToUpdateDesc = buttonToUpdateDesc,
            let actionButtonToBottom = buttonToBottom
            else {
                return 0
        }

        let titleToTopVal = titleToTop.layoutConstraints[0].constant
        let titleHeight = smallHeaderLabel.intrinsicContentSize.height

        let titleSpace = titleToTopVal + titleHeight

        let updateNameToTitleVal = updateNameToTitle.layoutConstraints[0].constant
        let updateNameHeight = titleLabel.intrinsicContentSize.height

        let updateNameSpace = updateNameToTitleVal + updateNameHeight

        let updateDescToUpdateNameVal = updateDescToUpdateName.layoutConstraints[0].constant
        let updateDescHeight = updateDescriptionHeight.layoutConstraints[0].constant

        let updateDescSpace = updateDescToUpdateNameVal + updateDescHeight

        let actionButtonToUpdateDescVal = actionButtonToUpdateDesc.layoutConstraints[0].constant
        let buttonHeight = primaryButton?.intrinsicContentSize.height ?? secondaryButton?.intrinsicContentSize.height ?? 0

        let actionButtonSpace = actionButtonToUpdateDescVal + buttonHeight

        let bottomOffset = -actionButtonToBottom.layoutConstraints[0].constant

        return ceil(titleSpace + updateNameSpace + updateDescSpace + actionButtonSpace + bottomOffset)
    }

    @objc func primaryButtonTapped() {
        if
            let homeViewController = whatsNewDelegate?.getCurrentHomeViewController(),
            let primaryAction = card.primaryActionHandler
        {
            primaryAction(homeViewController)
            let payload = PrimaryActionTappedPayload(actionDescription: card.title)
            Analytics.shared.log(payload)
        }
        if !isPromotion {
            self.whatsNewDelegate?.dismissView(card: card)
        }
    }

    @objc func secondaryButtonTapped() {
        if
            let homeViewController = whatsNewDelegate?.getCurrentHomeViewController(),
            let secondaryAction = card.secondaryActionHandler
        {
            secondaryAction(homeViewController)
            let payload = SecondaryActionTappedPayload(actionDescription: card.title)
            Analytics.shared.log(payload)
        }
        if !isPromotion {
            self.whatsNewDelegate?.dismissView(card: card)
        }
    }

    func open(_ link: String, optionalAppLink: String?, linkOpened: @escaping (() -> Void)) {
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

    @objc func dismissButtonPressed() {
        whatsNewDelegate?.dismissView(card: card)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
