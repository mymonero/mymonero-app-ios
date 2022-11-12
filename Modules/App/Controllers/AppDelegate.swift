//
//  AppDelegate.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/3/17.
//  Copyright (c) 2014-2019, MyMonero.com
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
import UserNotifications

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
	var screenshotPreventionView: UIView?
	//
	// Overrides - Imperatives

	//
	// Delegation - UIApplicationDelegate
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
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
		// Push notification registration invocation
		registerForPushNotifications()
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
		options: [UIApplication.OpenURLOptionsKey : Any] = [:]
	) -> Bool {
		return URLOpening.shared.appReceived(url: url)
	}
	
	// Handle push notification instantiation
	func application(
	  _ application: UIApplication,
	  didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
	) {
	  let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
	  let token = tokenParts.joined()
	  print("Device Token: \(token)")
	}
	
	func application(
	  _ application: UIApplication,
	  didFailToRegisterForRemoteNotificationsWithError error: Error
	) {
	  print("Failed to register: \(error)")
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
		do {
			// It's important to ensure all highly sensitive data is not visible to the system screenshotter was made. Initial thought was to reconfigure the UI without animation to avoid having to call 'lock down' but since the problem is the screenshotter, a curtain is displayed instead. On user return, the enter password gate will be displayed instantly if the idle timer would have been up. Better UX
			let window = UIApplication.shared.keyWindow!
			let view = UIView()
			view.frame = window.bounds // critical
			view.backgroundColor = UIColor.contentBackgroundColor
			self.screenshotPreventionView = view
			window.addSubview(view)
		}
		
	}
	func applicationWillEnterForeground(_ application: UIApplication)
	{
		if let view = self.screenshotPreventionView {
			UserIdle.shared.checkIdleTimeout() // instantly lock down if needed - and preferably, before removing the ss prevention view			
			UIView.animate(
				withDuration: 0.15,
				delay: 0.2, // this delay allows the password entry view time to be shown - however some views don't reconfigure in time, so just for extra safety, a delay is included
				options: .beginFromCurrentState,
				animations: {
					view.alpha = 0
				}
			) { (finished) in
				// TODO: maybe animate this fading away
				view.removeFromSuperview() // must be removed
			}
		}
	}

	func applicationDidBecomeActive(_ application: UIApplication)
	{
		// TODO: use this to cause wallet polling controller to immediately request?
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	// New push message notification functionality for new project
	func getNotificationSettings() {
	  UNUserNotificationCenter.current().getNotificationSettings { settings in
		print("Notification settings: \(settings)")
		guard settings.authorizationStatus == .authorized else { return }
		DispatchQueue.main.async {
		  UIApplication.shared.registerForRemoteNotifications()
		}
	  }
	}
	
	func registerForPushNotifications() {
	  //1
		UNUserNotificationCenter.current()
		  .requestAuthorization(
			options: [.alert, .sound, .badge]) { [weak self] granted, _ in
			print("Permission granted: \(granted)")
			guard granted else { return }
			self?.getNotificationSettings()
		  }
	}
}

