//
//  RuntimeController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import UIKit
import SwiftDate

class RuntimeController
{
	var windowController: WindowController!
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
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
		mymoneroCore = MyMoneroCore(window: windowController.window)
		hostedMoneroAPIClient = HostedMoneroAPIClient(mymoneroCore: mymoneroCore)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1)
		{

//			let moneroAmount = MoneroAmount.new(withDouble: 0.5)
//			NSLog("m \(moneroAmount)")
//			let formattedMoney = FormattedString(fromMoneroAmount: moneroAmount)
//			NSLog("f \(formattedMoney)")
			
			
//			let target_address = "43zxvpcj5Xv9SEkNXbMCG7LPQStHMpFCQCmkmR4u5nzjWwq5Xkv5VmGgYEsHXg4ja2FGRD5wMWbBVMijDTqmmVqm93wHGkg" // dark grey
////			"4APbcAKxZ2KPVPMnqa5cPtJK25tr7maE7LrJe67vzumiCtWwjDBvYnHZr18wFexJpih71Mxsjv8b7EpQftpB9NjPPXmZxHN" // light grey wallet
//			let amount = 0.01
//			let wallet__secretMnemonic = "idiom lumber jeans duration update selfish aunt hesitate buzzer volcano goat leech leech" // light grey
//			// "foxes selfish humid nexus juvenile dodge pepper ember biscuit elapse jazz vibrate biscuit" // dark grey
//			let wallet__wordsetName = MoneroMnemonicWordsetName.English
//			self.mymoneroCore.WalletDescriptionFromMnemonicSeed(wallet__secretMnemonic, wallet__wordsetName)
//			{ (err, walletDescription) in
//				NSLog("err \(err.debugDescription)")
//				NSLog("walletDescription \(walletDescription.debugDescription)")
//				if err != nil {
//					NSLog("Error \(err!)")
//					return
//				}
//				guard let walletDescription = walletDescription else {
//					NSLog("Unable to obtain wallet description")
//					return
//				}
//				SendFunds(
//					target_address: target_address,
//					amount: amount,
//					wallet__public_address: walletDescription.publicAddress,
//					wallet__private_keys: walletDescription.privateKeys,
//					wallet__public_keys: walletDescription.publicKeys,
//					mymoneroCore: self.mymoneroCore,
//					hostedMoneroAPIClient: self.hostedMoneroAPIClient,
//					payment_id:	"",
//					success_fn:
//					{ (tx_hash, tx_fee) in
//						NSLog("✅ Funds sent.")
//					},
//					failWithErr_fn:
//					{ (err_str) in
//						NSLog("❌ Error while sending funds: '\(err_str)'")
//					}
//				)
//			}
			
//			let url = New_RequestFunds_URL(
//				address: "44UW4sPKb4XbWHm8PXr6K8GQi7jUs9i7t2mTsjDn2zK7jYZwNERfoHaC1Yy4PYs1eTCZ9766hkB6RLUf1y95EvCQNpCZnuu",
//				amount: "1.4", // XMR
//				description: "For you",
//				paymentId: "9117db7d3a7bb4e4bdf0518715ecea1030b7b3fe44a59ff6c0497f971f4b18ed",
//				message: "hi, here are some special chars © ひらがな ⚠️"
//			)
//			NSLog("url is \(url)")
//			// alerting this because the console appears to have some kind of bug in printing escaped strings?
//			let alertController = UIAlertController(title: "Title", message: url.absoluteString, preferredStyle: UIAlertControllerStyle.alert)
//			let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
//			{ (result: UIAlertAction) -> Void in
//			}
//			alertController.addAction(okAction)
//			self.windowController.window.rootViewController!.present(alertController, animated: true, completion: nil)
			
			
//			let (err_str, parsedRequest) = New_ParsedRequest_FromURIString("monero://44UW4sPKb4XbWHm8PXr6K8GQi7jUs9i7t2mTsjDn2zK7jYZwNERfoHaC1Yy4PYs1eTCZ9766hkB6RLUf1y95EvCQNpCZnuu?tx_amount=1.4&tx_description=For%20you&tx_payment_id=9117db7d3a7bb4e4bdf0518715ecea1030b7b3fe44a59ff6c0497f971f4b18ed&tx_message=hi,%20here%20are%20some%20special%20chars%20%C2%A9%20%E3%81%B2%E3%82%89%E3%81%8C%E3%81%AA%20%E2%9A%A0%EF%B8%8F")
//			NSLog("err_str: \(err_str)")
//			NSLog("parsedRequest: \(parsedRequest)")
//			
			
			
			
//			let domain = "donate.moneroworld.com"
//			let records =
//			[
//				"oa1:xmr recipient_address=44UW4sPKb4XbWHm8PXr6K8GQi7jUs9i7t2mTsjDn2zK7jYZwNERfoHaC1Yy4PYs1eTCZ9766hkB6RLUf1y95EvCQNpCZnuu; recipient_name=Moneroworld; tx_payment_id=9117db7d3a7bb4e4bdf0518715ecea1030b7b3fe44a59ff6c0497f971f4b18ed"
//			]
//			let dnssec_used = false
//			let secured = false
//			let dnssec_fail_reason: String? = nil
//			let openAliasPrefix = "xmr"
//			let (err_str, validated_descriptions) = ValidatedOARecordsFromTXTRecordsWithOpenAliasPrefix(
//				domain: domain,
//				records: records,
//				dnssec_used: dnssec_used,
//				secured: secured,
//				dnssec_fail_reason: dnssec_fail_reason,
//				openAliasPrefix: openAliasPrefix
//			)
//			if let err_str = err_str {
//				NSLog("err_str \(err_str)")
//			}
//			if let validated_descriptions = validated_descriptions {
//				NSLog("validated_descriptions \(validated_descriptions)")
//			}
//			//
//			let isOAAddr = IsAddressNotMoneroAddressAndThusProbablyOAAddress(domain)
//			NSLog("isOAAddr \(isOAAddr)")
			
			
//			self.mymoneroCore.New_PaymentID({ paymentID in
//				NSLog("pid: \(paymentID)")
//			})
//			let isValidPID = self.mymoneroCore.IsValidPaymentIDOrNoPaymentID(paymentId: "3d2af3d25ddeedb8e679a6217043a6acc3949eeadd818cba2ede9abdfa3b7538")
//			NSLog("Is valid PID? \(isValidPID)")
			//
			//
//			let mnemonic_wordsetName = MoneroMnemonicWordsetName.English
//			let seedAsMnemonicString = "1union younger algebra emulate extra tribal awoken memoir tunnel wolf hamburger awning awning"
//			//
//			let account_seed = "1bc83e30aed0656998e7e0d5ae4701fb8"
//			//
//			let address = "45zapp8CdfW5Q3j8EFbyDoeKQXCCvJNQ99g4Y8DBuETx6cL8bUKW17WAbjaoUzqvb5E3Hiim91UQWJDeu6RYXzcj7Gfwdpp"
//			let private_viewKey = "c1146dd8fd04501ae1e640b27663cecf2fbb93407a8faf5d49f0393a7276110b"
//			let private_spendKey = "f3174dc0c2a623e07be6d3e90572d4ab67a72f134865eecbc7798d930f26ca06"
//			self.mymoneroCore.DecodeAddress(
//				address,
//				{ (err, keypair) in
//					NSLog("err, keypair: \(err), \(keypair)")
//				}
//			)
//			self.mymoneroCore.NewlyCreatedWallet({ walletDescription in
//				NSLog("newly generated wallet: \(walletDescription)")
//			})
//			self.mymoneroCore.MnemonicStringFromSeed(account_seed, mnemonic_wordsetName)
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
//			self.mymoneroCore.WalletDescriptionFromMnemonicSeed(seedAsMnemonicString, mnemonic_wordsetName)
//			{ (err, walletDescription) in
//				NSLog("err \(err.debugDescription)")
//				NSLog("walletDescription \(walletDescription.debugDescription)")
//			}
//			self.mymoneroCore.New_VerifiedComponentsForLogIn(
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
//			self.mymoneroCore.Lazy_KeyImage(
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
//			let blockchain_height = 1306517
//			let mock_tx_json: [String: Any] =
//			[
//				"hash": "253813442512d384d70453842bab22283b7a371e1f559ff3b8edf3b03379f01f",
//				"height": 1300696,
//				"unlock_time": Double(0), // parser should supply Double for this
//				"timestamp": Date().timeIntervalSince1970 - 999, // Double or TimeInterval
//				"total_received": "50000000000",
//				"total_sent": "0",
//				"amount": MoneroAmount("50000000000")!
//			]
//			let tx_height = mock_tx_json["height"] as! Int
//			let tx_unlockTime = mock_tx_json["unlock_time"] as! Double
//			let isConfirmed = self.mymoneroCore.IsTransactionConfirmed(tx_height, blockchain_height)
//			let isUnlocked = self.mymoneroCore.IsTransactionUnlocked(tx_unlockTime, blockchain_height)
//			let lockedReason = self.mymoneroCore.TransactionLockedReason(tx_unlockTime, blockchain_height)
//			NSLog("isConfirmed \(isConfirmed)")
//			NSLog("isUnlocked \(isUnlocked)")
//			NSLog("lockedReason \(lockedReason)")
		}
	}
}
