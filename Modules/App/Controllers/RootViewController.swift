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
		self.setup_presentationSingletons()
		//
		self.preEmptively_startObserving_passwordEntryNavigationViewController() // before the tab bar views are set up and cause the pw to be requested
		//
		self.setup_views()
		//
		self.startObserving_statusBarFrame()
	}
	func setup_presentationSingletons()
	{
		let _ = PasswordEntryPresentationController.shared // the shared PasswordEntryPresentationController must get set up first so it sets the passwordController's pw entry delegate before others cause the pw to be requested
		//
		let _ = ConnectivityMessagePresentationController.shared // ensure this starts observing
	}
	func setup_views()
	{
		self.view.backgroundColor = UIColor.contentBackgroundColor
		//
		//
		self.tabBarViewController = RootTabBarViewController()
		self.addChildViewController(tabBarViewController)
		self.view.addSubview(self.tabBarViewController.view)
	}
	func preEmptively_startObserving_passwordEntryNavigationViewController()
	{
		NotificationCenter.default.addObserver(self, selector: #selector(PasswordEntryNavigationViewController_willDismissView), name: PasswordEntryNavigationViewController.NotificationNames.willDismissView.notificationName, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(PasswordEntryNavigationViewController_willPresentInView), name: PasswordEntryNavigationViewController.NotificationNames.willPresentInView.notificationName, object: nil)
	}
	func startObserving()
	{
		self.startObserving_statusBarFrame()
	}
	func startObserving_statusBarFrame()
	{
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(UIApplicationWillChangeStatusBarFrame),
			name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame,
			object: nil
		)
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
	//
	// Delegation - Views - Layout - Overrides
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		var y: CGFloat!
		do {
			if let statusBarFrame = self._forLayout__to_statusBarFrame {
				y = statusBarFrame.size.height
			} else {
				y = 0
			}
		}
		self.tabBarViewController.view.frame = CGRect(
			x: 0,
			y: y,
			width: self.view.bounds.size.width,
			height: self.view.bounds.size.height - y
		)
	}
	//
	// Delegation - Notifications
	@objc func PasswordEntryNavigationViewController_willDismissView()
	{
		self.tabBarViewController.setTabBarItemButtonsInteractivityNeedsUpdateFromProviders()
	}
	@objc func PasswordEntryNavigationViewController_willPresentInView()
	{
		self.tabBarViewController.setTabBarItemButtonsInteractivityNeedsUpdateFromProviders()
	}
	//
	var _forLayout__to_statusBarFrame: CGRect?
	@objc func UIApplicationWillChangeStatusBarFrame(_ notification: Notification)
	{
		let to_statusBarFrame = notification.userInfo![UIApplicationStatusBarFrameUserInfoKey] as! NSValue
		self._forLayout__to_statusBarFrame = to_statusBarFrame.cgRectValue
		self.view.setNeedsLayout()
	}
}

