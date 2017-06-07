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
	}
}
