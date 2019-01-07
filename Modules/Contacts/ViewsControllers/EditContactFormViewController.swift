//
//  EditContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/30/17.
//  Copyright (c) 2014-2019, MyMonero.com
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
		let generator = UINotificationFeedbackGenerator()
		generator.prepare()
		generator.notificationOccurred(.warning)
		//
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
				title: NSLocalizedString("Cancel", comment: ""),
				style: .default
			) { (result: UIAlertAction) -> Void in
			}
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Delete", comment: ""),
				style: .destructive
			) { (result: UIAlertAction) -> Void in
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
		self.navigationController!.present(alertController, animated: true, completion: nil)
	}
}
