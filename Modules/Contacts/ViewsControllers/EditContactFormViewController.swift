//
//  EditContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/30/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

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
	//
	override var _overridable_wantsDeleteRecordButton: Bool { return true }
	//
	// Overrides - Delegation
	override func deleteButton_tapped()
	{
		let alertController = UIAlertController(
			title: NSLocalizedString("Delete this contact?", comment: ""),
			message: NSLocalizedString(
				"Delete this contact? This cannot be undone.",
				comment: ""
			),
			preferredStyle: .alert
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Delete", comment: ""),
				style: .destructive
			)
			{ (result: UIAlertAction) -> Void in
				let err_str = ContactsListController.shared.givenBooted_delete(listedObject: self.contact)
				if err_str != nil {
					self.setValidationMessage(err_str!)
					return
				}
				assert(self.navigationController!.presentingViewController != nil)
				// we always expect self to be presented modally
				self.navigationController?.dismiss(animated: true, completion: nil)
			}
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Cancel", comment: ""),
				style: .default
			)
			{ (result: UIAlertAction) -> Void in
			}
		)
		self.navigationController!.present(alertController, animated: true, completion: nil)
	}
}
