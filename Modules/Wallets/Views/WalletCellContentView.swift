//
//  WalletCellContentView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WalletCellContentView: UIView
{
	deinit
	{
		self.prepareForReuse()
	}
	func prepareForReuse()
	{
		if self.object != nil {
			self.stopObserving_object()
			self.object = nil
		}
	}
	func stopObserving_object()
	{
		assert(self.object != nil)
		DDLog.Todo("Wallets", "stop observing wallet")
	}
	//
	var object: Wallet?
	func configure(withObject object: Wallet)
	{
		assert(self.object == nil)
		self.object = object
		//		self.cellContentView.configure(withWallet: wallet)
		self.startObserving_object()
	}
	func startObserving_object()
	{
		DDLog.Todo("Wallets", "start observing wallet")
	}
}
