//
//  RuntimeController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class RuntimeController
{
	var windowController: WindowController!
	var mymoneroJSCore: MyMoneroCoreJS!
	//
	init(windowController: WindowController)
	{
		self.windowController = windowController
		setup()
	}
	func setup()
	{
		setup_mymoneroJSCore()
	}
	func setup_mymoneroJSCore()
	{
		mymoneroJSCore = MyMoneroCoreJS(window: windowController.window)
	}
}
