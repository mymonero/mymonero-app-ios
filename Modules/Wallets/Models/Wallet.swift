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
	//
	// Types
	//
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
		func colorHexString() -> String { return self.rawValue }
		func jsonRepresentation() -> String { return self.rawValue }
		static func new(from_jsonRepresentation jsonRepresentation: String) -> SwatchColor
		{
			return self.init(rawValue: jsonRepresentation)!
		}
	}
	enum NotificationNames: String
	{
		case balanceChanged		 = "Wallet_NotificationNames_balanceChanged"
		case spentOutputsChanged = "Wallet_NotificationNames_spentOutputsChanged"
		case heightsUpdated		 = "Wallet_NotificationNames_heightsUpdated"
		case transactionsChanged = "Wallet_NotificationNames_transactionsChanged"
	}
	// Internal
	enum DictKeys: String
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
	var didFailToBoot_flag: Bool?
	var didFailToBoot_errStr: String?
	var isSendingFunds = false
	//
	//
	// Properties - Objects
	//
	var hostPollingController: Wallet_HostPollingController?
	//
	//
	// 'Protocols' - Persistable Object
	//
	override func new_dictRepresentation() -> [String: Any]
	{
		var dict = super.new_dictRepresentation() // since it constructs the base object for us
		do {
			dict[DictKeys.currency.rawValue] = self.currency.jsonRepresentation()
			dict[DictKeys.walletLabel.rawValue] = self.walletLabel
			dict[DictKeys.swatchColorHexString.rawValue] = self.swatchColor.jsonRepresentation()
			dict[DictKeys.publicAddress.rawValue] = self.public_address
			if let value = self.account_seed {
				dict[DictKeys.accountSeed.rawValue] = value
			}
			dict[DictKeys.publicKeys.rawValue] = self.public_keys.jsonRepresentation
			dict[DictKeys.privateKeys.rawValue] = self.private_keys.jsonRepresentation
			if let value = self.shouldDisplayImportAccountOption {
				dict[DictKeys.shouldDisplayImportAccountOption.rawValue] = value
			}
			dict[DictKeys.isLoggedIn.rawValue] = self.isLoggedIn
			if let isInViewOnlyMode = self.isInViewOnlyMode {
				dict[DictKeys.isInViewOnlyMode.rawValue] = isInViewOnlyMode
			}
			//
			if let date = self.dateThatLast_fetchedAccountInfo {
				dict[DictKeys.dateThatLast_fetchedAccountInfo.rawValue] = date.timeIntervalSince1970
			}
			if let date = self.dateThatLast_fetchedAccountTransactions {
				dict[DictKeys.dateThatLast_fetchedAccountTransactions.rawValue] = date.timeIntervalSince1970
			}
			//
			if let value = self.totalReceived {
				dict[DictKeys.totalReceived.rawValue] = String(value, radix: 10)
			}
			if let value = self.totalSent {
				dict[DictKeys.totalSent.rawValue] = String(value, radix: 10)
			}
			if let value = self.lockedBalance {
				dict[DictKeys.lockedBalance.rawValue] = String(value, radix: 10)
			}
			//
			if let array = self.spentOutputs {
				dict[DictKeys.spentOutputs.rawValue] = MoneroSpentOutputDescription.newSerializedDictRepresentation(
					withArray: array
				)
			}
			//
			dict[DictKeys.account_scanned_tx_height.rawValue] = self.account_scanned_tx_height
			dict[DictKeys.account_scanned_height.rawValue] = self.account_scanned_height
			dict[DictKeys.account_scanned_block_height.rawValue] = self.account_scanned_block_height
			dict[DictKeys.account_scan_start_height.rawValue] = self.account_scan_start_height
			dict[DictKeys.transaction_height.rawValue] = self.transaction_height
			dict[DictKeys.blockchain_height.rawValue] = self.blockchain_height
			//
			if let array = self.transactions {
				dict[DictKeys.transactions.rawValue] = MoneroHistoricalTransactionRecord.newSerializedDictRepresentation(
					withArray: array
				)
			}
		}
		return dict
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
		self.isLoggedIn = dictRepresentation[DictKeys.isLoggedIn.rawValue] as! Bool
		self.isInViewOnlyMode = dictRepresentation[DictKeys.isInViewOnlyMode.rawValue] as? Bool
		self.shouldDisplayImportAccountOption = dictRepresentation[DictKeys.shouldDisplayImportAccountOption.rawValue] as? Bool
		if let date = dictRepresentation[DictKeys.dateThatLast_fetchedAccountInfo.rawValue] {
			guard let timeInterval = date as? TimeInterval else {
				assert(false, "not a TimeInterval")
				return nil
			}
			self.dateThatLast_fetchedAccountInfo = Date(timeIntervalSince1970: timeInterval)
		}
		if let date = dictRepresentation[DictKeys.dateThatLast_fetchedAccountInfo.rawValue] {
			guard let timeInterval = date as? TimeInterval else {
				assert(false, "not a TimeInterval")
				return nil
			}
			self.dateThatLast_fetchedAccountInfo = Date(timeIntervalSince1970: timeInterval)
		}
		//
		self.currency = Currency.new(
			from_jsonRepresentation: dictRepresentation[DictKeys.currency.rawValue] as! String
		)
		self.walletLabel = dictRepresentation[DictKeys.walletLabel.rawValue] as! String
		self.swatchColor = SwatchColor.new(
			from_jsonRepresentation: dictRepresentation[DictKeys.swatchColorHexString.rawValue] as! String
		)
		// Not going to check whether the acct seed is nil/'' here because if the wallet was
		// imported with public addr, view key, and spend key only rather than seed/mnemonic, we
		// cannot obtain the seed.
		self.mnemonic_wordsetName = dictRepresentation[DictKeys.mnemonic_wordsetName.rawValue] as? MoneroMnemonicWordsetName
		self.public_address = dictRepresentation[DictKeys.publicAddress.rawValue] as! MoneroAddress
		self.public_keys = MoneroKeyDuo.new(
			fromJSONRepresentation: dictRepresentation[DictKeys.publicKeys.rawValue] as! [String: Any]
		)
		self.account_seed = dictRepresentation[DictKeys.accountSeed.rawValue] as? MoneroSeed
		self.private_keys = MoneroKeyDuo.new(
			fromJSONRepresentation: dictRepresentation[DictKeys.privateKeys.rawValue] as! [String: Any]
		)
		//
		if let string = dictRepresentation[DictKeys.totalReceived.rawValue] {
			self.totalReceived = MoneroAmount(string as! String)
		}
		if let string = dictRepresentation[DictKeys.totalSent.rawValue] {
			self.totalSent = MoneroAmount(string as! String)
		}
		if let string = dictRepresentation[DictKeys.lockedBalance.rawValue] {
			self.lockedBalance = MoneroAmount(string as! String)
		}
		//
		self.account_scanned_tx_height = dictRepresentation[DictKeys.account_scanned_tx_height.rawValue] as? Int
		self.account_scanned_height = dictRepresentation[DictKeys.account_scanned_height.rawValue] as? Int
		self.account_scanned_block_height = dictRepresentation[DictKeys.account_scanned_block_height.rawValue] as? Int
		self.account_scan_start_height = dictRepresentation[DictKeys.account_scan_start_height.rawValue] as? Int
		self.transaction_height = dictRepresentation[DictKeys.transaction_height.rawValue] as? Int
		self.blockchain_height = dictRepresentation[DictKeys.blockchain_height.rawValue] as? Int
		//
		if let jsonRepresentations = dictRepresentation[DictKeys.spentOutputs.rawValue] {
			self.spentOutputs = MoneroSpentOutputDescription.newArray(
				fromJSONRepresentations: jsonRepresentations as! [[String: Any]]
			)
		}
		if let jsonRepresentations = dictRepresentation[DictKeys.transactions.rawValue] {
			self.transactions = MoneroHistoricalTransactionRecord.newArray(
				fromJSONRepresentations: jsonRepresentations as! [[String: Any]]
			)
		}
		//
		if let timeIntervalSince1970 = dictRepresentation[DictKeys.dateThatLast_fetchedAccountInfo.rawValue] {
			self.dateThatLast_fetchedAccountInfo = Date(timeIntervalSince1970: timeIntervalSince1970 as! TimeInterval)
		}
		if let timeIntervalSince1970 = dictRepresentation[DictKeys.dateThatLast_fetchedAccountTransactions.rawValue] {
			self.dateThatLast_fetchedAccountTransactions = Date(timeIntervalSince1970: timeIntervalSince1970 as! TimeInterval)
		}
		NSLog("Hydrated wallet with existing doc: \(self)")
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
			fn
		)
	}
	func Boot_byLoggingIn_existingWallet_withMnemonic(
		walletLabel: String,
		swatchColor: SwatchColor,
		mnemonicString: MoneroSeedAsMnemonic,
		_ fn: @escaping (_ err_str: String?) -> Void
	) -> Void
	{
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		//
		let (wordsetName__err_str, wordsetName) = WordsetName(accordingToMnemonicString: mnemonicString)
		if wordsetName__err_str != nil {
			NSLog("Error while detecting mnemonic wordset from mnemonic string: \(wordsetName__err_str.debugDescription)")
			self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: wordsetName__err_str)
			return
		}
		self.mnemonic_wordsetName = wordsetName!
		//
		// We're not going to set self.mnemonicString here because we re-derive it from seed in _trampolineFor_successfullyBooted
		//
		MyMoneroCore.shared.WalletDescriptionFromMnemonicSeed(
			mnemonicString,
			self.mnemonic_wordsetName!,
			{ (err, walletDescription) in
				if err != nil {
					self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err!.localizedDescription)
					return
				}
				self._boot_byLoggingIn(
					address: walletDescription!.publicAddress,
					view_key__private: walletDescription!.privateKeys.view,
					spend_key_orNilForViewOnly: walletDescription!.privateKeys.spend,
					seed_orNil: walletDescription!.seed,
					wasAGeneratedWallet: false,
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
		_ fn: @escaping (_ err_str: String?) -> Void
	)
	{
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		//
		self._boot_byLoggingIn(
			address: address,
			view_key__private: privateKeys.view,
			spend_key_orNilForViewOnly: privateKeys.spend,
			seed_orNil: nil,
			wasAGeneratedWallet: false,
			fn
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
		if self.blockchain_height == nil || self.blockchain_height == 0 {
			NSLog("Warn: .isScannerCatchingUp called while nil/0 blockchain_height")
			return true
		}
		if self.account_scanned_block_height == nil || self.account_scanned_block_height == 0  {
			NSLog("Warn: .isScannerCatchingUp called while nil/0 account_scanned_block_height")
			return true
		}
		let nBlocksBehind = self.blockchain_height! - self.account_scanned_block_height!
		if nBlocksBehind >= 10 {
			return true
		} else if nBlocksBehind < 0 {
			NSLog("Warn: nBlocksBehind < 0")
			return false
		}
		return false
	}
	var nBlocksBehind: Int
	{
		if self.blockchain_height == nil || self.blockchain_height == 0 {
			NSLog("Warn: .nBlocksBehind called while nil/0 blockchain_height")
			return 0
		}
		if self.account_scanned_block_height == nil || self.account_scanned_block_height == 0  {
			NSLog("Warn: .nBlocksBehind called while nil/0 account_scanned_block_height")
			return 0
		}
		let nBlocksBehind = self.blockchain_height! - self.account_scanned_block_height!
		return nBlocksBehind
	}
	var catchingUpPercentageFloat: Double // btn 0 and 1.0
	{
		if self.account_scanned_height == nil || self.account_scanned_height == 0 {
			NSLog("Warn: .catchingUpPercentageFloat accessed while nil/0 self.account_scanned_height. Bailing.")
			return 0
		}
		if self.transaction_height == nil || self.transaction_height == 0 {
			NSLog("Warn: .catchingUpPercentageFloat accessed while nil/0 self.transaction_height. Bailing.")
			return 0
		}
		let pct: Double = Double(self.account_scanned_height!) / Double(self.transaction_height!)
		NSLog("CatchingUpPercentageFloat \(self.account_scanned_height!)/\(self.transaction_height!) = \(pct)%")
		return pct
	}
	//
	var balance_formattedString: String
	{
		let balanceAmount = (self.totalReceived ?? MoneroAmount(0)) - (self.totalSent ?? MoneroAmount(0))
		//
		return balanceAmount.humanReadableString
	}
	var lockedBalance_formattedString: String
	{
		return (self.lockedBalance ?? MoneroAmount(0)).humanReadableString
	}
	var hasLockedFunds: Bool
	{
		if self.lockedBalance == nil {
			return false
		}
		if self.lockedBalance == MoneroAmount(0) {
			return false
		}
		return true
	}
	//
	//
	// Runtime - Imperatives - Public - Booting - Reading saved wallets
	//
	func Boot_havingLoadedDecryptedExistingInitDoc(
		_ fn: @escaping (_ err_str: String?) -> Void
	)
	{ // nothing to do here as we assume validation done on init
		self._trampolineFor_successfullyBooted(fn)
	}
	//
	//
	// Runtime - Imperatives - Private - Booting
	//
	func __trampolineFor_failedToBootWith_fnAndErrStr(
		fn: (_ err_str: String?) -> Void,
		err_str: String?
	)
	{
		self.didFailToBoot_flag = true
		self.didFailToBoot_errStr = err_str
		//
		fn(err_str)
	}
	func _trampolineFor_successfullyBooted(
		_ fn: @escaping (_ err_str: String?) -> Void
	)
	{
		func __proceed_havingActuallyBooted()
		{
			NSLog("✅  Successfully booted \(self)")
			self.isBooted = true
			fn(nil)
			DispatchQueue.main.async {
				self._atRuntime_setup_hostPollingController() // instantiate (and kick off) polling controller
			}
		}
		if self.account_seed == nil || self.account_seed!.characters.count < 1 {
			NSLog("⚠️  Wallet initialized without an account_seed.")
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
		{ (err, seedAsMnemonic) in
			if let err = err {
				self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err.localizedDescription)
				return
			}
			self.mnemonicString = seedAsMnemonic!
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
		)
		{ (err, verifiedComponentsForLogIn) in
			if let err = err {
				self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err.localizedDescription)
				return
			}
			HostedMoneroAPIClient.shared.LogIn(
				address: address,
				view_key__private: view_key__private,
				{ (err_str, isANewAddressToServer) in
					if err_str != nil {
						self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err_str)
						return
					}
					self.public_address = verifiedComponentsForLogIn!.publicAddress
					self.account_seed = verifiedComponentsForLogIn!.seed
					self.public_keys = verifiedComponentsForLogIn!.publicKeys
					self.private_keys = verifiedComponentsForLogIn!.privateKeys
					self.isInViewOnlyMode = verifiedComponentsForLogIn!.isInViewOnlyMode
					//
					self.isLoggingIn = false
					self.isLoggedIn = true
					//
					self.shouldDisplayImportAccountOption = wasAGeneratedWallet == false && isANewAddressToServer == true
					//
					let err_str = self.saveToDisk()
					if err_str != nil {
						self.__trampolineFor_failedToBootWith_fnAndErrStr(fn: fn, err_str: err_str)
						return
					}
					self._trampolineFor_successfullyBooted(fn)
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
		self.walletLabel = walletLabel
		self.swatchColor = swatchColor
		let err_str = self.saveToDisk()
		return err_str
	}
	//
	//
	// Runtime (Booted) - Imperatives - Sending Funds
	//
	func SendFunds(
		target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
		amount: HumanUnderstandableCurrencyAmountDouble, // human-understandable number, e.g. input 0.5 for 0.5 XMR
		payment_id: MoneroPaymentID?,
		success_fn: @escaping (
			_ tx_hash: MoneroTransactionHash,
			_ tx_fee: MoneroAmount
		) -> Void,
		failWithErr_fn: @escaping (
			_ err_str: String
		) -> Void
	)
	{
		func __isLocked() -> Bool { return self.isSendingFunds }
		if __isLocked() {
			failWithErr_fn("Currently sending funds. Please try again when complete.")
			return
		}
		func __lock()
		{
			self.isSendingFunds = true
			// TODO:
			// 1. userIdleInWindowController.TemporarilyDisable_userIdle
			// 2. disable screen dim
		}
		func __unlock()
		{
			self.isSendingFunds = false
			// TODO: re-enable user idle and screen dim
		}
		__lock()
		HostedMoneroAPIClient.SendFunds(
			target_address: target_address,
			amount: amount,
			wallet__public_address: self.public_address,
			wallet__private_keys: self.private_keys,
			wallet__public_keys: self.public_keys,
			mymoneroCore: MyMoneroCore.shared,
			hostedMoneroAPIClient: HostedMoneroAPIClient.shared,
			payment_id: payment_id,
			success_fn:
			{ (tx_hash, tx_fee) in
				__unlock()
				success_fn(tx_hash, tx_fee)
			},
			failWithErr_fn:
			{ err_str in
				__unlock()
				failWithErr_fn(err_str)
			}
		)
	}
	//
	//
	// HostPollingController - Delegation / Protocol
	// 
	func _HostPollingController_didFetch_addressInfo(
		_ parsedResult: HostedMoneroAPIClient_Parsing.ParsedResult_AddressInfo
	) -> Void
	{
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
		_ parsedResult: HostedMoneroAPIClient_Parsing.ParsedResult_AddressTransactions
	) -> Void
	{
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
