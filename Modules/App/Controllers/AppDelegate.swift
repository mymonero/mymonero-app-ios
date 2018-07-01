//
//  AppDelegate.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/3/17.
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
import UIKit
import WebKit

//@UIApplicationMain // intentionally commented - see main.swift

class AppDelegate: UIResponder, UIApplicationDelegate
{
	//
	// Constants
	enum NotificationNames: String
	{
		case willLockDownAppOn_didEnterBackground = "AppDelegate.NotificationNames.willLockDownAppOn_didEnterBackground"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	//
	// Properties
	var window: UIWindow?
	var windowController: WindowController!
	var appSingletonsController: AppSingletonsController!
	//
	// Overrides - Imperatives

	//
	// Delegation - UIApplicationDelegate
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
	) -> Bool {
		//
		// While launch screen still showing, let's take the chance to synchronously do any migrations:
		let _ = LocalDataMigrations.shared
		//
		//
		self.windowController = WindowController() // the window must be initialized after app finishes launching or nested UITabBarControllers will
		self.window = self.windowController.window // setting this as early as possible
		self.appSingletonsController = AppSingletonsController()
		//
		self.windowController.makeKeyAndVisible()
//		do { // apparently we don't need to do this… given new application:open:
//			if launchOptions != nil {
//				if let launchOptions_url = launchOptions![UIApplicationLaunchOptionsKey.url] as? URL {
//					let _ = URLOpening.appReceived(url: launchOptions_url)
//				}
//			}
//		}
		//
		return true
	}
	func application(
		_ application: UIApplication,
		open url: URL,
		sourceApplication: String?,
		annotation: Any
	) -> Bool {
		return URLOpening.shared.appReceived(url: url)
	}
	func application(
		_ app: UIApplication,
		open url: URL,
		options: [UIApplicationOpenURLOptionsKey : Any] = [:]
	) -> Bool {
		return URLOpening.shared.appReceived(url: url)
	}
	func applicationWillResignActive(_ application: UIApplication)
	{
		// goal is to lock down app before OS takes app screenshot for multitasker but we cannot use this method to do so b/c it gets called for a variety of temporary interruptions, such as asking for photos permissions
	}
	func applicationDidEnterBackground(_ application: UIApplication)
	{
		NotificationCenter.default.post(
			name: NotificationNames.willLockDownAppOn_didEnterBackground.notificationName,
			object: nil,
			userInfo: nil
		)
		PasswordController.shared.lockDownAppAndRequirePassword() // goal is to lock down app before OS takes app screenshot for multitasker
	}
	func applicationWillEnterForeground(_ application: UIApplication)
	{
	}

	func applicationDidBecomeActive(_ application: UIApplication)
	{
		// TODO: use this to cause wallet polling controller to immediately request?
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

