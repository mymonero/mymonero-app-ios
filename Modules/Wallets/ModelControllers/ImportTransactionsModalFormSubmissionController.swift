//
//  ImportTransactionsModalFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/20/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

extension ImportTransactionsModal
{
	class SubmissionController
	{
		struct Parameters
		{
			let fromWallet: Wallet
			let infoRequestParsingResult: HostedMoneroAPIClient_Parsing.ParsedResult_ImportRequestInfoAndStatus
			//
			var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void // aka error
			var success_fn: () -> Void
		}
		var parameters: Parameters
		// TODO:
//		var sendFunds_requestHandle: HostedMoneroAPIClient.RequestHandle?
		init(parameters: Parameters)
		{
			self.parameters = parameters
		}
		deinit
		{
			// TODO
//			self.cancel() // if any
		}
		//
		// Imperatives
		func handle()
		{
			let target_address = self.parameters.infoRequestParsingResult.payment_address
			let payment_id = self.parameters.infoRequestParsingResult.payment_id
			let amount = self.parameters.infoRequestParsingResult.import_fee
			self.parameters.fromWallet.SendFunds(
				target_address: target_address,
				amount: DoubleFromMoneroAmount(moneroAmount: amount), // TODO:? this may be a bit round-about
				payment_id: payment_id,
				success_fn:
				{ (transactionHash, sentAmount) in
					// TODO: show transactionHash to user somehow!
					self.parameters.success_fn()
				},
				failWithErr_fn:
				{ (err_str) in
					self.parameters.preSuccess_terminal_validationMessage_fn(err_str)
				}
			)
		}
		// TODO
//		func cancel()
//		{
//			if self.sendFunds_requestHandle != nil {
//				self.sendFunds_requestHandle!.cancel()
//				self.sendFunds_requestHandle = nil
//			}
//			// if someone else is cancelling this, or the cancel is actually going to succeed on a deinit, we'll assume the consumer is the one initiating the cancel, so there's no need to call a cb
//		}
	}
}
