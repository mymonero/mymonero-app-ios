//
//  WindowController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WindowController
{
	//
	// Static - Convenience
	static var appDelegate: AppDelegate {
		return UIApplication.shared.delegate as! AppDelegate
	}
	static var windowController: WindowController? {
		guard let windowController = appDelegate.windowController else {
			let err_str = "WindowController.presentModalsInViewController called but windowController not yet initialized and set on appDelegate."
			DDLog.Warn("App", err_str)
			//			assert(false, err_str)
			return nil
		}
		return windowController
	}
	static var rootViewController: RootViewController? {
		guard let windowController = WindowController.windowController else {
			return nil
		}
		return windowController.rootViewController
	}
	static var rootTabBarViewController: RootTabBarViewController? {
		guard let rootViewController = WindowController.rootViewController else {
			return nil
		}
		return rootViewController.tabBarViewController
	}
	static var presentModalsInViewController: UIViewController? {
		return WindowController.rootViewController // the tab bar - so the connectivityView is still visibile.
	}
	//
	// Properties
	var window = UIWindow(frame: UIScreen.main.bounds)
	var rootViewController = RootViewController()
	//
	// Lifecycle - Init
	init()
	{
		self.setup()
	}
	func setup()
	{
		let _ = ThemeController.shared // so as to initialize it so it sets up appearance, mode, etc
		self.window.backgroundColor = UIColor.contentBackgroundColor
		//
		window.rootViewController = self.rootViewController
	}
	//
	// Accessors
	var presentModalsInViewController: UIViewController {
		return self.rootViewController.tabBarViewController // rather than the RootViewController, because we need to allow the ConnectivityMessageView embedded in RootViewController to be visible despite e.g. the passwordEntryViewController being presented
	}
	//
	// Imperatives
	func makeKeyAndVisible()
	{
		window.makeKeyAndVisible()
	}
}
