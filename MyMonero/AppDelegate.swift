//
//  AppDelegate.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
import JavaScriptCore
import WebKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
	) -> Bool
	{
		let filename = "mymonero-js-core-build"
		guard let filepath = Bundle.main.path(forResource: filename, ofType: "js") else {
			NSLog("❌  Can't find js file named \(filename)")
			return false
		}
		guard let fileJSString = try? String(contentsOfFile:filepath, encoding:.utf8) else {
			NSLog("❌  Error while loading string contents of file named \(filename)")
			return false
		}
		//
		let webView = WKWebView()
		webView.isHidden = true
		self.window!.addSubview(webView)
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
		
		return true
		
		
		
		
		
		
//		
//		guard let javascriptContext = JSContext() else {
//			NSLog("❌  Couldn't create JSContext")
//			return false
//		}
//		//
//		javascriptContext.exceptionHandler =
//		{ context, exception in
//			NSLog("❌  JS Exception: \(exception?.description ?? "unknown error")")
//		}
//		//
//		javascriptContext.evaluateScript(
//			"var console = { log: function(message) { _console_log(message) }, warn: function(message) { _console_warn(message) }, error: function(message) { _console_error(message) } };"
//		)
//		let console_log: @convention(block) (String) -> Void =
//		{ message in
//			NSLog("💬  INFO: JS Console: \(message)")
//		}
//		let console_warn: @convention(block) (String) -> Void =
//		{ message in
//			NSLog("⚠️  WARN: JS Console: \(message)")
//		}
//		let console_error: @convention(block) (String) -> Void =
//		{ message in
//			NSLog("❌  ERROR: JS Console: \(message)")
//		}
//		javascriptContext.setObject(console_log, forKeyedSubscript: "_console_log" as NSString)
//		javascriptContext.setObject(console_warn, forKeyedSubscript: "_console_warn" as NSString)
//		javascriptContext.setObject(console_error, forKeyedSubscript: "_console_error" as NSString)
//		//
//		javascriptContext.evaluateScript("var window = this;")
//		javascriptContext.evaluateScript("window.IsJavascriptCore = true;")
//		//
//		let filename = "mymonero-js-core-build"
//		guard let filepath = Bundle.main.path(forResource: filename, ofType: "js") else {
//			NSLog("❌  Can't find js file named \(filename)")
//			return false
//		}
//		guard let fileJSString = try? String(contentsOfFile:filepath, encoding:.utf8) else {
//			NSLog("❌  Error while loading string contents of file named \(filename)")
//			return false
//		}
//		NSLog("🔍  Loading \(filename).js")
//		if let jsValue = javascriptContext.evaluateScript(fileJSString) {
//			if jsValue.isUndefined == false {
//				NSLog("💬  evaluateScript('\(filename).js') returned: \(jsValue)")
//			}
//		}
//		//
//		let js__monero_utils = javascriptContext.objectForKeyedSubscript("monero_utils")
//		let js__monero_utils__rand32 = js__monero_utils?.objectForKeyedSubscript("rand_32")
//		let rn = js__monero_utils__rand32?.call(withArguments: [])
//		NSLog("rn: \(rn)")
//		

		//
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

