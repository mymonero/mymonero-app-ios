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
	// Accessors - Overrides
	override func new_navigationTitle() -> String
	{
		if self.listController.hasBooted == false || self.listController.records.count == 0 {
			return "MyMonero"
		}
		return "My Monero Wallets"
	}
	override func new_emptyStateView() -> UIView?
	{
		let view = WalletsListEmptyView(
			useExisting_tapped_fn: { [unowned self] in
				self._presentAddWalletWizard(inTaskMode: .firstTime_useExisting)
			},
			createNew_tapped_fn: { [unowned self] in
				self._presentAddWalletWizard(inTaskMode: .firstTime_createWallet)
			}
		)
		return view
	}
	//
	// Runtime - Imperatives - Wizard
	var current_wizardController: AddWallet_WizardController?
	func _presentAddWalletWizard(inTaskMode taskMode: AddWallet_WizardController.TaskMode)
	{
		assert(self.current_wizardController == nil)
		let wizardController = AddWallet_WizardController(taskMode: taskMode)
		wizardController.didDismiss_fn =
		{ [unowned self] in
			self.current_wizardController = nil
		}
		self.current_wizardController = wizardController
		wizardController.present(/*inViewController: self.navigationController*/)
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
		self._presentAddWalletWizard(inTaskMode: .pickCreateOrUseExisting)
	}
}
