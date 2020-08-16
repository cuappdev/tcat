//
//  BusIcon.swift
//  TCAT
//
//  Created by Matthew Barker on 2/26/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//
import UIKit

enum BusIconType: String {

    case blueBannerSmall, directionLarge, directionSmall, liveTracking, redBannerSmall

    /// Return BusIcon's frame width
    var width: CGFloat {
        switch self {
        case .blueBannerSmall, .directionSmall, .redBannerSmall:
            return 48
        case .directionLarge:
            return 72
        case .liveTracking:
            return 72
        }
    }

    /// Return BusIcon's frame height
    var height: CGFloat {
        switch self {
        case .blueBannerSmall, .directionSmall, .redBannerSmall:
            return 24
        case .directionLarge:
            return 36
        case .liveTracking:
            return 30
        }
    }

    /// Return BusIcon's corner radius
    var cornerRadius: CGFloat {
        switch self {
        case .directionLarge:
            return 8
        default:
            return 4
        }
    }

    var baseColor: UIColor {
        switch self {
        case .blueBannerSmall, .redBannerSmall:
            return Colors.white
        case .directionLarge, .directionSmall, .liveTracking:
            return Colors.tcatBlue
        }
    }

    var contentColor: UIColor {
        switch self {
        case .blueBannerSmall:
            return Colors.tcatBlue
        case .directionLarge, .directionSmall, .liveTracking:
            return Colors.white
        case .redBannerSmall:
            return Colors.lateRed
        }
    }

}

class BusIcon: UIView {

    private var type: BusIconType

    private let baseView = UIView()
    private let image = UIImageView(image: UIImage(named: "bus"))
    private let label = UILabel()
    private var liveIndicator: LiveIndicator?

    override var intrinsicContentSize: CGSize {
        return CGSize(width: type.width, height: type.height)
    }

    // MARK: - Init

    init(type: BusIconType, number: Int) {
        self.type = type
        super.init(frame: .zero)

        var fontSize: CGFloat
        switch type {
        case .blueBannerSmall, .directionSmall, .redBannerSmall: fontSize = 14
        case .directionLarge: fontSize = 20
        case .liveTracking: fontSize = 16
        }

        backgroundColor = .clear
        isOpaque = false

        baseView.backgroundColor = type.baseColor
        baseView.layer.cornerRadius = type.cornerRadius
        addSubview(baseView)

        image.tintColor = type.contentColor
        addSubview(image)

        label.text = "\(number)"
        label.font = .getFont(.semibold, size: fontSize)
        label.textColor = type.contentColor
        label.textAlignment = .center
        addSubview(label)

        if type == .liveTracking {
            liveIndicator = LiveIndicator(size: .large, color: type.contentColor)
            addSubview(liveIndicator!)
        }

        setupConstraints(for: type)
    }

    private func setupConstraints(for type: BusIconType) {
        let imageLeadingOffset: CGFloat = type == .directionLarge ? 12 : 8

        var constant: CGFloat
        switch type {
        case .blueBannerSmall, .directionSmall, .redBannerSmall: constant = 0.75
        case .directionLarge: constant = 1
        case .liveTracking: constant = 0.87
        }
        let imageSize = CGSize(width: image.frame.width * constant, height: image.frame.height * constant)

        let labelLeadingOffset: CGFloat = type == .liveTracking
            ? 4
            : (type.width - imageSize.width - imageLeadingOffset - label.intrinsicContentSize.width) / 2
        let liveIndicatorLeadingOffset = 4

        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.size.equalTo(CGSize(width: type.width, height: type.height))
        }

        image.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(imageLeadingOffset)
            make.centerY.equalToSuperview()
            make.size.equalTo(imageSize)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(image.snp.trailing).offset(labelLeadingOffset)
            make.centerY.equalToSuperview()
            make.size.equalTo(label.intrinsicContentSize)
        }

        if let liveIndicator = liveIndicator {
            liveIndicator.snp.makeConstraints { make in
                make.leading.equalTo(label.snp.trailing).offset(liveIndicatorLeadingOffset)
                make.centerY.equalToSuperview()
                make.size.equalTo(liveIndicator.intrinsicContentSize)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        type = .directionSmall
        super.init(coder: aDecoder)
    }

}
