//
//  NotificationsViewController.swift
//  TCAT
//
//  Created by Yana Sang on 4/19/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit
import SnapKit
import DZNEmptyDataSet

class NotificationsViewController: UIViewController {

    var table: UITableView = UITableView()
    var notifications: [Route] = []

    // MARK: Spacing vars
    let spacing: CGFloat = 12.0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.Titles.notifications
        view.backgroundColor = Colors.backgroundWash
        navigationController?.navigationBar.tintColor = Colors.primaryText

        navigationItem.setRightBarButton(self.editButtonItem, animated: false)
        self.editButtonItem.action = #selector(editSelected)
        let buttonTitleTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.getFont(.regular, size: 18),
            .foregroundColor: Colors.tcatBlue
        ]
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(
            buttonTitleTextAttributes, for: .normal
        )

        setUpTable()
        view.addSubview(table)
        table.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(spacing)
            make.top.bottom.equalToSuperview()
        }
    }

    @objc func editSelected() {
        if(table.isEditing == true) {
            table.isEditing = false
//            self.navigationItem.rightBarButtonItem?.title = "Edit"
//            table.snp.removeConstraints()
//            table.snp.makeConstraints { make in
//                make.leading.trailing.equalToSuperview().inset(spacing)
//                make.top.bottom.equalToSuperview()
//            }
        } else {
            table.isEditing = true
//            table.snp.removeConstraints()
//            table.snp.makeConstraints { make in
//                make.leading.equalToSuperview().inset(46.0)
//                make.trailing.equalToSuperview().offset(22.0)
//                make.top.bottom.equalToSuperview()
//            }
            self.navigationItem.rightBarButtonItem?.title = "Done"

        }
    }

}

// MARK: TableView DataSource
extension NotificationsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return spacing
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: Constants.Cells.notificationsIdentifier, for: indexPath) as! NotificationsTableViewCell

        cell.setUpTimeLabel()
        cell.setUpDepartureLabel()
        cell.setUpLiveElements()
        cell.layer.cornerRadius = 6.0
        cell.layer.masksToBounds = true
        cell.selectionStyle = .none

        return cell
    }
}

// MARK: TableView Delegate
extension NotificationsViewController: UITableViewDelegate {
    private func setUpTable() {
        table.delegate = self
        table.dataSource = self
        table.register(NotificationsTableViewCell.self, forCellReuseIdentifier: Constants.Cells.notificationsIdentifier)

        table.backgroundColor = UIColor.clear
        table.separatorStyle = .none

        table.isEditing = false
    }

}

extension NotificationsViewController: DZNEmptyDataSetSource {

}

extension NotificationsViewController: DZNEmptyDataSetDelegate {

}
