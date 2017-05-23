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
class Wallet: PersistableObject, ListedObject
{
	//
	// Types
	enum Currency: String
	{
		case Monero = "xmr"
		//
		func jsonRepresentation() -> String
		{
			return self.rawValue
		}
		static func fromJSONRepresentation(jsonRepresentation: String) -> Currency
		{
			return self.init(rawValue: jsonRepresentation)!
		}
		func humanReadable(currency: Currency) -> String
		{
			switch currency {
				case .Monero:
					return "Monero"
			}
		}
	}
	enum DictKeys: String
	{
		case currency = "currency"
		case walletLabel = "walletLabel"
		case mnemonic_wordsetName = "mnemonic_wordsetName"
	}
	//
	// Properties - Values
	var currency: Currency!
	var walletLabel: String!
	var mnemonic_wordsetName: MoneroMnemonicWordsetName!
	var generatedOnInit_walletDescription: MoneroWalletDescription?
	//
	// Properties - Boolean State
	var isBooted = false
	var isLoggedIn = false
	var isLoggingIn = false
	//
	// 'Protocols' - Persistable Object
	override func dictRepresentation() -> [String: Any]
	{
		var dict = super.dictRepresentation() // since it already has _id on it
		dict[DictKeys.currency.rawValue] = self.currency.jsonRepresentation()
		dict[DictKeys.walletLabel.rawValue] = self.walletLabel
		//
		return dict
	}
	//
	// Lifecycle - Init - For adding wallet to app
	required init()
	{
		super.init()
	}
	convenience init?(
		ifGeneratingNewWallet_walletDescription: MoneroWalletDescription? // this is left to the consumer to generate because currently to generate it is asynchronous and that would make this init code a bit messy
	) throws
	{
		self.init()
		self.currency = .Monero // for now
		self.mnemonic_wordsetName = MoneroMnemonicWordsetName.new_withCurrentLocale()
		if ifGeneratingNewWallet_walletDescription != nil {
			self.generatedOnInit_walletDescription = ifGeneratingNewWallet_walletDescription
		}
	}
	//
	// Lifecycle - Init - Reading existing (already saved) wallet
	required init?(withDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	{
		try super.init(withDictRepresentation: dictRepresentation) // this will set _id for us
		//
		self.currency = Currency.fromJSONRepresentation(
			jsonRepresentation: dictRepresentation[DictKeys.currency.rawValue] as! String
		)
		self.walletLabel = dictRepresentation[DictKeys.walletLabel.rawValue] as! String
	}
	//
	// (Booting) Post init, pre-runtime - Imperatives
	
}
