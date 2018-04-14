//
//  Wallet_HostPollingController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/26/17.
//  Copyright (c) 2014-2018, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
import Foundation
//
class Wallet_HostPollingController
{
	weak var wallet: Wallet? // prevent retain cycle since wallet owns self
	var timer: Timer!
	//
	var requestHandleFor_addressInfo: HostedMonero.APIClient.RequestHandle?
	var requestHandleFor_addressTransactions: HostedMonero.APIClient.RequestHandle?
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
		// start polling:
		self.timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(__timerFired), userInfo: nil, repeats: true)
		// ^ just immediately going to jump into the runtime - so only instantiate self when you're ready to do this
		//
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
		self.requestHandleFor_addressInfo = HostedMonero.APIClient.shared.AddressInfo(
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
		self.requestHandleFor_addressTransactions = HostedMonero.APIClient.shared.AddressTransactions(
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
	@objc func __timerFired()
	{
		self.performRequests()
	}
}
