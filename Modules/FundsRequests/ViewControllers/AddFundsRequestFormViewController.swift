//
//  AddFundsRequestFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddFundsRequestFormViewController: UICommonComponents.FormViewController
{
	//
	// Properties
	var toWallet_label: UICommonComponents.Form.FieldLabel!
	var toWallet_inputView: UICommonComponents.WalletPickerButtonView!
	//
	var amount_label: UICommonComponents.Form.FieldLabel!
	var amount_fieldset: UICommonComponents.Form.AmountInputFieldsetView!
	//
	var aboveMemo_separatorView: UICommonComponents.Details.FieldSeparatorView!
	//
	var memo_label: UICommonComponents.Form.FieldLabel!
	var memo_accessoryLabel: UICommonComponents.Form.FieldLabelAccessoryLabel!
	var memo_inputView: UICommonComponents.FormInputField!
	//
	var requestFrom_label: UICommonComponents.Form.FieldLabel!
	var requestFrom_accessoryLabel: UICommonComponents.Form.FieldLabelAccessoryLabel!
	var requestFrom_inputView: UICommonComponents.Form.ContactPickerView!
	//
//	var resolving_activityIndicator: UICommonComponents.ResolvingActivityIndicatorView!
	//
//	var paymentID_label: UICommonComponents.Form.FieldLabel?
//	var paymentID_inputView: UICommonComponents.FormTextViewContainerView?
	//
//	var paymentID_fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel?
	//
//	var deleteButton_separatorView: FieldSeparatorView?
//	var deleteButton: UICommonComponents.LinkButtonView?
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
				title: NSLocalizedString("TO", comment: "")
			)
			self.toWallet_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.WalletPickerButtonView(selectedWallet: nil)
			self.toWallet_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("AMOUNT", comment: "")
			)
			self.amount_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.AmountInputFieldsetView()
			let inputField = view.inputField
			inputField.delegate = self
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			inputField.returnKeyType = .next
			self.amount_fieldset = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Details.FieldSeparatorView(mode: .contentBackgroundAccent)
			self.aboveMemo_separatorView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("MEMO", comment: "")
			)
			self.memo_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabelAccessoryLabel(title: NSLocalizedString("optional", comment: ""))
			self.memo_accessoryLabel = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("Note about the transaction", comment: "")
			)
			let inputField = view
			inputField.autocorrectionType = .default
			inputField.autocapitalizationType = .sentences
			inputField.delegate = self
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			inputField.returnKeyType = .next
			self.memo_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("REQUEST FROM", comment: "")
			)
			self.requestFrom_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabelAccessoryLabel(title: NSLocalizedString("optional", comment: ""))
			self.requestFrom_accessoryLabel = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.ContactPickerView()
//			let inputField = view.inputField
			self.requestFrom_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		// TODO: resolving indicator view
		//
		// TODO: +CREATE NEW CONTACT -> modal -> autopopulate (need/how to emit before dismissed like JS app?)
		//
		// TODO: +ADD PAYMENT ID 
		// TODO: payment id fields, auto visibility and population + contact picker etc
		
		
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem)
		)
		self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .cancel,
			target: self,
			action: #selector(tapped_barButtonItem_cancel)
		)
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		if self.formSubmissionController != nil {
			return false
		}
		if self.amount_fieldset.inputField.hasInputButIsNotSubmittable {
			return false // for ex if they just put in "."
		}
		// TODO…
		return true
	}
	
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
//		if inputView == self.amount_inputView {
//			return self.memo_inputView.textView
//		}
//		if inputView == self.memo_inputView.textView {
//			if let paymentID_inputView = self.paymentID_inputView {
//				return paymentID_inputView.textView
//			}
//			return nil
//		}
//		if let paymentID_inputView = self.paymentID_inputView {
//			if inputView == paymentID_inputView.textView {
//				return nil
//			}
//		}
		assert(false, "Unexpected")
		return nil
	}
	//
	// Accessors
	var sanitizedInputValue__toWallet: Wallet {
		return self.toWallet_inputView.selectedWallet! // we are never expecting this modal to be visible when no wallets exist, so a crash is/ought to be ok 
	}
	var sanitizedInputValue__amount: MoneroAmount? {
		return self.amount_fieldset.inputField.submittableAmount_orNil
	}
	var sanitizedInputValue__selectedContact: Contact? {
		return self.requestFrom_inputView.selectedContact
	}
//	var sanitizedInputValue__paymentID: MoneroPaymentID? {
//		if self.paymentID_inputView != nil && self.paymentID_inputView!.isHidden != true {
//			let stripped_paymentID = self.paymentID_inputView!.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
//			if stripped_paymentID != "" {
//				return stripped_paymentID
//			}
//		}
//		return nil
//	}
	//
	// Imperatives - Resolving indicator
	// TODO
