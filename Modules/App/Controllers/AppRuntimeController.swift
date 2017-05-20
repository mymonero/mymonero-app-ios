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

class AppRuntimeController
{
	var windowController: WindowController!
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
	var unlockableRuntimeController: UnlockableRuntimeController!
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
		unlockableRuntimeController = UnlockableRuntimeController(
			mymoneroCore: mymoneroCore,
			hostedMoneroAPIClient: hostedMoneroAPIClient
//			, passwordController: passwordController
		)
		
		DispatchQueue.main.async
		{
			// TODO: notify that app is ready?
		}
	}
}
