//
//  ImportTransactionsModalFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/20/17.
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

extension ImportTransactionsModal
{
	class SubmissionController
	{
		struct Parameters
		{
			let fromWallet: Wallet
			let infoRequestParsingResult: HostedMonero.ParsedResult_ImportRequestInfoAndStatus
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
			self.parameters.fromWallet.sendFunds(
				target_address: target_address,
				amount: DoubleFromMoneroAmount(moneroAmount: amount), // TODO:? this may be a bit round-about
				payment_id: payment_id,
				priority: MoneroTransferSimplifiedPriority.defaultPriority, // .med
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
