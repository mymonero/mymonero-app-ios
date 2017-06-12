//
//  WalletsTabNavigationViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/7/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WalletsTabNavigationViewController: UINavigationController
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
		do {
			self.tabBarItem = UITabBarItem(
				title: nil,
				image: UIImage(named: "icon_tabBar_wallets")!.withRenderingMode(.alwaysOriginal),
				selectedImage: UIImage(named: "icon_tabBar_wallets__active")!.withRenderingMode(.alwaysOriginal)
			)
		}
		do {
			let viewController = WalletsListViewController()
			self.viewControllers = [ viewController ]
		}
	}
}
