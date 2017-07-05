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
	// TODO: add delete button
	//
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Edit Contact", comment: "")
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem)
		)
	}
	//
	// Overrides - Accessors
	override var _overridable_formSubmissionMode: ContactFormSubmissionController.Mode { return .update }
	override var _overridable_forMode_update__contactInstance: Contact? { return self.contact }
	//
	override var new_initial_value_name: String? { return self.contact.fullname }
	override var new_initial_value_emoji: Emoji.EmojiCharacter { return self.contact.emoji }
	override var new_initial_value_address: String? { return self.contact.address }
	override var new_initial_value_paymentID: String? { return self.contact.payment_id }
}
