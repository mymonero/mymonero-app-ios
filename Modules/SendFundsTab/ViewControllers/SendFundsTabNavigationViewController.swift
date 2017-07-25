//
//  SendFundsTabNavigationViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/7/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class SendFundsTabNavigationViewController: UINavigationController
{
	let sendFundsViewController = SendFundsForm.ViewController()
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
		self.viewControllers = [ self.sendFundsViewController ]
	}
}
