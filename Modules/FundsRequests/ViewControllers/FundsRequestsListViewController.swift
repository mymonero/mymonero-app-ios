//
//  FundsRequestsListViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
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
		self.tableView.contentInset = UIEdgeInsets.init(top: 17, left: 0, bottom: 16, right: 0)
	}
	override func startObserving()
	{
		super.startObserving()
		NotificationCenter.default.addObserver(self, selector: #selector(WalletAppContactActionsCoordinator_didTrigger_requestFundsFromContact(_:)), name: WalletAppContactActionsCoordinator.NotificationNames.didTrigger_requestFundsFromContact.notificationName, object: nil)
	}
	override func configure_navigation_barButtonItems()
	{
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(type: .add, target: self, action: #selector(addButton_tapped))
	}
	//
	override func stopObserving()
	{
		super.stopObserving()
		NotificationCenter.default.removeObserver(self, name: WalletAppContactActionsCoordinator.NotificationNames.didTrigger_requestFundsFromContact.notificationName, object: nil)
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
	// Imperatives - Modals
	func presentOrConfigureExistingCreateRequestFormView(
		withContact contact: Contact?,
		selectedWallet wallet: Wallet?
	) {
		if let presentedViewController = self.navigationController!.presentedViewController {
			guard let presented_addFundsRequestFormViewController = presentedViewController as? AddFundsRequestFormViewController else {
				DDLog.Warn("FundsRequests", "Presented view is not a AddFundsRequestFormViewController. Bailing")
				return
			}
			if contact == nil && wallet == nil {
				assert(
					false,
					"expected either contact or wallet to always be non-nil when being asked to reconfigure already presented Form"
				)
				return
			}
			presented_addFundsRequestFormViewController.reconfigureFormAtRuntime_havingElsewhereSelected(
				requestFromContact: contact,
				receiveToWallet: wallet
			)
			return
		}
		let viewController = AddFundsRequestFormViewController(
			contact: contact, // which might be nil
			selectedWallet: wallet // also might be nil
		)
		let modalViewController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
		modalViewController.modalPresentationStyle = .formSheet
		self.navigationController!.present(modalViewController, animated: true, completion: nil)
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
		var viewController: UIViewController?
		if record.is_displaying_local_wallet == true {
			viewController = FundsRequestQRDisplayViewController(fundsRequest: record, presentedAsModal: false/* just to be explicit - not strictly necessary*/)
		} else {
			viewController = FundsRequestDetailsViewController(fundsRequest: record)
		}
		self.navigationController?.pushViewController(viewController!, animated: true)
	}
	//
	// Delegation - Interactions
	@objc func addButton_tapped()
	{
		self.presentOrConfigureExistingCreateRequestFormView(
			withContact: nil,
			selectedWallet: nil
		)
	}
	//
	// Delegation - Notifications
	@objc func WalletAppContactActionsCoordinator_didTrigger_requestFundsFromContact(_ notification: Notification)
	{
		self.navigationController?.popToRootViewController(animated: false) // essential for the case they're viewing a request details view…
		// but do not dismiss modals - reconfigure instead
		let userInfo = notification.userInfo!
		let contact = userInfo[WalletAppContactActionsCoordinator.NotificationUserInfoKeys.contact.key] as! Contact
		self.presentOrConfigureExistingCreateRequestFormView(withContact: contact, selectedWallet: nil)
	}
}
