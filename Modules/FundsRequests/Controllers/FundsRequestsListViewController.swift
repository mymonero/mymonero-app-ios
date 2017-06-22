//
//  FundsRequestsListViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class FundsRequestsListViewController: ListViewController
{
	init()
	{
		super.init(withListController: FundsRequestsListController.shared)
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func setup_tableView()
	{
		super.setup_tableView()
		self.tableView.backgroundColor = .contentBackgroundColor
		self.tableView.separatorStyle = .none
		self.tableView.contentInset = UIEdgeInsetsMake(17, 0, 4, 0)
		self.tableView.backgroundView = FundsRequestListEmptyView()
	}
	override func configure_navigation_barButtonItems()
	{
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(type: .add, target: self, action: #selector(addButton_tapped))
	}
	//
	// Accessors - Required overrides
	override func new_navigationTitle() -> String
	{
		return "Monero Requests"
	}
	//
	// Delegation - Table
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		var cell = self.tableView.dequeueReusableCell(withIdentifier: FundsRequestsListViewCell.reuseIdentifier) as? FundsRequestsListViewCell
		if cell == nil {
			cell = FundsRequestsListViewCell()
		}
		let object = self.listController.records[indexPath.row] as! FundsRequest
		cell!.configure(withObject: object)
		//
		return cell!
	}
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return FundsRequestsListViewCell.cellHeight
	}
	//
	// Delegation - Interactions
	func addButton_tapped()
	{
		assert(false, "TODO")
	}
}
