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
	func setup_views()
	{
		self.view.backgroundColor = UIColor.contentBackgroundColor
		//
		// this passwordEntryNavigationViewController must get set up first so it sets the passwordController's pw entry delegate before others cause the pw to be requested
		self.passwordEntryNavigationViewController = PasswordEntryNavigationViewController()
		//
		self.tabBarViewController = RootTabBarViewController()
		self.addChildViewController(tabBarViewController)
		self.view.addSubview(self.tabBarViewController.view)
	}
}

