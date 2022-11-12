//
//  SendFundsFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
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
//
extension SendFundsForm
{
	class SubmissionController
	{
		struct Parameters
		{
			//
			// Input values:
			var fromWallet: Wallet! // must we make this weak? effects?
			var amount_submittableDouble: Double?
			var isSweeping: Bool
			var priority: MoneroTransferSimplifiedPriority
			var isYatHandle: Bool
			//
			let selectedContact: Contact?
			let enteredAddressValue: String?
			//
			let resolvedAddress: String?
			let resolvedAddress_fieldIsVisible: Bool
			//
			let manuallyEnteredPaymentID: String?
			let manuallyEnteredPaymentID_fieldIsVisible: Bool
			//
			let resolvedPaymentID: String?
			let resolvedPaymentID_fieldIsVisible: Bool
			//
			// Process callbacks
			var preSuccess_nonTerminal_validationMessageUpdate_fn: (_ localizedString: String) -> Void
			var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void
			var preSuccess_passedValidation_willBeginSending: () -> Void
			var canceled_fn: () -> Void
			var success_fn: (
				_ mockedTransaction: MoneroHistoricalTransactionRecord,
				_ sentTo_address: MoneroAddress, // this may differ from enteredAddress.. e.g. std addr + short pid -> int addr
				_ isXMRAddressIntegrated: Bool, // regarding sentTo_address
				_ integratedAddressPIDForDisplay_orNil: MoneroPaymentID?
			) -> Void
			var resolvedYatHandle: Bool?
		}
		var parameters: Parameters
		init(parameters: Parameters)
		{
			self.parameters = parameters
			assert(self.parameters.isSweeping || self.parameters.amount_submittableDouble != nil)
		}
		// deinit already cancels request
		//
		// Imperatives
		func handle()
		{
			let hasPickedAContact = self.parameters.selectedContact != nil
			let manuallyEnteredPaymentID_exists = self.parameters.manuallyEnteredPaymentID != nil && self.parameters.manuallyEnteredPaymentID != ""
			let canUseManualPaymentID =
				manuallyEnteredPaymentID_exists
					&& self.parameters.manuallyEnteredPaymentID_fieldIsVisible
					&& !self.parameters.resolvedPaymentID_fieldIsVisible // but not if we have a resolved one!
			if canUseManualPaymentID && hasPickedAContact {
				assert(false, "canUseManualPaymentID shouldn't be true at same time as hasPickedAContact")
				// NOTE: That this is an exception will also be the case even if we are using the payment ID from a Funds Request QR code / URI because we set the request URI as a 'resolved' / "detected" payment id. So the `hasPickedAContact` usage above yields slight ambiguity in code and could be improved to encompass request uri pid "forcing"
				self.parameters.preSuccess_terminal_validationMessage_fn(
					NSLocalizedString("Code error while sending. Please contact support.", comment: "")
				)
				return
			}
			let amount_string = self.parameters.amount_submittableDouble != nil // human-understandable number, e.g. input 0.5 for 0.5 XMR
				? MoneyAmount.newMoneroAmountString(withAmountDouble: self.parameters.amount_submittableDouble!)
				: nil
			
			self.parameters.fromWallet.sendFunds(
				enteredAddressValue: self.parameters.enteredAddressValue,
				resolvedAddress: self.parameters.resolvedAddress,
				manuallyEnteredPaymentID: self.parameters.manuallyEnteredPaymentID,
				resolvedPaymentID: self.parameters.resolvedPaymentID,
				hasPickedAContact: hasPickedAContact,
				resolvedAddress_fieldIsVisible: self.parameters.resolvedAddress_fieldIsVisible,
				manuallyEnteredPaymentID_fieldIsVisible: self.parameters.manuallyEnteredPaymentID_fieldIsVisible,
				resolvedPaymentID_fieldIsVisible: self.parameters.resolvedPaymentID_fieldIsVisible,
				//
				contact_payment_id: self.parameters.selectedContact?.payment_id,
				cached_OAResolved_address: self.parameters.selectedContact?.cached_OAResolved_XMR_address,
				contact_hasOpenAliasAddress: self.parameters.selectedContact?.hasOpenAliasAddress,
				contact_address: self.parameters.selectedContact?.address,
				//
				raw_amount_string: amount_string,
				isSweeping: self.parameters.isSweeping,
				simple_priority: self.parameters.priority,
				//
				didUpdateProcessStep_fn: { [weak self] (msg) in
					guard let thisSelf = self else {
						return
					}
					thisSelf.parameters.preSuccess_nonTerminal_validationMessageUpdate_fn(msg)
				},
				success_fn: { [weak self] (sentTo_address, isXMRAddressIntegrated, integratedAddressPIDForDisplay_orNil, final_sentAmount, sentPaymentID_orNil, tx_hash, tx_fee, tx_key, mockedTransaction) in
					guard let thisSelf = self else {
						return
					}
					// formulate a mocked/transient historical transaction for details view presentation, and see if we need to present an "Add Contact From Sent" screen based on whether they sent w/o using a contact
					thisSelf._didSend(
						sentTo_address: sentTo_address,
						isXMRAddressIntegrated: isXMRAddressIntegrated,
						integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil,
						mockedTransaction: mockedTransaction
					)
				},
				canceled_fn: { [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.parameters.canceled_fn()
				},
				failWithErr_fn: { [weak self] (err_str) in
					guard let thisSelf = self else {
						return
					}
					thisSelf.parameters.preSuccess_terminal_validationMessage_fn(err_str)
				}
			)
		}
		//
		// Delegation
		func _didSend(
			sentTo_address: MoneroAddress,
			isXMRAddressIntegrated: Bool,
			integratedAddressPIDForDisplay_orNil: MoneroPaymentID?,
			mockedTransaction: MoneroHistoricalTransactionRecord
		) {
			if self.parameters.fromWallet == nil {
				assert(false, "FYI: wallet freed before end of SendFunds")
				return
			}
			do { // and fire off a request to have the wallet get the latest (real) tx records
				DispatchQueue.main.async
				{ [weak self] in
					guard let thisSelf = self else {
						return
					}
					guard let wallet = thisSelf.parameters.fromWallet else {
						return
					}
					wallet.hostPollingController?._fetch_addressTransactions() // TODO: fix up the API for this
				}
			}
			self.parameters.success_fn(
				mockedTransaction,
				sentTo_address,
				isXMRAddressIntegrated,
				integratedAddressPIDForDisplay_orNil
			)
		}
	}
}
