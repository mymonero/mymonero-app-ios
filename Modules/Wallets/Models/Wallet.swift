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
	// all of:
	var walletLabel: String
	//
	// and either:
	var generateNewWallet: Bool? // default to no
	// or,
	var mnemonicString: MoneroSeedAsMnemonic?
	// or,
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
	// Protocols - Listed Object - Generating a new document
	static func new(
		withInsertDescription description: ListedObjectInsertDescription
	) -> (
		err_str: String?,
		listedObject: ListedObject?
	)
	{
		do {
			guard let listedObject = try self.init(withInsertDescription: description) else {
				return ("Unknown error while adding wallet", nil) // would be a code fault
			}
			return (nil, listedObject)
		} catch let e {
			return (e.localizedDescription, nil)
		}
	}
	//
	// Lifecycle - Init - Generating a new wallet
	required init?(withInsertDescription description: ListedObjectInsertDescription) throws
	{
		super.init()
		try self.setupAndInsert(withInsertDescription: description as! WalletInsertDescription)
	}
	func setupAndInsert(withInsertDescription description: WalletInsertDescription) throws
	{ // TODO: need way to pass error back to new.(withInsertDescription)
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
	// Lifecycle - Init - Existing (already saved) document
	required init?(withDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	{
		try super.init(withDictRepresentation: dictRepresentation) // this will set _id for us
		// TODO: hydrate with doc contents, converting where necessary
		NSLog("hydrate with \(dictRepresentation)")
	}
}
