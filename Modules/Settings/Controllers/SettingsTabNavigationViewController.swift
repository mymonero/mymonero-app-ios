//
//  SettingsTabNavigationViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/7/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class SettingsTabNavigationViewController: UINavigationController
{
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.tabBarItem = UITabBarItem(
			title: nil,
			image: UIImage(named: "icon_tabBar_settings")!.withRenderingMode(.alwaysOriginal),
			selectedImage: UIImage(named: "icon_tabBar_settings__active")!.withRenderingMode(.alwaysOriginal)
		)
	}
}
