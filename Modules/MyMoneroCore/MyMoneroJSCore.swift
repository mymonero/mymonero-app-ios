//
//  MyMoneroJSCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import UIKit // because we use a WKWebView
import WebKit
import BigInt
//
// Accessory types
enum MyMoneroCoreJS_ModuleName: String
{
	case core = "monero_utils"
	case wallet = "monero_wallet_utils"
	case walletLocale = "monero_wallet_locale"
	case paymentID = "monero_paymentID_utils"
	case keyImageCache = "monero_keyImage_cache_utils"
}
typealias MoneroSeed = String
typealias MoneroSeedAsMnemonic = String
typealias MoneroAddress = String
typealias MoneroPaymentID = String
typealias MoneroKey = String
typealias MoneroKeyImage = String
typealias MoneroAmount = BigInt
struct MoneroKeyDuo
{
	var view: MoneroKey
	var spend: MoneroKey
}
struct MoneroWalletDescription
{
	var mnemonic: MoneroSeedAsMnemonic
	var seed: MoneroSeed
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
}
struct MoneroVerifiedComponentsForLogIn
{
	var seed: MoneroSeed
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
	var isInViewOnlyMode: Bool
}
enum MoneroMnemonicWordsetName: String
{
	case English = "english"
	case Japanese = "japanese"
	case Spanish = "spanish"
	case Portuguese = "portuguese"
}
//
// Constants
struct MoneroConstants
{
	static let currency_name = "Monero"
	static let currency_symbol = "XMR"
	static let currency_requestURIPrefix = "monero:"
	static let currency_openAliasPrefix = "xmr" // OpenAlias prefix
	//
	static let addressPrefix = 18 // Prefix code for addresses; 18 => addresses start with "4"
	static let integratedAddressPrefix = 19 // Prefix code for addresses
	//
	static let currency_unitPlaces = 12 // Number of atomic units in one unit of currency. e.g. 12 => 10^12 = 1000000000000
	static let txMinConfirms = 10 // Minimum number of confirmations for a transaction to show as confirmed
	static let maxBlockNumber = 500000000 // Maximum block number, used for tx unlock time
	static let avgBlockTime = 60 // Average block time in seconds, used for unlock time estimation
	//
	static let feePerKB = MoneroAmount("2000000000")! // 0.002 XMR; Network per kb fee in atomic units
	static let dustThreshold = MoneroAmount("10000000000")! // Dust threshold in atomic units; 10^10 used for choosing outputs/change - we decompose all the way down if the receiver wants now regardless of threshold
}
//
// Principal type
class MyMoneroCoreJS : NSObject, WKScriptMessageHandler
{
	let window: UIWindow!
	var webView: WKWebView!
	var hasBooted = false
	//
	init(window: UIWindow)
	{
		self.window = window
		super.init()
		self.setup()
	}
	func setup()
	{
		self.setup_webView()
	}
	func setup_webView()
	{
		let filename = "mymonero-js-core-ios-build"
		guard let filepath = Bundle.main.path(forResource: filename, ofType: "js") else {
			NSLog("❌  Can't find js file named \(filename)")
			return
		}
		guard let fileJSString = try? String(contentsOfFile:filepath, encoding:.utf8) else {
			NSLog("❌  Error while loading string contents of file named \(filename)")
			return
		}
		//
		let configuration = WKWebViewConfiguration()
		configuration.userContentController.add(self, name: "javascriptEmissions")
		self.webView = WKWebView(frame: .zero, configuration: configuration)
		webView.isHidden = true
		self.window.addSubview(webView)
		let htmlString = "<html><head></head><body></body></html>"
		webView.loadHTMLString(htmlString, baseURL: nil)
		//
		webView.evaluateJavaScript(fileJSString)
		{ (any, err) in
			if let err = err {
				NSLog("Load err \(err)")
				return
			}
			self.hasBooted = true
			if let any = any {
				NSLog("Load any \(any)")
			}
		}
	}
	//
	//
	// Interface - Accessors
	//
	func NewlyCreatedWallet(_ fn: @escaping (MoneroWalletDescription) -> Void)
	{
		self.MnemonicWordsetNameWithCurrentLocale({ wordsetName in
			self._callSync(.wallet, "NewlyCreatedWallet", [ "\"\(wordsetName.rawValue)\"" ])
			{ (any, err) in
				if let dict = any as? [String: AnyObject] {
					let description = self._new_moneroWalletDescription_byParsing_dict(dict, nil)
					fn(description)
				}
			}
		})
	}
	func MnemonicStringFromSeed(
		_ account_seed: String,
		_ wordsetName: MoneroMnemonicWordsetName,
		_ fn: @escaping (Error?, MoneroSeedAsMnemonic?) -> Void
	)
	{
		self._callSync(.wallet, "MnemonicStringFromSeed", [ "\"\(account_seed)\"", "\"\(wordsetName.rawValue)\"" ])
		{ (any, err) in
			if let err = err {
				fn(err, nil)
				return
			}
			let mnemonicString = any as! MoneroSeedAsMnemonic
			fn(nil, mnemonicString)
		}
	}
	func WalletDescriptionFromMnemonicSeed(
		_ mnemonicString: MoneroSeedAsMnemonic,
		_ wordsetName: MoneroMnemonicWordsetName,
		_ fn: @escaping (Error?, MoneroWalletDescription?) -> Void
	)
	{
		self._callSync(.wallet, "SeedAndKeysFromMnemonic_sync", [ "\"\(mnemonicString)\"", "\"\(wordsetName.rawValue)\"" ])
		{ (any, err) in
			if let err = err {
				fn(err, nil)
				return
			}
			guard let dict = any as? [String: AnyObject] else {
				// return err?
				NSLog("Error: Couldn't cast return value as [String: AnyObject]")
				return
			}
			if let dict_err_str = dict["err_str"] {
				guard let _ = dict_err_str as? NSNull else {
					let err = NSError(domain:"MyMoneroJSCore", code:-1, userInfo:[ "err_str": dict_err_str as! String ])
					fn(err, nil)
					return
				}
			}
			let description = self._new_moneroWalletDescription_byParsing_dict(dict, mnemonicString)
			fn(nil, description)
		}
	}
	func MnemonicWordsetNameWithCurrentLocale(_ fn: @escaping (MoneroMnemonicWordsetName) -> Void)
	{
		let locale = NSLocale.current
		let languageCode = locale.languageCode ?? "en" // default to en
		self._callSync(.walletLocale, "MnemonicWordsetNameWithLocale", [ "\"\(languageCode)\"" ])
		{ (any, err) in
			let wordsetName = MoneroMnemonicWordsetName(rawValue: any as! String) // just going to assume it matches; TODO? check?
			fn(wordsetName!)
		}
	}
	func DecodeAddress(
		_ address: String,
		_ fn: @escaping (Error?, MoneroKeyDuo?) -> Void
	)
	{
		self._callSync(.core, "decode_address", [ "\"\(address)\"" ])
		{ (any, err) in
			if let err = err {
				NSLog("err \(err)")
				fn(err, nil)
				return
			}
			if let dict = any as? [String: AnyObject] {
				let view = dict["view"] as! MoneroKey
				let spend = dict["spend"] as! MoneroKey
				let keypair = MoneroKeyDuo(view: view, spend: spend)
				fn(nil, keypair)
				return
			}
			// TODO: throw?
		}
	}
	func New_VerifiedComponentsForLogIn(
		_ address: MoneroAddress,
		_ view_key: MoneroKey,
		spend_key_orNilForViewOnly: MoneroKey?,
		seed_orUndefined: MoneroSeed?,
		wasAGeneratedWallet: Bool,
		_ fn: @escaping (Error?, MoneroVerifiedComponentsForLogIn?) -> Void
	)
	{
		let args =
		[
			"\"\(address)\"",
			"\"\(view_key)\"",
			"\(spend_key_orNilForViewOnly != nil ? "\"\(spend_key_orNilForViewOnly!)\"" : "undefined")",
			"\(seed_orUndefined != nil ? "\"\(seed_orUndefined!)\"" : "undefined")",
			"\(wasAGeneratedWallet)"
		]
		self._callSync(.wallet, "VerifiedComponentsForLogIn_sync", args)
		{ (any, err) in
			if let err = err {
				NSLog("err \(err)")
				fn(err, nil)
				return
			}
			if let dict = any as? [String: AnyObject] {
				if let dict_err_str = dict["err_str"] {
					guard let _ = dict_err_str as? NSNull else {
						let err = NSError(domain:"MyMoneroJSCore", code:-1, userInfo:[ "err_str": dict_err_str as! String ])
						fn(err, nil)
						return
					}
				}
				let seed = dict["account_seed"] as! MoneroSeed
				let publicAddress = dict["address"] as! MoneroAddress
				let public_keys = dict["public_keys"] as! [String: AnyObject]
				let private_keys = dict["private_keys"] as! [String: AnyObject]
				let publicKeys = MoneroKeyDuo(
					view: public_keys["view"] as! MoneroKey,
					spend: public_keys["spend"] as! MoneroKey
				)
				let privateKeys = MoneroKeyDuo(
					view: private_keys["view"] as! MoneroKey,
					spend: private_keys["spend"] as! MoneroKey
				)
				let isInViewOnlyMode = dict["isInViewOnlyMode"] as! Bool
				let components = MoneroVerifiedComponentsForLogIn(
					seed: seed,
					publicAddress: publicAddress,
					publicKeys: publicKeys,
					privateKeys: privateKeys,
					isInViewOnlyMode: isInViewOnlyMode
				)
				fn(nil, components)
				return
			}
			// TODO: throw?
		}
	}
	func New_PaymentID(_ fn: @escaping (MoneroPaymentID) -> Void)
	{
		self._callSync(.paymentID, "New_TransactionID", nil)
		{ (any, err) in
			if let any = any {
				let paymentID = any as! MoneroPaymentID
				fn(paymentID)
				return
			}
			// TODO: throw?
		}
	}
	func Lazy_KeyImage(
		tx_pub_key: String,
		out_index: Int,
		publicAddress: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		_ fn: @escaping (Error?, MoneroKeyImage?) -> Void
	)
	{
		let args =
		[
			"\"\(tx_pub_key)\"",
			"\(out_index)",
			"\"\(publicAddress)\"",
			"\"\(view_key__private)\"",
			"\"\(spend_key__public)\"",
			"\"\(spend_key__private)\""
		]
		self._callSync(.keyImageCache, "Lazy_KeyImage", args)
		{ (any, err) in
			if let err = err {
				NSLog("err \(err)")
				fn(err, nil)
				return
			}
			fn(nil, any as? MoneroKeyImage)
		}
	}
	func MoneroAmountFormattedString(
		_ amount: MoneroAmount,
		_ fn: @escaping (Error?, String?) -> Void
	)
	{
		let args = [ "new mymonero_core_js.JSBigInt(\(amount))" ]
		self._callSync(.core, "formatMoney", args)
		{ (any, err) in
			if let err = err {
				NSLog("err \(err)")
				fn(err, nil)
				return
			}
			fn(nil, any as? String)
		}
	}
	func IsValidPaymentIDOrNoPaymentID(paymentId: String?) -> Bool
	{
		NSLog("Error: This method \(#function) is not implemented in the JS bridge. See MyMoneroCore.swift.") // TODO: throw? what is compile-time equiv?
		return false
	}
	func IsTransactionConfirmed(_ tx_height: Int, _ blockchain_height: Int) -> Bool
	{
		NSLog("Error: This method \(#function) is not implemented in the JS bridge. See MyMoneroCore.swift.") // TODO: throw? what is compile-time equiv?
		return false
	}
	func IsTransactionUnlocked(_ tx_unlockTime: Double?, _ blockchain_height: Int) -> Bool
	{
		NSLog("Error: This method \(#function) is not implemented in the JS bridge. See MyMoneroCore.swift.") // TODO: throw? what is compile-time equiv?
		return false
	}
	func TransactionLockedReason(_ tx_unlockTime: Double?, _ blockchain_height: Int) -> String
	{
		NSLog("Error: This method is not implemented in the JS bridge. See MyMoneroCore.swift.") // TODO: throw? what is compile-time equiv?
		return ""
	}
	//
	//
	// Internal - Accessors - Parsing/Factories
	//
	func _new_moneroWalletDescription_byParsing_dict(_ dict: [String: AnyObject], _ optl_passThrough_mnemonicString: MoneroSeedAsMnemonic?) -> MoneroWalletDescription
	{
		let mnemonicString = optl_passThrough_mnemonicString ?? dict["mnemonicString"] as! MoneroSeedAsMnemonic
		let seed = dict["seed"] as! MoneroSeed
		let keys = dict["keys"] as! [String: AnyObject]
		let spendKeys = keys["spend"] as! [String: AnyObject]
		let viewKeys = keys["view"] as! [String: AnyObject]
		let publicAddress = keys["public_addr"] as! MoneroAddress
		let publicKeys = MoneroKeyDuo(
			view: viewKeys["pub"] as! MoneroKey,
			spend: spendKeys["pub"] as! MoneroKey
		)
		let privateKeys = MoneroKeyDuo(
			view: viewKeys["sec"] as! MoneroKey,
			spend: spendKeys["sec"] as! MoneroKey
		)
		let description = MoneroWalletDescription(
			mnemonic: mnemonicString,
			seed: seed,
			publicAddress: publicAddress,
			publicKeys: publicKeys,
			privateKeys: privateKeys
		)
		return description
	}
	//
	//
	// Internal - Imperatives - Function calling
	//
	func _callSync(
		_ moduleName: MyMoneroCoreJS_ModuleName,
		_ functionName: String,
		_ argsAsJSFormattedStrings: [String]?,
		_ completionHandler: ((Any?, Error?) -> Void)?
	)
	{
		let args = argsAsJSFormattedStrings ?? []
		let joined_args = args.joined(separator: ",")
		let argsAreaString = joined_args
		let javaScriptString = "mymonero_core_js.\(moduleName.rawValue).\(functionName)(\(argsAreaString))"
		self._evaluateJavaScript(
			javaScriptString,
			completionHandler:
			{ (any, err) in
				if let err = err {
					NSLog("err \(err)")
				}
				if let any = any {
					NSLog("any \(any)")
				}
				if let completionHandler = completionHandler {
					completionHandler(any, err)
				}
			}
		)
	}
	//
	//
	// Internal - Imperatives - Javascript evaluating
	//
	func _evaluateJavaScript(
		_ javaScriptString: String,
		completionHandler: ((Any?, Error?) -> Void)?
	)
	{
		self.__evaluateJavaScript(
			javaScriptString,
			completionHandler: completionHandler,
			tryNumber: 0
		)
	}
	func __evaluateJavaScript(
		_ javaScriptString: String,
		completionHandler: ((Any?, Error?) -> Void)?,
		tryNumber: Int
	)
	{
		if (self.hasBooted == false) { // semi-janky but should be unlikely and finite
			let retryAfter_s = 0.1
			// TODO? check tryNumber * retryAfter_s < T?
			DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter_s)
			{
				self.__evaluateJavaScript(
					javaScriptString,
					completionHandler: completionHandler,
					tryNumber: (tryNumber + 1)
				)
			}
			return
		}
		self.webView.evaluateJavaScript(
			javaScriptString,
			completionHandler: completionHandler
		)
	}
	//
	//
	// Internal - Delegation - WKScriptMessageHandler
	//
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
	{ // not really used currently - possibly in the future for any necessarily async stuff
		NSLog("received message: \(message), \(message.body)")
	}
}
