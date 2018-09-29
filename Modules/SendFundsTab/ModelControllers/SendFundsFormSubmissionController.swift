//
//  SendFundsFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
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
			if self.parameters.fromWallet.didFailToInitialize_flag == true {
				self.parameters.preSuccess_terminal_validationMessage_fn(
					NSLocalizedString("Unable to load that wallet.", comment: "")
				)
				return
			}
			if self.parameters.fromWallet.didFailToBoot_flag == true {
				self.parameters.preSuccess_terminal_validationMessage_fn(
					NSLocalizedString("Unable to log into that wallet.", comment: "")
				)
				return
			}
			let enteredAddressValue_exists = self.parameters.enteredAddressValue != "" && self.parameters.enteredAddressValue != nil // it will be valid if it exists
			let hasPickedAContact = self.parameters.selectedContact != nil
//			let notPickedContactBut_enteredAddressValue = !hasPickedAContact && enteredAddressValue_exists ? true : false
			//
			let resolvedAddress_exists = self.parameters.resolvedAddress != "" && self.parameters.resolvedAddress != nil // NOTE: it might be hidden, though!
			//
			let resolvedPaymentID_exists = self.parameters.resolvedPaymentID != "" // NOTE: it might be hidden, though!
			if self.parameters.resolvedPaymentID_fieldIsVisible {
				assert(resolvedPaymentID_exists)
			}
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
			var xmrAddress_toDecode: MoneroAddress! // may be integrated
			var paymentID_toUseOrToNilIfIntegrated: MoneroPaymentID?
			if hasPickedAContact { // we have already re-resolved the payment_id
				let contact = self.parameters.selectedContact!
				paymentID_toUseOrToNilIfIntegrated = contact.payment_id
				if contact.hasOpenAliasAddress {
					do { // ensure address indeed was able to be resolved - but UI should preclude it not having been by here
						if contact.cached_OAResolved_XMR_address == nil {
							assert(false)
							self.parameters.preSuccess_terminal_validationMessage_fn(
								NSLocalizedString("Unable to find a recipient address for this transfer. This may be a bug.", comment: "")
							)
							return
						}
					}
					xmrAddress_toDecode = contact.cached_OAResolved_XMR_address! // We can just use the cached_OAResolved_XMR_address because in order to have picked this contact and for the user to hit send, we'd need to have gone through an OA resolve (_didPickContact)
				} else {
					xmrAddress_toDecode = contact.address
				}
			} else {
				if enteredAddressValue_exists == false {
					self.parameters.preSuccess_terminal_validationMessage_fn(
						NSLocalizedString("Please specify the recipient of this transfer.", comment: "")
					)
					return
				}
				let enteredAddressValue = self.parameters.enteredAddressValue!
				// address input via text input…
				let is_enteredAddressValue_OAAddress = OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(
					enteredAddressValue
				)
				if is_enteredAddressValue_OAAddress {
					if self.parameters.resolvedAddress_fieldIsVisible == false || resolvedAddress_exists == false {
						self.parameters.preSuccess_terminal_validationMessage_fn(
							NSLocalizedString("Couldn't resolve this OpenAlias address.", comment: "")
						)
						return
					}
					xmrAddress_toDecode = self.parameters.resolvedAddress!
					paymentID_toUseOrToNilIfIntegrated = self.parameters.resolvedPaymentID_fieldIsVisible ? self.parameters.resolvedPaymentID : canUseManualPaymentID ? self.parameters.manuallyEnteredPaymentID : nil
				} else { // then it's an XMR address
					xmrAddress_toDecode = enteredAddressValue
					// we don't care whether it's an integrated address or not here since we're not going to use its payment id
					if canUseManualPaymentID {
						if self.parameters.resolvedPaymentID_fieldIsVisible {
							assert(false)
							self.parameters.preSuccess_terminal_validationMessage_fn(
								NSLocalizedString("Detected payment ID unexpectedly visible while manual input field visible. This could be a bug.", comment: "")
							)
							return
						}
						paymentID_toUseOrToNilIfIntegrated = self.parameters.manuallyEnteredPaymentID! // ! to be explicit
					} else if self.parameters.resolvedPaymentID_fieldIsVisible {
						paymentID_toUseOrToNilIfIntegrated = self.parameters.resolvedPaymentID! // ! to be explicit
					}
				}
			}
			assert(xmrAddress_toDecode != nil)
			//
			let (err_str, decodedAddressComponents) = MyMoneroCore.shared_objCppBridge.decoded(address: xmrAddress_toDecode)
			if err_str != nil {
				self.parameters.preSuccess_terminal_validationMessage_fn(
					NSLocalizedString(
						String(format: "Couldn't validate destination Monero address of %@.", xmrAddress_toDecode),
						comment: ""
					)
				)
				return
			}
			if decodedAddressComponents!.intPaymentId != nil { // is integrated address!
				self._proceedTo_generateSendTransaction(
					withTargetAddress: xmrAddress_toDecode, // for integrated addrs, we don't want to extract the payment id and then use the integrated addr as well (TODO: unless we use fluffy's patch?)
					payment_id: nil,
					isXMRAddressIntegrated: true,
					integratedAddressPIDForDisplay_orNil: decodedAddressComponents!.intPaymentId
				)
				return
			}
			let paymentID_orNil = paymentID_toUseOrToNilIfIntegrated
			// since we may have a payment ID here (which may also have been entered manually), validate
			if MoneroUtils.PaymentIDs.isAValidOrNotA(paymentId: paymentID_orNil) == false { // convenience function - will be true if nil pid
				self.parameters.preSuccess_terminal_validationMessage_fn(
					NSLocalizedString("Please enter a valid payment ID.", comment: "")
				)
				return
			}
			do { // short pid / integrated address coersion
				if paymentID_orNil != nil {
					if decodedAddressComponents!.isSubaddress != true { // this is critical or funds will be lost!!
						if paymentID_orNil!.count == MoneroUtils.PaymentIDs.Variant.short.charLength { // a short one
							assert(decodedAddressComponents!.isSubaddress != true)
							if decodedAddressComponents!.isSubaddress {
								fatalError("Code fault: missing isSubaddress == false check")
							}
							let fabricated_integratedAddress_orNil = MyMoneroCore.shared_objCppBridge.New_IntegratedAddress( // construct integrated address
								fromStandardAddress: xmrAddress_toDecode as MoneroStandardAddress, // the monero one
								short_paymentID: paymentID_orNil! as MoneroShortPaymentID // short pid
							)
							if fabricated_integratedAddress_orNil == nil {
								self.parameters.preSuccess_terminal_validationMessage_fn(
									NSLocalizedString(
										String(format: "Couldn't construct integrated address with short payment ID."),
										comment: ""
									)
								)
								return
							}
							self._proceedTo_generateSendTransaction(
								withTargetAddress: fabricated_integratedAddress_orNil!,
								payment_id: nil, // must now zero this or Send will throw a "pid must be blank with integrated addr"
								isXMRAddressIntegrated: true,
								integratedAddressPIDForDisplay_orNil: paymentID_orNil! // a short pid
							)
							return // return early to prevent fall-through to non-short or zero pid case
						}
					}
				}
			}
			self._proceedTo_generateSendTransaction(
				withTargetAddress: xmrAddress_toDecode, // therefore, non-integrated normal XMR address
				payment_id: paymentID_toUseOrToNilIfIntegrated, // may still be nil
				isXMRAddressIntegrated: false,
				integratedAddressPIDForDisplay_orNil: nil
			)
		}
		func _proceedTo_generateSendTransaction(
			withTargetAddress target_address: MoneroAddress,
			payment_id: MoneroPaymentID?,
			isXMRAddressIntegrated: Bool,
			integratedAddressPIDForDisplay_orNil: MoneroPaymentID?
		) {
			self.parameters.preSuccess_passedValidation_willBeginSending()
			let statusMessage_prefix = self.parameters.isSweeping
				? NSLocalizedString("Sending wallet balance…", comment: "")
				: String(
					format: NSLocalizedString("Sending %@ XMR…", comment: ""),
					MoneroAmount.new(withDouble: self.parameters.amount_submittableDouble!).localized_formattedString
				)
			self.parameters.preSuccess_nonTerminal_validationMessageUpdate_fn(statusMessage_prefix) // start with just prefix
			//
			self.parameters.fromWallet.sendFunds(
				target_address: target_address,
				amount_orNilIfSweeping: self.parameters.amount_submittableDouble,
				isSweeping: self.parameters.isSweeping,
				payment_id: payment_id,
				integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil,
				priority: self.parameters.priority,
				didUpdateProcessStep_fn:
				{ [weak self] (processStep) in
					guard let thisSelf = self else {
						return
					}
					let str = statusMessage_prefix + " " + processStep.localizedDescription // TODO: localize this concatenation
					thisSelf.parameters.preSuccess_nonTerminal_validationMessageUpdate_fn(str)
				},
				success_fn:
				{ [weak self] (final_sentAmount, sentPaymentID_orNil, tx_hash, tx_fee, tx_key, mockedTransaction) in
					guard let thisSelf = self else {
						return
					}
					// formulate a mocked/transient historical transaction for details view presentation, and see if we need to present an "Add Contact From Sent" screen based on whether they sent w/o using a contact
					thisSelf._didSend(
						sentTo_address: target_address,
						isXMRAddressIntegrated: isXMRAddressIntegrated,
						integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil,
						sentWith_paymentID: sentPaymentID_orNil,
						transactionHash: tx_hash,
						transactionKey: tx_key,
						tx_fee: tx_fee,
						sentAmount: final_sentAmount, // may be different for a sweep
						mockedTransaction: mockedTransaction
					)
				},
				canceled_fn:
				{ [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.parameters.canceled_fn()
				},
				failWithErr_fn:
				{ [weak self] (err_str) in
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
			sentWith_paymentID: MoneroPaymentID?,
			transactionHash: MoneroTransactionHash,
			transactionKey: MoneroTransactionSecKey,
			tx_fee: MoneroAmount,
			sentAmount: MoneroAmount,
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
