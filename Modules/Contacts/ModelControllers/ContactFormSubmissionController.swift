//
//  ContactFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
class ContactFormSubmissionController: OpenAliasResolverRequestMaker
{
	struct Parameters
	{
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
		// Process callbacks
		var preInputValidation_terminal_validationMessage_fn: (_ localizedString: String) -> Void
		var passedInputValidation_fn: (Void) -> Void
		var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void
		//
		var feedBackOverridingPaymentIDValue_fn: (_ overiding_paymentID: MoneroPaymentID?) -> Void // if nil, clear the paymentID
		//
		var didBeginResolving_fn: (Void) -> Void
		var didEndResolving_fn: (Void) -> Void
		//
		var success_fn: (_ instance: Contact) -> Void
	}
	var parameters: Parameters
	init(parameters: Parameters)
	{
		self.parameters = parameters
	}
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
			if self.parameters.canSkipEntireOAResolveAndDirectlyUseInputValues == true {
				let paymentID_exists = self.parameters.paymentID != nil && self.parameters.paymentID! != ""
				let paymentID_existsAndIsNotValid = paymentID_exists && MyMoneroCoreUtils.isValidPaymentIDOrNoPaymentID(
					self.parameters.paymentID!
				) == false
				if paymentID_existsAndIsNotValid {
					self.parameters.preInputValidation_terminal_validationMessage_fn(
						NSLocalizedString("Please enter a valid payment ID.", comment: "")
					)
					return
				}
				return
			}
		}
		//
		// Now we can enter submission process
		self.parameters.passedInputValidation_fn()
		//
		if self.parameters.canSkipEntireOAResolveAndDirectlyUseInputValues == true {
			DDLog.Info("Contacts", "Skipping OA resolve on AddContact.")
			self.__proceedTo_addContact(
				withPaymentID: self.parameters.paymentID, // now, by now, we've already validated that if they've entered a paymentID, it's valid
				cached_OAResolved_XMR_address: self.parameters.skippingOAResolve_explicit__cached_OAResolved_XMR_address
			)
			return
		}
		//
		let isPresumedToBeOAAddress = MyMoneroCoreUtils.isAddressNotMoneroAddressAndThusProbablyOAAddress(self.parameters.address)
		if isPresumedToBeOAAddress == false {
			self._handleValidated_xmrAddressSubmission()
		} else {
			self._handleValidated_oaAddressSubmission()
		}
	}
	func _handleValidated_xmrAddressSubmission()
	{
		let oaRecord_address = self.parameters.address
		MyMoneroCore.shared.DecodeAddress(oaRecord_address)
		{ [unowned self] (err_str, decodedAddressComponents) in
			if let _ = err_str {
				self.parameters.preSuccess_terminal_validationMessage_fn(
					NSLocalizedString("Please enter a valid Monero address", comment: "") // not using the error here cause it can be pretty unhelpful to the lay user
				)
				return
			}
			let integratedAddress_paymentId = decodedAddressComponents!.intPaymentId
			let isIntegratedAddress = integratedAddress_paymentId != nil && integratedAddress_paymentId! != "" ? true : false
			if isIntegratedAddress != true { // is NOT an integrated addr - normal wallet addr
				if self.parameters.paymentID == nil || self.parameters.paymentID! == "" {
					MyMoneroCore.shared.New_PaymentID(
						{ [unowned self] (err_str, generated_paymentID) in
							if err_str != nil {
								self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
								return
							}
							let paymentID = generated_paymentID!
							self.parameters.feedBackOverridingPaymentIDValue_fn(paymentID)
							self.__proceedTo_addContact(
								withPaymentID: paymentID,
								cached_OAResolved_XMR_address: nil
							)
					})
					return
				}
				// else, simply use the entered paymentID
				self.__proceedTo_addContact(
					withPaymentID: self.parameters.paymentID!, // and it's not necessary but ! added to be explicit
					cached_OAResolved_XMR_address: nil
				)
				return
				
			}
			// else, IS integrated address
			let paymentID = integratedAddress_paymentId // use this one instead
			self.parameters.feedBackOverridingPaymentIDValue_fn(paymentID)
			self.__proceedTo_addContact(
				withPaymentID: paymentID,
				cached_OAResolved_XMR_address: nil
			)
			return
		}
	}
	func _handleValidated_oaAddressSubmission()
	{
		self.parameters.didBeginResolving_fn()
		//
		self.resolve_requestHandle = OpenAliasResolver.shared.resolveOpenAliasAddress(
			openAliasAddress: self.parameters.address,
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
				let handle_wasNil = self.resolve_requestHandle == nil
				self.resolve_requestHandle = nil
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
				self.__proceedTo_addContact(
					withPaymentID: paymentID_toSave, // aka use no/zero/emptystr payment id rather than null as null will create a new
					cached_OAResolved_XMR_address: cached_OAResolved_XMR_address // it's ok if this is nil
				)
			}
		)
	}
	//

	func __proceedTo_addContact(
		withPaymentID paymentID_toSave: MoneroPaymentID?,
		cached_OAResolved_XMR_address: MoneroAddress?
		)
	{
		assert(false, "make this save edit instead of create new if configured as such")
		
	}
}
