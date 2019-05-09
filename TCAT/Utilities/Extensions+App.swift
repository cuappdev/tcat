//
//  UIColor+Shared.swift
//  TCAT
//
//  Created by Annie Cheng on 3/5/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON
import CoreLocation

let increaseTapTargetTag: Int = 1865

extension MKPolyline {
    public var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: self.pointCount)

        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))

        return coords
    }
}

extension UIView {

    /** Round specific corners of UIView */
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

    /// Get UIImage of passed in view
    func getImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }

    static let zero = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))

}

extension UILabel {

    /// Returns the number of lines the UILabel will take based on its width.
    func numberOfLines() -> Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight
        let labelText = (text ?? "") as NSString
        let textSize = labelText.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font ?? UIFont.getFont(.regular, size: 16)], context: nil)
        return Int(textSize.height/charSize)
    }

    // Find the position of a string in a label
    func boundingRect(of string: String) -> CGRect? {

        guard let range = self.text?.range(of: string) else { return nil }
        let nsRange = string.nsRange(from: range)

        guard let attributedText = attributedText else { return nil }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()

        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0.0

        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()

        // Convert the range for glyphs.
        layoutManager.characterRange(forGlyphRange: nsRange, actualGlyphRange: &glyphRange)

        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }

}

extension UIViewController {

    var isModal: Bool {
        if let index = navigationController?.viewControllers.firstIndex(of: self), index > 0 {
            return false
        } else if presentingViewController != nil {
            return true
        } else if navigationController?.presentingViewController?.presentedViewController == navigationController {
            return true
        } else if tabBarController?.presentingViewController is UITabBarController {
            return true
        } else {
            return false
        }
    }

    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}

extension String {

    /// See function name
    func capitalizingFirstLetter() -> String {
        let first = String(prefix(1)).capitalized
        let other = String(dropFirst()).lowercased()
        return first + other
    }

    /// Convert Range to NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let from = range.lowerBound.utf16Offset(in: self)
        let to = range.upperBound.utf16Offset(in: self)
        return NSRange(location: from - startIndex.utf16Offset(in: self), length: to - from)
    }

    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin],
                                            attributes: [.font: font], context: nil)
        return boundingBox.height
    }
    /** Bold a phrase that appears in a string, and return the attributed string. Only shows the last bolded phrase.

        - Parameter containerText: The string to scan through and make `self` bold inside.
        - Parameter originalFont: The initial font of the containerText.
        - Parameter boldFont: The font to make the bold string.
     */
    func bold(in containerText: String, from originalFont: UIFont, to boldFont: UIFont) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: containerText, attributes: [.font: originalFont])
        return self.bold(in: attributedString, to: boldFont)
    }

    /** Bold a phrase that appears in an attributed string, and return the attributed string */
    func bold(in containerText: NSMutableAttributedString, to boldFont: UIFont) -> NSMutableAttributedString {

        let pattern = self
        let attributedString: NSMutableAttributedString = containerText
        let newAttributedString = attributedString
        let plain_string: String = attributedString.string

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let ranges = regex.matches(in: plain_string, options: [], range: NSRange(location: 0, length: plain_string.count)).map { $0.range }
            for range in ranges { newAttributedString.addAttributes([.font: boldFont], range: range) }
        } catch {
            print("bold NSRegularExpression failed")
        }

        return newAttributedString

    }

    /** Return a list of all lone-standing integers in a list */
    func intsFromString() -> [Int] {
        var intList = [Int]()
        let stringArray = self.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for item in stringArray {
            if let number = Int(item) {
                intList.append(number)
            }
        }
        return intList
    }
}

extension Array where Element: UIView {
    /// Remove each view from its superview.
    func removeViewsFromSuperview() {
        self.forEach { $0.removeFromSuperview() }
    }
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}

/// Present a share sheet for a route in any context.
func presentShareSheet(from view: UIView, for route: Route, with image: UIImage? = nil) {

    let shareText = route.summaryDescription
    let promotionalText = "Download Ithaca Transit on the App Store! \(Constants.App.appStoreLink)"

    var activityItems: [Any] = [promotionalText]
    if let shareImage = image {
        activityItems.insert(shareImage, at: 0)
    } else {
        activityItems.insert(shareText, at: 0)
    }

    let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    activityVC.excludedActivityTypes = [.print, .assignToContact, .openInIBooks, .addToReadingList]
    activityVC.popoverPresentationController?.sourceView = view
    activityVC.completionWithItemsHandler = { (activity, completed, items, error) in
        let sharingMethod = activity?.rawValue.replacingOccurrences(of: "com.apple.UIKit.activity.", with: "") ?? "None"
        let payload = RouteSharedEventPayload(activityType: sharingMethod, didSelectAndCompleteShare: completed, error: error?.localizedDescription)
        Analytics.shared.log(payload)
    }

    UIApplication.shared.delegate?.window??.presentInApp(activityVC)

}

func areObjectsEqual<T: Equatable>(type: T.Type, a: Any, b: Any) -> Bool {
    guard let a = a as? T, let b = b as? T else { return false }
    return a == b
}

infix operator ???: NilCoalescingPrecedence

public func ???<T> (optional: T?, defaultValue: @autoclosure () -> String) -> String {
    switch optional {
    case let value?: return String(describing: value)
    case nil: return defaultValue()
    }
}

extension Collection {
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
}

class LargeTapTargetButton: UIButton {

    var tapTargetValue: CGFloat

    required init(extendBy: CGFloat) {
        tapTargetValue = extendBy

        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = self.bounds
        let hitTestEdgeInsets = UIEdgeInsets(top: -tapTargetValue, left: -tapTargetValue, bottom: -tapTargetValue, right: -tapTargetValue)
        let hitFrame = relativeFrame.inset(by: hitTestEdgeInsets)
        return hitFrame.contains(point)
    }

}
