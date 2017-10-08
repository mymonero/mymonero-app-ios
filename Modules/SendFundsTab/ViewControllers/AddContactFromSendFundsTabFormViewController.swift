//
//  AddContactFromSendFundsTabFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/24/17.
//  Copyright (c) 2014-2017, MyMonero.com
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
import UIKit
//
class AddContactFromSendFundsTabFormViewController: AddContactFromOtherTabFormViewController
{
	//
	// Constants
	struct InitializationParameters
	{
		var enteredAddressValue: String // not nil; this ought to also always be the .address we save to the Contact
		var isXMRAddressIntegrated: Bool
		var integratedAddressPIDForDisplay_orNil: MoneroPaymentID?
		var resolvedAddress: MoneroAddress?
		var sentWith_paymentID: MoneroPaymentID? // nil for integrated addr
	}
	//
	// Parameters - Initial
	var parameters: InitializationParameters
	var isEnteredAddress_OA: Bool
	//
	var detected_iconAndMessageView: UICommonComponents.DetectedIconAndMessageView?
	let fieldGroupDecorationSectionView = UICommonComponents.Form.FieldGroupDecorationSectionView(
		sectionHeaderTitle: NSLocalizedString("SAVE THIS ADDRESS AS A CONTACT?", comment: "")
		// Note: This 'decoration' view is admittedly fairly lame. Better solution would be to enhance the ContactForm to support placing fields inside of a SectionView in the same manner as Details.FieldViews
	)
	//
	// Setup
	init(parameters: InitializationParameters)
	{
		self.parameters = parameters
		do {
			self.isEnteredAddress_OA = OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(self.parameters.enteredAddressValue)
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
		do { // underneath other views
			let view = self.fieldGroupDecorationSectionView
			self.scrollView.addSubview(view)
		}
		super.setup_views()
		self.set(
			validationMessage: NSLocalizedString("Your Monero is on its way.", comment: ""),
			wantsXButton: true // could also be false
		)
		do {
			self.address_inputView.set(isEnabled: false)
			self.address_inputView.isImmutable = true
			//
			var value = self.parameters.enteredAddressValue
			if self.isEnteredAddress_OA {
				value = value.lowercased() // jic
			}
			self.address_inputView.textView.text = value
		}
		if self.paymentID_inputView != nil {
			self.paymentID_inputView!.set(isEnabled: false)
			self.paymentID_inputView!.isImmutable = true
			self.paymentID_inputView!.textView.text = self.parameters.sentWith_paymentID ?? self.parameters.integratedAddressPIDForDisplay_orNil
		}
		//
		let wantsDetectedIndicator = self.parameters.isXMRAddressIntegrated // either integrated
			|| (self.isEnteredAddress_OA && self._overridable_wants_paymentID_fieldAccessoryMessageLabel) // or OA and we are going to show the field
		if wantsDetectedIndicator {
			let view = UICommonComponents.DetectedIconAndMessageView()
			self.scrollView.addSubview(view)
			self.detected_iconAndMessageView = view
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
		return self.parameters.sentWith_paymentID != nil || self.parameters.integratedAddressPIDForDisplay_orNil != nil // if we have a pid, show; else just hide
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
	override var sanitizedInputValue__paymentID: MoneroPaymentID? {
		// causing this to ignore field input and use values directly to avoid integrated addr pid submission
		return self.parameters.sentWith_paymentID // and not the integrated addr pid which is only for display		
	}
	override var _overridable_bottomMostView: UIView { // support layout this out while preserving scroll size etc
		return self.detected_iconAndMessageView ?? super._overridable_bottomMostView
	}
	//
	override var new__formFieldsCustomInsets: UIEdgeInsets {
		let base_insets = super.new__formFieldsCustomInsets
		// ^- we're expecting these to be 0, or in >= ios 11, the safe area
		return UIEdgeInsetsMake(
			base_insets.top + UICommonComponents.Form.FieldLabel.fixedHeight + 8 + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView/*approx*/,
			base_insets.left + 16,
			base_insets.bottom + 0,
			base_insets.right + 16
		)
	}
	//
	// Delegation - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		let bottomFieldView = self.detected_iconAndMessageView ?? /* no pid accessory label */ self.paymentID_inputView ?? self.address_inputView
		self.fieldGroupDecorationSectionView.sizeAndLayOutToEncompass(
			topFieldView: self.name_label,
			bottomFieldView: bottomFieldView!,
			//
			withContainingWidth: self.scrollView/*not self.view*/.bounds.size.width,
			yOffset: top_yOffset
		)
	}
	override func _overridable_didLayOutFormElementsButHasYetToSizeScrollableContent()
	{
		super._overridable_didLayOutFormElementsButHasYetToSizeScrollableContent() // not that it does anything
		//
		// this is our chance to insert the layout for any views we want to add... such as the detected label
		if self.detected_iconAndMessageView != nil {
			let mostPreviouslyVisibleView: UIView
			do {
				if self.paymentID_inputView != nil {
					mostPreviouslyVisibleView = self.paymentID_inputView!
				} else {
					mostPreviouslyVisibleView = self.address_inputView!
				}
			}
			let label_x = self.new__label_x
			let fullWidth_label_w = self.new__fieldLabel_w // already has customInsets subtracted
			self.detected_iconAndMessageView!.frame = CGRect(
				x: label_x,
				y: mostPreviouslyVisibleView.frame.origin.y + mostPreviouslyVisibleView.frame.size.height + (7 - UICommonComponents.FormInputCells.imagePadding_y),
				width: fullWidth_label_w,
				height: self.detected_iconAndMessageView!.frame.size.height
			).integral
		}
	}
}
