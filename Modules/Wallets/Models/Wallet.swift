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
		case didChange_isFetchingAnyUpdates = "Wallet_NotificationNnames_didChange_isFetchingAnyUpdates"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	// Internal
	enum DictKey: String
	{ // (For persistence)
		case login__new_address = "login__new_address"
		case login__generated_locally = "login__generated_locally"
		case local_wasAGeneratedWallet = "local_wasAGeneratedWallet"
		//
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
	}
	//
	//
	// Properties - Principal Persisted Values
	let keyImageCache = MoneroUtils.KeyImageCache()
	//
	var local_wasAGeneratedWallet: Bool?
	var login__new_address: Bool?
	var login__generated_locally: Bool?
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
	var account_scanned_tx_height: UInt64?
	var account_scanned_height: UInt64? // TODO: it would be good to resolve account_scanned_height vs account_scanned_tx_height
	var account_scanned_block_height: UInt64?
	var account_scan_start_height: UInt64?
	var transaction_height: UInt64?
	var blockchain_height: UInt64?
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
	var isInViewOnlyMode: Bool?
	// transient/not persisted
	var isBooted = false
	var shouldDisplayImportAccountOption: Bool?
	var isLoggingIn = false
	var wasInitializedWith_addrViewAndSpendKeysInsteadOfSeed: Bool?
	var isSendingFunds = false
	//
	// Properties - Objects
	var logIn_requestHandle: HostedMonero.APIClient.RequestHandle?
	var hostPollingController: Wallet_HostPollingController? // strong
	var txCleanupController: Wallet_TxCleanupController? // strong
	var fundsSender: HostedMonero.FundsSender?
	//
	// 'Protocols' - Persistable Object
	override func new_dictRepresentation() -> [String: Any]
	{
		var dict = super.new_dictRepresentation() // since it constructs the base object for us
		do {
			if self.login__new_address != nil {
				dict[DictKey.login__new_address.rawValue] = self.login__new_address!
			}
			if self.login__generated_locally != nil {
				dict[DictKey.login__generated_locally.rawValue] = self.login__generated_locally!
			}
			if self.local_wasAGeneratedWallet != nil {
				dict[DictKey.local_wasAGeneratedWallet.rawValue] = self.local_wasAGeneratedWallet!
			}
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
				dict[DictKey.mnemonic_wordsetName.rawValue] = value // value itself
			}
			dict[DictKey.publicKeys.rawValue] = self.public_keys.jsonRepresentation
			dict[DictKey.privateKeys.rawValue] = self.private_keys.jsonRepresentation
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
	override class func collectionName() -> String
	{
		return "Wallets"
	}
	required init?(withPlaintextDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	{
		try super.init(withPlaintextDictRepresentation: dictRepresentation) // this will set _id for us
		//
		self.local_wasAGeneratedWallet = dictRepresentation[DictKey.local_wasAGeneratedWallet.rawValue] as? Bool
		self.login__generated_locally = dictRepresentation[DictKey.login__generated_locally.rawValue] as? Bool
		self.login__new_address = dictRepresentation[DictKey.login__new_address.rawValue] as? Bool
		//
		self.isLoggedIn = dictRepresentation[DictKey.isLoggedIn.rawValue] as! Bool
		self.isInViewOnlyMode = dictRepresentation[DictKey.isInViewOnlyMode.rawValue] as? Bool
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
		self.walletLabel = dictRepresentation[DictKey.walletLabel.rawValue] as? String
		self.swatchColor = SwatchColor.new(
			from_jsonRepresentation: dictRepresentation[DictKey.swatchColorHexString.rawValue] as! String
		)
		// Not going to check whether the acct seed is nil/'' here because if the wallet was
		// imported with public addr, view key, and spend key only rather than seed/mnemonic, we
		// cannot obtain the seed.
		
		self.public_address = dictRepresentation[DictKey.publicAddress.rawValue] as? MoneroAddress
		self.public_keys = MoneroKeyDuo.new(
			fromJSONRepresentation: dictRepresentation[DictKey.publicKeys.rawValue] as! [String: Any]
		)
		self.account_seed = dictRepresentation[DictKey.accountSeed.rawValue] as? MoneroSeed
		self.mnemonic_wordsetName = dictRepresentation[DictKey.mnemonic_wordsetName.rawValue] as? MoneroMnemonicWordsetName
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
		self.account_scanned_tx_height = dictRepresentation[DictKey.account_scanned_tx_height.rawValue] as? UInt64
		self.account_scanned_height = dictRepresentation[DictKey.account_scanned_height.rawValue] as? UInt64
		self.account_scanned_block_height = dictRepresentation[DictKey.account_scanned_block_height.rawValue] as? UInt64
		self.account_scan_start_height = dictRepresentation[DictKey.account_scan_start_height.rawValue] as? UInt64
		self.transaction_height = dictRepresentation[DictKey.transaction_height.rawValue] as? UInt64
		self.blockchain_height = dictRepresentation[DictKey.blockchain_height.rawValue] as? UInt64
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
		//
		// Regenerate any runtime vals that depend on persisted vals..
		self.regenerate_shouldDisplayImportAccountOption()
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
	) throws {
		self.init()
		self.currency = .Monero // for now
		if ifGeneratingNewWallet_walletDescription != nil {
			self.generatedOnInit_walletDescription = ifGeneratingNewWallet_walletDescription
			self.mnemonic_wordsetName = self.generatedOnInit_walletDescription!.mnemonicLanguage
		}
	}
	//
	// Lifecycle - Deinit
	override func teardown()
	{
		super.teardown()
		self.tearDownRuntime()
	}
	func tearDownRuntime()
	{
		self.hostPollingController = nil // stop requests
		self.txCleanupController = nil // stop timer
		//
		self.logIn_requestHandle?.cancel() // in case wallet is being rebooted on API address change via settings
		self.logIn_requestHandle = nil
		self.isLoggingIn = false
		//
		if self.isSendingFunds { // just in case - i.e. on teardown while sending but user sends the app to the background
			UserIdle.shared.reEnable_userIdle()
			ScreenSleep.reEnable_screenSleep()
		}
		self.fundsSender?.cancel() // to get the network request cancel immediately
		self.fundsSender = nil
	}
	func deBoot()
	{
		let old__totalReceived = self.totalReceived
		let old__totalSent = self.totalSent
		let old__lockedBalance = self.lockedBalance
		let old__spentOutputs = self.spentOutputs
		let old__transactions = self.transactions
		do {
			self.tearDownRuntime() // stop any requests, etc
		}
		do {
			// important flags to clear:
			self.isLoggedIn = false
			self.didFailToBoot_flag = nil
			self.didFailToBoot_errStr = nil
			self.isBooted = false
			//
			self.totalReceived = nil
			self.totalSent = nil
			self.lockedBalance = nil
			//
			self.account_scanned_tx_height = nil
			self.account_scanned_height = nil
			self.account_scanned_block_height = nil
			self.account_scan_start_height = nil
			self.transaction_height = nil
			self.blockchain_height = nil
			//
			self.spentOutputs = nil
			self.transactions = nil
			//
			self.dateThatLast_fetchedAccountInfo = nil
			self.dateThatLast_fetchedAccountTransactions = nil
		}
		do {
			self.___didReceiveActualChangeTo_balance(
				old_totalReceived: old__totalReceived,
				old_totalSent: old__totalSent,
				old_lockedBalance: old__lockedBalance
			)
			self.___didReceiveActualChangeTo_spentOutputs(
				old_spentOutputs: old__spentOutputs
			)
			self.___didReceiveActualChangeTo_heights()
			self.___didReceiveActualChangeTo_transactions(
				old_transactions: old__transactions
			)
			self.regenerate_shouldDisplayImportAccountOption()
		}
		let save_err_str = self.saveToDisk()
		if save_err_str != nil {
			DDLog.Error("Wallet", "Error while saving during a deBoot(): \(save_err_str!)")
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
	) -> Void {
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		//
		assert(self.generatedOnInit_walletDescription != nil, "nil generatedOnInit_walletDescription")
		let generatedOnInit_walletDescription = self.generatedOnInit_walletDescription!
		self._boot_byLoggingIn(
			address: generatedOnInit_walletDescription.publicAddress,
			view_key__private: generatedOnInit_walletDescription.privateKeys.view,
			spend_key: generatedOnInit_walletDescription.privateKeys.spend,
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
		self.mnemonicString = mnemonicString // even though we re-derive the mnemonicString on success, this is being set here so as to prevent the bug where it gets lost when changing the API server and a reboot w/mnemonicSeed occurs
		// we'll set the wordset name in a moment
		//
		MyMoneroCore.shared_objCppBridge.WalletDescriptionFromMnemonicSeed(
			mnemonicString,
			{ [unowned self] (err_str, walletDescription) in
				if err_str != nil {
					self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err_str!)
					return
				}
				self.mnemonic_wordsetName = walletDescription!.mnemonicLanguage
				//
				assert(walletDescription!.seed != "")
				self._boot_byLoggingIn(
					address: walletDescription!.publicAddress,
					view_key__private: walletDescription!.privateKeys.view,
					spend_key: walletDescription!.privateKeys.spend,
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
			spend_key: privateKeys.spend,
			seed_orNil: nil,
			wasAGeneratedWallet: false,
			persistEvenIfLoginFailed_forServerChange: persistEvenIfLoginFailed_forServerChange,
			fn
		)
	}
	func logOutThenSaveAndLogIn()
	{
		if self.isLoggedIn || (self.didFailToBoot_flag != nil && self.didFailToBoot_flag!) || self.isBooted { // if we actually do need to log out ... otherwise this may be an attempt by the ListController to log in after having loaded a failed login from a previous user session upon launching the app
			self.deBoot()
		}
		self._boot_byLoggingIn(
			address: self.public_address,
			view_key__private: self.private_keys.view,
			spend_key: self.private_keys.spend, // currently not expecting nil
			seed_orNil: self.account_seed,
			wasAGeneratedWallet: self.local_wasAGeneratedWallet ?? false,
			persistEvenIfLoginFailed_forServerChange: true,
			{ [weak self] (err_str) in
				guard let _ = self else {
					return
				}
				if err_str != nil {
					DDLog.Error("Wallets", "Failed to log back in with error: \(err_str!)")
					return
				}
				DDLog.Done("Wallets", "Logged back in.")
			}
		)
	}
	//
	// Interface - Runtime - Accessors/Properties
	var isFetchingAnyUpdates: Bool {
		if self.hostPollingController == nil {
			return false
		}
		return self.hostPollingController!.isFetchingAnyUpdates
	}
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
		}
		return false
	}
	var nBlocksBehind: UInt64
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
		//
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
	) { // nothing to do here as we assume validation done on init
		self._trampolineFor_successfullyBooted(fn)
	}
	//
	// Runtime - Imperatives - Private - Booting
	func _setStateThatFailedToBoot(
		withErrStr err_str: String?
	) {
		self.didFailToBoot_flag = true
		self.didFailToBoot_errStr = err_str
	}
	func __trampolineFor_failedToBootWith_fnAndErrStr(
		fn: (_ err_str: String?) -> Void,
		err_str: String?
	) {
		self._setStateThatFailedToBoot(withErrStr: err_str)
		//
		DispatchQueue.main.async
		{ [weak self] in
			guard let thisSelf = self else {
				return
			}
			NotificationCenter.default.post(
				name: PersistableObject.NotificationNames.failedToBoot.notificationName,
				object: thisSelf,
				userInfo: nil
			)
		}
		fn(err_str)
	}
	func _trampolineFor_successfullyBooted(
		_ fn: @escaping (_ err_str: String?) -> Void
	) {
		func __proceed_havingActuallyBooted()
		{
//			DDLog.Done("Wallets", "Successfully booted \(self)")
			self.isBooted = true
			self.didFailToBoot_errStr = nil
			self.didFailToBoot_flag = nil
			DispatchQueue.main.async
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				thisSelf._atRuntime_setup_hostPollingController() // instantiate (and kick off) polling controller
				thisSelf.txCleanupController = Wallet_TxCleanupController(wallet: thisSelf)
				//
				NotificationCenter.default.post(name: PersistableObject.NotificationNames.booted.notificationName, object: thisSelf, userInfo: nil)
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
		let (err_str, seedAsMnemonic) = MyMoneroCore.shared_objCppBridge.MnemonicStringFromSeed(
			self.account_seed!,
			self.mnemonic_wordsetName!
		)
		if let err_str = err_str {
			self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err_str)
			return
		}
		if self.mnemonicString != nil {
			let areMnemonicsEqual = MyMoneroCore.shared_objCppBridge.areEqualMnemonics(
				self.mnemonicString!,
				seedAsMnemonic!
			)
			if areMnemonicsEqual == false { // would be rather odd; NOTE: must use this comparator instead of string comparison to support partial-word mnemonic strings
				assert(false, "Different mnemonicString derived from accountSeed than was entered for login")
				self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: "Mnemonic seed mismatch")
				return
			}
		}
		self.mnemonicString = seedAsMnemonic! // set it in all cases - because we want to support converting partial-word input to full-word for display and recording
		//
		__proceed_havingActuallyBooted()
	}
	func _atRuntime_setup_hostPollingController()
	{
		self.hostPollingController = Wallet_HostPollingController(
			wallet: self,
			didUpdate_factorOf_isFetchingAnyUpdates_fn:
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				DispatchQueue.main.async
				{ [weak thisSelf] in
					guard let thisSelf1 = thisSelf else {
						return
					}
					NotificationCenter.default.post(
						name: Wallet.NotificationNames.didChange_isFetchingAnyUpdates.notificationName,
						object: thisSelf1,
						userInfo: nil
					)
				}
			}
		)
	}
	func _boot_byLoggingIn(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key: MoneroKey,
		seed_orNil: MoneroSeed?,
		wasAGeneratedWallet: Bool,
		persistEvenIfLoginFailed_forServerChange: Bool,
		_ fn: @escaping (_ err_str: String?) -> Void
	) {
		self.isLoggingIn = true
		//
		MyMoneroCore.shared_objCppBridge.New_VerifiedComponentsForLogIn(
			address,
			view_key__private,
			spend_key: spend_key,
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
			self.local_wasAGeneratedWallet = wasAGeneratedWallet
			//
			self.logIn_requestHandle = HostedMonero.APIClient.shared.LogIn(
				address: address,
				view_key__private: view_key__private,
				generated_locally: wasAGeneratedWallet,
				{ [weak self] (login__err_str, result) in
					guard let thisSelf = self else {
						return // already dealloc'd
					}
					thisSelf.isLoggingIn = false
					thisSelf.isLoggedIn = login__err_str == nil // supporting shouldExitOnLoginError=false for wallet reboot
					//
					let shouldExitOnLoginError = persistEvenIfLoginFailed_forServerChange == false
					if login__err_str != nil {
						if shouldExitOnLoginError == true {
							thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr(
								fn: fn,
								err_str: login__err_str
							)
							thisSelf.logIn_requestHandle = nil
							return
						} else {
							// this allows us to continue with the above-set login info to call 'saveToDisk()' when this call to log in is coming from a wallet reboot. reason is that we expect all such wallets to be valid monero wallets if they are able to have been rebooted.
						}
					}
					//
					if result != nil { // i.e. on error but shouldExitOnLoginError != true
						thisSelf.login__new_address = result!.isANewAddressToServer
						thisSelf.login__generated_locally = result!.generated_locally
						thisSelf.account_scan_start_height = result!.start_height
						//
						thisSelf.regenerate_shouldDisplayImportAccountOption() // now this can be called
					}
					//
					let saveToDisk__err_str = thisSelf.saveToDisk()
					if saveToDisk__err_str != nil {
						thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr(
							fn: fn,
							err_str: saveToDisk__err_str
						)
						thisSelf.logIn_requestHandle = nil
						return
					}
					if shouldExitOnLoginError == false && login__err_str != nil {
						// if we are attempting to re-boot the wallet, but login failed
						thisSelf.__trampolineFor_failedToBootWith_fnAndErrStr( // i.e. leave the wallet in the 'errored'/'failed to boot' state even though we saved
							fn: fn,
							err_str: login__err_str
						)
						thisSelf.logIn_requestHandle = nil
					} else { // it's actually a success
						thisSelf._trampolineFor_successfullyBooted(fn)
						thisSelf.logIn_requestHandle = nil
					}
				}
			)
		}
	}
	//
	// Imperatives
	func requestManualUserRefresh()
	{
		if let controller = self.hostPollingController {
			controller.requestFromUI_manualRefresh()
		} else {
			DDLog.Warn("Wallet", "Manual refresh requested before hostPollingController set up.")
			// not booted yet.. ignoring
		}
	}
	func regenerate_shouldDisplayImportAccountOption()
	{
		let isAPIBeforeGeneratedLocallyAPISupport = self.login__generated_locally == nil || self.account_scan_start_height == nil
		if isAPIBeforeGeneratedLocallyAPISupport {
			if self.local_wasAGeneratedWallet == nil {
				self.local_wasAGeneratedWallet = false // just going to set this to false - it means the user is on a wallet which was logged in via a previous version
			}
			if self.login__new_address == nil {
				self.login__new_address = false // going to set this to false if it doesn't exist - it means the user is on a wallet which was logged in via a previous version
			}
			self.shouldDisplayImportAccountOption = self.local_wasAGeneratedWallet! == false && self.login__new_address! == true
		} else {
			if self.account_scan_start_height == nil {
				fatalError("Logic error: expected latest_scan_start_height")
			}
			self.shouldDisplayImportAccountOption = self.login__generated_locally != true && self.account_scan_start_height! != 0
		}
	}
	//
	// Runtime (Booted) - Imperatives - Updates
	func SetValuesAndSave(
		walletLabel: String,
		swatchColor: SwatchColor
	) -> String? { // err_str -- maybe port to 'throws'
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
	// Imperatives - Local tx CRUD
	func _manuallyInsertTransactionRecord(
		_ transaction: MoneroHistoricalTransactionRecord
	) {
		let old_transactions = self.transactions
		if self.transactions == nil {
			self.transactions = []
		}
		self.transactions!.append(transaction)
		if let _ = self.saveToDisk() {
			return // TODO: anything to do here? maybe saveToDisk should implement retry logic
		}
		// notify/yield
		self.___didReceiveActualChangeTo_transactions(
			old_transactions: old_transactions
		)
	}
	//
	// Runtime (Booted) - Imperatives - Sending Funds
	func sendFunds(
		target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
		amount_orNilIfSweeping: HumanUnderstandableCurrencyAmountDouble?, // human-understandable number, e.g. input 0.5 for 0.5 XMR
		isSweeping: Bool,
		payment_id: MoneroPaymentID?,
		integratedAddressPIDForDisplay_orNil: MoneroPaymentID?, // this is not a parameter for sending - it's merely so that it can be used as the final pid for display in the mockedTransaction and sent back to the consumer
		priority: MoneroTransferSimplifiedPriority,
		didUpdateProcessStep_fn: @escaping ((_ processStep: HostedMonero.FundsSender.ProcessStep) -> Void),
		success_fn: @escaping (
			_ final_sentAmountWithoutFee: MoneroAmount,
			_ sentPaymentID_orNil: MoneroPaymentID?,
			_ tx_hash: MoneroTransactionHash,
			_ tx_fee: MoneroAmount,
			_ tx_key: MoneroTransactionSecKey,
			_ mockedTransaction: MoneroHistoricalTransactionRecord
		) -> Void,
		canceled_fn: @escaping () -> Void,
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
		func __really_proceed()
		{
			self.__lock_sending()
			assert(self.fundsSender == nil)
			if amount_orNilIfSweeping == 0 || amount_orNilIfSweeping == nil {
				assert(isSweeping, "Missing amount and not sweeping")
			}
			let fundsSender = HostedMonero.FundsSender(
				target_address: target_address,
				amount_orNilIfSweeping: amount_orNilIfSweeping,
				isSweeping: isSweeping,
				wallet__public_address: self.public_address,
				wallet__private_keys: self.private_keys,
				wallet__public_keys: self.public_keys,
				payment_id: payment_id,
				priority: priority,
				wallet__keyImageCache: self.keyImageCache
			)
			fundsSender.success_fn =
			{ [weak self] (final_sentAmountWithoutFee, sentPaymentID_orNil, tx_hash, tx_fee, tx_key) in
				guard let thisSelf = self else {
					return
				}
				thisSelf.__unlock_sending()
				//
				var outgoingAmountForDisplay = final_sentAmountWithoutFee + tx_fee // mutable copy
				outgoingAmountForDisplay.sign = .minus // make negative as it's outgoing
				//
				let mockedTransaction = MoneroHistoricalTransactionRecord(
					amount: outgoingAmountForDisplay,
					totalSent: final_sentAmountWithoutFee + tx_fee,
					totalReceived: MoneroAmount("0"),
					approxFloatAmount: DoubleFromMoneroAmount(moneroAmount: outgoingAmountForDisplay),
					spent_outputs: nil, // TODO: is this ok?
					timestamp: Date(), // faking this
					hash: tx_hash,
					paymentId: sentPaymentID_orNil ?? integratedAddressPIDForDisplay_orNil, // transaction.paymentId will be nil for integrated addresses but we show it here anyway and, in the situation where they used a std xmr addr and a short pid, an int addr would get fabricated anyway, leaving sentWith_paymentID nil even though user is expecting a pid - so we want to make sure it gets saved in either case
					mixin: MyMoneroCore.fixedMixin,
					//
					mempool: true, // is this correct?
					unlock_time: 0,
					height: nil, // mocking the initial value -not- to exist (rather than to erroneously be 0) so that isconfirmed -> false
					//
//					coinbase: false, // TODO
					//
					isFailed: nil, // since we've just created it
					//
					cached__isConfirmed: false, // important
					cached__isUnlocked: true, // TODO: not sure about this
					cached__lockedReason: nil,
					//
					isJustSentTransientTransactionRecord: true,
					//
					tx_key: tx_key,
					tx_fee: tx_fee,
					to_address: target_address
					//				contact: hasPickedAContact ? self.pickedContact : null, // TODO?
				)
				//
				success_fn(final_sentAmountWithoutFee, sentPaymentID_orNil, tx_hash, tx_fee, tx_key, mockedTransaction)
				//
				// manually insert .. and subsequent fetches from the server will be
				// diffed against this, preserving the tx_fee, tx_key, to_address...
				thisSelf._manuallyInsertTransactionRecord(mockedTransaction);
			}
			fundsSender.didUpdateProcessStep_fn = didUpdateProcessStep_fn
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
		}
		if SettingsController.shared.authentication__requireWhenSending == false {
			__really_proceed()
		} else {
			PasswordController.shared.initiate_verifyUserAuthenticationForAction(
				customNavigationBarTitle: NSLocalizedString("Authenticate", comment: ""),
				canceled_fn: {
					canceled_fn()
				},
				// all failures show in entry UI
				entryAttempt_succeeded_fn: {
					__really_proceed()
				}
			)
		}
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
	// HostPollingController - Delegation / Protocol
	func _HostPollingController_didFetch_addressInfo(
		_ parsedResult: HostedMonero.ParsedResult_AddressInfo
	) -> Void {
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
			self.regenerate_shouldDisplayImportAccountOption() // scan start height may have changed
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
		var didActuallyChange_transactions = false // we'll see if anything actually changed and only emit if so
		// We will construct the txs from the incoming txs here as follows.
		// Doing this allows us to selectively preserve already-cached info.
		var numberOfTransactionsAdded = 0
//		var newTransactions = [MoneroHistoricalTransactionRecord]()
		let existing_transactions = (self.transactions ?? [])!
		let incoming_txs = parsedResult.transactions
		//
		// Always make sure to construct new array so we have the old set
		var txs_by_hash = [MoneroTransactionHash: MoneroHistoricalTransactionRecord]()
		for (_, existing_tx) in existing_transactions.enumerated() {
			// in JS here we delete the 'id' field but we don't have it in Swift - in JS, the comment is: "not expecting an id but just in case .. so we don't break diffing"
			txs_by_hash[existing_tx.hash] = existing_tx // start with old one
		}
		for (_, incoming_tx) in incoming_txs.enumerated() {
			// in JS here we delete the 'id' field but we don't have it in Swift - in JS, the comment is: "because this field changes while sending funds, even though hash stays the same, and because we don't want `id` messing with our ability to diff. so we're not even going to try to store this"
			let existing_tx = txs_by_hash[incoming_tx.hash]
			let isNewTransaction = existing_tx == nil
			let finalized_incoming_tx = incoming_tx
			// ^- If any existing tx is also in incoming txs, this will cause
			// the (correct) deletion of e.g. isJustSentTransaction=true.
			if isNewTransaction { // This is generally now only going to be hit when new incoming txs happen - or outgoing txs done on other logins
				didActuallyChange_transactions = true
				numberOfTransactionsAdded += 1
			} else {
				let existing_same_tx = existing_tx!
				if incoming_tx != existing_same_tx {
					didActuallyChange_transactions = true // this is likely to happen if tx.height changes while pending confirmation
				}
				// Check if existing tx has any cached info which we
				// want to bring into the finalized_tx before setting;
				if existing_same_tx.tx_key != nil {
					finalized_incoming_tx.tx_key = existing_same_tx.tx_key
				}
				if existing_same_tx.to_address != nil {
					finalized_incoming_tx.to_address = existing_same_tx.to_address
				}
				if existing_same_tx.tx_fee != nil {
					finalized_incoming_tx.tx_fee = existing_same_tx.tx_fee
				}
				if incoming_tx.paymentId == nil || incoming_tx.paymentId == "" {
					if existing_same_tx.paymentId != nil {
						finalized_incoming_tx.paymentId = existing_same_tx.paymentId // if the tx lost it.. say, while it's being scanned, keep pid
					}
				}
				if incoming_tx.mixin == nil || incoming_tx.mixin == 0 {
					if existing_same_tx.mixin != nil && existing_same_tx.mixin != 0 {
						finalized_incoming_tx.mixin = existing_same_tx.mixin // if the tx lost it.. say, while it's being scanned, keep mixin
					}
				}
				//
				// We could probably check if the existing_same_tx has a
				// negative amount and the incoming_tx has a positive amount and
				// then cause the existing_tx to use the negative amount ... but
				// those criteria are too loose, and the potential for incorrect
				// behavior too great imo.
			}
			// always overwrite existing ones:
			txs_by_hash[incoming_tx.hash] = finalized_incoming_tx; // the finalized tx
			// Commented b/c we don't use this yet:
//			if isNewTransaction { // waiting so we have the finalized incoming_tx obj
//				newTransactions.append(finalized_incoming_tx)
//			}
		}
		//
		var finalized_transactions = [MoneroHistoricalTransactionRecord]()
		for (_, pair) in txs_by_hash.enumerated() {
			finalized_transactions.append(pair.value)
		}
		finalized_transactions.sort { (a, b) -> Bool in
			// there are no ids here for sorting so we'll use timestamp
			// and .mempool can mess with user's expectation of tx sorting
			// when .isFailed is involved, so just going with a simple sort here
			return b.timestamp < a.timestamp
		}
		//
		self.transactions = finalized_transactions
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
			self.regenerate_shouldDisplayImportAccountOption() // scan start height may have changed
			self.___didReceiveActualChangeTo_heights()
		}
	}
	//
	// Delegation - Internal - Data value property update events
	func ___didReceiveActualChangeTo_balance(
		// Not actually using these args currently…
		old_totalReceived: MoneroAmount?,
		old_totalSent: MoneroAmount?,
		old_lockedBalance: MoneroAmount?
	) {
		NotificationCenter.default.post(
			name: Notification.Name(NotificationNames.balanceChanged.rawValue),
			object: self
		)
	}
	func ___didReceiveActualChangeTo_spentOutputs(
		// Not actually using this arg currently…
		old_spentOutputs: [MoneroSpentOutputDescription]?
	) {
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
	) {
		NotificationCenter.default.post(
			name: Notification.Name(NotificationNames.transactionsChanged.rawValue),
			object: self
		)
	}
}
