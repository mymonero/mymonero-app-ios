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
			
			let mnemonic_wordsetName = MoneroMnemonicWordsetName.English
			let seedAsMnemonicString = "union younger algebra emulate extra tribal awoken memoir tunnel wolf hamburger awning awning"
			//
			let account_seed = "bc83e30aed0656998e7e0d5ae4701fb8"
			//
			let address = "45zapp8CdfW5Q3j8EFbyDoeKQXCCvJNQ99g4Y8DBuETx6cL8bUKW17WAbjaoUzqvb5E3Hiim91UQWJDeu6RYXzcj7Gfwdpp"
			let private_viewKey = "c1146dd8fd04501ae1e640b27663cecf2fbb93407a8faf5d49f0393a7276110b"
			let private_spendKey = "f3174dc0c2a623e07be6d3e90572d4ab67a72f134865eecbc7798d930f26ca06"

			
			
//			self.mymoneroJSCore.New_PaymentID({ paymentID in
//				NSLog("pid: \(paymentID)")
//			})
//			self.mymoneroJSCore.DecodeAddress(
//				address,
//				{ (err, keypair) in
//					NSLog("err, keypair: \(err), \(keypair)")
//				}
//			)
//			self.mymoneroJSCore.NewlyCreatedWallet({ walletDescription in
//				NSLog("newly generated wallet: \(walletDescription)")
//			})
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
//			self.mymoneroJSCore.WalletDescriptionFromMnemonicSeed(seedAsMnemonicString, mnemonic_wordsetName)
//			{ (err, walletDescription) in
//				NSLog("walletDescription \(walletDescription)")
//			}
			self.mymoneroJSCore.New_VerifiedComponentsForLogIn(
				address,
				private_viewKey,
				spend_key_orNilForViewOnly: private_spendKey,
				seed_orUndefined: account_seed,
				wasAGeneratedWallet: false,
				{ (err, verifiedComponents) in
					NSLog("err: \(err)")
					NSLog("verifiedComponents: \(verifiedComponents)")
				}
			)
		}
	}
}
