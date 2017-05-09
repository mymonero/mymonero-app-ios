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
			//
//			let mnemonic_wordsetName = MoneroMnemonicWordsetName.English
//			let seedAsMnemonicString = "union younger algebra emulate extra tribal awoken memoir tunnel wolf hamburger awning awning"
//			//
//			let account_seed = "bc83e30aed0656998e7e0d5ae4701fb8"
//			//
//			let address = "45zapp8CdfW5Q3j8EFbyDoeKQXCCvJNQ99g4Y8DBuETx6cL8bUKW17WAbjaoUzqvb5E3Hiim91UQWJDeu6RYXzcj7Gfwdpp"
//			let private_viewKey = "c1146dd8fd04501ae1e640b27663cecf2fbb93407a8faf5d49f0393a7276110b"
//			let private_spendKey = "f3174dc0c2a623e07be6d3e90572d4ab67a72f134865eecbc7798d930f26ca06"
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
//			self.mymoneroJSCore.New_VerifiedComponentsForLogIn(
//				address,
//				private_viewKey,
//				spend_key_orNilForViewOnly: private_spendKey,
//				seed_orUndefined: account_seed,
//				wasAGeneratedWallet: false,
//				{ (err, verifiedComponents) in
//					NSLog("err: \(err)")
//					NSLog("verifiedComponents: \(verifiedComponents)")
//				}
//			)
			//
//			let tx_pub_key = "0cd004e743df025b45559373fbd9010e0404f4b40b7d9d2c460ea96e23979264"
//			let out_index = 1
//			let public_address = "4APbcAKxZ2KPVPMnqa5cPtJK25tr7maE7LrJe67vzumiCtWwjDBvYnHZr18wFexJpih71Mxsjv8b7EpQftpB9NjPPXmZxHN"
//			let view_key__private = "b7f5c0663187b0a24ca88613d3ae5cfd592b9d3751dc230588c808a1fa903907"
//			let spend_key__public = "e759123b355ce4867492f73c67680b677e643c5b37673c76ad02a44684192947"
//			let spend_key__private = "7f714e8e238eda2a910b7084638404874dbd324ce6c26920d04d684e27c1560e"
//			self.mymoneroJSCore.Lazy_KeyImage(
//				tx_pub_key: tx_pub_key,
//				out_index: out_index,
//				publicAddress: public_address,
//				view_key__private: view_key__private,
//				spend_key__public: spend_key__public,
//				spend_key__private: spend_key__private,
//				{ (err, keyImage) in
//					NSLog("err \(err.debugDescription)")
//					NSLog("keyImage \(keyImage.debugDescription)")
//					if (keyImage != "a4e86abbe70116558e0d2e4079a13b46e87b1310da2819b54d99383dd9078eaa") {
//						NSLog("error: does not match")
//					}
//				}
//			)
			//
			let outputAmount = MoneroAmount(100000000000)
			self.mymoneroJSCore.MoneroAmountFormattedString(
				outputAmount,
				{ (err, string) in
					NSLog("err \(err)")
					NSLog("string \(string)")
				}
			)
		}
	}
}
