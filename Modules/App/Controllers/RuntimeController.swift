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
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1)
		{
//			self.mymoneroJSCore.New_PaymentID({ paymentID in
//				NSLog("pid: \(paymentID)")
//			})
			//
			let address = "49ntR6oy9JQBWUKcsk7i7a1m4JA7WsK1cNDAhRmzLmvkUGbv3xGhM5UCvGmymLt2Jw2Pqz7PAvLLRAMYd84nnsnLKSWGd7h"
			let account_seed = "bc83e30aed0656998e7e0d5ae4701fb8"
			let mnemonic_wordsetName = MoneroMnemonicWordsetName.English
			let seedAsMnemonicString = "union younger algebra emulate extra tribal awoken memoir tunnel wolf hamburger awning awning"
//			self.mymoneroJSCore.DecodeAddress(
//				address,
//				{ (err, keypair) in
//					NSLog("err, keypair: \(err), \(keypair)")
//				}
//			)
			//
//			self.mymoneroJSCore.NewlyCreatedWallet({ walletDescription in
//				NSLog("newly generated wallet: \(walletDescription)")
//			})
			//
//			self.mymoneroJSCore.MnemonicStringFromSeed(account_seed, mnemonic_wordsetName)
//			{ (err, mnemonicString) in
//				NSLog("err \(err.debugDescription)")
//				NSLog("mnemonicString \(mnemonicString.debugDescription)")
//				guard let mnemonicString = mnemonicString else {
//					return
//				}
//				if seedAsMnemonicString != mnemonicString {
//					NSLog("err: strings unequal")
//				}
//			}
			self.mymoneroJSCore.WalletDescriptionFromMnemonicSeed(seedAsMnemonicString, mnemonic_wordsetName)
			{ (err, walletDescription) in
				NSLog("walletDescription \(walletDescription)")
			}
		}
	}
}
