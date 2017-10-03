//
//  ContactsListViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright (c) 2014-2017, MyMonero.com
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
		self.tableView.separatorStyle = .none // on cell
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
		return NSLocalizedString("Contacts", comment: "")
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
		return ContactsListViewCell.cellHeight(withPosition: cellPosition)
	}
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		self.tableView.deselectRow(at: indexPath, animated: true)
		let record = self.listController.records[indexPath.row] as! Contact
		let viewController = ContactDetailsViewController(contact: record)
		self.navigationController?.pushViewController(viewController, animated: true)
	}
	//
	// Delegation - Interactions
	@objc func addButton_tapped()
	{
		let viewController = AddContactFromContactsTabFormViewController()
		let modalViewController = UINavigationController(rootViewController: viewController)
		modalViewController.modalPresentationStyle = .formSheet
		self.navigationController!.present(modalViewController, animated: true, completion: nil)
	}
}
