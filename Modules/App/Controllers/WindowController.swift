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
		let _ = ThemeController.shared // so as to initialize it so it sets up appearance, mode, etc
		//
		window.rootViewController = self.rootViewController
	}
	func makeKeyAndVisible()
	{
		window.makeKeyAndVisible()
	}
}
