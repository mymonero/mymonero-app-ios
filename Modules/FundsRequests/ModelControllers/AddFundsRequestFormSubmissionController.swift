//
//  AddFundsRequestFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddFundsRequestFormSubmissionController
{
	struct Parameters
	{
		var optl__toWallet_color: Wallet.SwatchColor
		var toWallet_address: MoneroAddress
		var optl__fromContact_name: String?
		var paymentID: MoneroPaymentID?
		var amount: String?
		var optl__memo: String? // TODO: is this message, or really description?
//		var description: String? // no support yet
		//
		var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void
		var success_fn: (_ instance: FundsRequest) -> Void
	}
	var parameters: Parameters
	init(parameters: Parameters)
	{
		self.parameters = parameters
	}
	func handle()
	{
		FundsRequestsListController.shared.onceBooted_addFundsRequest(
			from_fullname: self.parameters.optl__fromContact_name,
			to_walletSwatchColor: self.parameters.optl__toWallet_color,
			to_address: self.parameters.toWallet_address,
			payment_id: self.parameters.paymentID,
			amount: self.parameters.amount,
			message: self.parameters.optl__memo,
			description: nil // self.parameters.message //
		)
		{ (err_str, instance) in
			if err_str != nil {
				self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
				return
			}
			self.parameters.success_fn(instance!)
		}
	}
}
