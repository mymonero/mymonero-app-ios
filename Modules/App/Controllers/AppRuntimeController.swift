//
//  RuntimeController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
class AppRuntimeController
{
	init()
	{
		setup()
	}
	func setup()
	{
		let _ = UserIdle.shared // just to make sure it gets instantiated!
		let _ = URLOpening.shared // "
	}
}
