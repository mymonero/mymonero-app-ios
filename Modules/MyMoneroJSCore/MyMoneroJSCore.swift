//
//  MyMoneroJSCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

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
}
typealias MoneroMnemonicSeed = String
typealias MoneroAddress = String
typealias MoneroPaymentID = String
typealias MoneroKey = String
struct MoneroKeyDuo
{
	var view: MoneroKey
	var spend: MoneroKey
}
struct MoneroNewWalletDescription
{
	var mnemonic: MoneroMnemonicSeed
	var seed: String
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
}
enum MoneroMnemonicWordsetName: String
{
	case English = "english"
	case Japanese = "japanese"
	case Spanish = "spanish"
	case Portuguese = "portuguese"
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
	// Accessors
	func NewlyCreatedWallet(_ fn: @escaping (MoneroNewWalletDescription) -> Void)
	{
		self.MnemonicWordsetNameWithCurrentLocale({ wordsetName in
			self._callSync(.wallet, "NewlyCreatedWallet", [ wordsetName.rawValue ])
			{ (any, err) in
				if let dict = any as? [String: AnyObject] {
					let seed = dict["seed"] as! String
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
					let description = MoneroNewWalletDescription(
						mnemonic: dict["mnemonicString"] as! MoneroMnemonicSeed,
						seed: seed,
						publicAddress: publicAddress,
						publicKeys: publicKeys,
						privateKeys: privateKeys
					)
					fn(description)
				}
			}
		})
	}
	func MnemonicWordsetNameWithCurrentLocale(_ fn: @escaping (MoneroMnemonicWordsetName) -> Void)
	{
		let locale = NSLocale.current
		let languageCode = locale.languageCode ?? "en" // default to en
		self._callSync(.walletLocale, "MnemonicWordsetNameWithLocale", [ languageCode ])
		{ (any, err) in
			let wordsetName = MoneroMnemonicWordsetName(rawValue: any as! String) // just going to assume it matches; TODO? check?
			fn(wordsetName!)
		}
	}
	func New_PaymentID(_ fn: @escaping (MoneroPaymentID) -> Void)
	{
		self._callSync(.paymentID, "New_TransactionID", nil)
		{ (any, err) in
			if let any = any {
				let paymentID = any as! MoneroPaymentID
				fn(paymentID)
			}
			// TODO: throw?
		}
	}
	func DecodeAddress(
		_ address: String,
		_ fn: @escaping (Error?, MoneroKeyDuo?) -> Void
	)
	{
		self._callSync(.core, "decode_address", [ address ])
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
			}
			// TODO: throw?
		}
	}
	//
	// Internal - Imperatives - Function calling
	func _callSync(
		_ moduleName: MyMoneroCoreJS_ModuleName,
		_ functionName: String,
		_ argsAsJSStrings: [String]?,
		_ completionHandler: ((Any?, Error?) -> Void)?
	)
	{
		let args = argsAsJSStrings ?? []
		let joined_args = args.joined(separator: "\",\"")
		let argsAreaString = "\"\(joined_args)\""
		NSLog("argsAreaString \(argsAreaString)")
		let javaScriptString = "mymonero_core_js.\(moduleName.rawValue).\(functionName)(\(argsAreaString))"
		// TODO: investigate how to get the results of an async fn
		self._evaluateJavaScript(
			javaScriptString,
			completionHandler:
			{ (any, err) in
				NSLog("err \(err)")
				NSLog("any \(any)")
				if let completionHandler = completionHandler {
					completionHandler(any, err)
				}
			}
		)
	}
	//
	// Internal - Imperatives - Javascript evaluating
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
	{
		NSLog("received message: \(message), \(message.body)")
	}
}
