//
//  ContactFormSubmissionController.swift
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
class ContactFormSubmissionController: OpenAliasResolverRequestMaker
{
	enum Mode
	{
		case insert
		case update
	}
	struct Parameters
	{
		// Mode:
		var mode: Mode
		//
		// Input values:
		var name: String
		var emoji: Emoji.EmojiCharacter
		var address: String
		var paymentID: MoneroPaymentID?
		var canSkipEntireOAResolveAndDirectlyUseInputValues: Bool = false // this will not be true in the typical case - used for cases after we’re guaranteed to have just done the resolve from, e.g., the send funds form
		//
		// Special cases
		var skippingOAResolve_explicit__cached_OAResolved_XMR_address: MoneroAddress?
		//
		var forMode_update__contactInstance: Contact?
		//
		// Process callbacks
		var preInputValidation_terminal_validationMessage_fn: (_ localizedString: String) -> Void
		var passedInputValidation_fn: () -> Void
		var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void
		//
		var feedBackOverridingPaymentIDValue_fn: (_ overiding_paymentID: MoneroPaymentID?) -> Void // if nil, clear the paymentID
		//
		var didBeginResolving_fn: () -> Void
		var didEndResolving_fn: () -> Void
		//
		var success_fn: (_ instance: Contact) -> Void
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
		self.cancelAnyRequestFor_oaResolution() // just in case
		do { // input validation…
			if self.parameters.name == "" {
				self.parameters.preInputValidation_terminal_validationMessage_fn(
					NSLocalizedString("Please enter a name for this contact.", comment: "")
				)
				return
			}
			if self.parameters.address == "" {
				self.parameters.preInputValidation_terminal_validationMessage_fn(
					NSLocalizedString("Please enter an address for this contact.", comment: "")
				)
				return
			}
		}
		let isPresumedToBeOAAddress = OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(self.parameters.address)
		do {
			if isPresumedToBeOAAddress {
				if self.parameters.canSkipEntireOAResolveAndDirectlyUseInputValues == true {
					let paymentID_exists = self.parameters.paymentID != nil && self.parameters.paymentID! != ""
					let paymentID_existsAndIsNotValid = paymentID_exists && MoneroUtils.PaymentIDs.isAValidOrNotA(paymentId: self.parameters.paymentID!) == false
					if paymentID_existsAndIsNotValid {
						self.parameters.preInputValidation_terminal_validationMessage_fn(
							NSLocalizedString("Please enter a valid payment ID.", comment: "")
						)
						return
					}
				}
			} else {
				
			}
		}
		//
		// Now we can enter submission process
		self.parameters.passedInputValidation_fn()
		//
		if isPresumedToBeOAAddress {
			if self.parameters.canSkipEntireOAResolveAndDirectlyUseInputValues == true {
				DDLog.Info("Contacts", "Skipping OA resolve on ContactForm submit.")
				self.__proceedTo_persistContact(
					withPaymentID: self.parameters.paymentID, // now, by now, we've already validated that if they've entered a paymentID, it's valid
					cached_OAResolved_XMR_address: self.parameters.skippingOAResolve_explicit__cached_OAResolved_XMR_address
				)
				return
			}
			self._handleValidated_oaAddressSubmission()
			return
		}
		// normal or integrated xmr addr
		self._handleValidated_xmrAddressSubmission()
	}
	func _handleValidated_xmrAddressSubmission()
	{
		let xmrAddress = self.parameters.address
		let (err_str, decodedAddressComponents) = MyMoneroCore.shared_objCppBridge.decoded(address: xmrAddress)
		if let _ = err_str {
			self.parameters.preSuccess_terminal_validationMessage_fn(
				NSLocalizedString("Please enter a valid Monero address", comment: "") // not using the error here cause it can be pretty unhelpful to the lay user
			)
			return
		}
		let integratedAddress_paymentId = decodedAddressComponents!.intPaymentId
		let isIntegratedAddress = integratedAddress_paymentId != nil && integratedAddress_paymentId! != "" ? true : false
		if isIntegratedAddress {
			let paymentID: MoneroPaymentID? = integratedAddress_paymentId // allowing this to be saved - but mostly for display purposes (to parity with design)
			self.parameters.feedBackOverridingPaymentIDValue_fn(paymentID) // display this
			self.__proceedTo_persistContact(
				withPaymentID: paymentID,
				cached_OAResolved_XMR_address: nil
			)
			return
		}
		// not an integrated addr.. subaddress?
		if decodedAddressComponents!.isSubaddress {
			self.__proceedTo_persistContact(
				withPaymentID: nil, // subaddr is not compatible with PID so we must return nil
				cached_OAResolved_XMR_address: nil
			)
			return
		}
		//
		// not a subaddr either - normal wallet addr
		if self.parameters.paymentID == nil || self.parameters.paymentID! == "" {
			MyMoneroCore.shared.New_PaymentID(
				{ [unowned self] (err_str, generated_paymentID) in
					if err_str != nil {
						self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
						return
					}
					let paymentID = generated_paymentID!
					self.parameters.feedBackOverridingPaymentIDValue_fn(paymentID)
					self.__proceedTo_persistContact(
						withPaymentID: paymentID,
						cached_OAResolved_XMR_address: nil
					)
			})
			return
		}
		// else, simply use the entered paymentID
		self.__proceedTo_persistContact(
			withPaymentID: self.parameters.paymentID!, // and it's not necessary but ! added to be explicit
			cached_OAResolved_XMR_address: nil
		)
	}
	func _handleValidated_oaAddressSubmission()
	{
		self.parameters.didBeginResolving_fn()
		//
		self.resolve_lookupHandle = OpenAliasResolver.shared.resolveOpenAliasAddress(
			openAliasAddress: self.parameters.address,
			forCurrency: .monero,
			{ [unowned self] (
				err_str: String?,
				addressWhichWasPassedIn: String?,
				response: OpenAliasResolver.OpenAliasResolverResponse?
			) in
				if self.parameters.address != addressWhichWasPassedIn {
					assert(false, "another request's resolution was returned on this form… does that mean it wasn't cancelled from earlier?")
					return
				}
				//
				self.parameters.didEndResolving_fn()
				//
				let handle_wasNil = self.resolve_lookupHandle == nil
				self.resolve_lookupHandle = nil
				//
				if err_str != nil {
					self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
					return
				}
				// we'll only care about whether the handle was nil after err_str != nil b/c it can be nil on sync callback e.g. on network error
				if handle_wasNil {
					// something else may have cancelled the request or it was not able to even return yet (i.e. callback happened synchronously but on non-error case)
					assert(false)
					return
				}
				let paymentID_toSave = response!.returned__payment_id ?? ""
				self.parameters.feedBackOverridingPaymentIDValue_fn(paymentID_toSave)
				//
				let cached_OAResolved_XMR_address = response!.moneroReady_address
				self.__proceedTo_persistContact(
					withPaymentID: paymentID_toSave, // aka use no/zero/emptystr payment id rather than null as null will create a new
					cached_OAResolved_XMR_address: cached_OAResolved_XMR_address // it's ok if this is nil
				)
			}
		)
	}
	//
	func __proceedTo_persistContact(
		withPaymentID paymentID_toSave: MoneroPaymentID?,
		cached_OAResolved_XMR_address: MoneroAddress?
	)
	{
		// final validation of paymentID…
		let paymentID_exists = paymentID_toSave != nil && paymentID_toSave != ""
		let paymentID_existsAndIsNotValid = paymentID_exists && MoneroUtils.PaymentIDs.isAValidOrNotA(paymentId: paymentID_toSave!) == false
		if paymentID_existsAndIsNotValid {
			self.parameters.preInputValidation_terminal_validationMessage_fn(
				NSLocalizedString("Please enter a valid payment ID.", comment: "")
			)
			return
		}
		if self.parameters.mode == .insert {
			ContactsListController.shared.onceBooted_addContact(
				fullname: self.parameters.name,
				address: self.parameters.address,
				payment_id: paymentID_toSave,
				emoji: self.parameters.emoji,
				cached_OAResolved_XMR_address: cached_OAResolved_XMR_address
			) { [unowned self] (err_str, contactInstance) in
				if err_str != nil {
					self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
					return
				}
				self.parameters.success_fn(contactInstance!)
			}
		} else {
			let err_str = self.parameters.forMode_update__contactInstance!.SetValuesAndSave_fromEditAndPossibleOAResolve(
				fullname: self.parameters.name,
				emoji: self.parameters.emoji,
				address: self.parameters.address,
				payment_id: paymentID_toSave,
				cached_OAResolved_XMR_address: cached_OAResolved_XMR_address
			)
			if err_str != nil {
				self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
				return
			}
			self.parameters.success_fn(self.parameters.forMode_update__contactInstance!)
		}
	}
}
