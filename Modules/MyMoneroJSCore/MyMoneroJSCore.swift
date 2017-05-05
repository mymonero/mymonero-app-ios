//
//  MyMoneroJSCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit // because we use a WKWebView
import WebKit

class MyMoneroCoreJS
{
	init?(window: UIWindow)
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
		let webView = WKWebView()
		webView.isHidden = true
		window.addSubview(webView)
		let htmlString = "<html><head></head><body></body></html>"
		webView.loadHTMLString(htmlString, baseURL: nil)
		//
		webView.evaluateJavaScript(fileJSString)
		{ (any, err) in
			NSLog("load any \(any)")
			NSLog("load err \(err)")
			
			//			webView.evaluateJavaScript("mymonero_core_js.monero_utils.rand_32()")
			//			{ (any, err) in
			//				NSLog("exec any \(any)")
			//				NSLog("exec err \(err)")
			//			}
			
			webView.evaluateJavaScript("mymonero_core_js.monero_wallet_utils.NewlyCreatedWallet(\"english\")")
			{ (any, err) in
				NSLog("exec any \(any)")
				NSLog("exec err \(err)")
			}
		}
	}
}
