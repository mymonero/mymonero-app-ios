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
	func GivenBooted_ObtainPW_AddNewlyGeneratedWallet(
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
		if self.hasBooted == false {
			assert(false, "\(#function) shouldn't be called when list controller not yet booted")
			return
		}
		PasswordController.shared.OncePasswordObtained( // this will 'block' until we have access to the pw
			{ (password, passwordType) in
				walletInstance.Boot_byLoggingIn_givenNewlyCreatedWallet(
					walletLabel: walletLabel,
					swatchColor: swatchColor,
					{ (err_str) in
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
	}
//	func WhenBooted_ObtainPW_AddExtantWalletWith_MnemonicString(
//		walletLabel,
//		swatch,
//		mnemonicString,
//		fn, // fn: (err: Error?, walletInstance: Wallet, wasWalletAlreadyInserted: Bool?) -> Void
//		optl__userCanceledPasswordEntry_fn
//		)
//	{
//		const userCanceledPasswordEntry_fn = optl__userCanceledPasswordEntry_fn || function() {}
//		const self = this
//		const context = self.context
//		self.ExecuteWhenBooted(
//			function()
//				{
//					context.passwordController.WhenBootedAndPasswordObtained_PasswordAndType( // this will block until we have access to the pw
//						function(obtainedPasswordString, userSelectedTypeOfPassword)
//						{
//							_proceedWithPassword(obtainedPasswordString)
//						},
//						function()
//							{ // user canceled
//								userCanceledPasswordEntry_fn()
//						}
//					)
//					function _proceedWithPassword(persistencePassword)
//					{
//						var walletAlreadyExists = false
//						const wallets_length = self.records.length
//						for (let i = 0 ; i < wallets_length ; i++) {
//							const wallet = self.records[i]
//							if (wallet.mnemonicString === mnemonicString) {
//								// simply return existing wallet
//								fn(null, wallet, true) // wasWalletAlreadyInserted: true
//								return
//							}
//							// TODO: solve limitation of this code; how to check if wallet with same address (but no mnemonic) was already added?
//						}
//						//
//						const options =
//							{
//								failedToInitialize_cb: function(err, walletInstance)
//								{
//									fn(err)
//								},
//								successfullyInitialized_cb: function(walletInstance)
//								{
//									walletInstance.Boot_byLoggingIn_existingWallet_withMnemonic(
//										persistencePassword,
//										walletLabel,
//										swatch,
//										mnemonicString,
//										function(err) {
//											if (err) {
//												fn(err)
//												return
//											}
//											self._atRuntime__record_wasSuccessfullySetUp(walletInstance)
//											//
//											fn(null, walletInstance, false) // wasWalletAlreadyInserted: false
//										}
//									)
//								},
//								//
//								didReceiveUpdateToAccountInfo: function()
//								{ // TODO: bubble?
//								},
//								didReceiveUpdateToAccountTransactions: function()
//								{ // TODO: bubble?
//								}
//						}
//						const wallet = new Wallet(options, context)
//					}
//			}
//		)
//	}
//	func WhenBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys(
//		walletLabel,
//		swatch,
//		address,
//		view_key__private,
//		spend_key__private,
//		fn, // fn: (err: Error?, walletInstance: Wallet, wasWalletAlreadyInserted: Bool?) -> Void
//		optl__userCanceledPasswordEntry_fn
//		)
//	{
//		const userCanceledPasswordEntry_fn = optl__userCanceledPasswordEntry_fn || function() {}
//		const self = this
//		const context = self.context
//		self.ExecuteWhenBooted(
//			function()
//				{
//					context.passwordController.WhenBootedAndPasswordObtained_PasswordAndType( // this will block until we have access to the pw
//						function(obtainedPasswordString, userSelectedTypeOfPassword)
//						{
//							_proceedWithPassword(obtainedPasswordString)
//						},
//						function()
//							{ // user canceled
//								userCanceledPasswordEntry_fn()
//						}
//					)
//					function _proceedWithPassword(persistencePassword)
//					{
//						var walletAlreadyExists = false
//						const wallets_length = self.records.length
//						for (let i = 0 ; i < wallets_length ; i++) {
//							const wallet = self.records[i]
//							if (wallet.public_address === address) {
//								// simply return existing wallet; note: this wallet might have mnemonic and thus seed
//								// so might not be exactly what consumer of WhenBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys is expecting
//								fn(null, wallet, true) // wasWalletAlreadyInserted: true
//								return
//							}
//						}
//						//
//						const options =
//							{
//								failedToInitialize_cb: function(err, walletInstance)
//								{
//									fn(err)
//								},
//								successfullyInitialized_cb: function(walletInstance)
//								{
//									walletInstance.Boot_byLoggingIn_existingWallet_withAddressAndKeys(
//										persistencePassword,
//										walletLabel,
//										swatch,
//										address,
//										view_key__private,
//										spend_key__private,
//										function(err)
//										{
//											if (err) {
//												fn(err)
//												return
//											}
//											self._atRuntime__record_wasSuccessfullySetUp(walletInstance)
//											//
//											fn(null)
//										}
//									)
//								},
//								//
//								didReceiveUpdateToAccountInfo: function()
//								{ // TODO: bubble?
//								},
//								didReceiveUpdateToAccountTransactions: function()
//								{ // TODO: bubble?
//								}
//						}
//						const wallet = new Wallet(options, context)
//					}
//			}
//		)
//	}
}
