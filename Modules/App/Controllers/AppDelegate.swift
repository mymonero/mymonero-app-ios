//
//  AppDelegate.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
		case didSetUpWindowAndRuntime_willMakeWindowKeyAndVisible = "AppDelegate_NotificationNames_didSetUpWindowAndRuntime_willMakeWindowKeyAndVisible"
		case didSetUpWindowAndRuntime_didMakeWindowKeyAndVisible = "AppDelegate_NotificationNames_didSetUpWindowAndRuntime_didMakeWindowKeyAndVisible"
		//
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
	var appRuntimeController: AppRuntimeController!
	//
	// Overrides - Imperatives

	//
	// Delegation - UIApplicationDelegate
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
	) -> Bool
	{
		self.windowController = WindowController() // the window must be initialized after app finishes launching or nested UITabBarControllers will
		self.window = self.windowController.window // setting this as early as possible
		self.appRuntimeController = AppRuntimeController() // TODO: this contains some services - some of which request pw controller, like UserIdle - maybe this should be refactored or renamed. 'app runtime' too vague
		do { // the posting of these notifications should remain synchronous
			NotificationCenter.default.post(
				name: NotificationNames.didSetUpWindowAndRuntime_willMakeWindowKeyAndVisible.notificationName,
				object: nil
			)
			//
			self.windowController.makeKeyAndVisible()
			//
			NotificationCenter.default.post(
				name: NotificationNames.didSetUpWindowAndRuntime_didMakeWindowKeyAndVisible.notificationName,
				object: nil
			)
		}
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
	) -> Bool
	{
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

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

