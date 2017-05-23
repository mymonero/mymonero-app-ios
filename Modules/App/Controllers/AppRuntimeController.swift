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
	var windowController: WindowController!
	var walletsListController: WalletsListController!
	//
	init(windowController: WindowController)
	{
		self.windowController = windowController
		setup()
	}
	func setup()
	{
		self.walletsListController = WalletsListController()
		DispatchQueue.main.async
		{
//			self.walletsListController.CreateNewWallet_NoBootNoListAdd()
//			{ (err_str, listedObject) in
//				if err_str != nil {
//					NSLog("err \(err_str!)")
//				} else {
//					NSLog("inserted instance: \(listedObject!)")
//				}
//			}
		}
	}
}
