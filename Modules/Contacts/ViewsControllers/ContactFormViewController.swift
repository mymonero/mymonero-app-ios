//
//  ContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/29/17.
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
import UIKit
//
class ContactFormViewController: UICommonComponents.FormViewController
{
	//
	// Properties - Interface - Settable
	var didSave_instance_fn: ((_ instance: Contact) -> Void)?
	//
	// Properties - Internal
	var name_label: UICommonComponents.Form.FieldLabel!
	var name_inputView: UICommonComponents.FormInputField!
	//
	var emoji_label: UICommonComponents.Form.FieldLabel!
	var emoji_inputView: EmojiUI.EmojiPickerButtonView!
	//
	var address_label: UICommonComponents.Form.FieldLabel!
	var address_inputView: UICommonComponents.FormTextViewContainerView!
	//
	var qrPicking_actionButtons: UICommonComponents.QRPickingActionButtons?
	//
	var resolving_activityIndicator: UICommonComponents.ResolvingActivityIndicatorView!
	//
	var useCamera_actionButtonView: UICommonComponents.ActionButton!
	var chooseFile_actionButtonView: UICommonComponents.ActionButton!
	//
	var paymentID_label: UICommonComponents.Form.FieldLabel?
	var paymentID_inputView: UICommonComponents.FormTextViewContainerView?
	var paymentID_fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel?
	//
	var deleteButton_separatorView: UICommonComponents.Details.FieldSeparatorView?
	var deleteButton: UICommonComponents.LinkButtonView?
	//
	// Lifecycle - Init
	override init()
	{
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("NAME", comment: "")
			)
			self.name_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("Enter name", comment: "")
			)
			view.autocorrectionType = .no
			view.autocapitalizationType = .words // not perfect
			view.spellCheckingType = .no
			view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			view.delegate = self
			view.returnKeyType = .next
			if let value = self.new_initial_value_name {
				view.text = value
			}
			self.name_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("EMOJI", comment: "")
			)
			self.emoji_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = EmojiUI.EmojiPickerButtonView()
			view.configure(withEmojiCharacter: self.new_initial_value_emoji)
			view.willPresentPopover_fn =
			{ [unowned self] in
				self.scrollView.resignCurrentFirstResponder() // if any
			}
			self.emoji_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("ADDRESS", comment: "")
			)
			self.address_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormTextViewContainerView(
				placeholder: NSLocalizedString("Enter address, email, or domain", comment: "")
			)
			view.textView.keyboardType = .emailAddress
			view.textView.autocorrectionType = .no
			view.textView.autocapitalizationType = .none
			view.textView.spellCheckingType = .no
			view.textView.returnKeyType = .next
			view.textView.delegate = self
			if let value = self.new_initial_value_address {
				view.textView.text = value
			}
			self.address_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.ResolvingActivityIndicatorView()
			view.isHidden = true
			self.resolving_activityIndicator = view
			self.scrollView.addSubview(view)
		}
		if self._overridable_wants_qrPickingButtons {
			let buttons = UICommonComponents.QRPickingActionButtons(
				containingViewController: self,
				attachingToView: self.scrollView // not self.view
			)
			buttons.havingPickedImage_shouldAllowPicking_fn =
			{ [weak self] in
				guard let thisSelf = self else {
					return false
				}
				if thisSelf.isFormEnabled == false {
					DDLog.Warn("ContactForm", "Disallowing QR code pick while form disabled")
					return false
				}
				return true
			}
			buttons.willDecodePickedImage_fn =
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				thisSelf.clearValidationMessage() // in case there was a parsing err etc displaying
			}
			buttons.didPick_fn =
			{ [weak self] (possibleUriString) in
				guard let thisSelf = self else {
					return
				}
				thisSelf.__shared_didPick(possibleRequestURIStringForAutofill: possibleUriString)
			}
			buttons.didEndQRScanWithErrStr_fn =
			{ [weak self] (localizedValidationMessage) in
				guard let thisSelf = self else {
					return
				}
				thisSelf.set(validationMessage: localizedValidationMessage, wantsXButton: true)
			}
			self.qrPicking_actionButtons = buttons
		}
		if self._overridable_wants_paymentIDField {
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("PAYMENT ID", comment: "")
				)
				self.paymentID_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: NSLocalizedString("Optional", comment: "")
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .go
				view.textView.delegate = self
				self.paymentID_inputView = view
				if let value = self.new_initial_value_paymentID {
					view.textView.text = value
				}
				self.scrollView.addSubview(view)
			}
			if self._overridable_wants_paymentID_fieldAccessoryMessageLabel {
				let view = UICommonComponents.FormFieldAccessoryMessageLabel(
					text: NSLocalizedString("Unless you use an OpenAlias or integrated address, if you don't provide a payment ID, one will be generated.", comment: "")
				)
				self.paymentID_fieldAccessoryMessageLabel = view
				self.scrollView.addSubview(view)
			}
		}
		if self._overridable_wantsDeleteRecordButton {
			do {
				let view = UICommonComponents.Details.FieldSeparatorView(mode: .contentBackgroundAccent)
				self.deleteButton_separatorView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.LinkButtonView(mode: .mono_destructive, size: .larger, title: "DELETE CONTACT")
				view.addTarget(self, action: #selector(deleteButton_tapped), for: .touchUpInside)
				self.deleteButton = view
				self.scrollView.addSubview(view)
			}
		}
//		self.scrollView.borderSubviews()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem),
			title_orNilForDefault: nil
		)
		self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .cancel,
			target: self,
			action: #selector(tapped_barButtonItem_cancel),
			title_orNilForDefault: self._overridable_cancelBarButtonTitle_orNilForDefault()
		)

	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		if self.formSubmissionController != nil {
			return false
		}
		if self.sanitizedInputValue__name == "" {
			return false
		}
		if self.sanitizedInputValue__address == "" {
			return false
		}
		return true
	}
	
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		if inputView == self.name_inputView {
			return self.address_inputView.textView
		}
		if inputView == self.address_inputView.textView {
			if let paymentID_inputView = self.paymentID_inputView, paymentID_inputView.isHidden == false {
				return paymentID_inputView.textView
			}
			return nil
		}
		if let paymentID_inputView = self.paymentID_inputView, paymentID_inputView.isHidden == false {
			if inputView == paymentID_inputView.textView {
				return nil
			}
		}
		assert(false, "Unexpected")
		return nil
	}
	//
	// Accessors - Overridable
	func _overridable_cancelBarButtonTitle_orNilForDefault() -> String? { return nil }
	var _overridable_defaultFalse_canSkipEntireOAResolveAndDirectlyUseInputValues: Bool { return false }
	var _overridable_formSubmissionMode: ContactFormSubmissionController.Mode { return .insert }
	var _overridable_defaultNil_skippingOAResolve_explicit__cached_OAResolved_XMR_address: MoneroAddress? { return nil }
	var _overridable_forMode_update__contactInstance: Contact? { return nil }
	var _overridable_wantsInputPermanentlyDisabled_address: Bool { return false }
	var _overridable_wantsInputPermanentlyDisabled_paymentID: Bool { return false }
	//
	var _overridable_wantsDeleteRecordButton: Bool { return false }
	var _overridable_wants_paymentIDField: Bool { return true }
	var _overridable_wants_paymentID_fieldAccessoryMessageLabel: Bool { return true }
	var _overridable_wants_qrPickingButtons: Bool { return false }
	//
	var _overridable_bottomMostView: UIView {
		return self.deleteButton ?? self.paymentID_fieldAccessoryMessageLabel ?? self.paymentID_inputView ?? self.address_inputView
	}
	//
	var new_initial_value_name: String? { return nil }
	var new_initial_value_emoji: Emoji.EmojiCharacter {
		let inUseEmojiCharacters = ContactsListController.shared.givenBooted_currentlyInUseEmojiCharacters()
		let value = Emoji.anEmojiWhichIsNotInUse(amongInUseEmoji: inUseEmojiCharacters)
		//
		return value
	}
	var new_initial_value_address: String? { return nil }
	var new_initial_value_paymentID: String? { return nil }
	//
	// Accessors
	var sanitizedInputValue__name: String {
		return self.name_inputView.text != nil && self.name_inputView.text != ""
			? self.name_inputView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
			: ""
	}
	var sanitizedInputValue__emoji: Emoji.EmojiCharacter {
		return self.emoji_inputView.selected_emojiCharacter
	}
	var sanitizedInputValue__address: String {
		return self.address_inputView.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	var sanitizedInputValue__paymentID: MoneroPaymentID? {
		if self.paymentID_inputView != nil && self.paymentID_inputView!.isHidden != true {
			let stripped_paymentID = self.paymentID_inputView!.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
			if stripped_paymentID != "" {
				return stripped_paymentID
			}
		}
		return nil
	}
	//
	// Imperatives - Resolving indicator
	func set(resolvingIndicatorIsVisible: Bool)
	{
		if resolvingIndicatorIsVisible {
			self.resolving_activityIndicator.show()
		} else {
			self.resolving_activityIndicator.hide()
		}
		self.view.setNeedsLayout()
	}
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		self.name_inputView.isEnabled = false
		self.emoji_inputView.isEnabled = false
		self.address_inputView.set(isEnabled: false)
		self.paymentID_inputView?.set(isEnabled: false)
		self.qrPicking_actionButtons?.set(isEnabled: false)
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.name_inputView.isEnabled = true
		self.emoji_inputView.isEnabled = true
		if self._overridable_wantsInputPermanentlyDisabled_address != true {
			self.address_inputView.set(isEnabled: true)
		}
		if self._overridable_wantsInputPermanentlyDisabled_paymentID != true {
			self.paymentID_inputView?.set(isEnabled: true)
		}
		self.qrPicking_actionButtons?.set(isEnabled: true)
	}
	var formSubmissionController: ContactFormSubmissionController?
	override func _tryToSubmitForm()
	{
		assert(self.sanitizedInputValue__name != "")
		assert(self.sanitizedInputValue__address != "")
		let parameters = ContactFormSubmissionController.Parameters(
			mode: self._overridable_formSubmissionMode,
			//
			name: self.sanitizedInputValue__name,
			emoji: self.sanitizedInputValue__emoji,
			address: self.sanitizedInputValue__address,
			paymentID: self.sanitizedInputValue__paymentID,
			canSkipEntireOAResolveAndDirectlyUseInputValues: self._overridable_defaultFalse_canSkipEntireOAResolveAndDirectlyUseInputValues,
			//
			skippingOAResolve_explicit__cached_OAResolved_XMR_address: self._overridable_defaultNil_skippingOAResolve_explicit__cached_OAResolved_XMR_address,
			forMode_update__contactInstance: self._overridable_forMode_update__contactInstance,
			//
			preInputValidation_terminal_validationMessage_fn:
			{ [unowned self] (localizedString) in
				self.setValidationMessage(localizedString)
				self.formSubmissionController = nil // must free as this is a terminal callback
				self.set_isFormSubmittable_needsUpdate()
			},
			passedInputValidation_fn:
			{ [unowned self] in
				self.clearValidationMessage()
				self.disableForm()
			},
			preSuccess_terminal_validationMessage_fn:
			{ [unowned self] (localizedString) in
				self.setValidationMessage(localizedString)
				self.formSubmissionController = nil // must free as this is a terminal callback
				self.set_isFormSubmittable_needsUpdate()
				self.reEnableForm() // b/c we disabled it
			},
			feedBackOverridingPaymentIDValue_fn:
			{ [unowned self] (paymentID_orNil) in
				if self.paymentID_inputView != nil {
					self.paymentID_inputView!.textView.text = paymentID_orNil ?? ""
				}
			},
			didBeginResolving_fn:
			{ [unowned self] in
				self.set(resolvingIndicatorIsVisible: true)
			},
			didEndResolving_fn:
			{ [unowned self] in
				self.set(resolvingIndicatorIsVisible: false)
			},
			success_fn:
			{ [unowned self] (contactInstance) in
				self.formSubmissionController = nil // must free as this is a terminal callback
				self.set_isFormSubmittable_needsUpdate()
				self.reEnableForm() // b/c we disabled it
				self._didSave(instance: contactInstance)
			}
		)
		let controller = ContactFormSubmissionController(parameters: parameters)
		self.formSubmissionController = controller
		do {
			self.set_isFormSubmittable_needsUpdate() // update submittability only after setting formSubmissionController
		}
		controller.handle()
	}
	//
	// Delegation - Form submission success
	func _didSave(instance: Contact)
	{ // Overridable but call on super
		if let fn = self.didSave_instance_fn {
			fn(instance)
		}
		self.navigationController!.dismiss(animated: true, completion: nil)
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		//
		let label_x = self.new__label_x
		let input_x = self.new__input_x
		let textField_w = self.new__textField_w // already has customInsets subtracted
		let fullWidth_label_w = self.new__fieldLabel_w // already has customInsets subtracted
		//
		let visual__nameField_marginRight: CGFloat = 24
		let nameField_marginRight = visual__nameField_marginRight - UICommonComponents.FormInputCells.imagePadding_x - UICommonComponents.PushButtonCells.imagePaddingForShadow_h
		//
		do {
			let visual__nameField_w = textField_w - (nameField_marginRight + self.emoji_inputView.frame.size.width)
			self.name_label.frame = CGRect(
				x: label_x,
				y: top_yOffset,
				width: visual__nameField_w,
				height: self.name_label.frame.size.height
			).integral
			self.name_inputView.frame = CGRect(
				x: input_x,
				y: self.name_label.frame.origin.y + self.name_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: visual__nameField_w,
				height: self.name_inputView.frame.size.height
			).integral
		}
		do {
			let emojiField_x = self.name_inputView.frame.origin.x + self.name_inputView.frame.size.width + nameField_marginRight
			let label_inset: CGFloat = 8
			self.emoji_label.frame = CGRect(
				x: emojiField_x + label_inset,
				y: top_yOffset,
				width: self.emoji_inputView.frame.size.width - label_inset,
				height: self.emoji_label.frame.size.height
			).integral
			self.emoji_inputView.frame = CGRect(
				x: emojiField_x - UICommonComponents.PushButtonCells.imagePaddingForShadow_h,
				y: self.name_label.frame.origin.y + self.name_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: self.emoji_inputView.frame.size.width,
				height: self.emoji_inputView.frame.size.height
			).integral
		}
		do {
			self.address_label.frame = CGRect(
				x: label_x,
				y: self.name_inputView.frame.origin.y + self.name_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.address_label.frame.size.height
			).integral
			self.address_inputView.frame = CGRect(
				x: input_x,
				y: self.address_label.frame.origin.y + self.address_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.address_inputView.frame.size.height
			).integral
		}
		if self.resolving_activityIndicator.isHidden == false {
			self.resolving_activityIndicator.frame = CGRect(
				x: label_x,
				y: self.address_inputView.frame.origin.y + self.address_inputView.frame.size.height + UICommonComponents.GraphicAndLabelActivityIndicatorView.marginAboveActivityIndicatorBelowFormInput,
				width: fullWidth_label_w,
				height: self.qrPicking_actionButtons != nil ? self.resolving_activityIndicator.new_height_withoutVSpacing : self.resolving_activityIndicator.new_height
			).integral
		}
		if self.qrPicking_actionButtons != nil {
			let justPreviousView = (self.resolving_activityIndicator.isHidden == false ? self.resolving_activityIndicator : self.address_inputView)!
			let margin_h = (self.scrollView.frame.size.width - textField_w) / 2
			self.qrPicking_actionButtons!.givenSuperview_layOut(
				atY: justPreviousView.frame.origin.y + justPreviousView.frame.size.height + UICommonComponents.ActionButton.topMargin,
				withMarginH: margin_h
			)
		}
		if self.paymentID_label != nil {
			assert(self.paymentID_inputView != nil)
			//
			let justPreviousView_frame = self.qrPicking_actionButtons != nil ? self.qrPicking_actionButtons!.frame : self.resolving_activityIndicator.isHidden == false ? self.resolving_activityIndicator.frame : self.address_inputView.frame
			let addressFieldset_bottomEdge = justPreviousView_frame.origin.y + justPreviousView_frame.size.height
			//
			self.paymentID_label!.frame = CGRect(
				x: label_x,
				y: addressFieldset_bottomEdge + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.paymentID_label!.frame.size.height
			).integral
			self.paymentID_inputView!.frame = CGRect(
				x: input_x,
				y: self.paymentID_label!.frame.origin.y + self.paymentID_label!.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.paymentID_inputView!.frame.size.height
			).integral
			if self.paymentID_fieldAccessoryMessageLabel != nil {
				self.paymentID_fieldAccessoryMessageLabel!.frame = CGRect(
					x: label_x,
					y: self.paymentID_inputView!.frame.origin.y + self.paymentID_inputView!.frame.size.height + UICommonComponents.FormFieldAccessoryMessageLabel.marginAboveLabelBelowTextInputView,
					width: fullWidth_label_w,
					height: 0
				).integral
				self.paymentID_fieldAccessoryMessageLabel!.sizeToFit()
			}
		} else {
			assert(self.paymentID_inputView == nil)
			assert(self.paymentID_fieldAccessoryMessageLabel == nil)
		}
		if self.deleteButton != nil {
			assert(self.deleteButton_separatorView != nil)
			let justPreviousView = (self.paymentID_fieldAccessoryMessageLabel ?? self.paymentID_inputView ?? self.address_inputView)!
			self.deleteButton_separatorView!.frame = CGRect(
				x: input_x,
				y: justPreviousView.frame.origin.y + justPreviousView.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
				width: self.scrollView.frame.size.width - 2 * input_x,
				height: UICommonComponents.Details.FieldSeparatorView.h
			)
			//
			self.deleteButton!.frame = CGRect(
				x: label_x,
				y: self.deleteButton_separatorView!.frame.origin.y + self.deleteButton_separatorView!.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
				width: self.deleteButton!.frame.size.width,
				height: self.deleteButton!.frame.size.height
			)
		}
		//
		self._overridable_didLayOutFormElementsButHasYetToSizeScrollableContent()
		//
		let bottomMostView = self._overridable_bottomMostView // to support overrides
		let bottomPadding: CGFloat = 18
		self.scrollableContentSizeDidChange(
			withBottomView: bottomMostView,
			bottomPadding: bottomPadding
		)
	}
	override func viewDidAppear(_ animated: Bool)
	{
		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
		if isFirstAppearance {
			DispatchQueue.main.async
			{ [unowned self] in
				self.name_inputView.becomeFirstResponder()
			}
		}
	}
	//
	// Delegation - Interactions
	@objc func tapped_rightBarButtonItem()
	{
		self.aFormSubmissionButtonWasPressed()
	}
	@objc func tapped_barButtonItem_cancel()
	{
		assert(self.navigationController!.presentingViewController != nil)
		// we always expect self to be presented modally
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	//
	@objc func deleteButton_tapped()
	{
		assert(false, "Override and implement")
	}
	//
	// Delegation - Internal - Overridable
	func _overridable_didLayOutFormElementsButHasYetToSizeScrollableContent()
	{
	}
	//
	// Delegation - URL picking (also used by QR picking)
	func ___shared_initialResetFormFor_didPick()
	{
		self.clearValidationMessage() // in case there was a parsing err etc displaying
	}
	func __shared_didPick(possibleRequestURIStringForAutofill possibleRequestURIString: String)
	{
		self.___shared_initialResetFormFor_didPick()
		//
		let (err_str, optl_requestPayload) = MoneroUtils.URIs.Requests.new_parsedRequest(
			fromPossibleURIOrMoneroOrOAAddressString: possibleRequestURIString
		)
		if err_str != nil {
			self.set(
				validationMessage: NSLocalizedString(
					"Unable to use the result of decoding that QR code: \(err_str!)",
					comment: ""
				),
				wantsXButton: true
			)
			return
		}
		self.__shared_havingClearedForm_didPick(requestPayload: optl_requestPayload!)
	}
	func __shared_havingClearedForm_didPick(requestPayload: MoneroUtils.URIs.Requests.ParsedRequest)
	{
		do {
			let target_address = requestPayload.address
			assert(target_address != "") // b/c it should have been caught as a validation err on New_ParsedRequest_FromURIString
			let payment_id_orNil = requestPayload.paymentID
			
			self.address_inputView.textView.text = target_address
			if payment_id_orNil != nil {
				self.paymentID_inputView?.textView.text = payment_id_orNil!
			}
		}
		self.set_isFormSubmittable_needsUpdate() // now that we've updated values
	}
}
