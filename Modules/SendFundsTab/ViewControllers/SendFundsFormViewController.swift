//
//  SendFundsFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/21/17.
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
import ImageIO
//
struct SendFundsForm
{
	static let rateAPI_domain = "cryptocompare.com"
}
//
extension SendFundsForm
{
	enum UsageGateState_PlainStorage_Keys: String
	{ // IMPORTANT NOTE: Do not use this to store personally identifying information unless you do a security analysis…. Also note: these are (or probably ought to be) cleared on a DeleteEverything
		case hasAgreedToTermsOfCalculatedEffectiveMoneroAmount = "SendFundsForm.UsageGateState_PlainStorage_Keys.hasAgreedToTermsOfCalculatedEffectiveMoneroAmount"
		//
		var key: String { return self.rawValue }
	}
	//
	class ViewController: UICommonComponents.FormViewController, DeleteEverythingRegistrant
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
		var fromWallet_inputView: UICommonComponents.WalletPickerButtonFieldView!
		var fromWallet_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var amount_label: UICommonComponents.Form.FieldLabel!
		var amount_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		var amount_fieldset: UICommonComponents.Form.Amounts.InputFieldsetView!
		var networkFeeEstimate_label: UICommonComponents.FormFieldAccessoryMessageLabel!
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
		var priority_label: UICommonComponents.Form.FieldLabel!
		var priority_inputView: UICommonComponents.Form.StringPicker.PickerButtonFieldView!
		var priority_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var qrPicking_actionButtons: UICommonComponents.QRPickingActionButtons!
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
					title: NSLocalizedString("FROM", comment: ""),
					sizeToFit: true
				)
				self.fromWallet_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.WalletPickerButtonFieldView(selectedWallet: nil)
				view.selectionUpdated_fn =
				{ [unowned self] in
					self.configure_amountInputTextGivenMaxToggledState()
				}
				self.fromWallet_inputView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"Monero makes transactions\nwith your \"available outputs\",\nso part of your balance will\nbe briefly locked and then\nreturned as change.",
						comment: ""
					)
				)
				view.tooltipDirectionFromOrigin = .right // since it's at the top of the page (it tries to go up on its own)
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.fromWallet_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("AMOUNT", comment: ""),
					sizeToFit: true
				)
				self.amount_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: String(
						format: NSLocalizedString(
							"Ring size value set to\nMonero default of %d.",
							comment: ""
						),
						MyMoneroCore.fixedRingsize
					)
				)
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.amount_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.Amounts.InputFieldsetView(
					effectiveAmountLabelBehavior: .yieldingRawOrEffectiveMoneroOnlyAmount, // different from Funds Request form
					effectiveAmountTooltipText_orNil: String(
						format: NSLocalizedString(
							"Currency selector for\ndisplay purposes only.\nThe app will send %@.\n\nRate providers include\n%@.",
							comment:""
						),
						CcyConversionRates.Currency.XMR.symbol,
						SendFundsForm.rateAPI_domain // not .authority - don't need subdomain
					),
					wantsMAXbutton: true
				)
				let inputField = view.inputField
				inputField.delegate = self
				inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				inputField.returnKeyType = .next
				view.didUpdateValueAvailability_fn =
				{ [weak self] in
					// this will be called when the ccyConversion rate changes and when the selected currency changes
					guard let thisSelf = self else {
						return
					}
					thisSelf.set_isFormSubmittable_needsUpdate() // wait for ccyConversion rate to come in from what ever is supplying it
					// TODO: do we need to update anything else here?
				}
				view.didUpdateMAXButtonToggleState_fn =
				{ [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.configure_amountInputTextGivenMaxToggledState()
					thisSelf.set_isFormSubmittable_needsUpdate()
				}
				self.amount_fieldset = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormFieldAccessoryMessageLabel(
					text: nil,
					displayMode: .prominent // slightly brighter here per design; considered merging
				)
				self.networkFeeEstimate_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: String(
						format: NSLocalizedString(
							"Based on Monero network\nfee estimate (not final).\n\nMyMonero does not charge\na transfer service fee.",
							comment: ""
						)
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
					title: NSLocalizedString("TO", comment: ""),
					sizeToFit: true
				)
				self.sendTo_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: String(
						format: NSLocalizedString(
							"Please double-check\nyour recipient info as\nMonero transfers are\nnot yet reversible.",
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
				{ [unowned self] in
					self.view.setNeedsLayout() // to get following subviews' layouts to update
					//
					// scroll to field in case, e.g., results table updated
					DispatchQueue.main.asyncAfter(
						deadline: .now() + 0.1
					) { [unowned self] in
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
					if detectedEmbedded_paymentID != nil {
						self.set_addPaymentID_buttonView(isHidden: true) // i.e. integrated address supplying one - we show it as 'detected'
						self.hideAndClear_manualPaymentIDField()
					} else {
						if self.manualPaymentID_inputView.isHidden {
							self.set_addPaymentID_buttonView(isHidden: false) // ensure this gets reshown if the input changes from a valid integrated address to an invalid/partial addr or valid std xmr addr
						}
					}
				}
				view.finishedValidatingTextInput_foundInvalidMoneroAddress_fn =
				{ [unowned self] in
					if self.manualPaymentID_inputView.isHidden {
						self.set_addPaymentID_buttonView(isHidden: false) // ensure this gets reshown if the input changes from a valid integrated address to an invalid address
					}
				}
				view.willBeginResolvingPossibleOATextInput_fn =
				{ [unowned self] in
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
				let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("+ ADD PAYMENT ID", comment: ""))
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
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("TRANSFER", comment: ""),
					sizeToFit: true
				)
				self.priority_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"You can pay the Monero\nnetwork a higher fee to\nhave your transfers\nconfirmed faster.",
						comment: ""
					)
				)
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.priority_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.StringPicker.PickerButtonFieldView(
					title: NSLocalizedString("Priority", comment: ""),
					selectedValue: MoneroTransferSimplifiedPriority.defaultPriority.humanReadableCapitalizedString,
					allValues: MoneroTransferSimplifiedPriority.allValues_humanReadableCapitalizedStrings
				)
				view.picker_inputField_didBeginEditing =
				{ [weak self] (inputField) in
					DispatchQueue.main.asyncAfter( // slightly janky
						deadline: .now() + UICommonComponents.FormViewController.fieldScrollDuration + 0.1
					) { [weak self] in
						guard let thisSelf = self else {
							return
						}
						if inputField.isFirstResponder { // jic
							thisSelf.scrollInputViewToVisible(thisSelf.priority_inputView)
						}
					}
				}
				view.selectedValue_fn =
				{ [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.configure_networkFeeEstimate_label()
					thisSelf.configure_amountInputTextGivenMaxToggledState()
				}
				self.priority_inputView = view
				self.scrollView.addSubview(view)
			}
			do {
				let buttons = UICommonComponents.QRPickingActionButtons(
					containingViewController: self,
					attachingToView: self.view // not self.scrollView
				)
				buttons.havingPickedImage_shouldAllowPicking_fn =
				{ [weak self] in
					guard let thisSelf = self else {
						return false
					}
					if thisSelf.isFormEnabled == false {
						DDLog.Warn("SendFundsTab", "Disallowing QR code pick while form disabled")
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
					thisSelf._clearForm() // may as well
				}
				buttons.didPick_fn =
				{ [weak self] (uriString) in
					guard let thisSelf = self else {
						return
					}
					thisSelf.__shared_didPick(requestURIStringForAutofill: uriString)
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
			//
			// initial configuration; now that references to both the fee estimate layer and the priority select control have been assigned…
			self.configure_networkFeeEstimate_label()
			self.configure_amountInputTextGivenMaxToggledState()
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
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(CcyConversionRates_didUpdateAvailabilityOfRates),
				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(SettingsController__NotificationNames_Changed__displayCurrencySymbol),
				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
				object: nil
			)
		}
		//
		override func tearDown()
		{
			super.tearDown()
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
			//
			NotificationCenter.default.removeObserver(
				self,
				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
			NotificationCenter.default.removeObserver(
				self,
				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
				object: nil
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
			let submittableMoneroAmountDouble_orNil = self.amount_fieldset.inputField.submittableMoneroAmountDouble_orNil(
				selectedCurrency: self.amount_fieldset.currencyPickerButton.selectedCurrency
			)
			if submittableMoneroAmountDouble_orNil == nil {
				let isSweeping = self.amount_fieldset.maxButtonView!.isToggledOn
				if isSweeping == false { // amount is required unless sweeping
					return false
				}
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
		var selected_priority: MoneroTransferSimplifiedPriority {
			let selectedString = self.priority_inputView.selectedValue!
			let priority = MoneroTransferSimplifiedPriority.new_priority(fromHumanReadableString: selectedString)
			//
			return priority
		}
		var new_xmr_estFeeAmount: MoneroAmount {
			let feePerKB_Amount = MoneroAmount("187000000")! // constant for now pending polling fee_per_kb on account info
			let priority = self.selected_priority
			let estNetworkFee_moneroAmount: MoneroAmount = MoneroUtils.Fees.estimated_neededNetworkFee(MyMoneroCore.fixedMixin, feePerKB_Amount, priority)
			//
			return estNetworkFee_moneroAmount
		}
		var new_xmr_estMaxAmount: MoneroAmount? { // may return nil if a wallet isn't present yet
			guard let wallet = self.fromWallet_inputView.selectedWallet else {
				return nil // no wallet yet
			}
			let availableWalletBalance = wallet.balanceAmount - wallet.lockedBalanceAmount // TODO: is it correct to incorporate locked balance into this?
			let estNetworkFee_moneroAmount = self.new_xmr_estFeeAmount
			if availableWalletBalance > estNetworkFee_moneroAmount {
				return availableWalletBalance - estNetworkFee_moneroAmount
			}
			return MoneroAmount("0") // can't actually send any of the balance - or maybe there are some dusty outputs that will come up in the actual sweep?99
		}
		var new_displayCcyFormatted_estMaxAmountString: String? { // this is going to return nil if the rate is not ready for the selected display currency - user will probably just have to keep hitting 'max'
			guard let xmr_estMaxAmount = self.new_xmr_estMaxAmount else {
				return nil
			}
			let displayCurrency = self.amount_fieldset.currencyPickerButton.selectedCurrency
			if displayCurrency != .XMR {
				let converted_amountDouble = displayCurrency.displayUnitsRounded_amountInCurrency(
					fromMoneroAmount: xmr_estMaxAmount
				)
				if converted_amountDouble == nil {
					return nil // rate not ready yet
				}
				return displayCurrency.nonAtomicCurrency_localized_formattedString(
					final_amountDouble: converted_amountDouble!
				)
			}
			return xmr_estMaxAmount.localized_formattedString // then it's an xmr amount
		}
		var new_displayCcyFormatted_estMaxAmount_fullInputText: String {
			guard let string = self.new_displayCcyFormatted_estMaxAmountString else {
				return NSLocalizedString("MAX", comment: "") // such as while rate not available
			}
			return "~ " + string // TODO: is this localized enough - consider writing direction
			// ^ luckily we can do this for long numbers because the field will right truncate it and then left align the text
		}
		func new_displayCcyFormatted_estFeeFigures() -> (
			amount_formattedString: String,
			displayCurrency: CcyConversionRates.Currency
		) {
			let estNetworkFee_moneroAmount = self.new_xmr_estFeeAmount
			var mutable_displayCurrency = SettingsController.shared.displayCurrency
			var mutable_amount_formattedString: String!
			do {
				if mutable_displayCurrency != .XMR {
					let converted_amountDouble = mutable_displayCurrency.displayUnitsRounded_amountInCurrency(
						fromMoneroAmount: estNetworkFee_moneroAmount
					)
					if converted_amountDouble != nil {
						mutable_amount_formattedString = mutable_displayCurrency.nonAtomicCurrency_localized_formattedString(
							final_amountDouble: converted_amountDouble!
						)
					} else {
						assert(mutable_displayCurrency != .XMR)
						mutable_displayCurrency = .XMR // and - special case - revert currency to .xmr while waiting on ccyConversion rate
					}
				}
				if mutable_displayCurrency == .XMR { // still
					// then we still need to derive final_amount_formattedString
					mutable_amount_formattedString = estNetworkFee_moneroAmount.localized_formattedString
				}
			}
			return (mutable_amount_formattedString, mutable_displayCurrency)
		}
		//
		// Imperatives - Field visibility
		func set_manualPaymentIDField(isHidden: Bool)
		{
			var touched: Bool = false
			if self.manualPaymentID_label.isHidden != isHidden {
				touched = true
				self.manualPaymentID_label.isHidden = isHidden
			}
			if self.manualPaymentID_inputView.isHidden != isHidden {
				touched = true
				self.manualPaymentID_inputView.isHidden = isHidden
			}
			if touched {
				self.view.setNeedsLayout()
			}
		}
		func show_manualPaymentIDField(withValue paymentID: String?)
		{
			self.manualPaymentID_inputView.text = paymentID ?? "" // nil to empty field
			self.set_manualPaymentIDField(isHidden: false)
		}
		func hideAndClear_manualPaymentIDField()
		{
			self.set_manualPaymentIDField(isHidden: true)
			if self.manualPaymentID_inputView.text != "" {
				self.manualPaymentID_inputView.text = ""
			}
		}
		//
		func set_addPaymentID_buttonView(isHidden: Bool)
		{
			self.addPaymentID_buttonView.isHidden = isHidden
			self.view.setNeedsLayout()
		}
		//
		// Imperatives - Configuration - Fee estimate label, Max amount, ...
		func configure_networkFeeEstimate_label()
		{
			let (final_amount_formattedString, final_displayCurrency) = self.new_displayCcyFormatted_estFeeFigures()
			let text = String(
				format: NSLocalizedString("+ %@ %@ EST. NETWORK FEE", comment: ""),
				final_amount_formattedString,
				final_displayCurrency.symbol
			)
			self.networkFeeEstimate_label.text = text
			//
			self.view.setNeedsLayout() // we must reflow the tooltip's x
		}
		func configure_amountInputTextGivenMaxToggledState()
		{
			let isMaxToggledOn = self.amount_fieldset.maxButtonView!.isToggledOn
			let toToggledOnText: String? = isMaxToggledOn
				? self.new_displayCcyFormatted_estMaxAmount_fullInputText // if non xmr ccy but rate nil (amount nil), will display "MAX" til it's ready
				: nil
			self.amount_fieldset.inputField.configureWithMAXToggled(
				on: isMaxToggledOn,
				toToggledOnText: toToggledOnText
			)
		}
		//
		// Imperatives - Contact picker, contact picking
		func scrollToVisible_sendTo()
		{
			self.scrollInputViewToVisible(self.sendTo_inputView)
		}
		public func reconfigureFormAtRuntime_havingElsewhereSelected(sendToContact contact: Contact)
		{
			self.amount_fieldset.clear() // figure that since this method is called when user is trying to initiate a new request, we should clear the amount
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
			self.fromWallet_inputView.set(isEnabled: false)
			
			self.amount_fieldset.inputField.isEnabled = false
			self.amount_fieldset.currencyPickerButton.isEnabled = false
			
			self.priority_inputView.set(isEnabled: false)
			
			self.sendTo_inputView.inputField.isEnabled = false
			if let pillView = self.sendTo_inputView.selectedContactPillView {
				pillView.xButton.isEnabled = true
			}
			self.manualPaymentID_inputView.isEnabled = false
			self.addPaymentID_buttonView.isEnabled = false
			//
			self.qrPicking_actionButtons.set(isEnabled: false)
		}
		override func reEnableForm()
		{
			super.reEnableForm()
			//
			// allowing scroll so user can check while sending despite no cancel support existing yet
//			self.scrollView.isScrollEnabled = true
			//
			self.fromWallet_inputView.set(isEnabled: true)
			
			self.amount_fieldset.inputField.isEnabled = true
			self.amount_fieldset.currencyPickerButton.isEnabled = true
			
			self.priority_inputView.set(isEnabled: true)
			
			self.sendTo_inputView.inputField.isEnabled = true
			if let pillView = self.sendTo_inputView.selectedContactPillView {
				pillView.xButton.isEnabled = true
			}
			self.manualPaymentID_inputView.isEnabled = true
			self.addPaymentID_buttonView.isEnabled = true
			//
			self.qrPicking_actionButtons.set(isEnabled: true)
		}
		var formSubmissionController: SendFundsForm.SubmissionController?
		override func _tryToSubmitForm()
		{
			self.clearValidationMessage()
			//
			let fromWallet = self.fromWallet_inputView.selectedWallet!
			let isSweeping = self.amount_fieldset.maxButtonView!.isToggledOn
			let amountText = self.amount_fieldset.inputField.text // we're going to allow empty amounts
			let amount_submittableDouble = self.amount_fieldset.inputField.submittableMoneroAmountDouble_orNil(
				selectedCurrency: self.amount_fieldset.currencyPickerButton.selectedCurrency
			)
			if isSweeping == false {
				assert(amount_submittableDouble != nil && amountText != nil && amountText != "")
				if amount_submittableDouble == nil {
					self.setValidationMessage(NSLocalizedString("Please enter a valid amount of Monero.", comment: ""))
					return
				}
				if amount_submittableDouble! <= 0 {
					self.setValidationMessage(NSLocalizedString("The amount to send must be greater than zero.", comment: ""))
					return
				}
			}
			//
			let selectedCurrency = self.amount_fieldset.currencyPickerButton.selectedCurrency
			func __proceedTo_disableFormAndExecute()
			{
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
				let priority = self.selected_priority
				//
				assert(isSweeping || amount_submittableDouble != nil)
				let parameters = SendFundsForm.SubmissionController.Parameters(
					fromWallet: fromWallet,
					amount_submittableDouble: amount_submittableDouble,
					isSweeping: isSweeping,
					priority: priority,
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
					preSuccess_nonTerminal_validationMessageUpdate_fn:
					{ [unowned self] (localizedString) in
						self.set(
							validationMessage: localizedString,
							wantsXButton: false // false b/c it's nonTerminal
						)
					},
					preSuccess_terminal_validationMessage_fn:
					{ [unowned self] (localizedString) in
						self.set(
							validationMessage: localizedString,
							wantsXButton: true // true because it's terminal
						)
						self.formSubmissionController = nil // must free as this is a terminal callback
						self.set_isFormSubmittable_needsUpdate()
						self.reEnableForm() // b/c we disabled it
					},
					preSuccess_passedValidation_willBeginSending:
					{
					},
					canceled_fn:
					{ [weak self] in
						guard let thisSelf = self else {
							return
						}
						thisSelf.clearValidationMessage() // un-set "Sending... "
						//
						thisSelf.formSubmissionController = nil // must free as this is a terminal callback
						thisSelf.set_isFormSubmittable_needsUpdate()
						thisSelf.reEnableForm() // b/c we disabled it
					},
					success_fn:
					{ [unowned self] (
						mockedTransaction,
						sentTo_address,
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
											enteredAddressValue: enteredAddressValue!,
											integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil, // NOTE: this will be non-nil if a short pid is supplied with a standard address - rather than an integrated addr alone being used
											resolvedAddress: resolvedAddress_fieldIsVisible ? resolvedAddress : nil,
											sentWith_paymentID: mockedTransaction.paymentId // will not be nil for integrated enteredAddress 
										)
										let viewController = AddContactFromSendFundsTabFormViewController(
											parameters: parameters
										)
										let navigationController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
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
			// now if using alternate display currency, be sure to ask for terms agreement before doing send
			if isSweeping == false && selectedCurrency != .XMR {
				let hasAgreedToUsageGateTerms = UserDefaults.standard.bool(
					forKey: UsageGateState_PlainStorage_Keys.hasAgreedToTermsOfCalculatedEffectiveMoneroAmount.key
				)
				if hasAgreedToUsageGateTerms == false {
					// show alert… iff user agrees, write user has agreed to terms and proceed to branch, else bail
					let alertController = UIAlertController(
						title: NSLocalizedString("Important", comment: ""),
						message: String(
							format: NSLocalizedString(
								"Though %@ is selected, the app will send %@. (This is not an exchange.)\n\nRate providers include %@. Neither accuracy or favorability are guaranteed. Use at your own risk.",
								comment: ""
							),
							selectedCurrency.symbol,
							CcyConversionRates.Currency.XMR.symbol,
							SendFundsForm.rateAPI_domain // not .authority - don't need subdomain
						),
						preferredStyle: .alert
					)
					alertController.addAction(
						UIAlertAction(
							title: String(
								format: NSLocalizedString("Agree and Send %@ %@", comment: ""),
								MoneroAmount.shared_localized_doubleFormatter().string(for: amount_submittableDouble!)!,
								CcyConversionRates.Currency.XMR.symbol
							),
							style: .destructive // or is red negative b/c the action is also constructive? (use .default)
						) { (result: UIAlertAction) -> Void in
							// must be sure to save state so alert is now not required until a DeleteEverything
							UserDefaults.standard.set(
								true,
								forKey: UsageGateState_PlainStorage_Keys.hasAgreedToTermsOfCalculatedEffectiveMoneroAmount.key
							)
							// and of course proceed
							__proceedTo_disableFormAndExecute()
						}
					)
					alertController.addAction(
						UIAlertAction(
							title: NSLocalizedString("Cancel", comment: ""),
							style: .default
						) { (result: UIAlertAction) -> Void in
							// bail
							// shouldn't need to re-enable form b/c we did alert branch/check before disabling form
						}
					)
					self.navigationController!.present(alertController, animated: true, completion: nil)
					return // early return pending alert result
				} else {
					let alertController = UIAlertController(
						title: NSLocalizedString("Confirm Amount", comment: ""),
						message: String(
							format: NSLocalizedString(
								"Send %@ %@?",
								comment: ""
							),
							MoneroAmount.shared_localized_doubleFormatter().string(for: amount_submittableDouble!)!,
							CcyConversionRates.Currency.XMR.symbol
						),
						preferredStyle: .alert
					)
					alertController.addAction(
						UIAlertAction(
							title: NSLocalizedString("Cancel", comment: ""),
							style: .default
						) { (result: UIAlertAction) -> Void in
							// bail
							// shouldn't need to re-enable form b/c we did alert branch/check before disabling form
						}
					)
					alertController.addAction(
						UIAlertAction(
							title: NSLocalizedString("Send", comment: ""),
							style: .default
						) { (result: UIAlertAction) -> Void in
							__proceedTo_disableFormAndExecute()
						}
					)
					self.navigationController!.present(alertController, animated: true, completion: nil)
					return // early return pending alert result
				}
			}
			// fall through
			__proceedTo_disableFormAndExecute()
		}
		//
		// Impertives - Clearing form
		func _clearForm()
		{
			self.clearValidationMessage()
			self.amount_fieldset.clear()
			self.sendTo_inputView.clearAndReset()
			do {
				self.hideAndClear_manualPaymentIDField()
				self.set_addPaymentID_buttonView(isHidden: false)
			}
			self.priority_inputView.set( // reset to default .. this will cause configure_networkFeeEstimate_label and configure_amountInputTextGivenMaxToggledState to be called to reconfigure fee
				selectedValue: MoneroTransferSimplifiedPriority.defaultPriority.humanReadableCapitalizedString,
				skipSettingOnPickerView: false
			)
		}
		//
		// Delegation - Form submission success
		func _didSave(instance: FundsRequest)
		{
			let viewController = FundsRequestDetailsViewController(fundsRequest: instance)
			let rootViewController = WindowController.rootViewController!
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
			let label_x = self.new__label_x
			let input_x = self.new__input_x
			let textField_w = self.new__textField_w
			let fullWidth_label_w = self.new__fieldLabel_w
			//
			let interSectionSpacing = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView
			//
			do {
				self.fromWallet_label.frame = CGRect(
					x: label_x,
					y: top_yOffset,
					width: self.fromWallet_label.frame.size.width,
					height: self.fromWallet_label.frame.size.height
				).integral
				do {
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.fromWallet_tooltipSpawn_buttonView.frame = CGRect(
						x: self.fromWallet_label.frame.origin.x + self.fromWallet_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: self.fromWallet_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.fromWallet_label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.fromWallet_inputView.frame = CGRect(
					x: input_x,
					y: self.fromWallet_label.frame.origin.y + self.fromWallet_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
					width: textField_w,
					height: type(of: self.fromWallet_inputView).fixedHeight
				).integral
			}
			do {
				self.amount_label.frame = CGRect(
					x: label_x,
					y: self.fromWallet_inputView.frame.origin.y + self.fromWallet_inputView.frame.size.height + interSectionSpacing,
					width: self.amount_label.frame.size.width,
					height: self.amount_label.frame.size.height
				).integral
				do {
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.amount_tooltipSpawn_buttonView.frame = CGRect(
						x: self.amount_label.frame.origin.x + self.amount_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: self.amount_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.amount_label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.amount_fieldset.frame = CGRect(
					x: input_x,
					y: self.amount_label.frame.origin.y + self.amount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w, // full-size width
					height: UICommonComponents.Form.Amounts.InputFieldsetView.h
				).integral
				self.networkFeeEstimate_label.frame = CGRect(
					x: label_x,
					y: self.amount_fieldset.frame.origin.y + self.amount_fieldset.frame.size.height + UICommonComponents.FormFieldAccessoryMessageLabel.marginAboveLabelBelowTextInputView,
					width: fullWidth_label_w,
					height: 0
				).integral
				do {
					self.networkFeeEstimate_label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
					var final__networkFeeEstimate_label_frame = self.networkFeeEstimate_label.frame
					final__networkFeeEstimate_label_frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
					self.networkFeeEstimate_label.frame = final__networkFeeEstimate_label_frame // kinda sucks to set this three times in this method. any alternative?
					//
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.feeEstimate_tooltipSpawn_buttonView.frame = CGRect(
						x: self.networkFeeEstimate_label.frame.origin.x + self.networkFeeEstimate_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: self.networkFeeEstimate_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.networkFeeEstimate_label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
			}
			do {
				self.sendTo_label.frame = CGRect(
					x: label_x,
					y: self.networkFeeEstimate_label.frame.origin.y + self.networkFeeEstimate_label.frame.size.height + interSectionSpacing,
					width: 18,
					height: self.sendTo_label.frame.size.height
				).integral
				do {
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.sendTo_tooltipSpawn_buttonView.frame = CGRect(
						x: self.sendTo_label.frame.origin.x + self.sendTo_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: self.sendTo_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.sendTo_label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.sendTo_inputView.frame = CGRect(
					x: input_x,
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
					x: label_x,
					y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + UICommonComponents.LinkButtonView.visuallySqueezed_marginAboveLabelForUnderneathField_textInputView,
					width: self.addPaymentID_buttonView!.frame.size.width,
					height: self.addPaymentID_buttonView!.frame.size.height
				)
			}
			//
			if self.manualPaymentID_label.isHidden == false {
				assert(self.addPaymentID_buttonView.isHidden == true)
				let lastMostVisibleView = self.sendTo_inputView! // why is the ! necessary?
				self.manualPaymentID_label.frame = CGRect(
					x: label_x,
					y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + interSectionSpacing,
					width: fullWidth_label_w,
					height: self.manualPaymentID_label.frame.size.height
				).integral
				self.manualPaymentID_inputView.frame = CGRect(
					x: input_x,
					y: self.manualPaymentID_label.frame.origin.y + self.manualPaymentID_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.manualPaymentID_inputView.frame.size.height
				).integral
			}
			//
			do {
				let previousSectionBottomView: UIView
				do {
					if self.manualPaymentID_inputView.isHidden == false {
						previousSectionBottomView = self.manualPaymentID_inputView
					} else if self.addPaymentID_buttonView.isHidden == false {
						previousSectionBottomView = self.addPaymentID_buttonView
					} else {
						previousSectionBottomView = self.sendTo_inputView
					}
				}
				//
				self.priority_label.frame = CGRect(
					x: label_x,
					y: previousSectionBottomView.frame.origin.y + previousSectionBottomView.frame.size.height + interSectionSpacing,
					width: self.priority_label.frame.size.width,
					height: self.priority_label.frame.size.height
				).integral
				do {
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.priority_tooltipSpawn_buttonView.frame = CGRect(
						x: self.priority_label.frame.origin.x + self.priority_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: self.priority_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.priority_label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				//
				self.priority_inputView.frame = CGRect(
					x: input_x,
					y: self.priority_label.frame.origin.y + self.priority_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.priority_inputView.fixedHeight
				)
			}
			//
			let bottomMostView: UIView = self.priority_inputView
			let bottomPadding: CGFloat = 18
			self.scrollableContentSizeDidChange(
				withBottomView: bottomMostView,
				bottomPadding: bottomPadding
			)
			//
			// non-scrolling:
			let buttons_y = self.view.bounds.size.height - UICommonComponents.ActionButton.wholeButtonsContainerHeight_withoutTopMargin
			self.qrPicking_actionButtons.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
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
		// Delegation - Amounts.InputField UITextField shunt
		func textField(
			_ textField: UITextField,
			shouldChangeCharactersIn range: NSRange,
			replacementString string: String
		) -> Bool {
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
		@objc func tapped_rightBarButtonItem()
		{
			self.aFormSubmissionButtonWasPressed()
		}
		@objc func addPaymentID_tapped()
		{
			self.set_addPaymentID_buttonView(isHidden: true)
			self.set_manualPaymentIDField(isHidden: false)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
			{ [unowned self] in
				self.manualPaymentID_inputView.becomeFirstResponder()
			}
		}
		//
		// Delegation - URL picking (also used by QR picking)
		func __shared_didPick(requestURIStringForAutofill requestURIString: String)
		{
			self.clearValidationMessage() // in case there was a parsing err etc displaying
			self._clearForm()
			//
			self.sendTo_inputView.cancelAny_oaResolverRequestMaker()
			//
			let (err_str, optl_requestPayload) = MoneroUtils.URIs.Requests.new_parsedRequest(fromURIString: requestURIString)
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
			var currencyToSelect: CcyConversionRates.Currency = .XMR // the default; to be finalized as follows…
			if let amountCurrencySymbol = requestPayload.amountCurrency,
				amountCurrencySymbol != ""
			{
				let currency = CcyConversionRates.Currency(
					rawValue: amountCurrencySymbol
				)
				if currency == nil {
					self.set(
						validationMessage: NSLocalizedString(
							"Unrecognized currency on funds request",
							comment: ""
						),
						wantsXButton: true
					)
					return
				}
				currencyToSelect = currency!
			}
			self.amount_fieldset.currencyPickerButton.set( // set no matter what, jic different
				selectedCurrency: currencyToSelect,
				skipSettingOnPickerView: false
			)
			// as long as currency was valid…
			if let amountString = requestPayload.amount, amountString != "" {
				self.amount_fieldset.inputField.text = amountString
				self.amount_fieldset.configure_effectiveMoneroAmountLabel() // b/c we just manually changed the text - would be nice to have an abstraction to do all this :P
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
						self.sendTo_inputView.setInputField(text: target_address) // we must use this method instead of just going _inputView.inputField.text = ... b/c that would not alone send the event .editingChanged and would cause e.g. .hasValidTextInput_moneroAddress to be stale
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
				self.qrPicking_actionButtons.teardownAnyPickers()
				// TODO/NOTE: This actually may be much better implemented as a property on the Settings controller as in the JS app
				do { // special:
					UserDefaults.standard.removeObject(
						forKey: UsageGateState_PlainStorage_Keys.hasAgreedToTermsOfCalculatedEffectiveMoneroAmount.key
					)
				}
				//
				// should already have popped to root thanks to root tab bar vc
			}
			//
			return nil // no error
		}
		//
		// Delegation - Notifications
		@objc func PasswordController_willDeconstructBootedStateAndClearPassword()
		{
			self._clearForm()
			self.qrPicking_actionButtons.teardownAnyPickers()
			//
			// should already have popped to root thanks to root tab bar vc
		}
		@objc func PasswordController_didDeconstructBootedStateAndClearPassword()
		{
		}
		@objc func URLOpening_saysTimeToHandleReceivedMoneroURL(_ notification: Notification)
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
		@objc func WalletAppContactActionsCoordinator_didTrigger_sendFundsToContact(_ notification: Notification)
		{
			self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // whether we should force-dismiss these (create new contact) is debatable…
			self.navigationController?.popToRootViewController(animated: false) // now pop pushed stack views - essential for the case they're viewing a transaction
			//
			if self.isFormEnabled == false {
				DDLog.Warn("SendFunds", "Triggered send funds from contact while submit btn disabled. Beep.")
				// TODO: is a .failure haptic appropriate here?
				// TODO: mayyybe alert tx in progress
				return
			}
			self._clearForm() // figure that since this method is called when user is trying to initiate a new request we should clear the form
			let contact = notification.userInfo![WalletAppContactActionsCoordinator.NotificationUserInfoKeys.contact.key] as! Contact
			self.sendTo_inputView.pick(contact: contact) // simulate user picking the contact
		}
		@objc func WalletAppWalletActionsCoordinator_didTrigger_sendFundsFromWallet(_ notification: Notification)
		{
			self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // whether we should force-dismiss these (create new contact) is debatable…
			self.navigationController?.popToRootViewController(animated: false) // now pop pushed stack views - essential for the case they're viewing a transaction
			//
			if self.isFormEnabled == false {
				DDLog.Warn("SendFunds", "Triggered send funds from wallet while submit btn disabled. Beep.")
				// TODO: is a .failure haptic appropriate here?
				// TODO: mayyybe alert tx in progress
				return
			}
			self._clearForm() // figure that since this method is called when user is trying to initiate a new request we should clear the form
			let wallet = notification.userInfo![WalletAppWalletActionsCoordinator.NotificationUserInfoKeys.wallet.key] as! Wallet
			self.fromWallet_inputView.set(selectedWallet: wallet)
		}
		//
		@objc func CcyConversionRates_didUpdateAvailabilityOfRates()
		{
			self.configure_networkFeeEstimate_label() // the amount field takes care of observing this for itself but the estimate label doesn't…… could be factored……
			self.configure_amountInputTextGivenMaxToggledState() // if necessary
		}
		@objc func SettingsController__NotificationNames_Changed__displayCurrencySymbol()
		{
			self.configure_networkFeeEstimate_label()
			self.configure_amountInputTextGivenMaxToggledState()
		}
	}
}
