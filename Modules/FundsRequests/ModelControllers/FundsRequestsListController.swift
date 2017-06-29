//
//  FundsRequestsListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class FundsRequestsListController: PersistedObjectListController
{
	// initial
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
	//
	static let shared = FundsRequestsListController()
	//
	private init()
	{
		super.init(listedObjectType: FundsRequest.self)
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
	// Imperatives - Public - Adding
	func onceBooted_addFundsRequest(
		from_fullname: String?,
		to_walletSwatchColor: Wallet.SwatchColor,
		to_address: MoneroAddress,
		payment_id: MoneroPaymentID,
		amount: String?,
		message: String?,
		description: String?,
		_ fn: @escaping (_ err_str: String?, _ instance: FundsRequest?) -> Void
	)
	{
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
						description: description
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
}
