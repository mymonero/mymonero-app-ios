//
//  ContactsListController.swift
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
import Foundation

class ContactsListController: PersistedObjectListController
{
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
	func givenBooted_currentlyInUseEmojiCharacters() -> [Emoji.EmojiCharacter]
	{
		let inUseEmojiCharacters = self.records.map
		{ (record) -> Emoji.EmojiCharacter in
			return (record as! Contact).emoji
		}
		return inUseEmojiCharacters
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
	) {
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
