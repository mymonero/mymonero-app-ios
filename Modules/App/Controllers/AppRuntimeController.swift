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
			
			
			
			let address = "43zxvpcj5Xv9SEkNXbMCG7LPQStHMpFCQCmkmR4u5nzjWwq5Xkv5VmGgYEsHXg4ja2FGRD5wMWbBVMijDTqmmVqm93wHGkg"
			let privateKeys = MoneroKeyDuo(
				view: "7bea1907940afdd480eff7c4bcadb478a0fbb626df9e3ed74ae801e18f53e104",
				spend: "4e6d43cd03812b803c6f3206689f5fcc910005fc7e91d50d79b0776dbefcd803"
			)
			self.walletsListController.OnceBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys(
				walletLabel: "m'wallet",
				swatchColor: .salmon,
				address: address,
				privateKeys: privateKeys,
				{ (err_str, wallet, wasWalletAlreadyInserted) in
					NSLog("err_str \(err_str.debugDescription)")
					NSLog("wallet \(wallet.debugDescription)")
					NSLog("wasWalletAlreadyInserted \(wasWalletAlreadyInserted.debugDescription)")
				},
				userCanceledPasswordEntry_fn:
				{
				}
			)
			
			
			
//			let seedAsMnemonicString = "foxes selfish humid nexus juvenile dodge pepper ember biscuit elapse jazz vibrate biscuit"
//			self.walletsListController.GivenBooted_ObtainPW_AddExtantWalletWith_MnemonicString(
//				walletLabel: "m'wallet",
//				swatchColor: .salmon,
//				mnemonicString: seedAsMnemonicString,
//				{ (err_str, wallet, wasWalletAlreadyInserted) in
//					if err_str != nil {
//						NSLog("err_str: \(err_str.debugDescription)")
//						return
//					}
//					NSLog("wallet \(wallet.debugDescription)")
//					NSLog("wasWalletAlreadyInserted \(wasWalletAlreadyInserted.debugDescription)")
//				},
//				{ // user canceled
//				}
//			)
			
			
			// Testing creating a new wallet:
//			self.walletsListController.CreateNewWallet_NoBootNoListAdd()
//			{ (err_str, walletInstance) in
//				if err_str != nil {
//					NSLog("err \(err_str!)")
//					return
//				}
//				NSLog("Created new wallet instance but not inserted or booted yet: \(walletInstance!)")
//				// …… gather info from user……
//				//
//				self.walletsListController.GivenBooted_ObtainPW_AddNewlyGeneratedWallet(
//					walletInstance: walletInstance!,
//					walletLabel: "Checking",
//					swatchColor: .salmon,
//					{ (err_str, addedWallet) in
//						if err_str != nil {
//							NSLog("err \(err_str!)")
//							return
//						}
//						NSLog("added/booted/logged in wallet \(addedWallet.debugDescription)")
//					}
//				)
//			}
		}
	}
}
