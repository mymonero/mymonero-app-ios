//
//  RootViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class RootViewController: UIViewController
{
	var tabBarViewController: RootTabBarViewController!
	var passwordEntryNavigationViewController: PasswordEntryNavigationViewController!
	//
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
	{
		fatalError("\(#function) has not been implemented")
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("\(#function) has not been implemented")
	}
	init()
	{
		super.init(nibName: nil, bundle: nil)
		//
		self.setup_views()
	}
	@objc func PasswordEntryNavigationViewController_willDismissView()
	{
		self.tabBarViewController.setTabBarItemButtonsInteractivityNeedsUpdateFromProviders()
	}
	@objc func PasswordEntryNavigationViewController_willPresentInView()
	{
		self.tabBarViewController.disableTabBarItems()
	}
	func setup_views()
	{
		self.view.backgroundColor = UIColor.contentBackgroundColor
		//
		// this passwordEntryNavigationViewController must get set up first so it sets the passwordController's pw entry delegate before others cause the pw to be requested
		self.passwordEntryNavigationViewController = PasswordEntryNavigationViewController()
		do { // start observing (usually is split out, but should be fine here esp since we don't need to stop observing)
			NotificationCenter.default.addObserver(self, selector: #selector(PasswordEntryNavigationViewController_willDismissView), name: PasswordEntryNavigationViewController.NotificationNames.willDismissView.notificationName, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(PasswordEntryNavigationViewController_willPresentInView), name: PasswordEntryNavigationViewController.NotificationNames.willPresentInView.notificationName, object: nil)
		}
		//
		self.tabBarViewController = RootTabBarViewController()
		self.addChildViewController(tabBarViewController)
		self.view.addSubview(self.tabBarViewController.view)
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		self.stopObserving()
	}
	func stopObserving()
	{
		// TODO: technically, good idea to remove all notification observations
	}	
}

