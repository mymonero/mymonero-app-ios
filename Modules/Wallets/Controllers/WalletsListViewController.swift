//
//  WalletsListViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WalletsListViewController: ListViewController
{
	init()
	{
		super.init(withListController: WalletsListController.shared)
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
		self.tableView.backgroundView = WalletsListEmptyView()
	}
	override func configure_navigation_barButtonItems()
	{
		if self.listController.hasBooted == false || self.listController.records.count == 0 {
			self.navigationItem.rightBarButtonItem = nil // b/c we have the empty state action buttons
		} else {
			self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(type: .add, target: self, action: #selector(addButton_tapped))
		}
	}
	//
	// Accessors - Required overrides
	override func new_navigationTitle() -> String
	{
		if self.listController.hasBooted == false || self.listController.records.count == 0 {
			return "MyMonero"
		}
		return "My Monero Wallets"
	}
	//
	// Delegation - Table
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		var cell = self.tableView.dequeueReusableCell(withIdentifier: WalletsListViewCell.reuseIdentifier) as? WalletsListViewCell
		if cell == nil {
			cell = WalletsListViewCell()
		}
		let object = self.listController.records[indexPath.row] as! Wallet
		cell!.configure(withObject: object)
		//
		return cell!
	}
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return WalletsListViewCell.cellHeight
	}
	//
	// Delegation - Interactions
	func addButton_tapped()
	{
		assert(false, "TODO")
	}
}
