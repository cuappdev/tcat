//
//  HeaderView.swift
//  TCAT
//
//  Created by Austin Astorga on 11/19/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import SnapKit

protocol HeaderViewDelegate: class {
    func displayFavoritesTVC()
    func clearRecentSearches()
}

enum buttonOption {
    case add
    case clear
    case none
}
class HeaderView: UITableViewHeaderFooterView {

    weak var headerViewDelegate: HeaderViewDelegate?

    static let separatorViewHeight: CGFloat = 1

    var label: UILabel!
    var button: UIButton?

    @objc func addNewFavorite(sender: UIButton) {
        headerViewDelegate?.displayFavoritesTVC()
    }

    @objc func clearRecentSearches(sender: UIButton) {
        headerViewDelegate?.clearRecentSearches()
    }

    func setupView(labelText: String? = nil, buttonType: buttonOption = .none, separatorVisible: Bool = false) {
        if labelText != nil {
            label = UILabel()
            label.font = .getFont(.regular, size: 14)
            label.textColor = Colors.metadataIcon
            label.text = labelText
            contentView.addSubview(label)

            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(20)
                make.bottom.equalToSuperview().offset(-10)
            }
            createButton(type: buttonType)
        }

        if separatorVisible {
            let separatorView = UIView()
            separatorView.backgroundColor = Colors.backgroundWash
            contentView.addSubview(separatorView)

            separatorView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.height.equalTo(HeaderView.separatorViewHeight)
                make.top.equalToSuperview()
            }
        }
    }

    func createButton(type: buttonOption) {
        button = UIButton(type: .system)
        button?.setTitleColor(Colors.tcatBlue, for: .normal)

        switch type {
        case .add:
            button?.setTitle(Constants.Buttons.add, for: .normal)
            button?.addTarget(self, action: #selector(addNewFavorite), for: .touchUpInside)
        case .clear:
            button?.setTitle(Constants.Buttons.clear, for: .normal)
            button?.addTarget(self, action: #selector(clearRecentSearches), for: .touchUpInside)
        default: return
        }

        if let button = button {
            contentView.addSubview(button)
            button.snp.makeConstraints { make in
                make.centerY.equalTo(label.snp.centerY)
                make.trailing.equalToSuperview().offset(-12)
            }
        }
    }
}
