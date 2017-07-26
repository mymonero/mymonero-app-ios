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
		self.tableView.contentInset = UIEdgeInsetsMake(17, 0, 16, 0)
	}
	override func configure_navigation_barButtonItems()
	{
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(type: .add, target: self, action: #selector(addButton_tapped))
	}
	//
	// Accessors - Required overrides
	override func new_navigationTitle() -> String
	{
		return NSLocalizedString("Monero Requests", comment: "")
	}
	override func new_emptyStateView() -> UIView?
	{
		return FundsRequestListEmptyView()
	}
	//
	// Delegation - Table
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		var cell = self.tableView.dequeueReusableCell(withIdentifier: ContactsListViewCell.reuseIdentifier) as? FundsRequestsListViewCell
		if cell == nil {
			cell = FundsRequestsListViewCell()
		}
		let object = self.listController.records[indexPath.row] as! FundsRequest
		let index = indexPath.row
		let cellsCount = self.listController.records.count // it'd be nice if we could cache this - probably on the list controller
		let cellPosition = UICommonComponents.newCellPosition(
			withCellIndex: index,
			cellsCount: cellsCount
		)
		cell!.configure(withObject: object, cellPosition: cellPosition)
		//
		return cell!

		
	}
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		let index = indexPath.row
		let cellsCount = self.listController.records.count // it'd be nice if we could cache this - probably on the list controller
		let cellPosition = UICommonComponents.newCellPosition(
			withCellIndex: index,
			cellsCount: cellsCount
		)
		return FundsRequestsListViewCell.cellHeight(withPosition: cellPosition)
	}
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		self.tableView.deselectRow(at: indexPath, animated: true)
		let record = self.listController.records[indexPath.row] as! FundsRequest
		let viewController = FundsRequestDetailsViewController(fundsRequest: record)
		self.navigationController?.pushViewController(viewController, animated: true)
	}
	//
	// Delegation - Interactions
	func addButton_tapped()
	{
		let viewController = AddFundsRequestFormViewController()
		let modalViewController = UINavigationController(rootViewController: viewController)
		self.navigationController!.present(modalViewController, animated: true, completion: nil)
	}
}
