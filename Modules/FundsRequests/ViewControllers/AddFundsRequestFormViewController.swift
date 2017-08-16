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
	// Properties - Set-up
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
	var requestFrom_inputView: UICommonComponents.Form.ContactAndAddressPickerView!
	var isWaitingOnFieldBeginEditingScrollTo_requestFrom = false // a bit janky
	//
	var createNewContact_buttonView: UICommonComponents.LinkButtonView!
	var addPaymentID_buttonView: UICommonComponents.LinkButtonView!
	//
	var manualPaymentID_label: UICommonComponents.Form.FieldLabel!
	var manualPaymentID_accessoryLabel: UICommonComponents.Form.FieldLabelAccessoryLabel!
	var manualPaymentID_inputView: UICommonComponents.FormInputField!
	//
	// Lifecycle - Init
	required init(
		contact: Contact?,
		selectedWallet: Wallet?
	)
	{
		super.init()
		// ^ this will call setup (synchronously)
		if contact != nil {
			self.requestFrom_inputView.pick(contact: contact!)
		}
		if selectedWallet != nil {
			self.toWallet_inputView.set(selectedWallet: selectedWallet!)
		}
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
			let view = UICommonComponents.Form.ContactAndAddressPickerView()
			// TODO: initial contact selection? (from spawn)
			view.textFieldDidBeginEditing_fn =
			{ [unowned self] (textField) in
				self.view.setNeedsLayout() // to be certain we get the updated bottom padding
				//
				self.aField_didBeginEditing(textField, butSuppressScroll: true) // suppress scroll and call manually
				// ^- this does not actually do anything at present, given suppressed scroll
				self.isWaitingOnFieldBeginEditingScrollTo_requestFrom = true // sort of janky
				DispatchQueue.main.asyncAfter(
					deadline: .now() + UICommonComponents.FormViewController.fieldScrollDuration + 0.1
				) // slightly janky to use delay/duration, we need to wait (properly/considerably) for any layout changes that will occur here
				{ [unowned self] in
					self.isWaitingOnFieldBeginEditingScrollTo_requestFrom = false // unset
					if view.inputField.isFirstResponder { // jic
						self.scrollToVisible_requestFrom()
					}
				}
			}
			view.didUpdateHeight_fn =
			{
				self.view.setNeedsLayout() // to get following subviews' layouts to update
				//
				// scroll to field in case, e.g., results table updated
				DispatchQueue.main.asyncAfter(
					deadline: .now() + 0.1
				)
				{ [unowned self] in
					if self.isWaitingOnFieldBeginEditingScrollTo_requestFrom == true {
						return // semi-janky -- but is used to prevent potential double scroll oddness
					}
					if view.inputField.isFirstResponder {
						self.scrollToVisible_requestFrom()
					}
				}
			}
			view.textFieldDidEndEditing_fn =
			{ (textField) in
				// nothing to do in this case
			}
			view.didPickContact_fn =
			{ [unowned self] (contact, doesNeedToResolveItsOAAddress) in
				do { // configurations regardless
					self.createNewContact_buttonView.isHidden = true
				}
				if doesNeedToResolveItsOAAddress == true { // so we still need to wait and check to see if they have a payment ID
					self.addPaymentID_buttonView.isHidden = true // hide if showing
					self.hideAndClear_manualPaymentIDField() // at least clear; hide for now
					//
					// contact picker will show its own resolving indicator while we look up the paymentID again
					self.set_isFormSubmittable_needsUpdate() // this will involve a check to whether the contact picker is resolving
					//
					self.clearValidationMessage() // assuming it's okay to do this here - and need to since the coming callback can set the validation msg
					//
					return
				}
				// does NOT need to resolve an OA address; handle contact's non-OA payment id - if we already have one
				if let paymentID = contact.payment_id {
					self.addPaymentID_buttonView.isHidden = true // hide if showing
					self.show_manualPaymentIDField(withValue: paymentID)
					// NOTE: ^--- This may seem unusual not to show as a 'detected' payment ID
					// here but unlike on the Send page, Requests (I think) must be able to be created
					// with an empty / nil payment ID field even though the user picked a contact.
				} else {
					self.addPaymentID_buttonView.isHidden = false // show if hidden
					self.hideAndClear_manualPaymentIDField() // hide if showing
				}
			}
			view.oaResolve__preSuccess_terminal_validationMessage_fn =
			{ [unowned self] (localizedString) in
				self.setValidationMessage(localizedString)
				self.set_isFormSubmittable_needsUpdate() // as it will check whether we are resolving
			}
			view.oaResolve__success_fn =
			{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
				self.set_isFormSubmittable_needsUpdate() // will check if picker is resolving
				do { // memo field
					self.memo_inputView.text = tx_description ?? "" // even if one was already entered; this is tbh an approximation of the behavior we want; ideally we'd try to detect and track whether the user intended to use/type their own custom memo – but that is surprisingly involved to do well enough! at least for now.
				}
				do { // there is no need to tell the contact to update its address and payment ID here as it will be observing the emitted event from this very request to .Resolve
					if payment_id != "" {
						self.addPaymentID_buttonView.isHidden = true // hide if showing
						self.show_manualPaymentIDField(withValue: payment_id)
					} else {
						// we already hid it above… but just in case
						self.addPaymentID_buttonView.isHidden = false // show if showing
						self.hideAndClear_manualPaymentIDField()
					}
				}
			}
			view.didClearPickedContact_fn =
			{ [unowned self] (preExistingContact) in
				self.clearValidationMessage() // in case there was an OA addr resolve network err sitting on the screen
				//
				self.set_isFormSubmittable_needsUpdate() // as it will look at resolving
				//
				self.addPaymentID_buttonView.isHidden = false // show if hidden
				self.hideAndClear_manualPaymentIDField() // if showing
				//
				if preExistingContact.hasOpenAliasAddress {
					self.memo_inputView.text = "" // we're doing this here to avoid stale state and because implementing proper detection of which memo the user intends to leave in there for this particular request is quite complicated. see note in _didPickContact… but hopefully checking having /come from/ an OA contact is good enough
				}
				self.createNewContact_buttonView.isHidden = false // show if hidden
			}
			let inputField = view.inputField
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			self.requestFrom_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: NSLocalizedString("+ CREATE NEW CONTACT", comment: ""))
			view.addTarget(self, action: #selector(createNewContact_tapped), for: .touchUpInside)
			self.createNewContact_buttonView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: NSLocalizedString("+ ADD PAYMENT ID", comment: ""))
			view.addTarget(self, action: #selector(addPaymentID_tapped), for: .touchUpInside)
			self.addPaymentID_buttonView = view
			self.scrollView.addSubview(view)
		}
		//
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("PAYMENT ID", comment: "")
			)
			view.isHidden = true // initially
			self.manualPaymentID_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabelAccessoryLabel(title: NSLocalizedString("optional", comment: ""))
			view.isHidden = true // initially
			self.manualPaymentID_accessoryLabel = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("A specific payment ID", comment: "")
			)
			view.isHidden = true // initially
			let inputField = view
			inputField.autocorrectionType = .no
			inputField.autocapitalizationType = .none
			inputField.delegate = self
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			inputField.returnKeyType = .go
			self.manualPaymentID_inputView = view
			self.scrollView.addSubview(view)
		}
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("New Request", comment: "")
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
		if self.requestFrom_inputView.isResolving {
			return false
		}
		if self.amount_fieldset.inputField.hasInputButIsNotSubmittable {
			return false // for ex if they just put in "."
		}
		return true
	}
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		switch inputView {
			case self.toWallet_inputView.picker_inputField:
				return self.amount_fieldset.inputField
			case self.amount_fieldset.inputField:
				return self.memo_inputView
			case self.memo_inputView:
				if self.requestFrom_inputView.inputField.isHidden == false {
					return self.requestFrom_inputView.inputField
				} else if self.manualPaymentID_inputView.isHidden == false {
					return self.manualPaymentID_inputView
				}
				return nil
			case self.requestFrom_inputView.inputField:
				if self.manualPaymentID_inputView.isHidden == false {
					return manualPaymentID_inputView
				}
				return nil
			case self.manualPaymentID_inputView:
				return nil
			default:
				assert(false, "Unexpected")
				return nil
		}
	}
	override func new_wantsBGTapRecognizerToReceive_tapped(onView view: UIView) -> Bool
	{
		if view.isAnyAncestor(self.requestFrom_inputView) {
			// this is to prevent taps on the searchResults tableView from dismissing the input (which btw makes selection of search results rows impossible)
			// but it's ok if this is the inputField itself
			return false
		}
		return super.new_wantsBGTapRecognizerToReceive_tapped(onView: view)
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
	var sanitizedInputValue__paymentID: MoneroPaymentID? {
		if self.manualPaymentID_inputView.text != nil && self.manualPaymentID_inputView!.isHidden != true {
			let stripped_paymentID = self.manualPaymentID_inputView!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
			if stripped_paymentID != "" {
				return stripped_paymentID
			}
		}
		return nil
	}
	//
	// Imperatives - Field visibility/configuration
	func set_manualPaymentIDField(isHidden: Bool)
	{
		self.manualPaymentID_label.isHidden = isHidden
		self.manualPaymentID_accessoryLabel.isHidden = isHidden
		self.manualPaymentID_inputView.isHidden = isHidden
		self.view.setNeedsLayout()
	}
	func show_manualPaymentIDField(withValue paymentID: String?)
	{
		self.manualPaymentID_inputView.text = paymentID ?? "" // nil to empty field
		self.set_manualPaymentIDField(isHidden: false)
	}
	func hideAndClear_manualPaymentIDField()
	{
		self.set_manualPaymentIDField(isHidden: true)
		self.manualPaymentID_inputView.text = ""
	}
	//
	// Imperatives - Contact picker, contact picking
	func scrollToVisible_requestFrom()
	{
		let toBeVisible_frame__absolute = CGRect(
			x: 0,
			y: self.requestFrom_label.frame.origin.y,
			width: self.requestFrom_inputView.frame.size.width,
			height: (self.requestFrom_inputView.frame.origin.y - self.requestFrom_label.frame.origin.y) + self.requestFrom_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField
		)
		self.scrollRectToVisible(
			toBeVisible_frame__absolute: toBeVisible_frame__absolute,
			atEdge: .top,
			finished_fn: {}
		)
	}
	public func reconfigureFormAtRuntime_havingElsewhereSelected(
		requestFromContact contact: Contact?,
		receiveToWallet wallet: Wallet?
	)
	{
		self.amount_fieldset.inputField.text = "" // figure that since this method is called when user is trying to initiate a new request, we should clear the amount
		//
		if contact != nil {
			self.requestFrom_inputView.pick(contact: contact!)
		} else {
			self.requestFrom_inputView.unpickSelectedContact_andRedisplayInputField()
		}
		//
		if wallet != nil {
			self.toWallet_inputView.set(selectedWallet: wallet!)
		}
	}
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
		self.manualPaymentID_inputView.isEnabled = false
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
		self.manualPaymentID_inputView.isEnabled = true
	}
	var formSubmissionController: AddFundsRequestFormSubmissionController? // TODO: maybe standardize into FormViewController
	override func _tryToSubmitForm()
	{
		self.clearValidationMessage()
		//
		let toWallet = self.toWallet_inputView.selectedWallet!
		//
		let amount = self.amount_fieldset.inputField.text // we're going to allow empty amounts
		let submittableDoubleAmount = self.amount_fieldset.inputField.submittableDouble_orNil
		do {
			assert(submittableDoubleAmount != nil || amount == nil || amount == "")
			if submittableDoubleAmount == nil && (amount != nil && amount != "") { // something entered but not usable
				self.setValidationMessage(NSLocalizedString("Please enter a valid amount  Monero.", comment: ""))
				return
			}
		}
		if submittableDoubleAmount != nil && submittableDoubleAmount! <= 0 {
			self.setValidationMessage(NSLocalizedString("Please enter an amount greater than zero.", comment: ""))
			return
		}
		var submittableAmountFinalString: String?
		if submittableDoubleAmount != nil {
			if amount!.characters.last == "." {
				submittableAmountFinalString = amount! + "0"
			} else {
				submittableAmountFinalString = amount!
			}
		}
		//
		let selectedContact = self.requestFrom_inputView.selectedContact
		let hasPickedAContact = selectedContact != nil
		let requestFrom_input_text = self.requestFrom_inputView.inputField.text
		if requestFrom_input_text != nil && requestFrom_input_text! != "" { // they have entered something
			if hasPickedAContact == false { // but not picked a contact
				self.setValidationMessage(NSLocalizedString("Please select a contact or clear the contact field below to generate this request.", comment: ""))
				return
			}
		}
		let fromContact_name_orNil = selectedContact != nil ? selectedContact!.fullname : nil
		//
		let paymentID: MoneroPaymentID? = self.manualPaymentID_inputView.isHidden == false ? self.manualPaymentID_inputView.text : nil
		let memoString = self.memo_inputView.text
		let parameters = AddFundsRequestFormSubmissionController.Parameters(
			optl__toWallet_color: toWallet.swatchColor,
			toWallet_address: toWallet.public_address,
			optl__fromContact_name: fromContact_name_orNil,
			paymentID: paymentID,
			amount: submittableAmountFinalString, // rather than using amount directly
			optl__memo: memoString,
			//
			preSuccess_terminal_validationMessage_fn:
			{ [unowned self] (localizedString) in
				self.setValidationMessage(localizedString)
				self.formSubmissionController = nil // must free as this is a terminal callback
				self.set_isFormSubmittable_needsUpdate()
				self.reEnableForm() // b/c we disabled it
			},
			success_fn:
			{ [unowned self] (instance) in
				self.formSubmissionController = nil // must free as this is a terminal callback
				self.reEnableForm() // b/c we disabled it
				self._didSave(instance: instance)
			}
		)
		let controller = AddFundsRequestFormSubmissionController(parameters: parameters)
		self.formSubmissionController = controller
		do {
			self.disableForm()
			self.set_isFormSubmittable_needsUpdate() // update submittability
		}
		controller.handle()
	}
	//
	// Delegation - Form submission success
	func _didSave(instance: FundsRequest)
	{
		let viewController = FundsRequestDetailsViewController(fundsRequest: instance)
		let rootViewController = UIApplication.shared.delegate!.window!!.rootViewController! as! RootViewController
		let fundsRequestsTabNavigationController = rootViewController.tabBarViewController.fundsRequestsTabViewController
		fundsRequestsTabNavigationController.pushViewController(viewController, animated: false) // NOT animated
		DispatchQueue.main.async // on next tick to make sure push view finished
		{ [unowned self] in
			self.navigationController!.dismiss(animated: true, completion: nil)
		}
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
				y: self.aboveMemo_separatorView.frame.origin.y
					+ ceil(self.aboveMemo_separatorView.frame.size.height)/*must ceil or we get a growing height due to .integral + demi-pixel separator thickness!*/
					+ UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, // estimated margin
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
		if self.createNewContact_buttonView.isHidden == false {
			self.createNewContact_buttonView!.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.requestFrom_inputView.frame.origin.y + self.requestFrom_inputView.frame.size.height + 8,
				width: self.createNewContact_buttonView!.frame.size.width,
				height: self.createNewContact_buttonView!.frame.size.height
			)
		}
		if self.addPaymentID_buttonView.isHidden == false {
			let lastMostVisibleView: UIView
			do {
				if self.createNewContact_buttonView.isHidden == false {
					lastMostVisibleView = self.createNewContact_buttonView
				} else {
					lastMostVisibleView = self.requestFrom_inputView
				}
			}
			self.addPaymentID_buttonView!.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + 8,
				width: self.addPaymentID_buttonView!.frame.size.width,
				height: self.addPaymentID_buttonView!.frame.size.height
			)
		}
		//
		if self.manualPaymentID_label.isHidden == false {
			assert(self.addPaymentID_buttonView.isHidden == true)
			//
			let lastMostVisibleView: UIView
			do {
				if self.createNewContact_buttonView.isHidden == false {
					lastMostVisibleView = self.createNewContact_buttonView
				} else {
					lastMostVisibleView = self.requestFrom_inputView
				}
			}
			self.manualPaymentID_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + 8,
				width: fullWidth_label_w,
				height: self.manualPaymentID_label.frame.size.height
			).integral
			self.manualPaymentID_accessoryLabel.frame = CGRect(
				x: CGFloat.form_labelAccessoryLabel_margin_x,
				y: self.manualPaymentID_label.frame.origin.y,
				width: fullWidth_label_w,
				height: self.manualPaymentID_accessoryLabel.frame.size.height
			).integral
			self.manualPaymentID_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.manualPaymentID_label.frame.origin.y + self.manualPaymentID_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.manualPaymentID_inputView.frame.size.height
			).integral
		}
		//
		let bottomMostView: UIView
		do {
			if self.manualPaymentID_inputView.isHidden == false {
				bottomMostView = self.manualPaymentID_inputView
			} else if self.addPaymentID_buttonView.isHidden == false {
				bottomMostView = self.addPaymentID_buttonView
			} else if self.createNewContact_buttonView.isHidden == false {
				bottomMostView = self.createNewContact_buttonView
			} else {
				bottomMostView = self.requestFrom_inputView
			}
		}
		let bottomPadding: CGFloat = 18 + (self.requestFrom_inputView.inputField.isFirstResponder ? 300/*prevent height disparity when view not large enough to stay scrolled to top*/ : 0)
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
//			DispatchQueue.main.async
//			{ [unowned self] in
//				if self.sanitizedInputValue__selectedContact == nil {
//					assert(self.requestFrom_inputView.inputField.isHidden == false)
//					self.requestFrom_inputView.inputField.becomeFirstResponder()
//				}
//			}
		}
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
	//
	func createNewContact_tapped()
	{
		let viewController = AddContactFromOtherTabFormViewController()
		viewController.didSave_instance_fn =
		{ [unowned self] (instance) in
			self.requestFrom_inputView.pick(contact: instance) // not going to call AtRuntime_reconfigureWith_fromContact() here because that's for user actions like Request where they're expecting the contact to be the initial state of self instead of this, which is initiated by their action from a modal that is nested within self
		}
		let navigationController = UINavigationController(rootViewController: viewController)
		self.navigationController!.present(navigationController, animated: true, completion: nil)
	}
	func addPaymentID_tapped()
	{
		self.set_manualPaymentIDField(isHidden: false)
		self.addPaymentID_buttonView.isHidden = true
	}
}
