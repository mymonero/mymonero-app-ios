//
//  RootTabBarViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class RootTabBarViewController: UITabBarController
{
	var walletsTabViewController = WalletsTabNavigationViewController()
	var sendFundsTabViewController = SendFundsTabNavigationViewController()
	var fundsRequestsTabViewController = FundsRequestsTabNavigationViewController()
	var contactsTabViewController = ContactsTabNavigationViewController()
	//
	var settingsTabViewController = SettingsTabNavigationViewController()
	//
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	init()
	{
		super.init(nibName: nil, bundle: nil)
		//
		self.setup()
	}
	func setup()
	{
		self.setup_views()
		self.startObserving()
	}
	func setup_views()
	{
		self.tabBar.backgroundImage = UIImage(named: "tabBarBGColorImage")
		//
		self.viewControllers =
		[
			self.walletsTabViewController,
			self.sendFundsTabViewController,
			self.fundsRequestsTabViewController,
			self.contactsTabViewController,
			self.settingsTabViewController
		]
		//
		// vertically center tab bar item images
		let offset_y: CGFloat = 5
		for (_, viewController) in self.viewControllers!.enumerated() {
			viewController.tabBarItem.imageInsets = UIEdgeInsetsMake(offset_y, 0, -offset_y, 0)
		}
		//
		func __passwordController_didBoot()
		{
			self.setTabBarItemButtonsInteractivityNeedsUpdateFromProviders()
		}
		if PasswordController.shared.hasBooted == true {
			__passwordController_didBoot()
		} else {
			self.disableTabBarItems() // force-disable all while booting
			PasswordController.shared.onceBooted
			{
				__passwordController_didBoot()
			}
		}
	}
	func startObserving()
	{
		do { // passwordController
			let emitter = PasswordController.shared
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(PasswordController_didDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
				object: emitter
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(PasswordController_havingDeletedEverything_didDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.havingDeletedEverything_didDeconstructBootedStateAndClearPassword.notificationName,
				object: emitter
			)
		}
		do { // walletsListController
			NotificationCenter.default.addObserver(self, selector: #selector(WalletsListController_listUpdated), name: WalletsListController.Notifications_List.updated.notificationName, object: WalletsListController.shared)
		}
		do { // walletAppContactActionsCoordinator
			NotificationCenter.default.addObserver(self, selector: #selector(WalletAppContactActionsCoordinator_willTrigger_sendFundsToContact), name: WalletAppContactActionsCoordinator.NotificationNames.willTrigger_sendFundsToContact.notificationName, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(WalletAppContactActionsCoordinator_willTrigger_requestFundsFromContact), name: WalletAppContactActionsCoordinator.NotificationNames.willTrigger_requestFundsFromContact.notificationName, object: nil)
		}
		do { // urlOpeningController
			NotificationCenter.default.addObserver(self, selector: #selector(URLOpening_receivedMoneroURL(_:)), name: URLOpening.NotificationNames.receivedMoneroURL.notificationName, object: nil)
		}
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
	// Runtime - Imperatives
	func setTabBarItems(isEnabled: Bool)
	{
		for (_, viewController) in self.viewControllers!.enumerated() {
			viewController.tabBarItem.isEnabled = isEnabled
		}
	}
	func enableTabBarItems()
	{
		self.setTabBarItems(isEnabled: true)
	}
	func disableTabBarItems()
	{
		self.setTabBarItems(isEnabled: false)
	}
	func setTabBarItemButtonsInteractivityNeedsUpdateFromProviders()
	{
		// NOTE: for now, not going to involve a runloop of some kind - just going to configure each time cause it's cheap
		//
		// NOTE: unlike the JS app, I (PS) have decided to centralize the implementation of this. it has the trade-off that we don't have to repeat certain logic, and it reduces burden on tabs slightly, and I figured it was more or less equivalent in terms of architecture complexity as we have the enumeration of tabs in self anyway
		//
		let passwordController = PasswordController.shared
		let shouldDisable_tabsWhichRequireUserHavingEverEnteredPassword = passwordController.isUserChangingPassword || passwordController.hasUserSavedAPassword == false
		let shouldDisable_tabsWhichDontRequireAppWithExistingPasswordToBeUnlocked = passwordController.isUserChangingPassword // cause it doesn't matter if we have a pw or not
		//
		let shouldEnable_tabsWhichRequireAWallet = WalletsListController.shared.hasBooted && WalletsListController.shared.records.count != 0 // if wallets, enable ; hasBooted is mostly just to prevent us having to write more complex logic to check whether or not we should bother checking for records.count yet (i.e. the above conditions about password entry state)
		//
		let shouldDisable_nonWalletAndSettingsTabs = shouldDisable_tabsWhichRequireUserHavingEverEnteredPassword
			|| shouldDisable_tabsWhichDontRequireAppWithExistingPasswordToBeUnlocked
			|| shouldEnable_tabsWhichRequireAWallet == false
		//
		let shouldDisable_wallets = shouldDisable_tabsWhichDontRequireAppWithExistingPasswordToBeUnlocked // enable regardless of whether wallets exist
		let shouldDisable_sendFunds = shouldDisable_nonWalletAndSettingsTabs
		let shouldDisable_fundsRequests = shouldDisable_nonWalletAndSettingsTabs
		let shouldDisable_contacts = shouldDisable_nonWalletAndSettingsTabs
		let shouldDisable_settings = shouldDisable_tabsWhichDontRequireAppWithExistingPasswordToBeUnlocked // enable regardless of whether wallets exist
		//
		self.walletsTabViewController.tabBarItem.isEnabled = !shouldDisable_wallets
		self.sendFundsTabViewController.tabBarItem.isEnabled = !shouldDisable_sendFunds
		self.fundsRequestsTabViewController.tabBarItem.isEnabled = !shouldDisable_fundsRequests
		self.contactsTabViewController.tabBarItem.isEnabled = !shouldDisable_contacts
		self.settingsTabViewController.tabBarItem.isEnabled = !shouldDisable_settings
	}
	//
	func resetAllTabContentViewsToRootState(animated: Bool)
	{
		for (_, viewController) in self.viewControllers!.enumerated() {
			let navigationController = (viewController as! UINavigationController)
			navigationController.popToRootViewController(animated: animated)
			if let _ = navigationController.presentedViewController {
				navigationController.dismiss(animated: animated, completion: nil) // just in case - a variety of things could be open
			}			
		}
	}
	//
	func selectTab_wallets()
	{
		if self.walletsTabViewController.tabBarItem.isEnabled == false {
			DDLog.Warn("App", "Asked to \(#function) but it was disabled.")
			return
		}
		self.selectedIndex = 0
	}
	func selectTab_sendFunds()
	{
		if self.sendFundsTabViewController.tabBarItem.isEnabled == false {
			DDLog.Warn("App", "Asked to \(#function) but it was disabled.")
			return
		}
		self.selectedIndex = 1
	}
	func selectTab_fundsRequests()
	{
		if self.fundsRequestsTabViewController.tabBarItem.isEnabled == false {
			DDLog.Warn("App", "Asked to \(#function) but it was disabled.")
			return
		}
		self.selectedIndex = 2
	}
	func selectTab_contacts()
	{
		if self.contactsTabViewController.tabBarItem.isEnabled == false {
			DDLog.Warn("App", "Asked to \(#function) but it was disabled.")
			return
		}
		self.selectedIndex = 3
	}
	func selectTab_settings()
	{
		if self.settingsTabViewController.tabBarItem.isEnabled == false {
			DDLog.Warn("App", "Asked to \(#function) but it was disabled.")
			return
		}
		self.selectedIndex = 4
	}
	//
	// Delegation - Notifications
	@objc func PasswordController_didDeconstructBootedStateAndClearPassword()
	{ // do stuff like popping stack nav views to root views
		self.resetAllTabContentViewsToRootState(animated: false) // not animated
	}
	@objc func PasswordController_havingDeletedEverything_didDeconstructBootedStateAndClearPassword()
	{
		self.selectTab_wallets() // in case it was triggered by settings - if we didn't
		// select this tab it would look like nothing happened cause the 'enter pw' modal would not be popped as there would be nothing for the list controllers to decrypt
		self.setTabBarItemButtonsInteractivityNeedsUpdateFromProviders() // disable some until we have booted again
	}
	//
	@objc func WalletsListController_listUpdated()
	{ // if there are 0 wallets we don't want certain buttons to be enabled
		self.setTabBarItemButtonsInteractivityNeedsUpdateFromProviders()
	}
	func URLOpening_receivedMoneroURL(_ notification: Notification)
	{
		if PasswordController.shared.hasUserEnteredValidPasswordYet == false {
			DDLog.Info("RootTabBar", "User hasn't entered valid pw yet - ignoring URL")
			return
		}
		if PasswordController.shared.isUserChangingPassword {
			DDLog.Info("RootTabBar", "User is changing pw - ignoring URL")
			return
		}
		if WalletsListController.shared.records.count == 0 {
			DDLog.Info("RootTabBar", "No wallet - ignoring URL")
			return
		}
		self.selectTab_sendFunds()
	}
	func WalletAppContactActionsCoordinator_willTrigger_sendFundsToContact()
	{
		self.selectTab_sendFunds()
	}
	func WalletAppContactActionsCoordinator_willTrigger_requestFundsFromContact()
	{
		self.selectTab_fundsRequests()
	}
}
