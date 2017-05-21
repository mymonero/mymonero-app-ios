//
//  Wallet.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
//
struct WalletInsertDescription: ListedObjectInsertDescription
{
	var walletLabel: String
	// and
	var generateNewWallet: Bool? // default to no
	// or
	var mnemonicString: MoneroSeedAsMnemonic?
	// or
	var address: MoneroAddress?
	var privateKeys: MoneroKeyDuo?
}
//
class Wallet: PersistableObject, ListedObject
{
	// Properties
	var walletLabel: String!
	//
	// 'Protocols' - Persistable Object
	override func dictRepresentation() -> [String: Any]
	{
		var dict = super.dictRepresentation() // since it already has _id on it
		dict["walletLabel"] = self.walletLabel
		// Note: Override this method and add data you would like encrypted
		return dict
	}
	//
	// Protocols - Listed Object
	static func new(withInsertDescription description: ListedObjectInsertDescription) -> ListedObject
	{
		return self.init(withInsertDescription: description)
	}
	//
	// Lifecycle - Init
	required init(withInsertDescription description: ListedObjectInsertDescription)
	{
		super.init()
		self.setupAndInsert(withInsertDescription: description as! WalletInsertDescription)
	}
	func setupAndInsert(withInsertDescription description: WalletInsertDescription)
	{ // TODO: need way to pass error back to new.(withInsertDescription)
		self._id = DocumentPersister.new_DocumentId() // generating a new UUID
		self.walletLabel = description.walletLabel
		//
		let generateNewWallet = description.generateNewWallet != nil ? description.generateNewWallet! : false
		if generateNewWallet == true {
			// TODO: continue, then save
			return
		}
		// look for mnemonic, or addr + keys
		if let mnemonicString = description.mnemonicString {
			NSLog("Setting up wallet with mnemonicString \(mnemonicString)")
			// TODO: continue, then save
			return
		}
		let address = description.address! // just going to assume it exists by this point
		let privateKeys = description.privateKeys!
		NSLog("Setting up wallet with address \(address) and privateKeys \(privateKeys)")
		// TODO: continue, then save
	}
	//
	required init(withDictRepresentation dictRepresentation: [String: Any])
	{
		super.init(withDictRepresentation: dictRepresentation) // this will set _id for us
		// TODO: hydrate with doc contents, converting where necessary
		NSLog("hydrate with \(dictRepresentation)")
	}
}
