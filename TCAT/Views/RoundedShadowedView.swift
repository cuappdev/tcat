//
//  RoundedShadowView.swift
//  TCAT
//
//  Created by Omar Rasheed on 4/16/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit

class RoundShadowedView: UIView {

    var containerView: UIView!

    func addRoundedCornersAndShadow() {
        backgroundColor = .clear

        layer.shadowColor = Colors.secondaryText.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2.5)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 2.5

        containerView = UIView()
        containerView.backgroundColor = .white

        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true

        addSubview(containerView)

        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override func addSubview(_ view: UIView) {
        if view.isEqual(containerView) {
            super.addSubview(view)
        } else {
            containerView.addSubview(view)
        }
    }
}
