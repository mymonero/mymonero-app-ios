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
	//
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
	//
	var passwordController: PasswordController!
	//
	var walletsListController: WalletsListController!
	//
	init(windowController: WindowController)
	{
		self.windowController = windowController
		setup()
	}
	func setup()
	{
		setup_mymoneroCore()
	}
	func setup_mymoneroCore()
	{
		self.mymoneroCore = MyMoneroCore(window: self.windowController.window)
		self.hostedMoneroAPIClient = HostedMoneroAPIClient(mymoneroCore: self.mymoneroCore)
		//
		self.passwordController = PasswordController()
		//
		self.walletsListController = WalletsListController(
			mymoneroCore: self.mymoneroCore,
			hostedMoneroAPIClient: self.hostedMoneroAPIClient,
			passwordController: self.passwordController
		)
		
		DispatchQueue.main.async
		{
			let listedObjectInsertDescription = WalletInsertDescription(
				walletLabel: "M'Wallet",
				generateNewWallet: true,
				mnemonicString: nil,
				address: nil,
				privateKeys: nil
			)
			self.walletsListController.InsertOne(withInitDescription: listedObjectInsertDescription)
			{ (err_str, listedObject) in
				if err_str != nil {
					NSLog("err \(err_str!)")
				} else {
					NSLog("inserted instance: \(listedObject!)")
				}
			}
		}
	}
}
