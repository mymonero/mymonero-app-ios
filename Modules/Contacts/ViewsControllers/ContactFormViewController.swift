//
//  ContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/29/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
	var resolving_activityIndicator: UICommonComponents.ResolvingActivityIndicatorView!
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
				title: NSLocalizedString("NAME", comment: ""),
				sizeToFit: true
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
				title: NSLocalizedString("EMOJI", comment: ""),
				sizeToFit: true
			)
			self.emoji_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = EmojiUI.EmojiPickerButtonView()
			view.configure(withEmojiCharacter: self.new_initial_value_emoji)
			view.tapped_fn =
			{ [unowned self] in
				self.scrollView.resignCurrentFirstResponder() // if any
			}
			self.emoji_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("ADDRESS", comment: ""),
				sizeToFit: true
			)
			self.address_label = view
			self.scrollView.addSubview(view)
		}
		do { // TODO: config as immutable by overridable flag
			let view = UICommonComponents.FormTextViewContainerView(
				placeholder: NSLocalizedString("Enter normal, integrated, or OpenAlias address", comment: "")
			)
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
		if self._overridable_wants_paymentIDField {
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("PAYMENT ID", comment: ""),
					sizeToFit: true
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
				let view = UICommonComponents.LinkButtonView(mode: .mono_destructive, title: "DELETE CONTACT")
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
	}
	var formSubmissionController: ContactFormSubmissionController? // TODO: maybe standardize into FormViewController
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
		let formFieldsCustomInsets = self.new__formFieldsCustomInsets
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView + formFieldsCustomInsets.top
		//
		let label_x = CGFloat.form_label_margin_x + formFieldsCustomInsets.left
		let input_x = CGFloat.form_input_margin_x + formFieldsCustomInsets.left
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
				y: ceil(top_yOffset),
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
				y: self.name_label.frame.origin.y + self.name_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton + 1, // +1 to align vertically - should not technically be necessary but there's some height weirdness with the text field
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
				height: self.resolving_activityIndicator.new_height
			).integral
		}
		if self.paymentID_label != nil {
			assert(self.paymentID_inputView != nil)
			//
			let addressFieldset_bottomEdge = self.resolving_activityIndicator.isHidden ?
				self.address_inputView.frame.origin.y + self.address_inputView.frame.size.height
			: self.resolving_activityIndicator.frame.origin.y + self.resolving_activityIndicator.frame.size.height
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
					y: self.paymentID_inputView!.frame.origin.y + self.paymentID_inputView!.frame.size.height + 7,
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
				width: self.scrollView.frame.size.width - 2 * CGFloat.form_input_margin_x,
				height: 1/UIScreen.main.scale
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
	// Delegation - UITextView
	func textView(
		_ textView: UITextView,
		shouldChangeTextIn range: NSRange,
		replacementText text: String
		) -> Bool
	{
		if text == "\n" { // simulate single-line input
			return self.aField_shouldReturn(textView, returnKeyType: textView.returnKeyType)
		}
		return true
	}
	//
	// Delegation - Interactions
	func tapped_rightBarButtonItem()
	{
		self.aFormSubmissionButtonWasPressed()
	}
	func tapped_barButtonItem_cancel()
	{
		assert(self.navigationController!.presentingViewController != nil)
		// we always expect self to be presented modally
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	//
	func deleteButton_tapped()
	{
		assert(false, "Override and implement")
	}
	//
	// Delegation - Internal - Overridable
	func _overridable_didLayOutFormElementsButHasYetToSizeScrollableContent()
	{
		
	}
}
