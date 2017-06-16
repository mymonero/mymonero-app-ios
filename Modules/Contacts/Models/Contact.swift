//
//  Contact.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class Contact: PersistableObject
{
	enum NotificationNames: String
	{
		case infoUpdated		= "Contact_NotificationNames_infoUpdated"
		var notificationName: NSNotification.Name
		{
			return NSNotification.Name(self.rawValue)
		}
	}
	enum DictKey: String
	{ // (For persistence)
		case fullname = "fullname"
		case address = "address"
		case payment_id = "payment_id"
		case emoji = "emoji"
		case cached_OAResolved_XMR_address = "cached_OAResolved_XMR_address"
	}
	//
	// Properties - Principal Persisted Values
	var fullname: String!
	var address: String! // String because it could be an OA address
	var payment_id: MoneroPaymentID!
	var emoji: String!
	var cached_OAResolved_XMR_address: MoneroAddress?
	//
	// 'Protocols' - Persistable Object
	override func new_dictRepresentation() -> [String: Any]
	{
		var dict = super.new_dictRepresentation() // since it constructs the base object for us
		do {
			dict[DictKey.fullname.rawValue] = self.fullname
			if let value = self.address {
				dict[DictKey.address.rawValue] = value
			}
			if let value = self.payment_id {
				dict[DictKey.payment_id.rawValue] = value
			}
			if let value = self.emoji {
				dict[DictKey.emoji.rawValue] = value
			}
			if let value = self.cached_OAResolved_XMR_address {
				dict[DictKey.cached_OAResolved_XMR_address.rawValue] = value
			}
		}
		return dict
	}
	//
	// Lifecycle - Init - Reading existing (already saved) wallet
	override func collectionName() -> String
	{
		return "Contact"
	}
	required init?(withPlaintextDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	{
		try super.init(withPlaintextDictRepresentation: dictRepresentation) // this will set _id for us
		//
		self.fullname = dictRepresentation[DictKey.fullname.rawValue] as! String
		self.address = dictRepresentation[DictKey.address.rawValue] as! String
		self.payment_id = dictRepresentation[DictKey.payment_id.rawValue] as? String
		self.emoji = dictRepresentation[DictKey.emoji.rawValue] as! String
		self.cached_OAResolved_XMR_address = dictRepresentation[DictKey.cached_OAResolved_XMR_address.rawValue] as? String
	}
	//
	// Lifecycle - Init - For adding new
	required init()
	{
		super.init()
	}
	convenience init(
		fullname: String,
		address: String,
		payment_id: MoneroPaymentID?,
		emoji: String?,
		cached_OAResolved_XMR_address: MoneroAddress?
	)
	{
		self.init()
		self.fullname = fullname
		self.address = address
		self.payment_id = payment_id
		self.emoji = emoji
		self.cached_OAResolved_XMR_address = cached_OAResolved_XMR_address
	}
	//
	// Interface - Runtime - Accessors/Properties

	//
	// Runtime - Imperatives - Update cases
	func SetValuesAndSave_fromEditAndPossibleOAResolve(
		fullname: String,
		emoji: String,
		address: String, // could be an OA address too
		payment_id: MoneroPaymentID,
		cached_OAResolved_XMR_address: MoneroAddress?
	) -> String? // err_str -- maybe port to 'throws'
	{
		self.fullname = fullname
		self.emoji = emoji
		// TODO:? validate emoji is in set
		self.address = address
		if MyMoneroCoreUtils.isAddressNotMoneroAddressAndThusProbablyOAAddress(address) == false {
			self.cached_OAResolved_XMR_address = nil // if new one is not OA addr, clear cached OA-resolved info
		} else {
			self.cached_OAResolved_XMR_address = cached_OAResolved_XMR_address
		}
		self.payment_id = payment_id
		let err_str = self.saveToDisk()
		if err_str != nil {
			return err_str
		}
		DispatchQueue.main.async
		{ [unowned self] in
			self._atRuntime_contactInfoUpdated()
		}
		return nil
	}
	func SetValuesAndSave_fromOAResolve(
		payment_id: MoneroPaymentID,
		cached_OAResolved_XMR_address: MoneroAddress
	) -> String? // err_str -- maybe port to 'throws'
	{
		self.payment_id = payment_id
		self.cached_OAResolved_XMR_address = cached_OAResolved_XMR_address
		let err_str = self.saveToDisk()
		if err_str != nil {
			return err_str
		}
		DispatchQueue.main.async
		{ [unowned self] in
			self._atRuntime_contactInfoUpdated()
		}
		return nil
	}
	//
	// Delegation - Internal - Data value property update events
	func _atRuntime_contactInfoUpdated()
	{
		NotificationCenter.default.post(
			name: Notification.Name(NotificationNames.infoUpdated.rawValue),
			object: self
		)
	}
}
