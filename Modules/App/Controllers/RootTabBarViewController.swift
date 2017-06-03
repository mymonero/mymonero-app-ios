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
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	func setup()
	{
		
	}
}
