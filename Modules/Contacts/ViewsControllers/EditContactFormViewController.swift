//
//  EditContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/30/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class EditContactFormViewController: ContactFormViewController
{
	var contact: Contact
	init(withContact contact: Contact)
	{
		self.contact = contact
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	//
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Edit Contact", comment: "")
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
		let err_str = self.contact.SetValuesAndSave_fromEditAndPossibleOAResolve(
			fullname: name,
			emoji: emoji,
			address: address,
			payment_id: paymentID_toSave,
			cached_OAResolved_XMR_address: cached_OAResolved_XMR_address
		)
		if err_str != nil {
			fn(err_str, nil)
			return
		}
		fn(nil, self.contact)
	}
}
