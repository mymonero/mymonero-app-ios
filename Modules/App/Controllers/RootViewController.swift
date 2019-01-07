//
//  RootViewController.swift
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

class RootViewController: UIViewController
{
	//
	// Types
	enum NotificationNames: String {
		case didAppearForFirstTime = "RootViewController_NotificationNames_didAppearForFirstTime"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	//
	// Properties
	var tabBarViewController: RootTabBarViewController!
	//
	// Lifecycle - Init
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		fatalError("\(#function) has not been implemented")
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("\(#function) has not been implemented")
	}
	func setup()
	{
		//
		self.setup_presentationSingletons()
		self.preEmptively_startObserving_passwordEntryNavigationViewController() // before the tab bar views are set up and cause the pw to be requested
		//
		self.setup_views()
		//
		self.startObserving()
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
		self.edgesForExtendedLayout = [.top] // slide under status bar but handle root tab vc layout
		//
		do {
			let controller = RootTabBarViewController()
			self.tabBarViewController = controller
			self.addChild(controller)
			self.view.addSubview(controller.view)
		}
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
			name: UIApplication.willChangeStatusBarFrameNotification,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(UIApplicationDidChangeStatusBarFrame),
			name: UIApplication.didChangeStatusBarFrameNotification,
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
	// Delegation - Views - Visibility lifecycle
	var _hasAppeared: Bool = false
	override func viewDidAppear(_ animated: Bool)
	{
		let isFirstAppearance = self._hasAppeared == false
		self._hasAppeared = true
		//
		super.viewDidAppear(animated)
		//
		if isFirstAppearance {
			NotificationCenter.default.post(name: NotificationNames.didAppearForFirstTime.notificationName, object: nil)
		}
	}
	//
	// Delegation - Views - Layout - Overrides
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		self.tabBarViewController.view.frame = self.view.bounds
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
	@objc func UIApplicationWillChangeStatusBarFrame(_ notification: Notification)
	{
		self.view.setNeedsLayout()
	}
	@objc func UIApplicationDidChangeStatusBarFrame(_ notification: Notification)
	{
		self.view.setNeedsLayout()
	}
}

