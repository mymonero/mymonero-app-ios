//
//  ContactsListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class ContactsListController: PersistedObjectListController
{
	// initial
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
	//
	static let shared = ContactsListController()
	//
	private init()
	{
		super.init(listedObjectType: Contact.self)
	}
	//
	// Accessors - Overridable
	override func overridable_shouldSortOnEveryRecordAdditionAtRuntime() -> Bool
	{
		return true
	}
	//
	// Accessors - State - Emoji
	//
	func givenBooted_CurrentlyInUseEmojis() -> [String]
	{
		let inUseEmojis = self.records.map { (record) -> String in
			return (record as! Contact).emoji
		}
		return inUseEmojis
	}
	//
	// Imperatives - Overrides
	override func overridable_sortRecords()
	{
		self.records = self.records.sorted(by: { (l, r) -> Bool in
			let l_casted = l as! Contact
			let r_casted = r as! Contact
			//
			return l_casted.fullname < r_casted.fullname
		})
	}
	// Imperatives - Public - Adding
	func onceBooted_addContact(
		fullname: String,
		address: String,
		payment_id: MoneroPaymentID?,
		emoji: String?,
		cached_OAResolved_XMR_address: MoneroAddress?,
		_ fn: @escaping (_ err_str: String?, _ instance: Contact?) -> Void
	)
	{
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					let instance = Contact(
						fullname: fullname,
						address: address,
						payment_id: payment_id,
						emoji: emoji,
						cached_OAResolved_XMR_address: cached_OAResolved_XMR_address
					)
					if let err_str = instance.saveToDisk() { // now we must save (insert) manually
						fn(err_str, nil)
						return
					}
					self._atRuntime__record_wasSuccessfullySetUp(instance)
					fn(nil, instance)
				},
				{ // user canceled
					assert(false) // not expecting this, according to UI
					fn("Code fault", nil)
				}
			)
		})
	}
}
