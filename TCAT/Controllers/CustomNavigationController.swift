//
//  RouteDetailViewController.swift
//  TCAT
//
//  Created by Matthew Barker on 2/11/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import FutureNova
import NotificationBannerSwift
import Reachability
import UIKit

protocol ReachabilityDelegate: class {
    func reachabilityChanged(connection: Reachability.Connection)
}

class CustomNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    /// Attributed string details for the back button text of a navigation controller
    static let buttonTitleTextAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.getFont(.regular, size: 14)
    ]

    private let additionalWidth: CGFloat = 30
    private let additionalHeight: CGFloat = 100
    /// Attributed string details for the title text of a navigation controller
    private let titleTextAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.getFont(.regular, size: 18),
        .foregroundColor: Colors.black
    ]

    private var screenshotObserver: NSObjectProtocol?
    private weak var reachabilityDelegate: ReachabilityDelegate?
    private var reachability: Reachability!
    private let banner = StatusBarNotificationBanner(title: Constants.Banner.noInternetConnection, style: .danger)

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        view.backgroundColor = Colors.white
        customizeAppearance()
    }

    open override var childForStatusBarStyle: UIViewController? {
        return visibleViewController
    }

    override func viewDidAppear(_ animated: Bool) {
        reachability = Reachability()!
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(notif:)),
                                               name: .reachabilityChanged,
                                               object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        banner.dismiss()
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if responds(to: #selector(getter: interactivePopGestureRecognizer)) {
            interactivePopGestureRecognizer?.delegate = self
            delegate = self
        }

        // Add screenshot listener, log view controller name
        let notifName = UIApplication.userDidTakeScreenshotNotification
        screenshotObserver = NotificationCenter.default.addObserver(forName: notifName, object: nil, queue: .main) { _ in
            guard let currentViewController = self.visibleViewController else { return }
            let payload = ScreenshotTakenPayload(location: "\(type(of: currentViewController))")
            Analytics.shared.log(payload)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let screenshotObserver = screenshotObserver {
            NotificationCenter.default.removeObserver(screenshotObserver)
        }
        reachability.stopNotifier()
    }

    private func customizeAppearance() {
        navigationBar.backgroundColor = Colors.white
        navigationBar.barTintColor = Colors.white
        navigationBar.tintColor = Colors.primaryText
        navigationBar.titleTextAttributes = titleTextAttributes
        navigationItem.backBarButtonItem?.setTitleTextAttributes(
            CustomNavigationController.buttonTitleTextAttributes, for: .normal
        )
    }

    /// Return an instance of custom back button
    private func customBackButton() -> UIBarButtonItem {

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
    @objc private func backAction() {
        _ = popViewController(animated: true)
    }

    @objc func reachabilityChanged(notif: Notification) {
        if let reachability = notif.object as? Reachability {
            switch reachability.connection {
            case .wifi, .cellular:
                banner.dismiss()
                UIApplication.shared.statusBarStyle = .default
            case .none:
                banner.show(queuePosition: .front, on: self)
                banner.autoDismiss = false
                banner.isUserInteractionEnabled = false
                UIApplication.shared.statusBarStyle = .lightContent
            }
            setNeedsStatusBarAppearanceUpdate()
            reachabilityDelegate?.reachabilityChanged(connection: reachability.connection)
        }
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

        if let delegate = viewController as? ReachabilityDelegate {
            reachabilityDelegate = delegate
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)
        if let lastViewController = viewControllers.last {
            if let delegate = viewController as? ReachabilityDelegate {
                reachabilityDelegate = delegate
            } else {
                reachabilityDelegate = nil
            }
            if let homeMapVC = lastViewController as? HomeMapViewController {
                homeMapVC.navigationItem.leftBarButtonItem = nil
            }
        }
        return viewController
    }

    // MARK: UINavigationControllerDelegate Functions

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        interactivePopGestureRecognizer?.isEnabled = (responds(to: #selector(getter: interactivePopGestureRecognizer)) && viewControllers.count > 1)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
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
