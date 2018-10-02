//
//  WalletsListViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright (c) 2014-2018, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
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
		self.tableView.contentInset = UIEdgeInsets.init(top: 17, left: 0, bottom: 16, right: 0)
	}
	override func configure_navigation_barButtonItems()
	{
		if self.listController.hasBooted == false || self.listController.records.count == 0 {
			self.navigationItem.rightBarButtonItem = nil // b/c we have the empty state action buttons
		} else {
			self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .add,
				target: self,
				action: #selector(addButton_tapped)
			)
		}
	}
	//
	// Accessors - Overrides
	override func new_navigationTitle() -> String
	{
		if self.listController.hasBooted == false || self.listController.records.count == 0 {
			return NSLocalizedString("MyMonero", comment: "")
		}
		return NSLocalizedString("Wallets", comment: "")
	}
	override func new_emptyStateView() -> UIView?
	{
		let view = WalletsListEmptyView(
			useExisting_tapped_fn:
			{ [unowned self] in
				self._presentAddWalletWizard(inTaskMode: .firstTime_useExisting)
			},
			createNew_tapped_fn:
			{ [unowned self] in
				self._presentAddWalletWizard(inTaskMode: .firstTime_createWallet)
			}
		)
		return view
	}
	//
	// Runtime - Imperatives - Wizard
	func _presentAddWalletWizard(inTaskMode taskMode: AddWalletWizardModalNavigationController.TaskMode)
	{
		let wizardController = AddWalletWizardModalNavigationController(taskMode: taskMode)
		wizardController.present()
	}
	//
	// Delegation - Table
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		var cell = self.tableView.dequeueReusableCell(withIdentifier: WalletsListViewCell.reuseIdentifier) as? WalletsListViewCell
		if cell == nil {
			cell = WalletsListViewCell()
		}
		if self.listController.records.count == 0 {
			// oddly, this occurs on 'delete everything' in ios 11
			return cell!
		}
		let object = self.listController.records[indexPath.row] as! Wallet
		cell!.configure(withObject: object)
		//
		return cell!
	}
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
	{
		let walletCell = cell as! WalletsListViewCell
		walletCell._willBecomeVisible()
	}
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		self.tableView.deselectRow(at: indexPath, animated: true)
		let record = self.listController.records[indexPath.row] as! Wallet
		let viewController = WalletDetails.ViewController(wallet: record)
		self.navigationController?.pushViewController(viewController, animated: true)
	}
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return WalletsListViewCell.cellHeight
	}
	//
	// Delegation - Interactions
	@objc func addButton_tapped()
	{
		self._presentAddWalletWizard(inTaskMode: .pickCreateOrUseExisting)
	}
	//
	// Delegation - View
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		//
		self.listController.records.forEach
		{ (object) in
			let wallet = object as! Wallet
			wallet.requestManualUserRefresh()
		}
		self.tableView.visibleCells.forEach { (cell) in
			let walletCell = cell as! WalletsListViewCell
			walletCell._willBecomeVisible()
		}
	}
}
