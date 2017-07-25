//
//  SendFundsFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
			var fromWallet: Wallet
			var amount_submittableDouble: Double
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
			var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void
			var preSuccess_passedValidation_willBeginSending: (Void) -> Void
			var success_fn: (
				_ mockedTransaction: MoneroHistoricalTransactionRecord,
				_ isXMRAddressIntegrated: Bool
			) -> Void
		}
		var parameters: Parameters
		init(parameters: Parameters)
		{
			self.parameters = parameters
		}
		// deinit already cancels request
		//
		// Imperatives
		func handle()
		{
			let enteredAddressValue_exists = self.parameters.enteredAddressValue != "" && self.parameters.enteredAddressValue != nil // it will be valid if it exists
			let hasPickedAContact = self.parameters.selectedContact != nil
			let notPickedContactBut_enteredAddressValue = !hasPickedAContact && enteredAddressValue_exists ? true : false
			//
			let resolvedAddress_exists = self.parameters.resolvedAddress != "" && self.parameters.resolvedAddress != nil // NOTE: it might be hidden, though!
			//
			let resolvedPaymentID_exists = self.parameters.resolvedPaymentID != "" // NOTE: it might be hidden, though!
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
				let is_enteredAddressValue_OAAddress = MyMoneroCoreUtils.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(
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
					paymentID_toUseOrToNilIfIntegrated = self.parameters.resolvedPaymentID_fieldIsVisible ? self.parameters.resolvedPaymentID : nil
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
			MyMoneroCore.shared.DecodeAddress(
				xmrAddress_toDecode,
				{ [unowned self] (err_str, decodedAddressComponents) in
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
							isXMRAddressIntegrated: true
						)
						return
					}
					let paymentID_orNil = paymentID_toUseOrToNilIfIntegrated
					// since we may have a payment ID here (which may also have been entered manually), validate
					if MyMoneroCoreUtils.isValidPaymentIDOrNoPaymentID(paymentID_orNil) == false { // convenience function - will be true if nil pid
						self.parameters.preSuccess_terminal_validationMessage_fn(
							NSLocalizedString("Please enter a valid payment ID.", comment: "")
						)
						return
					}
					self._proceedTo_generateSendTransaction(
						withTargetAddress: xmrAddress_toDecode, // therefore, non-integrated normal XMR address
						payment_id: paymentID_toUseOrToNilIfIntegrated, // may still be nil
						isXMRAddressIntegrated: false
					)
				}
			)
					}
		func _proceedTo_generateSendTransaction(
			withTargetAddress target_address: MoneroAddress,
			payment_id: MoneroPaymentID?,
			isXMRAddressIntegrated: Bool
		)
		{
			self.parameters.preSuccess_passedValidation_willBeginSending()
			//
			self.parameters.fromWallet.SendFunds(
				target_address: target_address,
				amount: self.parameters.amount_submittableDouble,
				payment_id: payment_id,
				success_fn:
				{ (transactionHash, sentAmount) in
					// formulate a mocked/transient historical transaction for details view presentation, and see if we need to present an "Add Contact From Sent" screen based on whether they sent w/o using a contact
					self._didSend(
						sentTo_address: target_address,
						isXMRAddressIntegrated: isXMRAddressIntegrated,
						sentWith_paymentID: payment_id,
						transactionHash: transactionHash,
						sentAmount: sentAmount
					)
				},
				failWithErr_fn:
				{ (err_str) in
					self.parameters.preSuccess_terminal_validationMessage_fn(err_str)
				}
			)
		}
		//
		// Delegation
		func _didSend(
			sentTo_address: MoneroAddress,
			isXMRAddressIntegrated: Bool,
			sentWith_paymentID: MoneroPaymentID?,
			transactionHash: MoneroTransactionHash,
			sentAmount: MoneroAmount
		)
		{
			let mockedTransaction = MoneroHistoricalTransactionRecord(
				amount: sentAmount,
				totalSent: sentAmount,
				totalReceived: MoneroAmount("0"),
				approxFloatAmount: -1 * self.parameters.amount_submittableDouble, // -1 b/c it's outgoing!
				spent_outputs: nil, // TODO: is this ok?
				timestamp: Date(), // faking this
				hash: transactionHash,
				paymentId: sentWith_paymentID, // transaction.paymentId will therefore be nil for integrated addresses
				mixin: FixedMixin(),
				mempool: false, // TODO: is this correct?
				unlock_time: 0,
				height: 0, // TODO: is this correct?
//				coinbase: false, // TODO: need this?
//				tx_fee: tx_fee, // TODO?
//				contact: hasPickedAContact ? self.pickedContact : null, // TODO?
				cached__isConfirmed: false, // important
				cached__isUnlocked: true, // TODO: not sure about this
				cached__lockedReason: nil,
				isJustSentTransientTransactionRecord: true
			)
			do { // and fire off a request to have the wallet get the latest (real) tx records
				let wallet = self.parameters.fromWallet
				DispatchQueue.main.async
				{
					wallet.hostPollingController!._fetch_addressTransactions() // TODO: maybe fix up the API for this
				}
			}
			self.parameters.success_fn(
				mockedTransaction,
				isXMRAddressIntegrated
			)
		}
	}
}
