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
	init(
		mymoneroCore: MyMoneroCore,
		hostedMoneroAPIClient: HostedMoneroAPIClient
	)
	{
		super.init(
			listedObjectType: Wallet.self
		)
	}
}
