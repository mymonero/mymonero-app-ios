//
//  Contact.swift
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
import CoreImage
import UIKit

class Contact: PersistableObject
{
	enum NotificationNames: String
	{
		case infoUpdated = "Contact_NotificationNames_infoUpdated"
		//
		var notificationName: NSNotification.Name {
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
	var payment_id: MoneroPaymentID?
	var emoji: Emoji.EmojiCharacter!
	//
	// Properties - Transient
	var cached_OAResolved_XMR_address: MoneroAddress?
	var cached_derived_integratedXMRAddress_orNilIfNotStdAddrPlusShortPid: MoneroIntegratedAddress?
	var qrCode_cgImage: CGImage!
	var cached__qrCode_image_small: UIImage!
	//
	func new__cached_derived_integratedXMRAddress_orNilIfNotStdAddrPlusShortPid() -> MoneroIntegratedAddress?
	{
		let payment_id: MoneroPaymentID? = self.payment_id
		if payment_id == nil || payment_id == "" {
			return nil // no possible derived int address
		}
		if MoneroUtils.PaymentIDs.isAValid(paymentId: payment_id!, ofVariant: .short) == false {
			return nil // must be a long payment ID
		}
		let (err_str, decodedAddress) = MyMoneroCore.shared_objCppBridge.decoded(address: self.address)
		if err_str != nil {
			return nil
		}
		let intPaymentId = decodedAddress!.intPaymentId
		if intPaymentId != nil && intPaymentId != "" {
			return nil // b/c we don't want to show a derived int addr if we already have the int addr
		}
		var address: MoneroIntegratedAddress?
		if self.hasOpenAliasAddress {
			address = self.cached_OAResolved_XMR_address!
		} else {
			address = self.address
		}
		if address == nil || address == "" {
			return nil // probably not resolved yet…… guess don't show any hypothetical derived int addr for now
		}
		//
		// now we know we have a std xmr addr and a short pid
		let integratedAddress_orNil = MyMoneroCore.shared_objCppBridge.New_IntegratedAddress(
			fromStandardAddress: address!,
			short_paymentID: payment_id!
		)
		return integratedAddress_orNil
	}
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
		self.emoji = dictRepresentation[DictKey.emoji.rawValue] as! Emoji.EmojiCharacter
		self.cached_OAResolved_XMR_address = dictRepresentation[DictKey.cached_OAResolved_XMR_address.rawValue] as? String
		//
		self.setup()
	}
	func generate_cached_derived_integratedXMRAddress_orNilIfNotStdAddrPlusShortPid()
	{
		//
		// NOTE: just going to invalidate it off the bat - too complicated otherwise
		self.cached_derived_integratedXMRAddress_orNilIfNotStdAddrPlusShortPid = nil //
		//
		let intAddr = self.new__cached_derived_integratedXMRAddress_orNilIfNotStdAddrPlusShortPid()
		self.cached_derived_integratedXMRAddress_orNilIfNotStdAddrPlusShortPid = intAddr
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
		emoji: Emoji.EmojiCharacter?,
		cached_OAResolved_XMR_address: MoneroAddress?
	) {
		self.init()
		self.fullname = fullname
		self.address = address
		self.payment_id = payment_id
		self.emoji = emoji
		self.cached_OAResolved_XMR_address = cached_OAResolved_XMR_address
		//
		self.setup()
	}
	func setup()
	{
		self.regeneratePropertiesDerivedFromAddressOrPid()
	}
	//
	// Interface - Runtime - Accessors/Properties
	func new_URI(inMode uriMode: MoneroUtils.URIs.URIMode) -> URL
	{
		// I would have created a URIs.Contacts but everything, including parsing, is the same anyway, so there wasn't a reason
		return MoneroUtils.URIs.Requests.new_URL(
			address: self.address,
			amount: nil, description: nil,
			paymentId: self.payment_id,
			message: nil, amountCurrency: nil,
			uriMode: uriMode
		)
	}
	//
	// Interface - Runtime - Accessors/Properties - Convenience
	var hasOpenAliasAddress: Bool {
		return OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(
			self.address
		)
	}
	//
	// Imperatives - Runtime - Cache generation
	func regeneratePropertiesDerivedFromAddressOrPid()
	{
		self.generate_cached_derived_integratedXMRAddress_orNilIfNotStdAddrPlusShortPid()
		//
		self.generate_qrCode_cgImage()
		self.cached__qrCode_image_small = QRCodeImages.new_qrCode_UIImage(fromCGImage: self.qrCode_cgImage, withQRSize: .small)
	}
	func generate_qrCode_cgImage()
	{
		let noSlashes_uri = self.new_URI(
			inMode: .addressAsFirstPathComponent
		)
		self.qrCode_cgImage = QRCodeImages.new_qrCode_cgImage(withContentString: noSlashes_uri.absoluteString)
	}
	//
	// Runtime - Imperatives - Update cases
	func SetValuesAndSave_fromEditAndPossibleOAResolve(
		fullname: String,
		emoji: Emoji.EmojiCharacter,
		address: String, // could be an OA address too
		payment_id: MoneroPaymentID?,
		cached_OAResolved_XMR_address: MoneroAddress?
	) -> String? { // err_str -- maybe port to 'throws'
		self.fullname = fullname
		self.emoji = emoji
		self.address = address
		if OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(address) == false {
			self.cached_OAResolved_XMR_address = nil // if new one is not OA addr, clear cached OA-resolved info
		} else {
			self.cached_OAResolved_XMR_address = cached_OAResolved_XMR_address
		}
		self.payment_id = payment_id
		//
		self.regeneratePropertiesDerivedFromAddressOrPid()
		//
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
		payment_id: MoneroPaymentID?,
		cached_OAResolved_XMR_address: MoneroAddress
	) -> String? { // err_str -- maybe port to 'throws'
		self.payment_id = payment_id
		self.cached_OAResolved_XMR_address = cached_OAResolved_XMR_address
		//
		self.regeneratePropertiesDerivedFromAddressOrPid()
		//
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
			name: NotificationNames.infoUpdated.notificationName,
			object: self
		)
	}
}
