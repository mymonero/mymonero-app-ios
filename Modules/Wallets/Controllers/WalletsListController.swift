//
//  WalletsListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class WalletsListController: PersistedListController
{
	// initial
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
	//
	init()
	{
		super.init(listedObjectType: Wallet.self)
	}
	//
	// Overrides
	override func overridable_sortRecords()
	{
		NSLog("TODO: sort on date added/inserted")
	}
}
