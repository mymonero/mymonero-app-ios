//
//  Wallet.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
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
import UIKit // for UIApplication idle timer
//
class Wallet: PersistableObject
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
		static func new(from_jsonRepresentation jsonRepresentation: String) -> Currency
		{
			return self.init(rawValue: jsonRepresentation)!
		}
		//
		var humanReadableCurrencySymbolString: String
		{
			return self.rawValue.uppercased()
		}
		static func humanReadableString(currency: Currency) -> String
		{
			switch currency {
				case .Monero:
					return "Monero"
			}
		}
		func humanReadableString() -> String
		{
			return Currency.humanReadableString(currency: self)
		}
	}
	enum SwatchColor: String
	{
		case darkGrey = "#6B696B"
		case lightGrey = "#CFCECF"
		case teal = "#00F4CD"
		case purple = "#D975E1"
		case salmon = "#F97777"
		case orange = "#EB8316"
		case yellow = "#EACF12"
		case blue = "#00C6FF"
		//
		static func allOrdered() -> [SwatchColor]
		{
			let order: [SwatchColor] =
			[
				.darkGrey,
				.lightGrey,
				.teal,
				.purple,
				.salmon,
				.orange,
				.yellow,
				.blue
			]
			return order
		}
		//
		var colorName: String {
			switch self {
			case .darkGrey:
				return "darkGrey"
			case .lightGrey:
				return "lightGrey"
			case .teal:
				return "teal"
			case .purple:
				return "purple"
			case .salmon:
				return "salmon"
			case .orange:
				return "orange"
			case .yellow:
				return "yellow"
			case .blue:
				return "blue"
			}
		}
		var rgbIntValue: Int {
			switch self {
				case .darkGrey:
					return 0x6B696B
				case .lightGrey:
					return 0xCFCECF
				case .teal:
					return 0x00F4CD
				case .purple:
					return 0xD975E1
				case .salmon:
					return 0xF97777
				case .orange:
					return 0xEB8316
				case .yellow:
					return 0xEACF12
				case .blue:
					return 0x00C6FF
			}
		}
		func colorHexString_withoutPoundPrefix() -> String {
			let hexColorString = self.colorHexString()
			let hexColorString_sansPound = (hexColorString as NSString).substring(from: 1) // strip "#" sign
			
			return hexColorString_sansPound
		}
		func colorHexString() -> String { return self.rawValue }
		func jsonRepresentation() -> String { return self.rawValue }
		static func new(from_jsonRepresentation jsonRepresentation: String) -> SwatchColor
		{
			return self.init(rawValue: jsonRepresentation)!
		}
		//
		var isADarkColor: Bool
		{
			switch self {
				case .darkGrey:
					return true
				default:
					return false
				}
		}
	}
	enum NotificationNames: String
	{
		case labelChanged		= "Wallet_NotificationNames_labelChanged"
		case swatchColorChanged	= "Wallet_NotificationNames_swatchColorChanged"
		case balanceChanged		= "Wallet_NotificationNames_balanceChanged"
		//
		case spentOutputsChanged = "Wallet_NotificationNames_spentOutputsChanged"
		case heightsUpdated		 = "Wallet_NotificationNames_heightsUpdated"
		case transactionsChanged = "Wallet_NotificationNames_transactionsChanged"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	struct RebootReconstitutionDescription
	{
		//		var currency: Currency!
		var walletLabel: String
		var swatchColor: Wallet.SwatchColor
		//
		var mnemonic_wordsetName: MoneroMnemonicWordsetName? // be sure this is supplied if account_seed is not nil nil but mnemonicSeed is nil so mnemonicString can be rederived
		var mnemonicString: MoneroSeedAsMnemonic?
		var account_seed: MoneroSeed?
		var private_keys: MoneroKeyDuo!
		var public_address: MoneroAddress!
		//
		static func new(fromWallet wallet: Wallet) -> RebootReconstitutionDescription
		{
			return RebootReconstitutionDescription(
				walletLabel: wallet.walletLabel,
				swatchColor: wallet.swatchColor,
				mnemonic_wordsetName: wallet.mnemonic_wordsetName,
				//
				mnemonicString: wallet.mnemonicString,
				account_seed: wallet.account_seed,
				private_keys: wallet.private_keys,
				public_address: wallet.public_address
			)
		}
	}
	// Internal
	enum DictKey: String
	{ // (For persistence)
		// Encrypted:
		case currency = "currency"
		case walletLabel = "walletLabel"
		case swatchColorHexString = "swatchColorHexString"
		case mnemonic_wordsetName = "mnemonic_wordsetName"
		case publicAddress = "publicAddress"
		case privateKeys = "privateKeys"
		case publicKeys = "publicKeys"
		case accountSeed = "accountSeed"
		// we do not save the mnemonic-encoded seed to disk, only accountSeed
		//
		case totalReceived = "totalReceived"
		case totalSent = "totalSent"
		case lockedBalance = "lockedBalance"
		//
		case account_scanned_tx_height = "account_scanned_tx_height"
		case account_scanned_height = "account_scanned_height"
		case account_scanned_block_height = "account_scanned_block_height"
		case account_scan_start_height = "account_scan_start_height"
		case transaction_height = "transaction_height"
		case blockchain_height = "blockchain_height"
		//
		case spentOutputs = "spentOutputs"
		//
		case transactions = "transactions"

		//
		case dateThatLast_fetchedAccountInfo = "dateThatLast_fetchedAccountInfo"
		case dateThatLast_fetchedAccountTransactions = "dateThatLast_fetchedAccountTransactions"
		//
		case isLoggedIn = "isLoggedIn"
		case isInViewOnlyMode = "isInViewOnlyMode"
		case shouldDisplayImportAccountOption = "shouldDisplayImportAccountOption"
	}
	//
	//
	// Properties - Principal Persisted Values
	//
	var currency: Currency!
	var walletLabel: String!
	var swatchColor: SwatchColor!
	//
	var mnemonicString: MoneroSeedAsMnemonic?
	var mnemonic_wordsetName: MoneroMnemonicWordsetName?
	var generatedOnInit_walletDescription: MoneroWalletDescription?
	var account_seed: MoneroSeed?
	var private_keys: MoneroKeyDuo!
	var public_keys: MoneroKeyDuo!
	var public_address: MoneroAddress!
	//
	var totalReceived: MoneroAmount?
	var totalSent: MoneroAmount?
	var lockedBalance: MoneroAmount?
	//
	var account_scanned_tx_height: Int?
	var account_scanned_height: Int? // TODO: it would be good to resolve account_scanned_height vs account_scanned_tx_height
	var account_scanned_block_height: Int?
	var account_scan_start_height: Int?
	var transaction_height: Int?
	var blockchain_height: Int?
	//
	var spentOutputs: [MoneroSpentOutputDescription]?
	var transactions: [MoneroHistoricalTransactionRecord]?
	//
	var dateThatLast_fetchedAccountInfo: Date?
	var dateThatLast_fetchedAccountTransactions: Date?
	//
	// Properties - Boolean State
	// persisted
	var isLoggedIn = false
	var shouldDisplayImportAccountOption: Bool?
	var isInViewOnlyMode: Bool?
	// transient/not persisted
	var isBooted = false
	var isLoggingIn = false
	var wasInitializedWith_addrViewAndSpendKeysInsteadOfSeed: Bool?
	var isSendingFunds = false
	//
	// Properties - Objects
	var logIn_requestHandle: HostedMonero.APIClient.RequestHandle?
	var hostPollingController: Wallet_HostPollingController? // strong
	var fundsSender: HostedMonero.FundsSender?
	//
	// 'Protocols' - Persistable Object
	override func new_dictRepresentation() -> [String: Any]
	{
		var dict = super.new_dictRepresentation() // since it constructs the base object for us
		do {
			dict[DictKey.currency.rawValue] = self.currency.jsonRepresentation()
			dict[DictKey.walletLabel.rawValue] = self.walletLabel
			dict[DictKey.swatchColorHexString.rawValue] = self.swatchColor.jsonRepresentation()
			dict[DictKey.publicAddress.rawValue] = self.public_address
			if let value = self.account_seed, value != "" {
				dict[DictKey.accountSeed.rawValue] = value
				assert(value != "")
			} else {
				DDLog.Warn("Wallets", "Saving w/o acct seed")
			}
			if let value = self.mnemonic_wordsetName {
				dict[DictKey.mnemonic_wordsetName.rawValue] = value.jsonRepresentation
			}
			dict[DictKey.publicKeys.rawValue] = self.public_keys.jsonRepresentation
			dict[DictKey.privateKeys.rawValue] = self.private_keys.jsonRepresentation
			if let value = self.shouldDisplayImportAccountOption {
				dict[DictKey.shouldDisplayImportAccountOption.rawValue] = value
			}
			dict[DictKey.isLoggedIn.rawValue] = self.isLoggedIn
			if let isInViewOnlyMode = self.isInViewOnlyMode {
				dict[DictKey.isInViewOnlyMode.rawValue] = isInViewOnlyMode
			}
			//
			if let date = self.dateThatLast_fetchedAccountInfo {
				dict[DictKey.dateThatLast_fetchedAccountInfo.rawValue] = date.timeIntervalSince1970
			}
			if let date = self.dateThatLast_fetchedAccountTransactions {
				dict[DictKey.dateThatLast_fetchedAccountTransactions.rawValue] = date.timeIntervalSince1970
			}
			//
			if let value = self.totalReceived {
				dict[DictKey.totalReceived.rawValue] = String(value, radix: 10)
			}
			if let value = self.totalSent {
				dict[DictKey.totalSent.rawValue] = String(value, radix: 10)
			}
			if let value = self.lockedBalance {
				dict[DictKey.lockedBalance.rawValue] = String(value, radix: 10)
			}
			//
			if let array = self.spentOutputs {
				dict[DictKey.spentOutputs.rawValue] = MoneroSpentOutputDescription.newSerializedDictRepresentation(
					withArray: array
				)
			}
			//
			dict[DictKey.account_scanned_tx_height.rawValue] = self.account_scanned_tx_height
			dict[DictKey.account_scanned_height.rawValue] = self.account_scanned_height
			dict[DictKey.account_scanned_block_height.rawValue] = self.account_scanned_block_height
			dict[DictKey.account_scan_start_height.rawValue] = self.account_scan_start_height
			dict[DictKey.transaction_height.rawValue] = self.transaction_height
			dict[DictKey.blockchain_height.rawValue] = self.blockchain_height
			//
			if let array = self.transactions {
				dict[DictKey.transactions.rawValue] = MoneroHistoricalTransactionRecord.newSerializedDictRepresentation(
					withArray: array
				)
			}
		}
		return dict
	}
	//
	//
	// Lifecycle - Init - Reading existing (already saved) wallet
	//
	override func collectionName() -> String
	{
		return "Wallet"
	}
	required init?(withPlaintextDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	{
		try super.init(withPlaintextDictRepresentation: dictRepresentation) // this will set _id for us
		//
		self.isLoggedIn = dictRepresentation[DictKey.isLoggedIn.rawValue] as! Bool
		self.isInViewOnlyMode = dictRepresentation[DictKey.isInViewOnlyMode.rawValue] as? Bool
		self.shouldDisplayImportAccountOption = dictRepresentation[DictKey.shouldDisplayImportAccountOption.rawValue] as? Bool
		if let date = dictRepresentation[DictKey.dateThatLast_fetchedAccountInfo.rawValue] {
			guard let timeInterval = date as? TimeInterval else {
				self.didFailToInitialize_flag = true
				assert(false, "not a TimeInterval")
				return nil
			}
			self.dateThatLast_fetchedAccountInfo = Date(timeIntervalSince1970: timeInterval)
		}
		if let date = dictRepresentation[DictKey.dateThatLast_fetchedAccountInfo.rawValue] {
			guard let timeInterval = date as? TimeInterval else {
				self.didFailToInitialize_flag = true
				assert(false, "not a TimeInterval")
				return nil
			}
			self.dateThatLast_fetchedAccountInfo = Date(timeIntervalSince1970: timeInterval)
		}
		//
		self.currency = Currency.new(
			from_jsonRepresentation: dictRepresentation[DictKey.currency.rawValue] as! String
		)
		self.walletLabel = dictRepresentation[DictKey.walletLabel.rawValue] as! String
		self.swatchColor = SwatchColor.new(
			from_jsonRepresentation: dictRepresentation[DictKey.swatchColorHexString.rawValue] as! String
		)
		// Not going to check whether the acct seed is nil/'' here because if the wallet was
		// imported with public addr, view key, and spend key only rather than seed/mnemonic, we
		// cannot obtain the seed.
		self.mnemonic_wordsetName = dictRepresentation[DictKey.mnemonic_wordsetName.rawValue] as? MoneroMnemonicWordsetName
		self.public_address = dictRepresentation[DictKey.publicAddress.rawValue] as! MoneroAddress
		self.public_keys = MoneroKeyDuo.new(
			fromJSONRepresentation: dictRepresentation[DictKey.publicKeys.rawValue] as! [String: Any]
		)
		self.account_seed = dictRepresentation[DictKey.accountSeed.rawValue] as? MoneroSeed
		if let string = dictRepresentation[DictKey.mnemonic_wordsetName.rawValue] {
			self.mnemonic_wordsetName = MoneroMnemonicWordsetName.new(fromJSONRepresentation: string as! String)
		}
		self.private_keys = MoneroKeyDuo.new(
			fromJSONRepresentation: dictRepresentation[DictKey.privateKeys.rawValue] as! [String: Any]
		)
		//
		if let string = dictRepresentation[DictKey.totalReceived.rawValue] {
			self.totalReceived = MoneroAmount(string as! String)
		}
		if let string = dictRepresentation[DictKey.totalSent.rawValue] {
			self.totalSent = MoneroAmount(string as! String)
		}
		if let string = dictRepresentation[DictKey.lockedBalance.rawValue] {
			self.lockedBalance = MoneroAmount(string as! String)
		}
		//
		self.account_scanned_tx_height = dictRepresentation[DictKey.account_scanned_tx_height.rawValue] as? Int
		self.account_scanned_height = dictRepresentation[DictKey.account_scanned_height.rawValue] as? Int
		self.account_scanned_block_height = dictRepresentation[DictKey.account_scanned_block_height.rawValue] as? Int
		self.account_scan_start_height = dictRepresentation[DictKey.account_scan_start_height.rawValue] as? Int
		self.transaction_height = dictRepresentation[DictKey.transaction_height.rawValue] as? Int
		self.blockchain_height = dictRepresentation[DictKey.blockchain_height.rawValue] as? Int
		//
		if let jsonRepresentations = dictRepresentation[DictKey.spentOutputs.rawValue] {
			self.spentOutputs = MoneroSpentOutputDescription.newArray(
				fromJSONRepresentations: jsonRepresentations as! [[String: Any]]
			)
		}
		if let jsonRepresentations = dictRepresentation[DictKey.transactions.rawValue] {
			self.transactions = MoneroHistoricalTransactionRecord.newArray(
				fromJSONRepresentations: jsonRepresentations as! [[String: Any]],
				wallet__blockchainHeight: self.blockchain_height!
			)
		}
		//
		if let timeIntervalSince1970 = dictRepresentation[DictKey.dateThatLast_fetchedAccountInfo.rawValue] {
			self.dateThatLast_fetchedAccountInfo = Date(timeIntervalSince1970: timeIntervalSince1970 as! TimeInterval)
		}
		if let timeIntervalSince1970 = dictRepresentation[DictKey.dateThatLast_fetchedAccountTransactions.rawValue] {
			self.dateThatLast_fetchedAccountTransactions = Date(timeIntervalSince1970: timeIntervalSince1970 as! TimeInterval)
		}
	}
	//
	//
	// Lifecycle - Init - For adding wallet to app
	//
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
	// Lifecycle - Deinit
	override func teardown()
	{
		super.teardown()
		//
		self.hostPollingController = nil // stop requests
		//
		self.logIn_requestHandle?.cancel() // in case wallet is being rebooted on API address change via settings
		self.logIn_requestHandle = nil
		//
		if self.isSendingFunds { // just in case - i.e. on teardown while sending but user sends the app to the background
			UserIdle.shared.reEnable_userIdle()
			ScreenSleep.reEnable_screenSleep()
		}
		self.fundsSender?.cancel() // to get the network request cancel immediately
		self.fundsSender = nil
		//
		if self.public_address != nil { // remember the wallet info may not have been successfully generated yet
			// And now that network requests have been terminated (with the exception, presently, of any SendFunds), we can delete the key image cache since no more will hopefully get added..
			MyMoneroCore.shared.DeleteManagedKeyImages(forWalletWithAddress: self.public_address,
			{ (err_str) in
				// TODO: Unhandled - see note in DeleteManagedKeyImages()
			})
		}
	}
	//
	//
	// Post init, pre-runtime - Imperatives - Booting - When creating or adding a wallet
	//
	func Boot_byLoggingIn_givenNewlyCreatedWallet(
		walletLabel: String,
		swatchColor: SwatchColor,
		_ fn: @escaping (_ err_str: String?) -> Void
	) -> Void
	{
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		//
		assert(self.generatedOnInit_walletDescription != nil, "nil generatedOnInit_walletDescription")
		let generatedOnInit_walletDescription = self.generatedOnInit_walletDescription!
		self._boot_byLoggingIn(
			address: generatedOnInit_walletDescription.publicAddress,
			view_key__private: generatedOnInit_walletDescription.privateKeys.view,
			spend_key_orNilForViewOnly: generatedOnInit_walletDescription.privateKeys.spend,
			seed_orNil: generatedOnInit_walletDescription.seed,
			wasAGeneratedWallet: true, // in this case
			persistEvenIfLoginFailed_forServerChange: false, // always, in this case
			fn
		)
	}
	func Boot_byLoggingIn_existingWallet_withMnemonic(
		walletLabel: String,
		swatchColor: SwatchColor,
		mnemonicString: MoneroSeedAsMnemonic,
		persistEvenIfLoginFailed_forServerChange: Bool,
		_ fn: @escaping (_ err_str: String?) -> Void
	) -> Void {
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		//
		let (wordsetName__err_str, wordsetName) = MoneroUtils.Mnemonics.wordsetName(accordingToMnemonicString: mnemonicString)
		if wordsetName__err_str != nil {
			DDLog.Error("Wallets", "Error while detecting mnemonic wordset from mnemonic string: \(wordsetName__err_str.debugDescription)")
			self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: wordsetName__err_str)
			return
		}
		self.mnemonicString = mnemonicString // even though we re-derive the mnemonicString on success, this is being set here so as to prevent the bug where it gets lost when changing the API server and a reboot w/mnemonicSeed occurs
		self.mnemonic_wordsetName = wordsetName!
		//
		MyMoneroCore.shared.WalletDescriptionFromMnemonicSeed(
			mnemonicString,
			self.mnemonic_wordsetName!,
			{ [unowned self] (err_str, walletDescription) in
				if err_str != nil {
					self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err_str!)
					return
				}
				assert(walletDescription!.seed != "")
				self._boot_byLoggingIn(
					address: walletDescription!.publicAddress,
					view_key__private: walletDescription!.privateKeys.view,
					spend_key_orNilForViewOnly: walletDescription!.privateKeys.spend,
					seed_orNil: walletDescription!.seed,
					wasAGeneratedWallet: false,
					persistEvenIfLoginFailed_forServerChange: persistEvenIfLoginFailed_forServerChange,
					fn
				)
			}
		)
	}
	func Boot_byLoggingIn_existingWallet_withAddressAndKeys(
		walletLabel: String,
		swatchColor: SwatchColor,
		address: MoneroAddress,
		privateKeys: MoneroKeyDuo,
		persistEvenIfLoginFailed_forServerChange: Bool,
		_ fn: @escaping (_ err_str: String?) -> Void
	) {
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		//
		self._boot_byLoggingIn(
			address: address,
			view_key__private: privateKeys.view,
			spend_key_orNilForViewOnly: privateKeys.spend,
			seed_orNil: nil,
			wasAGeneratedWallet: false,
			persistEvenIfLoginFailed_forServerChange: persistEvenIfLoginFailed_forServerChange,
			fn
		)
	}
	func Boot_byLoggingIn_existingWallet(
		reconstitutionDescription: RebootReconstitutionDescription,
		persistEvenIfLoginFailed_forServerChange: Bool = true,
		_ fn: @escaping (_ err_str: String?) -> Void
	) {
		func _proceedTo_login(mnemonicString: MoneroSeedAsMnemonic?)
		{
			if mnemonicString != nil {
				self.Boot_byLoggingIn_existingWallet_withMnemonic(
					walletLabel: reconstitutionDescription.walletLabel,
					swatchColor: reconstitutionDescription.swatchColor,
					mnemonicString: mnemonicString!,
					persistEvenIfLoginFailed_forServerChange: persistEvenIfLoginFailed_forServerChange,
					fn
				)
			} else {
				assert(self.account_seed == nil)
				//
				self.Boot_byLoggingIn_existingWallet_withAddressAndKeys(
					walletLabel: reconstitutionDescription.walletLabel,
					swatchColor: reconstitutionDescription.swatchColor,
					address: reconstitutionDescription.public_address,
					privateKeys: reconstitutionDescription.private_keys,
					persistEvenIfLoginFailed_forServerChange: persistEvenIfLoginFailed_forServerChange,
					fn
				)
			}
		}
		if reconstitutionDescription.mnemonicString == nil {
			if reconstitutionDescription.account_seed != nil {
				assert(reconstitutionDescription.mnemonic_wordsetName != nil)
				// re-derive mnemonic string from account seed so we don't lose mnemonicSeed 
				MyMoneroCore.shared.MnemonicStringFromSeed(
					reconstitutionDescription.account_seed!,
					reconstitutionDescription.mnemonic_wordsetName!
				)
				{ (err_str, seedAsMnemonic) in
					if let err_str = err_str {
						fn(err_str)
						return
					}
					_proceedTo_login(mnemonicString: seedAsMnemonic!)
				}
				return
			}
		}
		_proceedTo_login(
			mnemonicString: reconstitutionDescription.mnemonicString // might be nil
		)
	}
	//
	//
	// Interface - Runtime - Accessors/Properties
	//
	var hasEverFetched_accountInfo: Bool
	{
		return self.dateThatLast_fetchedAccountInfo != nil
	}
	var hasEverFetched_transactions: Bool
	{
		return self.dateThatLast_fetchedAccountTransactions != nil
	}
	var isAccountScannerCatchingUp: Bool
	{
		if self.didFailToInitialize_flag == true || self.didFailToBoot_flag == true {
			assert(false, "not strictly illegal but accessing isAccountScannerCatching up before logged in")
			return false
		}
		if self.blockchain_height == nil || self.blockchain_height == 0 {
			DDLog.Warn("Wallets", ".isScannerCatchingUp called while nil/0 blockchain_height")
			return true
		}
		if self.account_scanned_block_height == nil || self.account_scanned_block_height == 0  {
			DDLog.Warn("Wallets", ".isScannerCatchingUp called while nil/0 account_scanned_block_height")
			return true
		}
		let nBlocksBehind = self.blockchain_height! - self.account_scanned_block_height!
		if nBlocksBehind >= 10 { // grace interval, i believe
			return true
		} else if nBlocksBehind < 0 {
			DDLog.Warn("Wallets", "nBlocksBehind < 0")
			return false
		}
		return false
	}
	var nBlocksBehind: Int
	{
		if self.blockchain_height == nil || self.blockchain_height == 0 {
			DDLog.Warn("Wallets", ".nBlocksBehind called while nil/0 blockchain_height")
			return 0
		}
		if self.account_scanned_block_height == nil || self.account_scanned_block_height == 0  {
			DDLog.Warn("Wallets", ".nBlocksBehind called while nil/0 account_scanned_block_height")
			return 0
		}
		let nBlocksBehind = self.blockchain_height! - self.account_scanned_block_height!
		return nBlocksBehind
	}
	var catchingUpPercentageFloat: Double // btn 0 and 1.0
	{
		if self.account_scanned_height == nil || self.account_scanned_height == 0 {
			DDLog.Warn("Wallets", ".catchingUpPercentageFloat accessed while nil/0 self.account_scanned_height. Bailing.")
			return 0
		}
		if self.transaction_height == nil || self.transaction_height == 0 {
			DDLog.Warn("Wallets", ".catchingUpPercentageFloat accessed while nil/0 self.transaction_height. Bailing.")
			return 0
		}
		let pct: Double = Double(self.account_scanned_height!) / Double(self.transaction_height!)
		DDLog.Info("Wallets", "CatchingUpPercentageFloat \(self.account_scanned_height!)/\(self.transaction_height!) = \(pct)%")
		return pct
	}
	//
	var balanceAmount: MoneroAmount {
		let balanceAmount = (self.totalReceived ?? MoneroAmount(0)) - (self.totalSent ?? MoneroAmount(0))
		//
		return balanceAmount
	}
	var lockedBalanceAmount: MoneroAmount {
		return (self.lockedBalance ?? MoneroAmount(0))
	}
	var hasLockedFunds: Bool {
		if self.lockedBalance == nil {
			return false
		}
		if self.lockedBalance == MoneroAmount(0) {
			return false
		}
		return true
	}
	//
	// Runtime - Imperatives - Public - Booting - Reading saved wallets
	func Boot_havingLoadedDecryptedExistingInitDoc(
		_ fn: @escaping (_ err_str: String?) -> Void
	)
	{ // nothing to do here as we assume validation done on init
		self._trampolineFor_successfullyBooted(fn)
	}
	//
	// Runtime - Imperatives - Private - Booting
	func _setStateThatFailedToBoot(
		withErrStr err_str: String?
	)
	{
		self.didFailToBoot_flag = true
		self.didFailToBoot_errStr = err_str
	}
	func __trampolineFor_failedToBootWith_fnAndErrStr(
		fn: (_ err_str: String?) -> Void,
		err_str: String?
	)
	{
		self._setStateThatFailedToBoot(withErrStr: err_str)
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: PersistableObject.NotificationNames.failedToBoot.notificationName, object: self, userInfo: nil)
		}
		fn(err_str)
	}
	func _trampolineFor_successfullyBooted(
		_ fn: @escaping (_ err_str: String?) -> Void
	)
	{
		func __proceed_havingActuallyBooted()
		{
//			DDLog.Done("Wallets", "Successfully booted \(self)")
			self.isBooted = true
			DispatchQueue.main.async
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				thisSelf._atRuntime_setup_hostPollingController() // instantiate (and kick off) polling controller
				//
				NotificationCenter.default.post(name: PersistableObject.NotificationNames.booted.notificationName, object: self, userInfo: nil)
			}
			fn(nil)
		}
		if self.account_seed == nil || self.account_seed! == "" {
			DDLog.Warn("Wallets", "Wallet initialized without an account_seed.")
			self.wasInitializedWith_addrViewAndSpendKeysInsteadOfSeed = true
			__proceed_havingActuallyBooted()
			//
			return
		}
		// re-derive mnemonic string from account seed
		MyMoneroCore.shared.MnemonicStringFromSeed(
			self.account_seed!,
			self.mnemonic_wordsetName!
		)
		{ [weak self] (err_str, seedAsMnemonic) in
			guard let thisSelf = self else {
				return
			}
			if let err_str = err_str {
				thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err_str)
				return
			}
			if thisSelf.mnemonicString != nil {
				if thisSelf.mnemonicString != seedAsMnemonic! { // would be rather odd
					assert(false, "Different mnemonicString derived from accountSeed than was entered for login")
					thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: "Mnemonic seed mismatch")
					return
				}
			} else {
				thisSelf.mnemonicString = seedAsMnemonic!
			}
			__proceed_havingActuallyBooted()
		}
	}
	func _atRuntime_setup_hostPollingController()
	{
		self.hostPollingController = Wallet_HostPollingController(wallet: self)
	}
	func _boot_byLoggingIn(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key_orNilForViewOnly: MoneroKey?,
		seed_orNil: MoneroSeed?,
		wasAGeneratedWallet: Bool,
		persistEvenIfLoginFailed_forServerChange: Bool,
		_ fn: @escaping (_ err_str: String?) -> Void
	)
	{
		self.isLoggingIn = true
		//
		MyMoneroCore.shared.New_VerifiedComponentsForLogIn(
			address,
			view_key__private,
			spend_key_orNilForViewOnly: spend_key_orNilForViewOnly,
			seed_orNil: seed_orNil,
			wasAGeneratedWallet: wasAGeneratedWallet
		) { [unowned self] (
			err_str,
			verifiedComponentsForLogIn
		) in
			if let err_str = err_str {
				if persistEvenIfLoginFailed_forServerChange == true {
					assert(false, "Only expecting already-persisted wallets to have had persistEvenIfLoginFailed_forServerChange=true") // yet components are now invalid…?
				}
				self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err_str)
				return
			}
			assert(seed_orNil == nil || seed_orNil != "") // not "" if not nil - so we can just check nilness
			if seed_orNil != nil { // only if user entered a seed, rather than addr+keys
				assert(verifiedComponentsForLogIn!.seed != "")
			}
			//
			// record these properties regardless of whether we are about to error on login
			self.public_address = verifiedComponentsForLogIn!.publicAddress
			self.account_seed = verifiedComponentsForLogIn!.seed
			self.public_keys = verifiedComponentsForLogIn!.publicKeys
			self.private_keys = verifiedComponentsForLogIn!.privateKeys
			self.isInViewOnlyMode = verifiedComponentsForLogIn!.isInViewOnlyMode
			//
			self.logIn_requestHandle = HostedMonero.APIClient.shared.LogIn(
				address: address,
				view_key__private: view_key__private,
				{ [weak self] (login__err_str, isANewAddressToServer) in
					guard let thisSelf = self else {
						return // already dealloc'd
					}
					//
					thisSelf.isLoggingIn = false
					thisSelf.isLoggedIn = login__err_str == nil // supporting shouldExitOnLoginError=false for wallet reboot
					//
					thisSelf.shouldDisplayImportAccountOption = wasAGeneratedWallet == false && isANewAddressToServer == true && thisSelf.isLoggedIn/*supporting shouldExitOnLoginError=false*/
					//
					let shouldExitOnLoginError = persistEvenIfLoginFailed_forServerChange == false
					if login__err_str != nil {
						if shouldExitOnLoginError == true {
							thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr(
								fn: fn,
								err_str: login__err_str
							)
							return
						} else {
							// this allows us to continue with the above-set login info to call 'saveToDisk()' when this call to log in is coming from a wallet reboot. reason is that we expect all such wallets to be valid monero wallets if they are able to have been rebooted.
						}
					}
					//
					let saveToDisk__err_str = thisSelf.saveToDisk()
					if saveToDisk__err_str != nil {
						thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr(
							fn: fn,
							err_str: saveToDisk__err_str
						)
						return
					}
					if shouldExitOnLoginError == false && login__err_str != nil {
						// if we are attempting to re-boot the wallet, but login failed
						thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr( // i.e. leave the wallet in the 'errored'/'failed to boot' state even though we saved
							fn: fn,
							err_str: login__err_str
						)
					} else { // it's actually a success
						thisSelf._trampolineFor_successfullyBooted(fn)
					}
				}
			)
		}
	}
	//
	//
	// Runtime (Booted) - Imperatives - Updates
	//
	func SetValuesAndSave(
		walletLabel: String,
		swatchColor: SwatchColor
	) -> String? // err_str -- maybe port to 'throws'
	{
		let isChanging__walletLabel = self.walletLabel != walletLabel
		let isChanging__swatchColor = self.swatchColor != swatchColor
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		let err_str = self.saveToDisk()
		if err_str != nil {
			return err_str
		}
		DispatchQueue.main.async
		{ [unowned self] in
			if isChanging__walletLabel {
				NotificationCenter.default.post(name: NotificationNames.labelChanged.notificationName, object: self)
			}
			if isChanging__swatchColor {
				NotificationCenter.default.post(name: NotificationNames.swatchColorChanged.notificationName, object: self)
			}
		}
		return nil
	}
	//
	//
	// Runtime (Booted) - Imperatives - Sending Funds
	//
	func sendFunds(
		target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
		amount: HumanUnderstandableCurrencyAmountDouble, // human-understandable number, e.g. input 0.5 for 0.5 XMR
		payment_id: MoneroPaymentID?,
		priority: MoneroTransferSimplifiedPriority,
		success_fn: @escaping (
			_ tx_hash: MoneroTransactionHash,
			_ tx_fee: MoneroAmount
		) -> Void,
		failWithErr_fn: @escaping (
			_ err_str: String
		) -> Void
	) {
		if self.shouldDisplayImportAccountOption != nil && self.shouldDisplayImportAccountOption! {
			failWithErr_fn(NSLocalizedString("This wallet must first be imported.", comment: ""))
			return
		}
		func __isLocked() -> Bool { return self.isSendingFunds }
		if __isLocked() {
			failWithErr_fn(NSLocalizedString("Currently sending funds. Please try again when complete.", comment: ""))
			return // TODO nil
		}
		//
		self.__lock_sending()
		assert(self.fundsSender == nil)
		let fundsSender = HostedMonero.FundsSender(
			target_address: target_address,
			amount: amount,
			wallet__public_address: self.public_address,
			wallet__private_keys: self.private_keys,
			wallet__public_keys: self.public_keys,
			payment_id: payment_id,
			priority: priority
		)
		fundsSender.success_fn =
		{ [weak self] (tx_hash, tx_fee) in
			guard let thisSelf = self else {
				return
			}
			thisSelf.__unlock_sending()
			success_fn(tx_hash, tx_fee)
		}
		fundsSender.failWithErr_fn =
		{ [weak self] err_str in
			guard let thisSelf = self else {
				return
			}
			thisSelf.__unlock_sending()
			failWithErr_fn(err_str)
		}
		self.fundsSender = fundsSender
		fundsSender.send() // kick off; after having set property
		//
		return
	}
	func __lock_sending()
	{
		self.isSendingFunds = true
		//
		UserIdle.shared.temporarilyDisable_userIdle()
		ScreenSleep.temporarilyDisable_screenSleep()
	}
	func __unlock_sending()
	{
		self.isSendingFunds = false
		self.fundsSender = nil // can assume if we're unlocking that this will always be nil… but the flip side of doing this here alone is that we must ensure we always call __unlock() when we need to nil fundsSender()
		//
		UserIdle.shared.reEnable_userIdle()
		ScreenSleep.reEnable_screenSleep()
	}
	//
	//
	// HostPollingController - Delegation / Protocol
	// 
	func _HostPollingController_didFetch_addressInfo(
		_ parsedResult: HostedMonero.ParsedResult_AddressInfo
	) -> Void {
		//
		let xmrToCcyRatesByCcy = parsedResult.xmrToCcyRatesByCcy
		DispatchQueue.main.async { // just to let wallet stuff finish first
			CcyConversionRates.Controller.shared.set_xmrToCcyRatesByCcy(
				xmrToCcyRatesByCcy
			)
		}
		//
		let existing_totalReceived = self.totalReceived
		let existing_totalSent = self.totalSent
		let existing_lockedBalance = self.lockedBalance
		let didActuallyChange_accountBalance = existing_totalReceived == nil || parsedResult.totalReceived != existing_totalReceived
			|| existing_totalSent == nil || parsedResult.totalSent != existing_totalSent
			|| existing_lockedBalance == nil || parsedResult.lockedBalance != existing_lockedBalance
		self.totalReceived = parsedResult.totalReceived
		self.totalSent = parsedResult.totalSent
		self.lockedBalance = parsedResult.lockedBalance
		//
		let existing_spentOutputs = self.spentOutputs
		let didActuallyChange_spentOutputs = existing_spentOutputs == nil || (parsedResult.spentOutputs != existing_spentOutputs!)
		self.spentOutputs = parsedResult.spentOutputs
		//
		let didActuallyChange_heights =
			(self.account_scanned_tx_height == nil || self.account_scanned_tx_height != parsedResult.account_scanned_tx_height)
			|| (self.account_scanned_block_height == nil || self.account_scanned_block_height != parsedResult.account_scanned_block_height)
			|| (self.account_scan_start_height == nil || self.account_scan_start_height != parsedResult.account_scan_start_height)
			|| (self.transaction_height == nil || self.transaction_height != parsedResult.transaction_height)
			|| (self.blockchain_height == nil || self.blockchain_height != parsedResult.blockchain_height)
		self.account_scanned_tx_height = parsedResult.account_scanned_tx_height
		self.account_scanned_block_height = parsedResult.account_scanned_block_height
		self.account_scan_start_height = parsedResult.account_scan_start_height
		self.transaction_height = parsedResult.transaction_height
		self.blockchain_height = parsedResult.blockchain_height
		//
		let wasFirstFetchOf_accountInfo = self.dateThatLast_fetchedAccountInfo == nil
		self.dateThatLast_fetchedAccountInfo = Date()
		//
		// Write:
		let err_str = self.saveToDisk()
		if err_str != nil {
			return // there was an issue saving update… TODO: silence here ok for now?
		}
		//
		// Now notify/emit/yield any actual changes
		var anyChanges = false
		if didActuallyChange_accountBalance == true
			|| wasFirstFetchOf_accountInfo == true
		{
			anyChanges = true
			self.___didReceiveActualChangeTo_balance(
				old_totalReceived: existing_totalReceived,
				old_totalSent: existing_totalSent,
				old_lockedBalance: existing_lockedBalance
			)
		}
		if didActuallyChange_spentOutputs == true
			|| wasFirstFetchOf_accountInfo == true
		{
			anyChanges = true
			self.___didReceiveActualChangeTo_spentOutputs(
				old_spentOutputs: existing_spentOutputs
			)
		}
		if didActuallyChange_heights == true
			|| wasFirstFetchOf_accountInfo == true
		{
			anyChanges = true
			self.___didReceiveActualChangeTo_heights()
		}
		if anyChanges == false {
			// console.log("💬  No actual changes to balance, heights, or spent outputs")
		}
	}
	func _HostPollingController_didFetch_addressTransactions(
		_ parsedResult: HostedMonero.ParsedResult_AddressTransactions
	) -> Void {
		let didActuallyChange_heights =
			(self.account_scanned_height == nil || self.account_scanned_height != parsedResult.account_scanned_height)
			|| (self.account_scanned_block_height == nil || self.account_scanned_block_height != parsedResult.account_scanned_block_height)
			|| (self.account_scan_start_height == nil || self.account_scan_start_height != parsedResult.account_scan_start_height)
			|| (self.transaction_height == nil || self.transaction_height != parsedResult.transaction_height)
			|| (self.blockchain_height == nil || self.blockchain_height != parsedResult.blockchain_height)
		self.account_scanned_height = parsedResult.account_scanned_height
		self.account_scanned_block_height = parsedResult.account_scanned_block_height
		self.account_scan_start_height = parsedResult.account_scan_start_height
		self.transaction_height = parsedResult.transaction_height
		self.blockchain_height = parsedResult.blockchain_height
		//
		// Transactions
		// Note: In the JS, we do a basic/initial diff of the txs and selectively construct the actual final used list, in order to preserve local metadata (and we see how many we've added etc) - but I will not port that yet since we are not implementing local notifications yet - and since we may have a more proper syncing engine soon
		let didActuallyChange_transactions = self.transactions == nil || self.transactions! != parsedResult.transactions
		let existing_transactions = self.transactions
		self.transactions = parsedResult.transactions
		//
		let wasFirstFetchOf_transactions = self.dateThatLast_fetchedAccountTransactions == nil
		self.dateThatLast_fetchedAccountTransactions = Date()
		//
		// Write:
		let err_str = self.saveToDisk()
		if err_str != nil {
			return // there was an issue saving update… TODO: silence here ok for now?
		}
		//
		// Now notify/emit/yield any actual changes
		if didActuallyChange_transactions == true
			|| wasFirstFetchOf_transactions == true
		{
			self.___didReceiveActualChangeTo_transactions(
				old_transactions: existing_transactions
			)
		}
		if didActuallyChange_heights == true
			|| wasFirstFetchOf_transactions == true
		{
			self.___didReceiveActualChangeTo_heights()
		}
	}
	//
	//
	// Delegation - Internal - Data value property update events
	//
	func ___didReceiveActualChangeTo_balance(
		// Not actually using these args currently…
		old_totalReceived: MoneroAmount?,
		old_totalSent: MoneroAmount?,
		old_lockedBalance: MoneroAmount?
	)
	{
		NotificationCenter.default.post(
			name: Notification.Name(NotificationNames.balanceChanged.rawValue),
			object: self
		)
	}
	func ___didReceiveActualChangeTo_spentOutputs(
		// Not actually using this arg currently…
		old_spentOutputs: [MoneroSpentOutputDescription]?
	)
	{
		NotificationCenter.default.post(
			name: Notification.Name(NotificationNames.spentOutputsChanged.rawValue),
			object: self
		)
	}
	func ___didReceiveActualChangeTo_heights()
	{
		NotificationCenter.default.post(
			name: Notification.Name(NotificationNames.heightsUpdated.rawValue),
			object: self
		)
	}
	func ___didReceiveActualChangeTo_transactions(
		old_transactions: [MoneroHistoricalTransactionRecord]?
	)
	{
		NotificationCenter.default.post(
			name: Notification.Name(NotificationNames.transactionsChanged.rawValue),
			object: self
		)
	}
}
