//
//  Wallet_HostPollingController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/26/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
class Wallet_HostPollingController
{
	var wallet: Wallet!
	var timer: Timer!
	//
	var requestHandleFor_addressInfo: HostedMoneroAPIClient.RequestHandle?
	var requestHandleFor_addressTransactions: HostedMoneroAPIClient.RequestHandle?
	//
	//
	// Lifecycle - Init
	//
	init(wallet: Wallet)
	{
		self.wallet = wallet
		self.setup()
	}
	func setup()
	{
		self._setup_startPolling()
		// ^ just immediately going to jump into the runtime - so only instantiate self when you're ready to do this
	}
	func _setup_startPolling()
	{
		self.timer = Timer(timeInterval: 30, target: self, selector: #selector(__timerFired), userInfo: nil, repeats: true)
		self.performRequests()
	}
	//
	//
	// Lifecycle - Teardown
	//
	deinit
	{
		do {
			self.timer.invalidate()
			self.timer = nil
		}
		do {
			if let requestHandle = self.requestHandleFor_addressInfo {
				requestHandle.cancel()
				self.requestHandleFor_addressInfo = nil
			}
			if let requestHandle = self.requestHandleFor_addressTransactions {
				requestHandle.cancel()
				self.requestHandleFor_addressTransactions = nil
			}
		}
	}
	//
	//
	// Imperatives
	//
	func performRequests()
	{
		self._fetch_addressInfo()
		self._fetch_addressTransactions()
	}
	func _fetch_addressInfo()
	{
		if self.requestHandleFor_addressInfo != nil {
			NSLog("⚠️  _fetch_addressInfo called but request already exists")
			return
		}
		//
		if wallet.isLoggedIn != true {
			NSLog("❌  Unable to do request while not isLoggedIn")
			return
		}
		if wallet.public_address == nil || wallet.public_address == "" {
			NSLog("❌  Unable to do request for wallet w/o public_address")
			return
		}
		if wallet.private_keys == nil {
			NSLog("❌  Unable to do request for wallet w/o private_keys")
			return
		}
		self.requestHandleFor_addressInfo = HostedMoneroAPIClient.shared.AddressInfo(
			address: wallet.public_address,
			view_key__private: wallet.private_keys.view,
			spend_key__public: wallet.public_keys.spend,
			spend_key__private: wallet.private_keys.spend,
			{ (err_str, parsedResult) in
				self.requestHandleFor_addressInfo = nil // first/immediately unlock this request fetch
				if err_str != nil {
					return // already logged err
				}
				self.wallet._HostPollingController_didFetch_addressInfo(parsedResult!)
			}
		)
	}
	func _fetch_addressTransactions()
	{
		if self.requestHandleFor_addressTransactions != nil {
			NSLog("⚠️  _fetch_addressInfo called but request already exists")
			return
		}
		//
		if wallet.isLoggedIn != true {
			NSLog("❌  Unable to do request while not isLoggedIn")
			return
		}
		if wallet.public_address == nil || wallet.public_address == "" {
			NSLog("❌  Unable to do request for wallet w/o public_address")
			return
		}
		if wallet.private_keys == nil {
			NSLog("❌  Unable to do request for wallet w/o private_keys")
			return
		}
		self.requestHandleFor_addressInfo = HostedMoneroAPIClient.shared.AddressTransactions(
			address: wallet.public_address,
			view_key__private: wallet.private_keys.view,
			spend_key__public: wallet.public_keys.spend,
			spend_key__private: wallet.private_keys.spend,
			{ (err_str, parsedResult) in
				self.requestHandleFor_addressTransactions = nil // first/immediately unlock this request fetch
				if err_str != nil {
					return // already logged err
				}
				self.wallet._HostPollingController_didFetch_addressTransactions(parsedResult!)
			}
		)
	}
	//
	//
	// Delegation
	// 
	@objc
	func __timerFired()
	{
		self.performRequests()
	}
}
