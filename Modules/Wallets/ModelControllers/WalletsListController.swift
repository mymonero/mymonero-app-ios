//
//  WalletsListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
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

class WalletsListController: PersistedObjectListController
{
	//
	static let shared = WalletsListController()
	//
	// Lifecycle - Init
	private init()
	{
		super.init(listedObjectType: Wallet.self)
	}
	//
	// Lifecycle - Overrides
	override func setup_startObserving()
	{
		super.setup_startObserving()
		//
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(HostedMonero_NotificationNames_initializedWithNewServerURL),
			name: HostedMonero.NotificationNames.initializedWithNewServerURL.notificationName,
			object: nil
		)
	}
	override func stopObserving()
	{
		super.stopObserving()
		//
		NotificationCenter.default.removeObserver(self, name: SettingsController.NotificationNames_Changed.specificAPIAddressURLAuthority.notificationName, object: nil)
	}
	//
	// Runtime - Accessors - Derived properties
	var givenBooted_swatchesInUse: [Wallet.SwatchColor]
	{
		if self.hasBooted != true {
			assert(false, "givenBooted_swatchesInUse called when \(self) not yet booted.")
			return [] // this may be for the first wallet creation - let's say nothing in use yet
		}
		var inUseSwatches: [Wallet.SwatchColor] = []
		for (_, record) in self.records.enumerated() {
			let wallet = record as! Wallet
			if let swatchColor = wallet.swatchColor {
				inUseSwatches.append(swatchColor)
			}
		}
		return inUseSwatches
	}
	//
	// Accessors - Overrides
	override var overridable_wantsRecordsAppendedNotPrepended: Bool {
		return true
	}
	override func overridable_shouldSortOnEveryRecordAdditionAtRuntime() -> Bool {
		return true
	}
	//
	// Runtime - Imperatives - Overrides
	override func overridable_finalizeAndSortRecords()
	{
		self.records = self.records.sorted(by: { (l, r) -> Bool in
			if l.insertedAt_date == nil {
				return false
			}
			if r.insertedAt_date == nil {
				return true
			}
			return l.insertedAt_date! <= r.insertedAt_date!
		})
	}
	//
	// Booted - Imperatives - Public - Wallets list
	func CreateNewWallet_NoBootNoListAdd(
		_ localeCode: String,
		_ fn: @escaping (_ err: String?, _ walletInstance: Wallet?) -> Void
	) -> Void { // call this first, then call WhenBooted_ObtainPW_AddNewlyGeneratedWallet
		MyMoneroCore.shared_objCppBridge.NewlyCreatedWallet(
			localeCode,
			{ (err_str, walletDescription) in
				if err_str != nil {
					fn(err_str, nil)
					return
				}
				do {
					guard let wallet = try Wallet(ifGeneratingNewWallet_walletDescription: walletDescription!) else {
						fn("Unable to add wallet.", nil)
						return
					}
					fn(nil, wallet)
				} catch let e {
					fn(e.localizedDescription, nil)
					return
				}
			}
		)
	}
	func OnceBooted_ObtainPW_AddNewlyGeneratedWallet(
		walletInstance: Wallet,
		walletLabel: String,
		swatchColor: Wallet.SwatchColor,
		_ fn: @escaping (
			_ err_str: String?,
			_ walletInstance: Wallet?
		) -> Void,
		userCanceledPasswordEntry_fn: (() -> Void)? = {}
	) -> Void {
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					walletInstance.Boot_byLoggingIn_givenNewlyCreatedWallet(
						walletLabel: walletLabel,
						swatchColor: swatchColor,
						{ [unowned self] (err_str) in
							if err_str != nil {
								fn(err_str, nil)
								return
							}
							self._atRuntime__record_wasSuccessfullySetUp(walletInstance)
							//
							fn(nil, walletInstance)
						}
					)
				},
				{ // user canceled
					(userCanceledPasswordEntry_fn ?? {})()
				}
			)
		})
	}
	func OnceBooted_ObtainPW_AddExtantWalletWith_MnemonicString(
		walletLabel: String,
		swatchColor: Wallet.SwatchColor,
		mnemonicString: MoneroSeedAsMnemonic,
		_ fn: @escaping (
			_ err_str: String?,
			_ walletInstance: Wallet?,
			_ wasWalletAlreadyInserted: Bool?
		) -> Void,
		userCanceledPasswordEntry_fn: (() -> Void)? = {}
	) -> Void {
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					do { // check if wallet already entered
						for (_, record) in self.records.enumerated() {
							let wallet = record as! Wallet
							guard let wallet_mnemonicString = wallet.mnemonicString else {
								// TODO: solve limitation of this code - check if wallet with same address (but no mnemonic) was already added
								continue
							}
							let areMnemonicsEqual = MyMoneroCore.shared_objCppBridge.areEqualMnemonics(
								wallet_mnemonicString,
								mnemonicString
							)
							if areMnemonicsEqual { // must use this comparator to support partial-word mnemomnic strings
								fn(nil, wallet, true) // wasWalletAlreadyInserted: true
								return
							}
						}
					}
					do {
						guard let wallet = try Wallet(ifGeneratingNewWallet_walletDescription: nil) else {
							fn("Unknown error while adding wallet.", nil, nil)
							return
						}
						wallet.Boot_byLoggingIn_existingWallet_withMnemonic(
							walletLabel: walletLabel,
							swatchColor: swatchColor,
							mnemonicString: mnemonicString,
							persistEvenIfLoginFailed_forServerChange: false, // not forServerChange
							{ [unowned self] (err_str) in
								if err_str != nil {
									fn(err_str, nil, nil)
									return
								}
								self._atRuntime__record_wasSuccessfullySetUp(wallet)
								fn(nil, wallet, false) // wasWalletAlreadyInserted: false
							}
						)
					} catch let e {
						fn(e.localizedDescription, nil, nil)
						return
					}
				},
				{ // user canceled
					(userCanceledPasswordEntry_fn ?? {})()
				}
			)
		})
	}
	func OnceBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys(
		walletLabel: String,
		swatchColor: Wallet.SwatchColor,
		address: MoneroAddress,
		privateKeys: MoneroKeyDuo,
		_ fn: @escaping (
			_ err_str: String?,
			_ wallet: Wallet?,
			_ wasWalletAlreadyInserted: Bool?
		) -> Void,
		userCanceledPasswordEntry_fn: (() -> Void)? = {}
	) {
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					do {
						for (_, record) in self.records.enumerated() {
							let wallet = record as! Wallet
							if wallet.public_address == address {
								// simply return existing wallet; note: this wallet might have mnemonic and thus seed
								// so might not be exactly what consumer of GivenBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys is expecting
								fn(nil, wallet, true) // wasWalletAlreadyInserted: true
								return
							}
						}
					}
					do {
						guard let wallet = try Wallet(ifGeneratingNewWallet_walletDescription: nil) else {
							fn("Unknown error while adding wallet.", nil, nil)
							return
						}
						wallet.Boot_byLoggingIn_existingWallet_withAddressAndKeys(
							walletLabel: walletLabel,
							swatchColor: swatchColor,
							address: address,
							privateKeys: privateKeys,
							persistEvenIfLoginFailed_forServerChange: false, // not forServerChange
							{ [unowned self] (err_str) in
								if err_str != nil {
									fn(err_str, nil, nil)
									return
								}
								self._atRuntime__record_wasSuccessfullySetUp(wallet)
								fn(nil, wallet, false) // wasWalletAlreadyInserted: false
							}
						)
					} catch let e {
						fn(e.localizedDescription, nil, nil)
						return
					}
				},
				{ // user canceled
					(userCanceledPasswordEntry_fn ?? {})()
				}
			)
		})
	}
	//
	// Delegation - Overrides - Booting reconstitution - Instance setup
	override func overridable_booting_didReconstitute(listedObjectInstance: PersistableObject)
	{
		let wallet = listedObjectInstance as! Wallet
		if wallet.isLoggedIn {
			wallet.Boot_havingLoadedDecryptedExistingInitDoc(
				{ err_str in
					if let err_str = err_str {
						DDLog.Error("Wallets", "Error while booting wallet: \(err_str)")
					}
				}
			)
		} else {
			assert(wallet.isLoggingIn == false) // jic
			DDLog.Do("Wallets", "Wallet which was unable to log in was loaded. Attempting to reboot.")
			// going to treat this as a wallet which was saved but which failed to log in
			wallet.logOutThenSaveAndLogIn() // this method can handle being called when the wallet is not logged in
		}
	}
	//
	// Delegation - Notifications
	@objc func HostedMonero_NotificationNames_initializedWithNewServerURL()
	{
		// 'log out' all wallets by deleting their runtime state, then reboot them
		if self.hasBooted == false {
			assert(self.records.count == 0)
			return // nothing to do
		}
		assert(self.hasBooted, "code fault")
		if self.records.count == 0 {
			return // nothing to do
		}
		if PasswordController.shared.hasUserEnteredValidPasswordYet == false {
			assert(false, "App expected password to exist as wallets exist")
			return
		}
		for (_, object) in self.records.enumerated() {
			(object as! Wallet).logOutThenSaveAndLogIn()
		}
		self.__dispatchAsync_listUpdated_records() // probably not necessary
	}
}
