//
//  FavoritesViewController.swift
//  TCAT
//
//  Created by Lucy Xu on 11/4/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import Pulley
import UIKit

class FavoritesViewController: UIViewController {

    // MARK: - View vars
    private let editButton = UIButton()
    private var favoritesCollectionView: UICollectionView!
    private let favoritesTitleLabel = UILabel()
    private let tabView = UIView()
    private let tabSize = CGSize(width: 32, height: 4)

    // MARK: - Data vars
    private let favoritesReuseIdentifier = "FavoritesCollectionViewCell"
    private let addFavoritesReuseIdentifier = "AddFavoritesCollectionViewCell"
    private let favoritePlaces = Global.shared.retrievePlaces(for: Constants.UserDefaults.favorites)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLabels()
        setupButtons()
        setupFavoritesCollectionView()
        setupTabView()
        setupConstraints()
    }

    private func setupLabels() {
        favoritesTitleLabel.text = "Favorites"
        favoritesTitleLabel.textColor = .black
        favoritesTitleLabel.font = .getFont(.medium, size: 24)
        view.addSubview(favoritesTitleLabel)
    }

    private func setupButtons() {
        let favoritesBlueColor = UIColor(hex: "08A0E0")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.getFont(.regular, size: 14.0),
            .foregroundColor: favoritesBlueColor,
        ]
        let attributedString = NSMutableAttributedString(string: "Edit", attributes: attributes)
        editButton.setAttributedTitle(attributedString, for: .normal)
        view.addSubview(editButton)
    }

    private func setupFavoritesCollectionView() {
        let favoritesFlowLayout = UICollectionViewFlowLayout()
        favoritesFlowLayout.minimumLineSpacing = 12.0
        favoritesFlowLayout.minimumInteritemSpacing = 4.0

        favoritesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: favoritesFlowLayout)
        favoritesCollectionView.delegate = self
        favoritesCollectionView.dataSource = self
        favoritesCollectionView.register(FavoritesCollectionViewCell.self, forCellWithReuseIdentifier: favoritesReuseIdentifier)
        favoritesCollectionView.register(AddFavoritesCollectionViewCell.self, forCellWithReuseIdentifier: addFavoritesReuseIdentifier)
        favoritesCollectionView.backgroundColor = .clear
        view.addSubview(favoritesCollectionView)
    }

    private func setupTabView() {
        tabView.backgroundColor = Colors.metadataIcon
        tabView.layer.cornerRadius = tabSize.height / 2
        tabView.clipsToBounds = true
        view.addSubview(tabView)
    }

    private func setupConstraints() {
        let tabTopInset: CGFloat = 6
        let horizontalPadding = 16
        let titleBarTopPadding = 21
        let favoritesTopPadding = 24
        let bottomPadding = 18

        favoritesTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(horizontalPadding)
            make.top.equalToSuperview().inset(titleBarTopPadding)
        }

        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(horizontalPadding)
            make.top.equalToSuperview().inset(titleBarTopPadding)
        }

        favoritesCollectionView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(horizontalPadding)
            make.trailing.equalToSuperview().inset(horizontalPadding).priority(.high)
            make.top.equalTo(favoritesTitleLabel.snp.bottom).offset(favoritesTopPadding)
            make.bottom.equalToSuperview().offset(-bottomPadding).priority(.high)
        }

        tabView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(tabTopInset)
            make.size.equalTo(tabSize)
        }
    }

}

extension FavoritesViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == favoritesCollectionView ? favoritePlaces.count + 1 : 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < favoritePlaces.count  {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: favoritesReuseIdentifier, for: indexPath) as! FavoritesCollectionViewCell
            cell.configure(for: favoritePlaces[indexPath.row])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: addFavoritesReuseIdentifier, for: indexPath) as! AddFavoritesCollectionViewCell
            cell.configure(for: "test", delegate: self)
            return cell
         }
    }
}

extension FavoritesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 95)
    }
}

extension FavoritesViewController: PulleyDrawerViewControllerDelegate {

    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 200
    }

    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .partiallyRevealed]
    }

}

// MARK: - HeaderView Delegate
extension FavoritesViewController: HeaderViewDelegate {

    func presentFavoritePicker() {
        if favoritePlaces.count < 3 {
            let favoritesTVC = FavoritesTableViewController()
            favoritesTVC.didAddFavorite = {
//                self.updatePlaces()
            }
            let navController = CustomNavigationController(rootViewController: favoritesTVC)
            present(navController, animated: true, completion: nil)
        } else {
            let title = Constants.Alerts.MaxFavorites.title
            let message = Constants.Alerts.MaxFavorites.message
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let done = UIAlertAction(title: Constants.Alerts.MaxFavorites.action, style: .default)
            alertController.addAction(done)
            present(alertController, animated: true, completion: nil)
        }
    }

    func clearRecentSearches() {
//        Global.shared.deleteAllRecents()
//        recentLocations = []
//        updateSections()
    }

}
