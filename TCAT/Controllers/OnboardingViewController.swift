//
//  OnboardingViewController.swift
//  TCAT
//
//  Created by Mihir Chauhan on 3/16/18.
//  Copyright © 2018 cuappdev. All rights reserved.
//

import UIKit
import Presentation

class OnboardingViewController: PresentationController {

    //
    // MARK: Variables
    //

    /// Change the main view's background color
    let backgroundColor = UIColor(hex: "C0DDEB")

    //
    // Navigation
    //

    /// The text color of the navigation buttons
    let navigationAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor(hex: "243C47")
    ]

    //
    // Labels
    //

    //
    //  Header Label
    //

    /// The position of the header label
    let titleLabelPosition = Position(left: 0.5, top: 0.2)

    let titleLabelFontName = Fonts.bold

    let titleLabelFontSize: CGFloat = 48.0

    let titleLabelTextColor = UIColor(hex: "243C47")

    let titleLabelMessages = [

        Constants.Onboarding.welcome,
        Constants.Onboarding.liveTracking,
        Constants.Onboarding.searchAnywhere,
        Constants.Onboarding.favorites,
        Constants.Onboarding.bestFeatures

    ]

    //
    // Detail Label
    //

    /// The position of the main label
    let detailLabelPosition = Position(left: 0.5, top: 0.35)

    /// Change the font type of text label
    let detailLabelFontName = Fonts.medium

    /// Change the font size of text label
    let detailLabelFontSize: CGFloat = 32.0

    /// Change the text label color
    let detailLabelTextColor = UIColor(hex: "243C47")

    /// Change the amount of messages in the view. The number of pages shown will equal the number of messages
    let detailLabelMessages = [
        Constants.Onboarding.welcomeMessage,
        Constants.Onboarding.liveTrackingMessage,
        Constants.Onboarding.searchAnywhereMessage,
        Constants.Onboarding.favoritesMessage,
        ""
    ]

    //
    // Assets
    //

    /// Set the asset type, position, and speed.
    let backgroundImages = [
        BackgroundImage(name: "treesnroad", left: -2.7, top: 0.71, speed: -1.3),
        BackgroundImage(name: "tcat", left: -0.60, top: 0.703, speed: 0.4),
        BackgroundImage(name: "hill", left: -1.5, top: 0.55, speed: -0.5),
        BackgroundImage(name: "mountain", left: -1.0, top: 0.41, speed: -0.2),
        BackgroundImage(name: "cloud", left: -2.0, top: 0.10, speed: -0.1)
    ]

    //
    // Ground View
    //

    /// The size of the ground view
    let groundViewSize = CGSize(width: 1024, height: 60)

    /// The position of the ground view
    let groundViewPosition = Position(left: 0.0, bottom: 0.063)

    /// The background color of the ground view
    let groundViewBackgroundColor = UIColor(hex: "243C47")

    //
    // MARK: Implementation
    //

    /// Used to determine what context this view is being shown in
    var isInitialViewing: Bool = true

    struct BackgroundImage {

        let name: String
        let left: CGFloat
        let top: CGFloat
        let speed: CGFloat

        init(name: String, left: CGFloat, top: CGFloat, speed: CGFloat) {
            self.name = name
            self.left = left
            self.top = top
            self.speed = speed
        }

        func positionAt(_ index: Int) -> Position? {
            var position: Position?

            if index == 0 || speed != 0.0 {
                let currentLeft = left + CGFloat(index) * speed
                position = Position(left: currentLeft, top: top)
            }

            return position
        }

    }

    private lazy var dismissButton: UIBarButtonItem = { [unowned self] in
        let dismissButton = UIBarButtonItem(
            title: Constants.Onboarding.dismiss,
            style: .plain,
            target: self,
            action: #selector(dismissView)
        )

        dismissButton.setTitleTextAttributes(navigationAttributes, for: .normal)

        return dismissButton
    }()

    @objc func dismissView() {

        if isInitialViewing {

            let rootVC = HomeMapViewController()
            let desiredViewController = CustomNavigationController(rootViewController: rootVC)

            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let snapshot: UIView = appDelegate.window!.snapshotView(afterScreenUpdates: true)!
            desiredViewController.view.addSubview(snapshot)

            appDelegate.window?.rootViewController = desiredViewController
            userDefaults.setValue(true, forKey: Constants.UserDefaults.onboardingShown)

            UIView.animate(withDuration: 0.5, animations: {
                snapshot.layer.opacity = 0
                snapshot.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5)
            }, completion: { _ in
                snapshot.removeFromSuperview()
            })

        } else {
            dismiss(animated: true)
        }

    }

    init(initialViewing: Bool) {
        self.isInitialViewing = initialViewing
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setNavigationTitle = false
        navigationItem.leftBarButtonItem = isInitialViewing ? nil : dismissButton

        view.backgroundColor = backgroundColor

        configureSlides()
        configureBackground()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private func configureSlides() {

        let width = UIScreen.main.bounds.width < 550 ? UIScreen.main.bounds.width : 550
        let height: CGFloat = 200

        // Detail Labels

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let detailWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0.8
        let detailHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0.6

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.getFont(detailLabelFontName, size: detailLabelFontSize * detailHeight),
            .foregroundColor: detailLabelTextColor,
            .paragraphStyle: paragraphStyle
        ]

        let detailTitles = detailLabelMessages.map { title -> Content in
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: width * detailWidth, height: height * detailHeight))
            label.numberOfLines = 5
            label.attributedText = NSAttributedString(string: title, attributes: attributes)
            return Content(view: label, position: detailLabelPosition)
        }

        // Title Labels

        let headerParagraphStyle = NSMutableParagraphStyle()
        headerParagraphStyle.alignment = .center

        let headerWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0.9
        let headerHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0.6

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.getFont(titleLabelFontName, size: titleLabelFontSize * headerHeight),
            .foregroundColor: titleLabelTextColor,
            .paragraphStyle: headerParagraphStyle
        ]

        let headerTitles = titleLabelMessages.map { title -> Content in
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: width * headerWidth, height: height * headerHeight))
            label.numberOfLines = 5
            label.attributedText = NSAttributedString(string: title, attributes: headerAttributes)
            return Content(view: label, position: titleLabelPosition)
        }

        // Button

        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 60)
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowColor = Colors.metadataIcon.cgColor
        button.layer.shadowOpacity = 0.5
        button.setTitle(Constants.Onboarding.begin, for: .normal)
        button.setTitleColor(Colors.white, for: .normal)
        button.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        button.titleLabel?.font = .getFont(.medium, size: 22)
        button.backgroundColor = Colors.tcatBlue // UIColor(hex: "D65851")
        button.layer.cornerRadius = 4
        let buttonPosition = Position(left: 0.5, top: 0.5)
        let startButton = Content(view: button, position: buttonPosition, centered: true)

        // Slides

        var slides = [SlideController]()

        for index in 0..<detailLabelMessages.count {

            var contents: [Content] = [detailTitles[index], headerTitles[index]]

            // Go Button
            if index == detailLabelMessages.count - 1 {
                contents.append(startButton)
            }

            let controller = SlideController(contents: contents)

            // Title Labels
            controller.add(animation: Content.centerTransition(forSlideContent: headerTitles[index]))
            controller.add(animation: TransitionAnimation(content: headerTitles[index], destination: titleLabelPosition))

            // Detail Labels
            let animation = Content.centerTransition(forSlideContent: detailTitles[index])
            controller.add(animation: animation)

            // Button
            controller.add(content: startButton)
            controller.add(animation: Content.centerTransition(forSlideContent: startButton))

            slides.append(controller)

        }

        add(slides)

    }

    private func configureBackground() {

        var contents = [Content]()

        for backgroundImage in backgroundImages {
            let imageView = UIImageView(image: UIImage(named: backgroundImage.name))
            if let position = backgroundImage.positionAt(0) {
                contents.append(Content(view: imageView, position: position, centered: false))
            }
        }

        addToBackground(contents)

        for row in 1...4 {
            for (column, backgroundImage) in backgroundImages.enumerated() {
                if let position = backgroundImage.positionAt(row), let content = contents.at(column) {
                    addAnimation(TransitionAnimation(content: content, destination: position,
                                                     duration: 2.0, damping: 1.0), forPage: row)
                }
            }
        }

        let groundView = UIView(frame: CGRect(origin: .zero, size: groundViewSize))
        groundView.backgroundColor = groundViewBackgroundColor

        let groundContent = Content(
            view: groundView,
            position: groundViewPosition,
            centered: false
        )

        contents.append(groundContent)
        addToBackground([groundContent])

    }

}

private extension Array {
    func at(_ index: Int?) -> Element? {
        var object: Element?
        if let index = index, index >= 0 && index < endIndex {
            object = self[index]
        }

        return object
    }
}
