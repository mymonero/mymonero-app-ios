//
//  ContactsListViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class ContactsListViewController: ListViewController
{
	init()
	{
		super.init(withListController: ContactsListController.shared)
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
	}
	override func configure_navigation_barButtonItems()
	{
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(type: .add, target: self, action: #selector(addButton_tapped))
	}
	//
	// Accessors - Required overrides
	override func new_navigationTitle() -> String
	{
		return "Contacts"
	}
	override func new_emptyStateView() -> UIView?
	{
		let view = ContactsListEmptyView()
		return view
	}
	//
	// Delegation - Table
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		var cell = self.tableView.dequeueReusableCell(withIdentifier: ContactsListViewCell.reuseIdentifier) as? ContactsListViewCell
		if cell == nil {
			cell = ContactsListViewCell()
		}
		let object = self.listController.records[indexPath.row] as! Contact
		cell!.configure(withObject: object)
		//
		return cell!
	}
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return ContactsListViewCell.cellHeight
	}
	//
	// Delegation - Interactions
	func addButton_tapped()
	{
		assert(false, "TODO")
	}
}
