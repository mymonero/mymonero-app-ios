//
//  SendFundsFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/21/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
struct SendFundsForm {}
//
extension SendFundsForm
{
	class ViewController: UICommonComponents.FormViewController
	{
		//
		// Static - Shared singleton
		static let shared = SendFundsForm.ViewController()
		//
		// Properties
		var fromWallet_label: UICommonComponents.Form.FieldLabel!
		var fromWallet_inputView: UICommonComponents.WalletPickerButtonView!
		//
		var amount_label: UICommonComponents.Form.FieldLabel!
		var amount_fieldset: UICommonComponents.Form.AmountInputFieldsetView!
		//
		var sendTo_label: UICommonComponents.Form.FieldLabel!
		var sendTo_inputView: UICommonComponents.Form.ContactAndAddressPickerView!
		var isWaitingOnFieldBeginEditingScrollTo_sendTo = false // a bit janky
		//
		var addPaymentID_buttonView: UICommonComponents.LinkButtonView!
		//
		var manualPaymentID_label: UICommonComponents.Form.FieldLabel!
		var manualPaymentID_inputView: UICommonComponents.FormInputField!
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
					title: NSLocalizedString("FROM", comment: "")
				)
				self.fromWallet_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.WalletPickerButtonView(selectedWallet: nil)
				self.fromWallet_inputView = view
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
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("TO", comment: "")
				)
				self.sendTo_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.ContactAndAddressPickerView(
					inputMode: .contactsAndAddresses,
					displayMode: .paymentIds_andResolvedAddrs
				)
				view.inputField.set(
					placeholder: NSLocalizedString("Contact name or address/domain", comment: "")
				)
				view.textFieldDidBeginEditing_fn =
				{ [unowned self] (textField) in
					self.view.setNeedsLayout() // to be certain we get the updated bottom padding
					
					self.aField_didBeginEditing(textField, butSuppressScroll: true) // suppress scroll and call manually
					// ^- this does not actually do anything at present, given suppressed scroll
					self.isWaitingOnFieldBeginEditingScrollTo_sendTo = true // sort of janky
					DispatchQueue.main.asyncAfter(
						deadline: .now() + UICommonComponents.FormViewController.fieldScrollDuration + 0.1
					) // slightly janky to use delay/duration, we need to wait (properly/considerably) for any layout changes that will occur here
					{ [unowned self] in
						self.isWaitingOnFieldBeginEditingScrollTo_sendTo = false // unset
						if view.inputField.isFirstResponder { // jic
							self.scrollToVisible_sendTo()
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
						if self.isWaitingOnFieldBeginEditingScrollTo_sendTo == true {
							return // semi-janky -- but is used to prevent potential double scroll oddness
						}
						if view.inputField.isFirstResponder {
							self.scrollToVisible_sendTo()
						}
					}
				}
				view.textFieldDidEndEditing_fn =
				{ (textField) in
					// nothing to do in this case
				}
				view.didPickContact_fn =
				{ [unowned self] (contact, doesNeedToResolveItsOAAddress) in
					self.set_addPaymentID_buttonView(isHidden: true) // hide if showing
					self.hideAndClear_manualPaymentIDField() // if there's a pid we'll show it as 'Detected' anyway
					//
					if doesNeedToResolveItsOAAddress == true { // so we still need to wait and check to see if they have a payment ID
						// contact picker will show its own resolving indicator while we look up the paymentID again
						self.set_isFormSubmittable_needsUpdate() // this will involve a check to whether the contact picker is resolving
						//
						self.clearValidationMessage() // assuming it's okay to do this here - and need to since the coming callback can set the validation msg
						//
						return
					}
					//
					// contact picker will handle showing resolved addr / pid etc
				}
				view.changedTextContent_fn =
				{ [unowned self] in
					self.clearValidationMessage() // in case any from text resolve
				}
				view.clearedTextContent_fn =
				{ [unowned self] in
					if self.manualPaymentID_inputView.isHidden {
						self.set_addPaymentID_buttonView(isHidden: false) // show if hidden as we may have hidden it
					}
				}
				view.willValidateNonZeroTextInput_fn =
				{ [unowned self] in
					self.set_isFormSubmittable_needsUpdate()
				}
				view.finishedValidatingTextInput_foundValidMoneroAddress_fn =
				{ [unowned self] (detectedEmbedded_paymentID) in
					self.set_isFormSubmittable_needsUpdate()
					if detectedEmbedded_paymentID != nil { // i.e. integrated address supplying one - we show it as 'detected'
						self.set_addPaymentID_buttonView(isHidden: true)
						self.hideAndClear_manualPaymentIDField()
					}
				}
				view.willBeginResolvingPossibleOATextInput_fn =
				{
					self.hideAndClear_manualPaymentIDField()
					self.set_addPaymentID_buttonView(isHidden: true)
					self.clearValidationMessage() // this is probably redundant here
				}
				view.oaResolve__preSuccess_terminal_validationMessage_fn =
				{ [unowned self] (localizedString) in
					self.setValidationMessage(localizedString)
					self.set_isFormSubmittable_needsUpdate() // as it will check whether we are resolving
				}
				view.oaResolve__success_fn =
				{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
					self.set_isFormSubmittable_needsUpdate() // will check if picker is resolving
					//
					// there is no need to tell the contact to update its address and payment ID here as it will be observing the emitted event from this very request to .Resolve
					//
					// the ContactPicker also already handles displaying the resolved addr and pids
					//
					do { // now since the contact picker's mode is handling resolving text inputs too:
						if view.hasValidTextInput_resolvedOAAddress {
							if payment_id != nil && payment_id != "" { // just to make sure we're not showing these,
								// we already hid the + and manual pid input views
							} else {
								if self.manualPaymentID_inputView.isHidden { // if manual payment field not showing
									self.set_addPaymentID_buttonView(isHidden: false) // then make sure we are at least showing the + payment ID btn
								} else {
									// it should be the case here that either add pymt id btn or manual payment field is visible
								}
							}
						} else {
							assert(view.selectedContact != nil) // or they'd better have selected a contact!!
						}
					}
				}
				view.didClearPickedContact_fn =
				{ [unowned self] (preExistingContact) in
					self.clearValidationMessage() // in case there was an OA addr resolve network err sitting on the screen
					//
					self.set_isFormSubmittable_needsUpdate() // as it will look at resolving
					//
					self.set_addPaymentID_buttonView(isHidden: false) // show if hidden
					self.hideAndClear_manualPaymentIDField() // if showing
				}
				let inputField = view.inputField
				inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				self.sendTo_inputView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: NSLocalizedString("+ ADD PAYMENT ID", comment: ""))
				view.addTarget(self, action: #selector(addPaymentID_tapped), for: .touchUpInside)
				self.addPaymentID_buttonView = view
				self.scrollView.addSubview(view)
			}
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
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("A specific payment ID", comment: "")
				)
				view.isHidden = true // initially
				let inputField = view
				inputField.autocorrectionType = .no
				inputField.autocapitalizationType = .none
				inputField.delegate = self
				inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				inputField.returnKeyType = .next
				self.manualPaymentID_inputView = view
				self.scrollView.addSubview(view)
			}
		}
		override func setup_navigation()
		{
			super.setup_navigation()
			self.navigationItem.title = NSLocalizedString("Send Monero", comment: "")
			self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .send,
				target: self,
				action: #selector(tapped_rightBarButtonItem)
			)
		}
		//
		// Accessors - Overrides
		override func new_isFormSubmittable() -> Bool
		{
			if self.formSubmissionController != nil {
				return false
			}
			if self.sendTo_inputView.isResolving {
				return false
			}
			if self.sendTo_inputView.isValidatingOrResolvingNonZeroTextInput {
				return false
			}
			if self.amount_fieldset.inputField.submittableAmount_orNil == nil { // amount is required
				return false
			}
			if self.sendTo_inputView.hasValidTextInput_moneroAddress == false
				&& self.sendTo_inputView.hasValidTextInput_resolvedOAAddress == false
				&& self.sendTo_inputView.selectedContact == nil {
				return false
			}
			return true
		}
		//
		// Accessors - Overrides
		override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
		{
			switch inputView {
			case self.fromWallet_inputView.picker_inputField:
				return self.amount_fieldset.inputField
			case self.amount_fieldset.inputField:
				if self.sendTo_inputView.inputField.isHidden == false {
					return self.sendTo_inputView.inputField
				} else if self.manualPaymentID_inputView.isHidden == false {
					return self.manualPaymentID_inputView
				}
				break
			case self.sendTo_inputView.inputField:
				if self.manualPaymentID_inputView.isHidden == false {
					return manualPaymentID_inputView
				}
				break 
			case self.manualPaymentID_inputView:
				break
			default:
				assert(false, "Unexpected")
				return nil
			}
			return self.fromWallet_inputView.picker_inputField // wrap to start
		}
		override func new_wantsBGTapRecognizerToReceive_tapped(onView view: UIView) -> Bool
		{
			if view.isAnyAncestor(self.sendTo_inputView) {
				// this is to prevent taps on the searchResults tableView from dismissing the input (which btw makes selection of search results rows impossible)
				// but it's ok if this is the inputField itself
				return false
			}
			return super.new_wantsBGTapRecognizerToReceive_tapped(onView: view)
		}
		//
		// Accessors
		var sanitizedInputValue__fromWallet: Wallet {
			return self.fromWallet_inputView.selectedWallet! // we are never expecting this modal to be visible when no wallets exist, so a crash is/ought to be ok
		}
		var sanitizedInputValue__amount: MoneroAmount? {
			return self.amount_fieldset.inputField.submittableAmount_orNil
		}
		var sanitizedInputValue__selectedContact: Contact? {
			return self.sendTo_inputView.selectedContact
		}
		var sanitizedInputValue__paymentID: MoneroPaymentID? {
			if self.manualPaymentID_inputView.text != nil && self.manualPaymentID_inputView!.isHidden != true {
				let stripped_paymentID = self.manualPaymentID_inputView!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
				if stripped_paymentID != "" {
					return stripped_paymentID
				}
			}
			// TODO:
			return nil
		}
		//
		// Imperatives - Field visibility/configuration
		func set_manualPaymentIDField(isHidden: Bool)
		{
			self.manualPaymentID_label.isHidden = isHidden
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
		func set_addPaymentID_buttonView(isHidden: Bool)
		{
			self.addPaymentID_buttonView.isHidden = isHidden
			self.view.setNeedsLayout()
		}
		//
		// Imperatives - Contact picker, contact picking
		func scrollToVisible_sendTo()
		{
			let toBeVisible_frame__absolute = CGRect(
				x: 0,
				y: self.sendTo_label.frame.origin.y,
				width: self.sendTo_inputView.frame.size.width,
				height: (self.sendTo_inputView.frame.origin.y - self.sendTo_label.frame.origin.y) + self.sendTo_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField
			)
			self.scrollRectToVisible(
				toBeVisible_frame__absolute: toBeVisible_frame__absolute,
				atEdge: .top,
				finished_fn: {}
			)
//			self.scrollView.scrollRectToVisible(toBeVisible_frame__absolute, animated: true)
		}
		public func reconfigureFormAtRuntime_havingElsewhereSelected(sendToContact contact: Contact)
		{
			self.amount_fieldset.inputField.text = "" // figure that since this method is called when user is trying to initiate a new request, we should clear the amount
			//
			self.sendTo_inputView.pick(contact: contact)
		}
		//
		// Runtime - Imperatives - Overrides
		override func disableForm()
		{
			super.disableForm()
			//
			self.scrollView.isScrollEnabled = false
			//
			self.fromWallet_inputView.isEnabled = false
			self.amount_fieldset.inputField.isEnabled = false
			self.sendTo_inputView.inputField.isEnabled = false
			if let pillView = self.sendTo_inputView.selectedContactPillView {
				pillView.xButton.isEnabled = true
			}
			self.manualPaymentID_inputView.isEnabled = false
			
			// TODO: disable action buttons too
		}
		override func reEnableForm()
		{
			super.reEnableForm()
			//
			self.scrollView.isScrollEnabled = true
			//
			self.fromWallet_inputView.isEnabled = true
			self.amount_fieldset.inputField.isEnabled = true
			self.sendTo_inputView.inputField.isEnabled = true
			if let pillView = self.sendTo_inputView.selectedContactPillView {
				pillView.xButton.isEnabled = true
			}
			self.manualPaymentID_inputView.isEnabled = true

			// TODO: enable action buttons too
		}
		var formSubmissionController: SendFundsForm.SubmissionController?
		override func _tryToSubmitForm()
		{
			self.clearValidationMessage()
			//
			let fromWallet = self.fromWallet_inputView.selectedWallet!
			//
			let amountText = self.amount_fieldset.inputField.text // we're going to allow empty amounts
			let amount_submittableDouble = self.amount_fieldset.inputField.submittableDouble_orNil
			do {
				assert(amount_submittableDouble != nil && amountText != nil && amountText != "")
				if amount_submittableDouble == nil {
					self.setValidationMessage(NSLocalizedString("Please enter a valid amount of Monero.", comment: ""))
					return
				}
			}
			if amount_submittableDouble! <= 0 {
				self.setValidationMessage(NSLocalizedString("The amount to send must be greater than zero.", comment: ""))
				return
			}
			//
			self.disableForm() // optimistic
			//
			let selectedContact = self.sendTo_inputView.selectedContact
			let enteredAddressValue = self.sendTo_inputView.inputField.text
			//
			let resolvedAddress = self.sendTo_inputView.resolvedXMRAddr_inputView?.textView.text
			let resolvedAddress_fieldIsVisible = self.sendTo_inputView.resolvedXMRAddr_inputView != nil && self.sendTo_inputView.resolvedXMRAddr_inputView?.isHidden == false
			//
			let manuallyEnteredPaymentID = self.manualPaymentID_inputView.text
			let manuallyEnteredPaymentID_fieldIsVisible = self.manualPaymentID_inputView.isHidden == false
			//
			let resolvedPaymentID = self.sendTo_inputView.resolvedPaymentID_inputView?.textView.text ?? ""
			let resolvedPaymentID_fieldIsVisible = self.sendTo_inputView.resolvedPaymentID_inputView != nil && self.sendTo_inputView.resolvedPaymentID_inputView?.isHidden == false
			//
			//
			let parameters = SendFundsForm.SubmissionController.Parameters(
				fromWallet: fromWallet,
				amount_submittableDouble: amount_submittableDouble!,
				//
				selectedContact: selectedContact,
				enteredAddressValue: enteredAddressValue,
				//
				resolvedAddress: resolvedAddress,
				resolvedAddress_fieldIsVisible: resolvedAddress_fieldIsVisible,
				//
				manuallyEnteredPaymentID: manuallyEnteredPaymentID,
				manuallyEnteredPaymentID_fieldIsVisible: manuallyEnteredPaymentID_fieldIsVisible,
				resolvedPaymentID: resolvedPaymentID,
				resolvedPaymentID_fieldIsVisible: resolvedPaymentID_fieldIsVisible,
				//
				preSuccess_terminal_validationMessage_fn:
				{ [unowned self] (localizedString) in
					self.set(
						validationMessage: localizedString,
						wantsXButton: true
					)
					self.formSubmissionController = nil // must free as this is a terminal callback
					self.set_isFormSubmittable_needsUpdate()
					self.reEnableForm() // b/c we disabled it
				},
				preSuccess_passedValidation_willBeginSending:
				{ [unowned self] in
					self.set(
						validationMessage: String(
							format: NSLocalizedString("Sending %@ XMR…", comment: ""),
							self.amount_fieldset.inputField.submittableAmount_orNil!.humanReadableString
						),
						wantsXButton: false
					)
				},
				success_fn:
				{ [unowned self] (mockedTransaction) in
					self.formSubmissionController = nil // must free as this is a terminal callback
					// will re-enable form shortly (after presentation)
					//
					do {
						let viewController = TransactionDetails.ViewController(
							transaction: mockedTransaction,
							inWallet: fromWallet
						)
						self.navigationController!.pushViewController(
							viewController,
							animated: true
						)
					}
					do { // and after a delay, present AddContactFromSendTabView
						if selectedContact == nil { // so they went with a text input address
							DispatchQueue.main.asyncAfter(
								deadline: .now() + 0.75 + 0.3, // after the navigation transition just above has taken place, and given a little delay for user to get their bearings
								execute:
								{ [unowned self] in
									// TODO
									let viewController = UIViewController()/*AddContactFromSendTabFormViewController(
										enteredAddressValue: enteredAddressValue
										// TODO: more values as necessary
									)*/
									let navigationController = UINavigationController(rootViewController: viewController)
									self.navigationController!.present(navigationController, animated: true, completion: nil)
								}
							)
						}
					}
					do { // finally, clean up form
						DispatchQueue.main.asyncAfter(
							deadline: .now() + 0.5, // after the navigation transition just above has taken place
							execute:
							{ [unowned self] in
								self._clearForm()
								// and lastly, importantly, re-enable everything
								self.reEnableForm()
							}
						)
					}
				}
			)
			let controller = SendFundsForm.SubmissionController(parameters: parameters)
			self.formSubmissionController = controller
			do {
				self.disableForm()
				self.set_isFormSubmittable_needsUpdate() // update submittability; after setting self.submissionController
			}
			controller.handle()
		}
		//
		// Impertives - Clearing form
		func _clearForm()
		{
			self.clearValidationMessage()
			self.amount_fieldset.inputField.text = ""
			self.sendTo_inputView.clearAndReset()
			do {
				self.hideAndClear_manualPaymentIDField()
				self.set_addPaymentID_buttonView(isHidden: false)
			}
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
				self.fromWallet_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: ceil(top_yOffset),
					width: fullWidth_label_w,
					height: self.fromWallet_label.frame.size.height
					).integral
				self.fromWallet_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.fromWallet_label.frame.origin.y + self.fromWallet_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
					width: textField_w,
					height: self.fromWallet_inputView.frame.size.height
					).integral
			}
			do {
				self.amount_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.fromWallet_inputView.frame.origin.y + self.fromWallet_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
					width: fullWidth_label_w,
					height: self.fromWallet_label.frame.size.height
					).integral
				self.amount_fieldset.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.amount_label.frame.origin.y + self.amount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: self.amount_fieldset.frame.size.width,
					height: self.amount_fieldset.frame.size.height
					).integral
			}
			do {
				self.sendTo_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.amount_fieldset.frame.origin.y + self.amount_fieldset.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
					width: fullWidth_label_w,
					height: self.sendTo_label.frame.size.height
					).integral
				self.sendTo_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.sendTo_label.frame.origin.y + self.sendTo_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.sendTo_inputView.frame.size.height
					).integral
			}
			//
			if self.addPaymentID_buttonView.isHidden == false {
				assert(self.manualPaymentID_label.isHidden == true)
				let lastMostVisibleView = self.sendTo_inputView!
				self.addPaymentID_buttonView!.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + 12,
					width: self.addPaymentID_buttonView!.frame.size.width,
					height: self.addPaymentID_buttonView!.frame.size.height
				)
			}
			//
			if self.manualPaymentID_label.isHidden == false {
				assert(self.addPaymentID_buttonView.isHidden == true)
				let lastMostVisibleView = self.sendTo_inputView! // why is the ! necessary?
				self.manualPaymentID_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + 12,
					width: fullWidth_label_w,
					height: self.manualPaymentID_label.frame.size.height
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
				} else {
					bottomMostView = self.sendTo_inputView
				}
			}
			let bottomPadding: CGFloat = 18 + (self.sendTo_inputView.inputField.isFirstResponder ? 300/*prevent height disparity when view not large enough to stay scrolled to top*/ : 0)
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
//				DispatchQueue.main.async
//				{ [unowned self] in
//					if self.sanitizedInputValue__selectedContact == nil {
//						assert(self.sendTo_inputView.inputField.isHidden == false)
//						self.sendTo_inputView.inputField.becomeFirstResponder()
//					}
//				}
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
		//
		func addPaymentID_tapped()
		{
			self.set_addPaymentID_buttonView(isHidden: true)
			self.set_manualPaymentIDField(isHidden: false)
		}
	}
}
