//
//  AddContactBaseFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/29/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddContactBaseFormViewController: ContactFormViewController
{
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("New Contact", comment: "")
	}
	override func _persistContact(
		name: String,
		emoji: Emoji.EmojiCharacter,
		address: String,
		withPaymentID paymentID_toSave: MoneroPaymentID?,
		cached_OAResolved_XMR_address: MoneroAddress?,
		fn: @escaping (_ err_str: String?, _ instance: Contact?) -> Void
	)
	{
		ContactsListController.shared.onceBooted_addContact(
			fullname: name,
			address: address,
			payment_id: paymentID_toSave,
			emoji: emoji,
			cached_OAResolved_XMR_address: cached_OAResolved_XMR_address
		)
		{ (err_str, contactInstance) in
			if err_str != nil {
				fn(err_str!, nil)
				return
			}
			fn(nil, contactInstance!)
		}
	}
	//
	// Delegation - Overrides
	override func _didSave(instance: Contact)
	{
		self.navigationController!.dismiss(animated: true, completion: nil)
	}
}
