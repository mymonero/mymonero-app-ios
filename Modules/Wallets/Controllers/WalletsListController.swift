//
//  WalletsListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class WalletsListController: PersistedObjectListController
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
		self.records = self.records.sorted(by: { (l, r) -> Bool in
			if l.insertedAt_date == nil {
				return false
			}
			if r.insertedAt_date == nil {
				return true
			}
			return l.insertedAt_date! > r.insertedAt_date!
		})
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
	//
	// Booted - Imperatives - Public - Wallets list
	//
	func CreateNewWallet_NoBootNoListAdd(
		_ fn: @escaping (_ err: String?, _ walletInstance: Wallet?) -> Void
	) -> Void
	{ // call this first, then call WhenBooted_ObtainPW_AddNewlyGeneratedWallet
		MyMoneroCore.shared.NewlyCreatedWallet
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
	) -> Void
	{
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
	) -> Void
	{
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					do {
						for (_, record) in self.records.enumerated() {
							let wallet = record as! Wallet
							if wallet.mnemonicString == mnemonicString {
								fn(nil, wallet, true) // wasWalletAlreadyInserted: true
								return
							}
							// TODO: solve limitation of this code - check if wallet with same address (but no mnemonic) was already added
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
	)
	{
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
	//
	// Delegation - Overrides - Booting reconstitution - Instance setup
	//
	override func overridable_booting_didReconstitute(listedObjectInstance: PersistableObject)
	{
		let wallet = listedObjectInstance as! Wallet
		wallet.Boot_havingLoadedDecryptedExistingInitDoc(
			{ err_str in
				if let err_str = err_str {
					DDLog.Error("Wallets", "Error while booting wallet: \(err_str)")
				}
			}
		)
	}
}
