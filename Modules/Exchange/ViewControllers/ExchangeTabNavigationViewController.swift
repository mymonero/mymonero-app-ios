//
//  ExchangeTabNavigationViewController.swift
//  MyMonero
//
//  Created by Karl Buys on 2020/10/27.
//  Copyright © 2020 MyMonero. All rights reserved.
//
//

import UIKit

class ExchangeTabNavigationViewController: UICommonComponents.NavigationControllers.SwipeableNavigationController
{
	let exchangeSendFundsViewController = ExchangeSendFundsForm.ViewController()
	//
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
			image: UIImage(named: "icon_tabBar_sendFunds")!.withRenderingMode(.alwaysOriginal),
			selectedImage: UIImage(named: "icon_tabBar_sendFunds__active")!.withRenderingMode(.alwaysOriginal)
		)
		self.viewControllers = [ self.exchangeSendFundsViewController ]
	}
}
