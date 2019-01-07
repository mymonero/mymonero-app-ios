//
//  FundsRequestsListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright (c) 2014-2019, MyMonero.com
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

class FundsRequestsListController: PersistedObjectListController
{
	//
	static let shared = FundsRequestsListController()
	//
	private init()
	{
		super.init(listedObjectType: FundsRequest.self)
	}
	func startObserving_walletsListController()
	{
		let c = WalletsListController.shared
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(PersistedObjectListController_Notifications_List_updated),
			name: PersistedObjectListController.Notifications_List.updated.notificationName,
			object: c
		)
	}
	//
	// Teardown
	func stopObserving_walletsListController()
	{
		let c = WalletsListController.shared
		NotificationCenter.default.removeObserver(
			self,
			name: PersistedObjectListController.Notifications_List.updated.notificationName,
			object: c
		)
	}
	//
	// Overrides
	override func overridable_deferBootUntil(_ fn: @escaping (_ err: String?) -> Void)
	{ // hopefully the following onceBooted doesn't need to get cancelled if WLC boot can be canceled - but I can't (yet?) see how it would be an issue
		WalletsListController.shared.onceBooted
		{ [weak self] in
			guard let thisSelf = self else {
				return
			}
			fn(nil) // no error
			thisSelf.startObserving_walletsListController()
		}
	}
	override func overridable_finalizeAndSortRecords()
	{
		// first, add any walletQRDisplayRequests which are missing
		for (_, o_w) in WalletsListController.shared.records.enumerated() {
			let wallet = o_w as! Wallet
			var hasRecord = false
			for (_, o_r) in self.records.enumerated() {
				let record = o_r as! FundsRequest
				if record.is_displaying_local_wallet == true {
					if record.to_address == wallet.public_address {
						hasRecord = true
						break
					}
				}
			}
			if hasRecord == false { // this is effectively the initial migration for older versions of the app which already have wallet records
				let instance = FundsRequest(
					from_fullname: nil,
					to_walletSwatchColor: nil,
					to_address: wallet.public_address,
					payment_id: nil,
					amount: nil,
					message: nil,
					description: nil,
					amountCurrency: nil,
					is_displaying_local_wallet: true
				)
				let _ = instance.saveToDisk() // ok to continue with error
				self._atRuntime__record_wasSuccessfullySetUp_noSortNoListUpdated(instance)
			}
		}
		// secondly, remove any qr display requests for now-deleted wallets
		var readyToSort_records = [FundsRequest]()
		for (_, o) in self.records.enumerated() {
			let record = o as! FundsRequest
			if record.is_displaying_local_wallet == true {
				let w = self.givenBootedWLC_findWallet(record.to_address, true /* suppress throw on not found */)
				if w != nil {
					readyToSort_records.append(record)
				} else {
					// leaving these behind - but they must be deleted or they will stack up in the app/user docs dir
					DDLog.Info("FundsRequests", "Dropping request because wallet was removed: \(record)")
					let _ = self.givenBooted_delete_noListUpdatedNotify(listedObject: record)
					// error not used, presently... this delete will be retried eventually
				}
			} else {
				readyToSort_records.append(record)
			}
		}
		// finally, sort
		self.records = readyToSort_records.sorted(by: { [weak self] (l, r) -> Bool in
			if l.is_displaying_local_wallet != true { // false or nil
				if r.is_displaying_local_wallet == true {
					return true
				}
			} else { // a is_displaying_local_wallet
				if (r.is_displaying_local_wallet != true) {
					return false
				}
				guard let thisSelf = self else {
					return false
				}
				let l_w = thisSelf.givenBootedWLC_findWallet(l.to_address)!
				let r_w = thisSelf.givenBootedWLC_findWallet(r.to_address)!
				return r_w.insertedAt_date! < l_w.insertedAt_date!
			}
			if l.insertedAt_date == nil {
				return false
			}
			if r.insertedAt_date == nil {
				return true
			}
			return l.insertedAt_date! > r.insertedAt_date!
		})
	}
	override func overridable_shouldSortOnEveryRecordAdditionAtRuntime() -> Bool
	{
		return true
	}
	//
	// Accessors
	func givenBootedWLC_findWallet(
		_ addr: String,
		_ suppressFatalErrorOnNotFound: Bool = false // optl; default false
	) -> Wallet? {
		assert(
			WalletsListController.shared.hasBooted,
			"code fault: givenBootedWLC_findWallet called while self.context.walletsListController.hasBooted!=true"
		)
		for (_, o) in WalletsListController.shared.records.enumerated() {
			let w = o as! Wallet
			if w.public_address == addr {
				return w
			}
		}
		if suppressFatalErrorOnNotFound != true {
			fatalError("Expected to find wallet for address") // TODO: maybe just filter FundsRequests which don't actually have wallets before this
		}
		return nil
	}
	//
	// Imperatives - Public - Adding
	func onceBooted_addFundsRequest(
		from_fullname: String?,
		to_walletSwatchColor: Wallet.SwatchColor,
		to_address: MoneroAddress,
		payment_id: MoneroPaymentID?,
		amount: String?,
		message: String?,
		description: String?,
		amountCurrency: CcyConversionRates.CurrencySymbol?, // needs to be nil if amt is nil
		_ fn: @escaping (_ err_str: String?, _ instance: FundsRequest?) -> Void
	) {
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					let instance = FundsRequest(
						from_fullname: from_fullname,
						to_walletSwatchColor: to_walletSwatchColor,
						to_address: to_address,
						payment_id: payment_id,
						amount: amount,
						message: message,
						description: description,
						amountCurrency: amountCurrency,
						is_displaying_local_wallet: false // to be clear
					)
					if let err_str = instance.saveToDisk() { // now we must save (insert) manually
						fn(err_str, nil)
						return
					}
					self._atRuntime__record_wasSuccessfullySetUp(instance)
					fn(nil, instance)
				},
				{ // user canceled
					assert(false) // not expecting this, according to UI
					fn("Code fault", nil)
				}
			)
		})
	}
	//
	// Delegation - Notifications
	@objc func PersistedObjectListController_Notifications_List_updated()
	{
		if self.hasBooted != true {
			DDLog.Warn("FundsRequests", "WLC updated but FRLC.hasBooted != true so, dropping.")
			return
		}
		self.overridable_finalizeAndSortRecords()
		self._listUpdated_records()
	}
}
