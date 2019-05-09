//
//  RouteDetailViewController.swift
//  TCAT
//
//  Created by Matthew Barker on 2/11/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    let additionalWidth: CGFloat = 30
    let additionalHeight: CGFloat = 100

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        view.backgroundColor = Colors.white
        customizeAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    open override var childForStatusBarStyle: UIViewController? {
        return visibleViewController
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        if responds(to: #selector(getter: interactivePopGestureRecognizer)) {
            interactivePopGestureRecognizer?.delegate = self
            delegate = self
        }

        // Add screenshot listener, log view controller name
        let notifName = UIApplication.userDidTakeScreenshotNotification
        NotificationCenter.default.addObserver(forName: notifName, object: nil, queue: .main) { _ in
            guard let currentViewController = self.visibleViewController else { return }
            let payload = ScreenshotTakenPayload(location: "\(type(of: currentViewController))")
            Analytics.shared.log(payload)
        }

    }

    /// Attributed string details for the title text of a navigation controller
    let titleTextAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.getFont(.regular, size: 18),
        .foregroundColor: Colors.black
    ]

    /// Attributed string details for the back button text of a navigation controller
    static let buttonTitleTextAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.getFont(.regular, size: 14)
    ]

    func customizeAppearance() {

        navigationBar.backgroundColor = Colors.white
        navigationBar.barTintColor = Colors.white
        navigationBar.tintColor = Colors.primaryText
        navigationBar.titleTextAttributes = titleTextAttributes
        navigationItem.backBarButtonItem?.setTitleTextAttributes(
            CustomNavigationController.buttonTitleTextAttributes, for: .normal
        )

        // Saved from other view controllers in case needed
        // navigationBar.isTranslucent = false
        // navigationBar.setBackgroundImage(UIImage(), for: .default)
        // navigationBar.shadowImage = UIImage()

    }

    /// Return an instance of custom back button
    func customBackButton() -> UIBarButtonItem {

        let backButton = UIButton()
        backButton.setImage(#imageLiteral(resourceName: "back"), for: .normal)
        backButton.tintColor = Colors.primaryText

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.getFont(.regular, size: 14.0),
            .foregroundColor: Colors.primaryText,
            .baselineOffset: 0.3
        ]
        let attributedString = NSMutableAttributedString(string: "  " + Constants.Buttons.back, attributes: attributes)
        backButton.setAttributedTitle(attributedString, for: .normal)
        backButton.sizeToFit()

        // Expand frame to create bigger touch area
        backButton.frame = CGRect(x: backButton.frame.minX, y: backButton.frame.minY, width: backButton.frame.width + additionalWidth, height: backButton.frame.height + additionalHeight)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: additionalWidth)

        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)

        return UIBarButtonItem(customView: backButton)
    }

    /** Move back one view controller in navigationController stack */
    @objc func backAction() {
        _ = popViewController(animated: true)
    }

    // MARK: UINavigationController Functions

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {

        if responds(to: #selector(getter: interactivePopGestureRecognizer)) {
            interactivePopGestureRecognizer?.isEnabled = false
        }

        super.pushViewController(viewController, animated: animated)

        if viewControllers.count > 1 {

            navigationBar.titleTextAttributes = titleTextAttributes

            // Add back button for non-modal non-peeked screens

            if !viewController.isModal {
                viewController.navigationItem.hidesBackButton = true
                viewController.navigationItem.setLeftBarButton(customBackButton(), animated: true)
            }

        }

    }

    override func popViewController(animated: Bool) -> UIViewController? {

        let viewController = super.popViewController(animated: animated)
        if let lastViewController = viewControllers.last as? HomeMapViewController {
            lastViewController.navigationItem.leftBarButtonItem = nil
        }
        return viewController

    }

    // MARK: UINavigationControllerDelegate Functions

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        interactivePopGestureRecognizer?.isEnabled = (responds(to: #selector(getter: interactivePopGestureRecognizer)) && viewControllers.count > 1)
    }

}

class OnboardingNavigationController: UINavigationController {

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
    }

    open override var childForStatusBarStyle: UIViewController? {
        return visibleViewController
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // Do NOT remove this initializer; OnboardingNavigationController will crash without it.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

}
