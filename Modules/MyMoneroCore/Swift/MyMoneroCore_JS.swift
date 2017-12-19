//
//  MyMoneroCore_JS.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright (c) 2014-2017, MyMonero.com
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
import UIKit // because we use a WKWebView
import WebKit
//
// Accessory types
enum MyMoneroCoreJS_ModuleName: String
{
	case core = "monero_utils"
	case responseParser = "api_response_parser_utils"
}
//
// Principal type
class MyMoneroCore_JS : NSObject, WKScriptMessageHandler
{
	// Interface - Singleton
	static let shared = MyMoneroCore_JS()
	//
	// Internal - Properties
	let window: UIWindow!
	var webView: WKWebView!
	var hasBooted = false
	//
	// Lifecycle - Init
	private convenience override init()
	{
		self.init(window: UIApplication.shared.delegate!.window!!)
	}
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
				DDLog.Error("MyMoneroCore", "Fatal err while evaluating Javascript on WebView load \(err)")
				assert(false, err.localizedDescription)
				//
				let exception = NSException(
					name: NSExceptionName("WebView JS eval err"),
					reason: err.localizedDescription,
					userInfo: (err as NSError).userInfo
				)
				exception.raise()
				//
				self.hasBooted = false
				//
				return
			}
			self.hasBooted = true
			if let returnedValue = returnedValue {
				DDLog.Info("MyMoneroCore", "Loaded \(returnedValue)")
			}
		}
	}
	//
	// Interface
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
	) -> Void {
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
	) -> Void {
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
	) {
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
