//
//  WindowController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WindowController
{
	var window = UIWindow(frame: UIScreen.main.bounds)
	var rootViewController = RootViewController()
	//
	init()
	{
		window.rootViewController = rootViewController
	}
	func makeKeyAndVisible()
	{
		window.makeKeyAndVisible()
	}
}
