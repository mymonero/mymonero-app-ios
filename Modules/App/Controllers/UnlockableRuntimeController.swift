//
//  UnlockableRuntimeController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class UnlockableRuntimeController
{
	// initial
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
	// transient
	var walletsListController: WalletsListController?
	//
	init(
		mymoneroCore: MyMoneroCore,
		hostedMoneroAPIClient: HostedMoneroAPIClient
		// TODO: passwordsController
	)
	{
		self.mymoneroCore = mymoneroCore
		self.hostedMoneroAPIClient = hostedMoneroAPIClient
		//
		self.setup()
	}
	func setup()
	{
		self._awaitAppUnlock()
		
		
	}
	//
	func _awaitAppUnlock()
	{
		// TODO: start observing password controller
		self._appWasUnlocked()
	}
	func __loadUnlockedRuntime()
	{
		NSLog("💬  Unlocking app.")
		self.walletsListController = WalletsListController(
			mymoneroCore: self.mymoneroCore,
			hostedMoneroAPIClient: self.hostedMoneroAPIClient
		)
	}
	func __unloadLockedRuntime()
	{
		NSLog("💬  Locking app.")
		self.walletsListController = nil
	}
	//
	func _appWasUnlocked()
	{
		self.__loadUnlockedRuntime()
	}
	func _appWasLocked()
	{
		self.__unloadLockedRuntime()
	}
}
