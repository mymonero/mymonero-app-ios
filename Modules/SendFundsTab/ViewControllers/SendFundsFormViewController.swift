//
//  SendFundsFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/21/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
import ImageIO
//
struct SendFundsForm {}
//
extension SendFundsForm
{
	class ViewController: UICommonComponents.FormViewController, DeleteEverythingRegistrant, UIImagePickerControllerDelegate, UINavigationControllerDelegate
	{
		//
		// Static - Shared singleton
		static let shared = SendFundsForm.ViewController()
		//
		// Properties/Protocols - DeleteEverythingRegistrant
		var instanceUUID = UUID()
		func identifier() -> String { // satisfy DeleteEverythingRegistrant for isEqual
			return self.instanceUUID.uuidString
		}
		//
		// Properties - Initial - Runtime
		var fromWallet_label: UICommonComponents.Form.FieldLabel!
		var fromWallet_inputView: UICommonComponents.WalletPickerButtonView!
		//
		var amount_label: UICommonComponents.Form.FieldLabel!
		var amount_fieldset: UICommonComponents.Form.AmountInputFieldsetView!
		var feeEstimate_label: UICommonComponents.FormFieldAccessoryMessageLabel!
		var feeEstimate_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var sendTo_label: UICommonComponents.Form.FieldLabel!
		var sendTo_inputView: UICommonComponents.Form.ContactAndAddressPickerView!
		var isWaitingOnFieldBeginEditingScrollTo_sendTo = false // a bit janky
		var sendTo_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var addPaymentID_buttonView: UICommonComponents.LinkButtonView!
		//
		var manualPaymentID_label: UICommonComponents.Form.FieldLabel!
		var manualPaymentID_inputView: UICommonComponents.FormInputField!
		//
		var useCamera_actionButtonView: UICommonComponents.ActionButton!
		var chooseFile_actionButtonView: UICommonComponents.ActionButton!
		//
		var presented_imagePickerController: UIImagePickerController?
		var presented_cameraViewController: QRCodeScanningCameraViewController?
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
			do {
				let view = UICommonComponents.FormFieldAccessoryMessageLabel(
					text: nil,
					displayMode: .prominent // slightly brighter here per design; considered merging
				)
				self.feeEstimate_label = view
				self.configure_feeEstimate_label()
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: String(
						format: NSLocalizedString(
							"Monero makes transactions with your \"available outputs\", so part of your balance will be briefly locked and then returned as change.\n\nMonero ringsize value set to %d.",
							comment: ""
						),
						FixedMixin()+1
					)
				)
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.feeEstimate_tooltipSpawn_buttonView = view
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
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: String(
						format: NSLocalizedString(
							"Please double-check the accuracy of your recipient information as Monero transactions are irreversible.",
							comment: ""
						)
					)
				)
				view.tooltipDirectionFromOrigin = .right
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.sendTo_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.ContactAndAddressPickerView(
					inputMode: .contactsAndAddresses,
					displayMode: .paymentIds_andResolvedAddrs,
					parentScrollView: self.scrollView
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
					self.set_isFormSubmittable_needsUpdate() // this will involve a check to whether the contact picker is resolving
					//
					if doesNeedToResolveItsOAAddress == true { // so we still need to wait and check to see if they have a payment ID
						// contact picker will show its own resolving indicator while we look up the paymentID again
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
					assert(Thread.isMainThread)
					self.set_isFormSubmittable_needsUpdate()
					if detectedEmbedded_paymentID != nil { // i.e. integrated address supplying one - we show it as 'detected'
						self.set_addPaymentID_buttonView(isHidden: true)
						self.hideAndClear_manualPaymentIDField()
					}
				}
				view.willBeginResolvingPossibleOATextInput_fn =
				{
					assert(Thread.isMainThread)
					self.hideAndClear_manualPaymentIDField()
					self.set_addPaymentID_buttonView(isHidden: true)
					self.clearValidationMessage() // this is probably redundant here
				}
				view.oaResolve__preSuccess_terminal_validationMessage_fn =
				{ [unowned self] (localizedString) in
					assert(Thread.isMainThread)
					self.setValidationMessage(localizedString)
					self.set_isFormSubmittable_needsUpdate() // as it will check whether we are resolving
				}
				view.oaResolve__success_fn =
				{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
					assert(Thread.isMainThread)
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
			//
			do {
				let iconImage = UIImage(named: "actionButton_iconImage__useCamera")!
				let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true, iconImage: iconImage)
				view.addTarget(self, action: #selector(useCamera_tapped), for: .touchUpInside)
				view.setTitle(NSLocalizedString("Use Camera", comment: ""), for: .normal)
				self.useCamera_actionButtonView = view
				self.view.addSubview(view) // not self.scrollView
			}
			do {
				let iconImage = UIImage(named: "actionButton_iconImage__chooseFile")!
				let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: false, iconImage: iconImage)
				view.addTarget(self, action: #selector(chooseFile_tapped), for: .touchUpInside)
				view.setTitle(NSLocalizedString("Choose file", comment: ""), for: .normal)
				self.chooseFile_actionButtonView = view
				self.view.addSubview(view) // not self.scrollView
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
		override func startObserving()
		{
			super.startObserving()
			PasswordController.shared.addRegistrantForDeleteEverything(self)
			//
			NotificationCenter.default.addObserver(self, selector: #selector(URLOpening_saysTimeToHandleReceivedMoneroURL(_:)), name: URLOpening.NotificationNames.saysTimeToHandleReceivedMoneroURL.notificationName, object: nil)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(WalletAppContactActionsCoordinator_didTrigger_sendFundsToContact(_:)),
				name: WalletAppContactActionsCoordinator.NotificationNames.didTrigger_sendFundsToContact.notificationName, // observe 'did' so we're guaranteed to already be on right tab
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(WalletAppWalletActionsCoordinator_didTrigger_sendFundsFromWallet(_:)),
				name: WalletAppWalletActionsCoordinator.NotificationNames.didTrigger_sendFundsFromWallet.notificationName, // observe 'did' so we're guaranteed to already be on right tab
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(PasswordController_willDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(PasswordController_didDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
		}
		//
		override func tearDown()
		{
			super.tearDown()
			self._tearDownAnyImagePickerController(animated: false)
			self._tearDownAnyQRScanningCameraViewController(animated: false)
		}
		override func stopObserving()
		{
			super.stopObserving()
			PasswordController.shared.removeRegistrantForDeleteEverything(self)
			//
			NotificationCenter.default.removeObserver(self, name: URLOpening.NotificationNames.saysTimeToHandleReceivedMoneroURL.notificationName, object: nil)

			NotificationCenter.default.removeObserver(self, name: WalletAppContactActionsCoordinator.NotificationNames.didTrigger_sendFundsToContact.notificationName, object: nil)
			//
			NotificationCenter.default.removeObserver(
				self,
				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			NotificationCenter.default.removeObserver(
				self,
				name: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
		}
		func _tearDownAnyImagePickerController(animated: Bool)
		{
			if let viewController = self.presented_imagePickerController {
				if self.navigationController?.presentedViewController == viewController {
					viewController.dismiss(animated: animated, completion: nil)
				} else {
					DDLog.Warn("SendFundsTab", "Asked to teardown image picker while it was non-nil but not presented.")
				}
				self.presented_imagePickerController = nil
			}
		}
		func _tearDownAnyQRScanningCameraViewController(animated: Bool)
		{
			if let viewController = self.presented_cameraViewController {
				let actualPresentedViewController = viewController.navigationController!
				if self.navigationController?.presentedViewController == actualPresentedViewController {
					actualPresentedViewController.dismiss(animated: animated, completion: nil)
				} else {
					DDLog.Warn("SendFundsTab", "Asked to teardown QR scanning camera vc while it was non-nil but not presented.")
				}
				self.presented_cameraViewController = nil
			}
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
		override func new_contentInset() -> UIEdgeInsets
		{
			var inset = super.new_contentInset()
			inset.bottom += UICommonComponents.ActionButton.wholeButtonsContainerHeight
			
			return inset
		}
		//
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
			return nil
		}
		//
		// Imperatives - Field visibility
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
		// Imperatives - Configuration - Fee estimate label
		func configure_feeEstimate_label()
		{
			let estimatedFee_formattedString: String = "0.028" // constant for now due to median blocksize difference in fee est algo plus fact that MyMonero fee turned off for now
			self.feeEstimate_label.text = String(
				format: NSLocalizedString("+ %@ EST. FEE", comment: ""),
				estimatedFee_formattedString
			)
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
//			self.scrollView.isScrollEnabled = false
			//
			self.fromWallet_inputView.isEnabled = false
			self.amount_fieldset.inputField.isEnabled = false
			self.sendTo_inputView.inputField.isEnabled = false
			if let pillView = self.sendTo_inputView.selectedContactPillView {
				pillView.xButton.isEnabled = true
			}
			self.manualPaymentID_inputView.isEnabled = false
			self.addPaymentID_buttonView.isEnabled = false
			//
			self.useCamera_actionButtonView.isEnabled = false
			self.chooseFile_actionButtonView.isEnabled = false
		}
		override func reEnableForm()
		{
			super.reEnableForm()
			//
			// allowing scroll so user can check while sending despite no cancel support existing yet
//			self.scrollView.isScrollEnabled = true
			//
			self.fromWallet_inputView.isEnabled = true
			self.amount_fieldset.inputField.isEnabled = true
			self.sendTo_inputView.inputField.isEnabled = true
			if let pillView = self.sendTo_inputView.selectedContactPillView {
				pillView.xButton.isEnabled = true
			}
			self.manualPaymentID_inputView.isEnabled = true
			self.addPaymentID_buttonView.isEnabled = true
			//
			self.useCamera_actionButtonView.isEnabled = true
			self.chooseFile_actionButtonView.isEnabled = true
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
				{ [unowned self] (
					mockedTransaction,
					isXMRAddressIntegrated,
					integratedAddressPIDForDisplay_orNil
				) in
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
									let parameters = AddContactFromSendFundsTabFormViewController.InitializationParameters(
										enteredAddressValue: enteredAddressValue!, // ! b/c selected contact was nil
										isXMRAddressIntegrated: isXMRAddressIntegrated,
										integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil,
										resolvedAddress: resolvedAddress_fieldIsVisible ? resolvedAddress : nil,
										sentWith_paymentID: mockedTransaction.paymentId
									)
									let viewController = AddContactFromSendFundsTabFormViewController(
										parameters: parameters
									)
									let navigationController = UINavigationController(rootViewController: viewController)
									navigationController.modalPresentationStyle = .formSheet
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
				self.feeEstimate_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.amount_fieldset.frame.origin.y + self.amount_fieldset.frame.size.height + UICommonComponents.FormFieldAccessoryMessageLabel.marginAboveLabelBelowTextInputView,
					width: fullWidth_label_w,
					height: 0
				).integral
				do {
					self.feeEstimate_label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
					var final__feeEstimate_label_frame = self.feeEstimate_label.frame
					final__feeEstimate_label_frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
					self.feeEstimate_label.frame = final__feeEstimate_label_frame // kinda sucks to set this three times in this method. any alternative?
					//
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.feeEstimate_tooltipSpawn_buttonView.frame = CGRect(
						x: self.feeEstimate_label.frame.origin.x + self.feeEstimate_label.frame.size.width - 4,
						y: self.feeEstimate_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.feeEstimate_label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
			}
			do {
				self.sendTo_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.feeEstimate_label.frame.origin.y + self.feeEstimate_label.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
					width: 13,
					height: self.sendTo_label.frame.size.height
				).integral
				do {					
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.sendTo_tooltipSpawn_buttonView.frame = CGRect(
						x: self.sendTo_label.frame.origin.x + self.sendTo_label.frame.size.width - 4,
						y: self.sendTo_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.sendTo_label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
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
			//
			// non-scrolling:
			let buttons_y = self.view.bounds.size.height - UICommonComponents.ActionButton.wholeButtonsContainerHeight_withoutTopMargin
			self.useCamera_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
			self.chooseFile_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
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
		override func viewWillDisappear(_ animated: Bool)
		{
			super.viewWillDisappear(animated)
			self.feeEstimate_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
			self.sendTo_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
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
		//
		func useCamera_tapped()
		{
			let viewController = QRCodeScanningCameraViewController()
			if let error = viewController.didFatalErrorOnInit {
				let alertController = UIAlertController(
					title: error.localizedDescription,
					message: error.userInfo["NSLocalizedRecoverySuggestion"] as? String ?? NSLocalizedString("Please ensure MyMonero can access your device camera via iOS Settings > Privacy.", comment: ""),
					preferredStyle: .alert
				)
				alertController.addAction(
					UIAlertAction(
						title: NSLocalizedString("OK", comment: ""),
						style: .default
						)
					{ (result: UIAlertAction) -> Void in
					}
				)
				self.navigationController!.present(alertController, animated: true, completion: nil)
				//
				return // effectively discarding viewController
			}
			viewController.didCancel_fn =
			{ [unowned self] in
				self._tearDownAnyQRScanningCameraViewController(animated: true)
			}
			var hasOnceUsedScannedString = false // prevent redundant submits
			viewController.didLocateQRCodeMessageString_fn =
			{ [unowned self] (scannedMessageString) in
				if hasOnceUsedScannedString == false {
					hasOnceUsedScannedString = true
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) // delay here merely for visual effect
					{ [unowned self] in
						self._tearDownAnyQRScanningCameraViewController(animated: true)
						self.__shared_didPick(requestURIStringForAutofill: scannedMessageString) // possibly wait til completion?
					}					
				}
			}
			self.presented_cameraViewController = viewController
			let navigationController = UINavigationController(rootViewController: viewController)
			self.navigationController!.present(
				navigationController,
				animated: true,
				completion: nil
			)
		}
		func chooseFile_tapped()
		{
			guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else {
				let alertController = UIAlertController(
					title: NSLocalizedString("Saved Photos Album not available", comment: ""),
					message: NSLocalizedString(
						"Please ensure you have allowed MyMonero to access your Photos.",
						comment: ""
					),
					preferredStyle: .alert
				)
				alertController.addAction(
					UIAlertAction(
						title: NSLocalizedString("OK", comment: ""),
						style: .default
						)
					{ (result: UIAlertAction) -> Void in
					}
				)
				self.navigationController!.present(alertController, animated: true, completion: nil)
				return
			}
			let pickerController = UIImagePickerController()
			pickerController.view.backgroundColor = .contentBackgroundColor // prevent weird flashing on transitions
			pickerController.navigationBar.tintColor = UIColor.systemStandard_navigationBar_tintColor // make it look at least slightly passable… would be nice if font size of btns could be reduced (next to such a small nav title font)… TODO: pimp out nav bar btns, including 'back', ala PushButton
			pickerController.allowsEditing = false
			pickerController.delegate = self
			pickerController.modalPresentationStyle = .formSheet
			self.presented_imagePickerController = pickerController
			self.navigationController!.present(pickerController, animated: true, completion: nil)
		}
		//
		// Delegation - UIImagePickerControllerDelegate
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
		{
			let picked_originalImage = info[UIImagePickerControllerOriginalImage] as! UIImage
			self._didPick(possibleQRCodeImage: picked_originalImage)
			self._tearDownAnyImagePickerController(animated: true)
		}
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
		{
			self._tearDownAnyImagePickerController(animated: true)
		}
		//
		// Delegation - QR code and URL picking
		func _didPick(possibleQRCodeImage image: UIImage)
		{
			if self.isFormEnabled == false {
				DDLog.Warn("SendFundsTab", "Disallowing QR code pick while form disabled")
				return
			}
			self.clearValidationMessage() // in case there was a parsing err etc displaying
			self._clearForm() // may as well
			//
			// now decode qr …
			let ciImage = CIImage(cgImage: image.cgImage!)
			var options: [String: Any] = [:]
			do {
				options[CIDetectorAccuracy] = CIDetectorAccuracyHigh
				do {
					let properties = ciImage.properties
					let raw_orientation = properties[kCGImagePropertyOrientation as String]
					let final_orientation = raw_orientation ?? 1 /* "If not present, a value of 1 is assumed." */
					//
					options[CIDetectorImageOrientation] = final_orientation
				}
			}
			let context = CIContext()
			let detector = CIDetector(
				ofType: CIDetectorTypeQRCode,
				context: context,
				options: options
			)!
			let features = detector.features(in: ciImage, options: options)
			if features.count == 0 {
				self.set(
					validationMessage: NSLocalizedString("Unable to find QR code data in image", comment: ""),
					wantsXButton: true
				)
				return
			}
			if features.count > 2 {
				self.set(
					validationMessage: NSLocalizedString("Unexpectedly found multiple QR features in image. This may be a bug.", comment: ""),
					wantsXButton: true
				)
			}
			let feature = features.first! as! CIQRCodeFeature
			let messageString = feature.messageString
			if messageString == nil || messageString == "" {
				self.set(
					validationMessage: NSLocalizedString("Unable to find message string in image's QR code.", comment: ""),
					wantsXButton: true
				)
				return
			}
			self.__shared_didPick(requestURIStringForAutofill: messageString!)
		}
		func __shared_didPick(requestURIStringForAutofill requestURIString: String)
		{
			self.clearValidationMessage() // in case there was a parsing err etc displaying
			self._clearForm()
			//
			self.sendTo_inputView.cancelAny_oaResolverRequestMaker()
			//
			let (err_str, optl_requestPayload) = MyMoneroCoreUtils.New_ParsedRequest_FromURIString(requestURIString)
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
			let requestPayload = optl_requestPayload!
			if let amountString = requestPayload.amount, amountString != "" {
				self.amount_fieldset.inputField.text = amountString
			}
			do {
				let target_address = requestPayload.address
				assert(target_address != "") // b/c it should have been caught as a validation err on New_ParsedRequest_FromURIString
				let payment_id_orNil = requestPayload.paymentID
				var foundContact: Contact?
				do {
					let records = ContactsListController.shared.records
					for (_, record) in records.enumerated() {
						let contact = record as! Contact
						if contact.address == target_address || contact.cached_OAResolved_XMR_address == target_address {
							// so this request's address corresponds with this contact…
							// how does the payment id match up?
							/*
							* Commented until we figure out this payment ID situation.
							* The problem is that the person who uses this request to send
							* funds (i.e. the user here) may have the target of the request
							* in their Address Book (the req creator) but the request recipient
							* would have in their address book a /different/ payment_id for the target
							* than the payment_id in the contact used by the creator to generate
							* this request.
							
							* One proposed solution is to give contacts a "ReceiveFrom-With" and "SendTo-With"
							* payment_id. Then when a receiver loads a request (which would have a payment_id of
							* the creator's receiver contact's version of "ReceiveFrom-With"), we find the contact
							* (by address/cachedaddr) and if it doesn't yet have a "SendTo-With" payment_id,
							* we show it as 'detected', and set its value to that of ReceiveFrom-With from the request
							* if they hit send. This way users won't have to send each other their pids.
							
							* Currently, this is made to work below by not looking at the contact itself for payment
							* ID match, but just using the payment ID on the request itself, if any.
							
							if (payment_id_orNull) { // request has pid
							if (contact.payment_id && typeof contact.payment_id !== 'undefined') { // contact has pid
							if (contact.payment_id !== payment_id_orNull) {
							console.log("contact has same address as request but different payment id!")
							continue // TODO (?) keep this continue? or allow and somehow use the pid from the request?
							} else {
							// contact has same pid as request pid
							console.log("contact has same pid as request pid")
							}
							} else { // contact has no pid
							console.log("request pid exists but contact has no request pid")
							}
							} else { // request has no pid
							if (contact.payment_id && typeof contact.payment_id !== 'undefined') { // contact has pid
							console.log("contact has pid but request has no pid")
							} else { // contact has no pid
							console.log("neither request nor contact have pid")
							// this is fine - we can use this contact
							}
							}
							*/
							foundContact = contact
							break
						}
					}
					if foundContact != nil {
						self.sendTo_inputView.pick(
							contact: foundContact!,
							skipOAResolve: true, // special case
							useContactPaymentID: false // but we're not going to show the PID stored on the contact!
						)
					} else { // we have an addr but no contact
						if let _ = self.sendTo_inputView.selectedContact {
							self.sendTo_inputView.unpickSelectedContact_andRedisplayInputField(
								skipFocusingInputField: true // do NOT focus input
							)
						}
						self.sendTo_inputView.inputField.text = target_address
					}
				}
				// and no matter what, display payment id from request, if present
				self.hideAndClear_manualPaymentIDField()
				if payment_id_orNil != nil { // but display it as a 'detected' pid which we can pick up on submit
					self.set_addPaymentID_buttonView(isHidden: true) // hide
					self.sendTo_inputView._display(resolved_paymentID: payment_id_orNil!) // NOTE: kind of bad to use these private methods like this - TODO: establish a proper interface for doing this!
				} else {
					self.sendTo_inputView._hide_resolved_paymentID() // jic // NOTE: kind of bad to use these private methods like this - TODO: establish a proper interface for doing this!
					self.set_addPaymentID_buttonView(isHidden: false) // show
				}
			}
			self.set_isFormSubmittable_needsUpdate() // now that we've updated values
		}
		//
		// Protocol - DeleteEverythingRegistrant
		func passwordController_DeleteEverything() -> String?
		{
			DispatchQueue.main.async
			{ [unowned self] in
				self._clearForm()
				self._tearDownAnyImagePickerController(animated: false)
				//
				// should already have popped to root thanks to root tab bar vc
			}
			//
			return nil // no error
		}
		//
		// Delegation - Notifications
		@objc
		func PasswordController_willDeconstructBootedStateAndClearPassword()
		{
			self._clearForm()
			self._tearDownAnyImagePickerController(animated: false)
			//
			// should already have popped to root thanks to root tab bar vc
		}
		@objc
		func PasswordController_didDeconstructBootedStateAndClearPassword()
		{
		}
		func URLOpening_saysTimeToHandleReceivedMoneroURL(_ notification: Notification)
		{
			let userInfo = notification.userInfo!
			let url = userInfo[URLOpening.NotificationUserInfoKeys.url.key] as! URL
			assert(self.isFormEnabled)
			// obviously, we can only do the following if the user has already unlocked the apps
			do { // dismissing these b/c of checks in __shared_isAllowedToPerformDropOrURLOpeningOps
				self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // if any
				self.navigationController?.popToRootViewController(animated: false) // if any
			}
			self.__shared_didPick(requestURIStringForAutofill: url.absoluteString)
		}
		//
		func WalletAppContactActionsCoordinator_didTrigger_sendFundsToContact(_ notification: Notification)
		{
			self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // whether we should force-dismiss these (create new contact) is debatable…
			self.navigationController?.popToRootViewController(animated: false) // now pop pushed stack views - essential for the case they're viewing a transaction
			//
			if self.isFormEnabled == false {
				DDLog.Warn("SendFunds", "Triggered send funds from contact while submit btn disabled. Beep.")
				// TODO: create system service for playing beep, an electron (shell.beep) implementation, and call it to beep
				// TODO: mayyybe alert tx in progress
				return
			}
			self._clearForm() // figure that since this method is called when user is trying to initiate a new request we should clear the form
			let contact = notification.userInfo![WalletAppContactActionsCoordinator.NotificationUserInfoKeys.contact.key] as! Contact
			self.sendTo_inputView.pick(contact: contact) // simulate user picking the contact
		}
		func WalletAppWalletActionsCoordinator_didTrigger_sendFundsFromWallet(_ notification: Notification)
		{
			self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // whether we should force-dismiss these (create new contact) is debatable…
			self.navigationController?.popToRootViewController(animated: false) // now pop pushed stack views - essential for the case they're viewing a transaction
			//
			if self.isFormEnabled == false {
				DDLog.Warn("SendFunds", "Triggered send funds from wallet while submit btn disabled. Beep.")
				// TODO: create system service for playing beep, an electron (shell.beep) implementation, and call it to beep
				// TODO: mayyybe alert tx in progress
				return
			}
			self._clearForm() // figure that since this method is called when user is trying to initiate a new request we should clear the form
			let wallet = notification.userInfo![WalletAppWalletActionsCoordinator.NotificationUserInfoKeys.wallet.key] as! Wallet
			self.fromWallet_inputView.set(selectedWallet: wallet)
		}
	}
}
