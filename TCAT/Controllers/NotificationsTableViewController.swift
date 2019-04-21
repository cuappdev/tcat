//
//  NotificationsTableViewController.swift
//  TCAT
//
//  Created by Yana Sang on 4/18/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import SnapKit

class NotificationsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.Titles.notifications
        view.backgroundColor = Colors.backgroundWash
        navigationController?.navigationBar.tintColor = Colors.primaryText

        navigationItem.setRightBarButton(self.editButtonItem, animated: false)
        let buttonTitleTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.getFont(.regular, size: 18),
            .foregroundColor: Colors.tcatBlue
        ]
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(
            buttonTitleTextAttributes, for: .normal
        )

        tableView.register(NotificationsTableViewCell.self, forCellReuseIdentifier: Constants.Cells.notificationsIdentifier)

        tableView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12.0)
            make.trailing.equalToSuperview().inset(12.0)

        }

        if #available(iOS 11.0, *) {
            navigationItem.searchController = nil
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            navigationItem.titleView = nil
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.contentOffset = CGPoint(x: 0.0, y: 107.0)

        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12.0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.notificationsIdentifier, for: indexPath) as! NotificationsTableViewCell
        // Configure the cell...

        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 107.0
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let inset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = inset
        }
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.preservesSuperviewLayoutMargins = false
        }
        if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
            cell.layoutMargins = inset
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
}

// MARK: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate
extension NotificationsTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

}
