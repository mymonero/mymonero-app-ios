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
	weak var wallet: Wallet? // prevent retain cycle since wallet owns self
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
			DDLog.Warn("Wallets", "_fetch_addressInfo called but request already exists")
			return
		}
		guard let wallet = self.wallet else {
			assert(self.wallet != nil)
			return
		}
		if wallet.isLoggedIn != true {
			DDLog.Error("Wallets", "Unable to do request while not isLoggedIn")
			return
		}
		if wallet.public_address == nil || wallet.public_address == "" {
			DDLog.Error("Wallets", "Unable to do request for wallet w/o public_address")
			return
		}
		if wallet.private_keys == nil {
			DDLog.Error("Wallets", "Unable to do request for wallet w/o private_keys")
			return
		}
		self.requestHandleFor_addressInfo = HostedMoneroAPIClient.shared.AddressInfo(
			address: wallet.public_address,
			view_key__private: wallet.private_keys.view,
			spend_key__public: wallet.public_keys.spend,
			spend_key__private: wallet.private_keys.spend,
			{ [unowned self] (err_str, parsedResult) in
//				if self == nil {
//					DDLog.Warn("Wallets.Wallet_HostPollingController", "self already nil")
//					return
//				}
				if self.requestHandleFor_addressInfo == nil {
					assert(false, "Already canceled")
					return
				}
				self.requestHandleFor_addressInfo = nil // first/immediately unlock this request fetch
				if err_str != nil {
					return // already logged err
				}
				guard let wallet = self.wallet else {
					DDLog.Warn("Wallets", "Wallet host polling request response returned but wallet already freed.")
					return
				}
				wallet._HostPollingController_didFetch_addressInfo(parsedResult!)
			}
		)
	}
	func _fetch_addressTransactions()
	{
		if self.requestHandleFor_addressTransactions != nil {
			DDLog.Warn("Wallets", "_fetch_addressInfo called but request already exists")
			return
		}
		guard let wallet = self.wallet else {
			assert(self.wallet != nil)
			return
		}
		if wallet.isLoggedIn != true {
			DDLog.Error("Wallets", "Unable to do request while not isLoggedIn")
			return
		}
		if wallet.public_address == nil || wallet.public_address == "" {
			DDLog.Error("Wallets", "Unable to do request for wallet w/o public_address")
			return
		}
		if wallet.private_keys == nil {
			DDLog.Error("Wallets", "Unable to do request for wallet w/o private_keys")
			return
		}
		self.requestHandleFor_addressTransactions = HostedMoneroAPIClient.shared.AddressTransactions(
			address: wallet.public_address,
			view_key__private: wallet.private_keys.view,
			spend_key__public: wallet.public_keys.spend,
			spend_key__private: wallet.private_keys.spend,
			{ [unowned self] (err_str, parsedResult) in
//				if self == nil {
//					DDLog.Warn("Wallets.Wallet_HostPollingController", "self already nil")
//					return
//				}
				if self.requestHandleFor_addressTransactions == nil {
					assert(false, "Already canceled")
					return
				}
				self.requestHandleFor_addressTransactions = nil // first/immediately unlock this request fetch
				if err_str != nil {
					return // already logged err
				}
				guard let wallet = self.wallet else {
					DDLog.Warn("Wallets", "Wallet host polling request response returned but wallet already freed.")
					return
				}
				wallet._HostPollingController_didFetch_addressTransactions(parsedResult!)
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
