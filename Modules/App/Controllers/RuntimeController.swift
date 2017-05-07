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
			let address = "49ntR6oy9JQBWUKcsk7i7a1m4JA7WsK1cNDAhRmzLmvkUGbv3xGhM5UCvGmymLt2Jw2Pqz7PAvLLRAMYd84nnsnLKSWGd7h"
			self.mymoneroJSCore.DecodeAddress(
				address,
				{ (err, keypair) in
					NSLog("err, keypair: \(err), \(keypair)")
				}
			)
			//
			self.mymoneroJSCore.NewlyCreatedWallet({ walletDescription in
				NSLog("wallet desc \(walletDescription)")
			})
		}
	}
}
