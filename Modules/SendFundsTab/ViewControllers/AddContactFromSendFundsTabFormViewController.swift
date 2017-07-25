//
//  AddContactFromSendFundsTabFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/24/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
class AddContactFromSendFundsTabFormViewController: AddContactFromOtherTabFormViewController
{
	//
	// Constants
	struct InitializationParameters
	{
		var enteredAddressValue: String // not nil; this ought to also always be the .address we save to the Contact
		var isXMRAddressIntegrated: Bool
		var resolvedAddress: MoneroAddress?
		var sentWith_paymentID: MoneroPaymentID?
	}
	//
	// Parameters - Initial
	var parameters: InitializationParameters
	var isEnteredAddress_OA: Bool
	//
	// Setup
	init(parameters: InitializationParameters)
	{
		self.parameters = parameters
		do {
			self.isEnteredAddress_OA = MyMoneroCoreUtils.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(self.parameters.enteredAddressValue)
		}
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func setup()
	{
		do {
			if self.parameters.isXMRAddressIntegrated {
				assert(self.parameters.sentWith_paymentID == nil) // it ought to be guaranteed to be nil for integrated addresses
			}
		}
		super.setup()
	}
	override func setup_views()
	{
		super.setup_views()
		self.set(
			validationMessage: NSLocalizedString("Your Monero is on its way.", comment: ""),
			wantsXButton: true // could also be false
		)
		do {
			self.address_inputView.set(isEnabled: false) // TODO: make this able survive form being re-enabled
			//
			var value = self.parameters.enteredAddressValue
			if self.isEnteredAddress_OA {
				value = value.lowercased() // jic
			}
			self.address_inputView.textView.text = value
		}
		if self.paymentID_inputView != nil {
			self.paymentID_inputView!.set(isEnabled: false) // TODO: make this able survive form being re-enabled
			self.paymentID_inputView!.textView.text = self.parameters.sentWith_paymentID
		}
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Save Contact", comment: "")
	}
	//
	// Accessors - Overrides
	override var _overridable_wants_paymentIDField: Bool {
		return self.parameters.sentWith_paymentID != nil // if we have a pid, show; else just hide
	}
	override var _overridable_wants_paymentID_fieldAccessoryMessageLabel: Bool {
		return false // regardless
	}
	override func _overridable_cancelBarButtonTitle_orNilForDefault() -> String? {
		return NSLocalizedString("Don't Save", comment: "")
	}
	override var _overridable_defaultFalse_canSkipEntireOAResolveAndDirectlyUseInputValues: Bool {
		return true // very special case - we've just done the resolve during the Send we just came from
	}
	override var _overridable_defaultNil_skippingOAResolve_explicit__cached_OAResolved_XMR_address: MoneroAddress? {
		return self.parameters.resolvedAddress // may be nil
	}
	override var _overridable_wantsInputPermanentlyDisabled_address: Bool {
		return true
	}
	override var _overridable_wantsInputPermanentlyDisabled_paymentID: Bool {
		return true
	}
}

