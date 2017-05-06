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
	case wallet = "monero_wallet_utils"
	case paymentID = "monero_paymentID_utils"
}

class MyMoneroCoreJS
{
	let window: UIWindow!
	let webView = WKWebView()
	var hasBooted = false
	//
	init(window: UIWindow)
	{
		self.window = window
		self.setup()
	}
	func setup()
	{
		self.setup_webView()
	}
	func setup_webView()
	{
		let filename = "mymonero-js-core-build"
		guard let filepath = Bundle.main.path(forResource: filename, ofType: "js") else {
			NSLog("❌  Can't find js file named \(filename)")
			return
		}
		guard let fileJSString = try? String(contentsOfFile:filepath, encoding:.utf8) else {
			NSLog("❌  Error while loading string contents of file named \(filename)")
			return
		}
		//
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
	
	func New_PaymentID(_ fn: @escaping (String) -> Void)
	{
		self._call(
			.paymentID,
			"New_TransactionID",
			nil,
			{ (any, err) in
				if let any = any {
					fn(any as! String)
				}
			}
		)
	}
	//
	// Internal - Imperatives - Function calling
	func _call(
		_ moduleName: MyMoneroCoreJS_ModuleName,
		_ functionName: String,
		_ args: [Any]?,
		_ completionHandler: ((Any?, Error?) -> Void)?
	)
	{
		let argsAreaString = "" // TODO
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
}