//	func set(resolvingIndicatorIsVisible: Bool)
//	{
//		if resolvingIndicatorIsVisible {
//			self.resolving_activityIndicator.show()
//		} else {
//			self.resolving_activityIndicator.hide()
//		}
//		self.view.setNeedsLayout()
//	}
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		self.toWallet_inputView.isEnabled = false
		self.amount_fieldset.inputField.isEnabled = false
		self.memo_inputView.isEnabled = false
		self.requestFrom_inputView.inputField.isEnabled = false
		if let pillView = self.requestFrom_inputView.selectedContactPillView {
			pillView.xButton.isEnabled = true
		}
//		self.address_inputView.textView.isEditable = false
//		self.paymentID_inputView?.textView.isEditable = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.toWallet_inputView.isEnabled = true
		self.amount_fieldset.inputField.isEnabled = true
		self.memo_inputView.isEnabled = true
		self.requestFrom_inputView.inputField.isEnabled = true
		if let pillView = self.requestFrom_inputView.selectedContactPillView {
			pillView.xButton.isEnabled = true
		}
//		self.address_inputView.textView.isEditable = true
//		self.paymentID_inputView?.textView.isEditable = true
	}
	var formSubmissionController: AddFundsRequestFormSubmissionController? // TODO: maybe standardize into FormViewController
	override func _tryToSubmitForm()
	{
		NSLog("TODO")
		let to_wallet = self.toWallet_inputView.selectedWallet
		let amount_orNil = self.amount_fieldset.inputField.submittableAmount_orNil
		
		
//		let parameters = AddFundsRequestFormSubmissionController.Parameters(
//			mode: self._overridable_formSubmissionMode,
//			//
//			name: self.sanitizedInputValue__name,
//			emoji: self.sanitizedInputValue__emoji,
//			address: self.sanitizedInputValue__address,
//			paymentID: self.sanitizedInputValue__paymentID,
//			canSkipEntireOAResolveAndDirectlyUseInputValues: self._overridable_defaultFalse_canSkipEntireOAResolveAndDirectlyUseInputValues,
//			//
//			skippingOAResolve_explicit__cached_OAResolved_XMR_address: self._overridable_defaultNil_skippingOAResolve_explicit__cached_OAResolved_XMR_address,
//			forMode_update__contactInstance: self._overridable_forMode_update__contactInstance,
//			//
//			preInputValidation_terminal_validationMessage_fn:
//			{ [unowned self] (localizedString) in
//				self.setValidationMessage(localizedString)
//				self.formSubmissionController = nil // must free as this is a terminal callback
//			},
//			passedInputValidation_fn:
//			{ [unowned self] in
//				self.clearValidationMessage()
//				self.disableForm()
//			},
//			preSuccess_terminal_validationMessage_fn:
//			{ [unowned self] (localizedString) in
//				self.setValidationMessage(localizedString)
//				self.formSubmissionController = nil // must free as this is a terminal callback
//				self.reEnableForm() // b/c we disabled it
//			},
//			feedBackOverridingPaymentIDValue_fn:
//			{ [unowned self] (paymentID_orNil) in
//				if self.paymentID_inputView != nil {
//					self.paymentID_inputView!.textView.text = paymentID_orNil ?? ""
//				}
//			},
//			didBeginResolving_fn:
//			{ [unowned self] in
//				self.set(resolvingIndicatorIsVisible: true)
//			},
//			didEndResolving_fn:
//			{ [unowned self] in
//				self.set(resolvingIndicatorIsVisible: false)
//			},
//			success_fn:
//			{ [unowned self] (contactInstance) in
//				self.formSubmissionController = nil // must free as this is a terminal callback
//				self.reEnableForm() // b/c we disabled it
//				self._didSave(instance: contactInstance)
//			}
//		)
//		let controller = ContactFormSubmissionController(parameters: parameters)
//		self.formSubmissionController = controller
//		controller.handle()
	}
	//
	// Delegation - Form submission success
	func _didSave(instance: Contact)
	{
		self.navigationController!.dismiss(animated: true, completion: nil)
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		let textField_w = self.new__textField_w
		let fullWidth_label_w = self.new__fieldLabel_w
		//
		do {
			self.toWallet_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: ceil(top_yOffset),
				width: fullWidth_label_w,
				height: self.toWallet_label.frame.size.height
			).integral
			self.toWallet_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.toWallet_label.frame.origin.y + self.toWallet_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: self.toWallet_inputView.frame.size.height
			).integral
		}
		do {
			self.amount_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.toWallet_inputView.frame.origin.y + self.toWallet_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.toWallet_label.frame.size.height
			).integral
			self.amount_fieldset.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.amount_label.frame.origin.y + self.amount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: self.amount_fieldset.frame.size.width,
				height: self.amount_fieldset.frame.size.height
			).integral
		}
		do {
			self.aboveMemo_separatorView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.amount_fieldset.frame.origin.y + self.amount_fieldset.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField, // estimate margin
				width: textField_w,
				height: self.aboveMemo_separatorView.frame.size.height
			)
		}
		do {
			self.memo_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.aboveMemo_separatorView.frame.origin.y + self.aboveMemo_separatorView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, // estimate margin
				width: fullWidth_label_w,
				height: self.memo_label.frame.size.height
			).integral
			self.memo_accessoryLabel.frame = CGRect(
				x: CGFloat.form_labelAccessoryLabel_margin_x,
				y: self.memo_label.frame.origin.y,
				width: fullWidth_label_w,
				height: self.memo_accessoryLabel.frame.size.height
			).integral
			self.memo_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.memo_label.frame.origin.y + self.memo_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.memo_inputView.frame.size.height
			).integral
		}
		
		do {
			self.requestFrom_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.memo_inputView.frame.origin.y + self.memo_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.requestFrom_label.frame.size.height
			).integral
			self.requestFrom_accessoryLabel.frame = CGRect(
				x: CGFloat.form_labelAccessoryLabel_margin_x,
				y: self.requestFrom_label.frame.origin.y,
				width: fullWidth_label_w,
				height: self.requestFrom_accessoryLabel.frame.size.height
			).integral
			self.requestFrom_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.requestFrom_label.frame.origin.y + self.requestFrom_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.requestFrom_inputView.frame.size.height
			).integral
		}


