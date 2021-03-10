//
//  YatTabNavigationViewController.swift
//  MyMonero
//
//  Created by Karl Buys on 2021/03/09.
//  Copyright © 2021 MyMonero. All rights reserved.
//

import UIKit

class YatTabNavigationViewController: UICommonComponents.NavigationControllers.SwipeableNavigationController
{
	//let yatLandingPageViewController = YatIntroFirstPage.ViewController()
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
		NSLog("Invoked YatTabNavigation setup")
		self.tabBarItem = UITabBarItem(
			title: nil,
			image: UIImage(named: "YatLogo")!.withRenderingMode(.alwaysOriginal),
			selectedImage: UIImage(named: "YatLogo")!.withRenderingMode(.alwaysOriginal)
		)
		self.viewControllers = [ self.exchangeSendFundsViewController ]
	}
}

/*

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
			image: UIImage(named: "XMRtoBTCInactive")!.withRenderingMode(.alwaysOriginal),
			selectedImage: UIImage(named: "XMRtoBTCActive")!.withRenderingMode(.alwaysOriginal)
		)
		self.viewControllers = [ self.exchangeSendFundsViewController ]
	}
}


**/
