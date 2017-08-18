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
//
// Accessory types
enum MyMoneroCoreJS_ModuleName: String
{
	case core = "monero_utils"
	case wallet = "monero_wallet_utils"
	case walletLocale = "monero_wallet_locale"
	case paymentID = "monero_paymentID_utils"
	case responseParser = "api_response_parser_utils"
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
			DDLog.Error("MyMoneroCore", "Can't find js file named \(filename)")
			return
		}
		guard let fileJSString = try? String(contentsOfFile:filepath, encoding:.utf8) else {
			DDLog.Error("MyMoneroCore", "Error while loading string contents of file named \(filename)")
			return
		}
		//
		let configuration = WKWebViewConfiguration()
		configuration.userContentController.add(self, name: "javascriptEmissions") // not currently used - to (probably) be removed 
		self.webView = WKWebView(frame: .zero, configuration: configuration)
		webView.isHidden = true
		self.window.addSubview(webView)
		let htmlString = "<html><head></head><body></body></html>"
		webView.loadHTMLString(htmlString, baseURL: nil)
		//
		webView.evaluateJavaScript(fileJSString)
		{ [unowned self] (returnedValue, err) in
			if let err = err {
				DDLog.Error("MyMoneroCore", "Load err \(err)")
				return
			}
			self.hasBooted = true
			if let returnedValue = returnedValue {
				DDLog.Info("MyMoneroCore", "Loaded \(returnedValue)")
			}
		}
	}
	//
	//
	// Interface - Accessors
	//
	func NewlyCreatedWallet(_ fn: @escaping (_ err_str: String?, MoneroWalletDescription?) -> Void)
	{
		let wordsetName = MoneroMnemonicWordsetName.new_withCurrentLocale()
		self._callSync(.wallet, "NewlyCreatedWallet", [ "\"\(wordsetName.rawValue)\"" ])
		{ [unowned self] (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let dict = any as! [String: AnyObject]
			let description = self._new_moneroWalletDescription_byParsing_dict(dict, nil)
			fn(nil, description)
		}
	}
	func MnemonicStringFromSeed(
		_ account_seed: String,
		_ wordsetName: MoneroMnemonicWordsetName,
		_ fn: @escaping (_ err_str: String?, MoneroSeedAsMnemonic?) -> Void
	)
	{
		self._callSync(.wallet, "MnemonicStringFromSeed", [ "\"\(account_seed)\"", "\"\(wordsetName.rawValue)\"" ])
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let mnemonicString = any as! MoneroSeedAsMnemonic
			fn(nil, mnemonicString)
		}
	}
	func WalletDescriptionFromMnemonicSeed(
		_ mnemonicString: MoneroSeedAsMnemonic,
		_ wordsetName: MoneroMnemonicWordsetName,
		_ fn: @escaping (_ err_str: String?, MoneroWalletDescription?) -> Void
	)
	{
		self._callSync(.wallet, "SeedAndKeysFromMnemonic_sync", [ "\"\(mnemonicString)\"", "\"\(wordsetName.rawValue)\"" ])
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			guard let dict = any as? [String: AnyObject] else {
				// return err?
				DDLog.Error("MyMoneroCore", "Couldn't cast return value as [String: AnyObject]")
				return
			}
			if let dict_err_str = dict["err_str"] {
				guard let _ = dict_err_str as? NSNull else {
					fn(dict_err_str as? String, nil)
					return
				}
			}
			let description = self._new_moneroWalletDescription_byParsing_dict(dict, mnemonicString)
			assert(description.seed != "")
			fn(nil, description)
		}
	}
	func DecodeAddress(
		_ address: String,
		_ fn: @escaping (_ err_str: String?, _ decodedAddressComponents: MoneroDecodedAddressComponents?) -> Void
	)
	{
		self._callSync(.core, "decode_address", [ "\"\(address)\"" ])
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let dict = any as! [String: AnyObject]
			let view = dict["view"] as! MoneroKey
			let spend = dict["spend"] as! MoneroKey
			var intPaymentId = dict["intPaymentId"] as? MoneroPaymentID
			if intPaymentId == "" { // normalize
				intPaymentId = nil
			}
			let keypair = MoneroKeyDuo(view: view, spend: spend)
			let components = MoneroDecodedAddressComponents(
				publicKeys: keypair,
				intPaymentId: intPaymentId
			)
			fn(nil, components)
		}
	}
	func New_VerifiedComponentsForLogIn(
		_ address: MoneroAddress,
		_ view_key: MoneroKey,
		spend_key_orNilForViewOnly: MoneroKey?,
		seed_orNil: MoneroSeed?,
		wasAGeneratedWallet: Bool,
		_ fn: @escaping (_ err_str: String?, MoneroVerifiedComponentsForLogIn?) -> Void
	)
	{
		let args =
		[
			"\"\(address)\"",
			"\"\(view_key)\"",
			"\(spend_key_orNilForViewOnly != nil ? "\"\(spend_key_orNilForViewOnly!)\"" : "undefined")",
			"\(seed_orNil != nil ? "\"\(seed_orNil!)\"" : "undefined")",
			"\(wasAGeneratedWallet)"
		]
		self._callSync(.wallet, "VerifiedComponentsForLogIn_sync", args)
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let dict = any as! [String: AnyObject]
			if let dict_err_str = dict["err_str"] {
				guard let _ = dict_err_str as? NSNull else {
					fn(dict_err_str as? String, nil)
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
		}
	}
	func New_PaymentID(_ fn: @escaping (_ err_str: String?, _ paymentId: MoneroPaymentID?) -> Void)
	{
		self._callSync(.paymentID, "New_TransactionID", nil)
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let paymentID = any as! MoneroPaymentID
			fn(nil, paymentID)
		}
	}
	func New_FakeAddressForRCTTx(
		_ fn: @escaping (_ err_str: String?, _ address: MoneroAddress?) -> Void
	)
	{
		self._callSync(.core, "random_scalar", [])
		{ [unowned self] (err_str, any) in
			if let err_str = err_str {
				fn("Error generating random scalar: \(err_str)", nil)
				return
			}
			guard let scalar = any as? String else {
				fn("No result of public_addr found on result of random_scalar.", nil)
				return
			}
			self._callSync(.core, "create_address", [ scalar ])
			{ (err_str, any) in
				if let err_str = err_str {
					fn("Error creating address with random scalar: \(err_str)", nil)
					return
				}
				guard let dict = any as? [String: AnyObject] else {
					fn("No result of create_address found", nil)
					return
				}
				guard let address = dict["public_addr"] as? MoneroAddress else {
					fn("No result of public_addr found on result of create_address.", nil)
					return
				}
				fn(nil, address)
			}
		}
	}
	func CreateTransaction(
		wallet__public_keys: MoneroKeyDuo,
		wallet__private_keys: MoneroKeyDuo,
		splitDestinations: [SendFundsTargetDescription], // in RingCT=true, splitDestinations can equal fundTransferDescriptions
		usingOuts: [MoneroOutputDescription],
		mix_outs: [MoneroRandomAmountAndOutputs],
		fake_outputs_count: Int,
		fee_amount: MoneroAmount,
		payment_id: MoneroPaymentID?,
		pid_encrypt: Bool? = false,
		ifPIDEncrypt_realDestViewKey: MoneroKey?,
		unlock_time: Int,
		isRingCT: Bool? = true,
		_ fn: @escaping (_ err_str: String?, _ signedTxDescription_dict: MoneroSignedTransaction?) -> Void
	) -> Void
	{
		// Serialize all arguments into good inputs to .core.create_transaction
		let args: [String] =
		[
			wallet__public_keys.jsRepresentationString,
			wallet__private_keys.jsRepresentationString,
			SendFundsTargetDescription.jsArrayString(splitDestinations),
			MoneroOutputDescription.jsArrayString(usingOuts),
			MoneroRandomAmountAndOutputs.jsArrayString(mix_outs),
			"\(fake_outputs_count)",
			fee_amount.jsRepresentationString,
			payment_id != nil ? payment_id!.jsRepresentationString : "undefined", // undefined rather than "undefined"
			"\(pid_encrypt != nil ? pid_encrypt! : false)",
			ifPIDEncrypt_realDestViewKey != nil ? ifPIDEncrypt_realDestViewKey!.jsRepresentationString : "undefined", // undefined rather than "undefined" - tho the undefined case here should be able to be a garbage value
			"\(unlock_time)",
			"\(isRingCT != nil ? isRingCT! : true)",
		]
		// might be nice to assert arg length here or centrally via some fn name -> length map
		self._callSync(.core, "create_transaction", args)
		{ (err_str, any) in
			if let err_str = err_str {
				fn("Error creating signed transaction: \(err_str)", nil)
				return
			}
			guard let signedTxDescription_dict = any as? MoneroSignedTransaction else {
				fn("No result of create_transaction found.", nil)
				return
			}
			fn(nil, signedTxDescription_dict)
		}
	}
	func SerializeTransaction(
		signedTx: MoneroSignedTransaction,
		_ fn: @escaping (
			_ err_str: String?,
			_ serialized_signedTx: MoneroSerializedSignedTransaction?,
			_ tx_hash: String?
		) -> Void
	) -> Void
	{
		let json_String = __jsonStringForArg(fromJSONDict: signedTx)
		self._callSync(.core, "serialize_rct_tx_with_hash", [ json_String ])
		{ (err_str, any) in
			if let err_str = err_str {
				DDLog.Error("MyMoneroCore", "\(err_str)")
				fn("Error creating signed transaction.", nil, nil)
				return
			}
			guard let raw_tx_and_hash = any as? [String: Any] else {
				fn("No result of serialize_rct_tx_with_hash found.", nil, nil)
				return
			}
			guard let serialized_signedTx = raw_tx_and_hash["raw"] as? MoneroSerializedSignedTransaction else {
				fn("Couldn't get raw serialized signed transaction.", nil, nil)
				return
			}
			guard let tx_hash = raw_tx_and_hash["hash"] as? MoneroTransactionHash else {
				fn("Couldn't get raw serialized signed transaction.", nil, nil)
				return
			}
			fn(nil, serialized_signedTx, tx_hash)

		}
	}
	//
	//
	// Internal - Accessors - Parsing/Factories
	//
	func _new_moneroWalletDescription_byParsing_dict(_ dict: [String: AnyObject], _ optl_passThrough_mnemonicString: MoneroSeedAsMnemonic?) -> MoneroWalletDescription
	{
		let mnemonicString = optl_passThrough_mnemonicString ?? dict["mnemonicString"] as! MoneroSeedAsMnemonic
		let seed = dict["seed"] as! MoneroSeed
		assert(seed != "")
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
		_ completionHandler: ((
			_ err_str: String?,
			_ returnedValue: Any?
		
		) -> Void)?
	)
	{
		let args = argsAsJSFormattedStrings ?? []
		let joined_args = args.joined(separator: ",")
		let argsAreaString = joined_args
//		DDLog.Info("MyMoneroCore", "argsAreaString")
//		print(argsAreaString)
		let javaScriptString = "mymonero_core_js.\(moduleName.rawValue).\(functionName)(\(argsAreaString))"
		self._evaluateJavaScript(
			javaScriptString,
			completionHandler:
			{ (returnedValue, err) in
				var err_str: String?
				do {
					if let err = err {
						let err_NSError = err as NSError
						if let err_WKError = err_NSError as? WKError {
							switch err_WKError.code {
								case .javaScriptExceptionOccurred:
									let exceptionMessage = err_WKError.userInfo["WKJavaScriptExceptionMessage"] as! String // TODO: any constant declared for "WKJavaScriptExceptionMessage"?
									err_str = exceptionMessage
									break
								default:
									break // nothing to do - fall through to localizedDescription - at least for now. TODO?
							}
						}
						if err_str == nil { // if still nil
							// fall back to general case
							err_str = err.localizedDescription
						}
					}
					if let err_str = err_str {
						DDLog.Error("MyMoneroCore", "[.\(moduleName)/\(functionName)]: \"\(err_str)\"")
					}
				}
				if let completionHandler = completionHandler {
					completionHandler(err_str, returnedValue)
				}
			}
		)
	}
	//
	//
	// Internal - Accessors - Shared
	//
	func __jsonStringForArg(fromJSONDict jsonDict: [String: Any]) -> String
	{
		let json_Data =  try! JSONSerialization.data(
			withJSONObject: jsonDict,
			options: []
		)
		let json_String = String(data: json_Data, encoding: .utf8)!
		return json_String
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
			{ [unowned self] in
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
	{ // not really used currently - possibly in the future for any necessarily async & JS stuff
		DDLog.Info("MyMoneroCore", "received message: \(message), \(message.body)")
	}
}