//		if self.resolving_activityIndicator.isHidden == false {
//			let size = self.resolving_activityIndicator.new_boundsSize
//			self.resolving_activityIndicator.frame = CGRect(
//				x: CGFloat.form_label_margin_x,
//				y: self.address_inputView.frame.origin.y + self.address_inputView.frame.size.height + UICommonComponents.GraphicAndLabelActivityIndicatorView.marginAboveActivityIndicatorBelowFormInput,
//				width: size.width,
//				height: size.height
//				).integral
//		}
//		if self.paymentID_label != nil {
//			assert(self.paymentID_inputView != nil)
//			
//			let addressFieldset_bottomEdge = self.resolving_activityIndicator.isHidden ?
//				self.address_inputView.frame.origin.y + self.address_inputView.frame.size.height
//				: self.resolving_activityIndicator.frame.origin.y + self.resolving_activityIndicator.frame.size.height
//			//
//			self.paymentID_label!.frame = CGRect(
//				x: CGFloat.form_label_margin_x,
//				y: addressFieldset_bottomEdge + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
//				width: fullWidth_label_w,
//				height: self.paymentID_label!.frame.size.height
//				).integral
//			self.paymentID_inputView!.frame = CGRect(
//				x: CGFloat.form_input_margin_x,
//				y: self.paymentID_label!.frame.origin.y + self.paymentID_label!.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
//				width: textField_w,
//				height: self.paymentID_inputView!.frame.size.height
//				).integral
//			if self.paymentID_fieldAccessoryMessageLabel != nil {
//				self.paymentID_fieldAccessoryMessageLabel!.frame = CGRect(
//					x: CGFloat.form_label_margin_x,
//					y: self.paymentID_inputView!.frame.origin.y + self.paymentID_inputView!.frame.size.height + 7,
//					width: fullWidth_label_w,
//					height: 0
//					).integral
//				self.paymentID_fieldAccessoryMessageLabel!.sizeToFit()
//			}
//		} else {
//			assert(self.paymentID_inputView == nil)
//			assert(self.paymentID_fieldAccessoryMessageLabel == nil)
//		}
//		if self.deleteButton != nil {
//			assert(self.deleteButton_separatorView != nil)
//			let justPreviousView = (self.paymentID_fieldAccessoryMessageLabel ?? self.paymentID_inputView ?? self.address_inputView)!
//			self.deleteButton_separatorView!.frame = CGRect(
//				x: CGFloat.form_input_margin_x,
//				y: justPreviousView.frame.origin.y + justPreviousView.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
//				width: self.scrollView.frame.size.width - 2 * CGFloat.form_input_margin_x,
//				height: 1/UIScreen.main.scale
//			)
//			//
//			self.deleteButton!.frame = CGRect(
//				x: CGFloat.form_label_margin_x,
//				y: self.deleteButton_separatorView!.frame.origin.y + self.deleteButton_separatorView!.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
//				width: self.deleteButton!.frame.size.width,
//				height: self.deleteButton!.frame.size.height
//			)
//		}
		
		let bottomMostView = self.requestFrom_inputView // TODO: find the bottom most, either the pid field or the add pid  // self.paymentID_fieldAccessoryMessageLabel ?? self.deleteButton ?? self.paymentID_inputView ?? self.address_inputView
		let bottomPadding: CGFloat = 18
		self.scrollableContentSizeDidChange(
			withBottomView: bottomMostView!,
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
				if self.sanitizedInputValue__selectedContact == nil {
					assert(self.requestFrom_inputView.inputField.isHidden == false)
					self.requestFrom_inputView.inputField.becomeFirstResponder()
				}
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
	// Delegation - AmountInputField UITextField shunt
	func textField(
		_ textField: UITextField,
		shouldChangeCharactersIn range: NSRange,
		replacementString string: String
	) -> Bool
	{
		if textField == self.amount_fieldset.inputField { // to support filtering characters
			return self.amount_fieldset.inputField.textField(
				textField,
				shouldChangeCharactersIn: range,
				replacementString: string
			)
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
}
