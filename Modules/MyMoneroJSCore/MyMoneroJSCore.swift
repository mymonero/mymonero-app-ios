//
//  MyMoneroJSCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit // because we use a WKWebView
import WebKit

enum MyMoneroCoreJS_ModuleName: String
{
	case moneroUtils = "monero_utils"
	case wallet = "monero_wallet_utils"
	case paymentID = "monero_paymentID_utils"
}

typealias MoneroPaymentID = String
struct MoneroKeyPair
{
	var view: String
	var spend: String
}

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
	func New_PaymentID(_ fn: @escaping (MoneroPaymentID) -> Void)
	{
		self._callSync(
			.paymentID,
			"New_TransactionID",
			nil,
			{ (any, err) in
				if let any = any {
					fn(any as! MoneroPaymentID)
				}
			}
		)
	}
	func DecodeAddress(
		_ address: String,
		_ fn: @escaping (Error?, MoneroKeyPair?) -> Void
	)
	{
		self._callSync(
			.moneroUtils,
			"decode_address",
			[ address ],
			{ (any, err) in
				if let err = err {
					NSLog("err \(err)")
					fn(err, nil)
					return
				}
				if let dict = any as? [String: AnyObject] {
					let view = dict["view"] as! String
					let spend = dict["spend"] as! String
					let keypair = MoneroKeyPair(view: view, spend: spend)
					fn(nil, keypair)
				}
			}
		)
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
