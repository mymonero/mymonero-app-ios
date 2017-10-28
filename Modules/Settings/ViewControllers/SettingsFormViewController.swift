//
//  SettingsFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/3/17.
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
class SettingsFormViewController: UICommonComponents.FormViewController, SettingsAppTimeoutAfterSecondsSliderInteractionsDelegate
{
	//
	// Static - Shared
	static let shared = SettingsFormViewController()
	//
	// Properties - Views
	var changePasswordButton = UICommonComponents.PushButton(pushButtonType: .utility)
	//
	var appTimeoutAfterS_label: UICommonComponents.Form.FieldLabel!
	var appTimeoutAfterS_inputView: SettingsAppTimeoutAfterSecondsSliderInputView!
	var appTimeoutAfterS_fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel!
	//
	var displayCurrency_label: UICommonComponents.Form.FieldLabel!
	var displayCurrency_inputView: UICommonComponents.Form.StringPicker.PickerButtonView!
	//
//	var notifyMeWhen_label: UICommonComponents.Form.FieldLabel!
//	var fundsComeIn_inputView: UICommonComponents.Form.Switches.TitleAndControlField!
//	var whenOutgoingTransactionsConfirmed_inputView: UICommonComponents.Form.Switches.TitleAndControlField!
	//
	var address_label: UICommonComponents.Form.FieldLabel!
	var address_inputView: UICommonComponents.FormInputField!
	var resolving_activityIndicator: UICommonComponents.GraphicAndLabelActivityIndicatorView!
	//
	var deleteButton: UICommonComponents.LinkButtonView!
	//
	// Lifecycle - Init
	override init()
	{
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func startObserving()
	{
		super.startObserving()
	}
	override func setup_views()
	{
		super.setup_views()
		//
		do {
			let view = self.changePasswordButton
			view.addTarget(self, action: #selector(changePasswordButton_tapped), for: .touchUpInside)
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("APP TIMEOUT", comment: "")
			)
			self.appTimeoutAfterS_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = SettingsAppTimeoutAfterSecondsSliderInputView()
			view.slider.interactionsDelegate = self
			self.appTimeoutAfterS_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormFieldAccessoryMessageLabel(
				text: "" // this will be set on viewWillAppear
			)
			self.appTimeoutAfterS_fieldAccessoryMessageLabel = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("DISPLAY CURRENCY", comment: "")
			)
			self.displayCurrency_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.StringPicker.PickerButtonView(
				selectedValue: SettingsController.shared.displayCurrencySymbol,
				allValues: ExchangeRates.Currency.lazy_allCurrencySymbols
			)
			view.selectedValue_fn =
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				let final_value = thisSelf.displayCurrency_inputView.selectedValue!
				let err_str = SettingsController.shared.set(
					displayCurrencySymbol_nilForDefault: final_value
				)
				if err_str != nil {
					assert(false, "error while setting display currency")
				}
			}
			self.displayCurrency_inputView = view
			self.scrollView.addSubview(view)
		}
		//
//		do {
//			let view = UICommonComponents.Form.FieldLabel(
//				title: NSLocalizedString("NOTIFY ME WHEN", comment: "")
//			)
//			self.notifyMeWhen_label = view
//			self.scrollView.addSubview(view)
//		}
//		do {
//			let view = UICommonComponents.Form.Switches.TitleAndControlField(
//				frame: .zero,
//				title: NSLocalizedString("Funds arrive", comment: "")
//			)
//			self.fundsComeIn_inputView = view
//			self.scrollView.addSubview(view)
//		}
//		do {
//			let view = UICommonComponents.Form.Switches.TitleAndControlField(
//				frame: .zero,
//				title: NSLocalizedString("Outgoing transactions are confirmed", comment: "")
//			)
//			self.whenOutgoingTransactionsConfirmed_inputView = view
//			self.scrollView.addSubview(view)
//		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("SERVER ADDRESS", comment: "")
			)
			self.address_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("Leave blank to use mymonero.com", comment: "")
			)
			view.keyboardType = .URL
			view.autocorrectionType = .no
			view.autocapitalizationType = .none
			view.spellCheckingType = .no
			view.returnKeyType = .next
			view.delegate = self
			view.addTarget(self, action: #selector(address_inputView__editingChanged), for: .editingChanged)
			if let value = SettingsController.shared.specificAPIAddressURLAuthority {
				view.text = value
			}
			self.address_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.GraphicAndLabelActivityIndicatorView()
			view.set(labelText: NSLocalizedString("CONNECTING…", comment: ""))
			view.isHidden = true
			self.resolving_activityIndicator = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_destructive, title: "DELETE EVERYTHING")
			view.addTarget(self, action: #selector(deleteButton_tapped), for: .touchUpInside)
			self.deleteButton = view
			self.scrollView.addSubview(view)
		}
		//
		let (_, _) = self._updateValidationErrorForAddressInputView() // so we get validation error from persisted but incorrect value, if necessary for user feedback

	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Preferences", comment: "")
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .cancel,
			target: self,
			action: #selector(tapped_barButtonItem_about),
			title_orNilForDefault: NSLocalizedString("About", comment: "")
		)
		
	}
	//
	// Lifecycle - Teardown
	override func tearDown()
	{
		super.tearDown()
		self.tearDown_timerToSave_durationUpdated()
		self.tearDown_timerToSave_addressEditingChanged()
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		return true // this is actually for the interactivity of the 'About' button in this case
	}
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		if inputView == self.address_inputView {
			return nil
		}
		assert(false, "Unexpected")
		return nil
	}
	//
	// Accessors
	var sanitizedInputValue__address: String? {
		if self.address_inputView.text != nil {
			guard let raw_text = self.address_inputView.text else {
				return nil
			}
			let trimmed_text = raw_text.trimmingCharacters(in: .whitespacesAndNewlines)
			if trimmed_text == "" {
				return nil // still nil
			}
			return trimmed_text
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
	// Imperatives - Address validation error message
	func _updateValidationErrorForAddressInputView() -> (
		didError: Bool,
		savableValue: String?
	)
	{
		var value = self.sanitizedInputValue__address // use even nil b/c it means use mymonero.com api
		if value == "" {
			assert(false)
			value = nil
		}
		var preSubmission_validationError: String?
		do {
			if value != nil {
				if value!.contains(".") == false && value!.contains(":") == false && value!.contains("localhost") == false {
					preSubmission_validationError = String(
						format: NSLocalizedString("Please enter a valid URL authority, e.g. %@.", comment: ""),
						HostedMoneroAPIClient.mymonero_apiAddress_authority
					)
				}
			}
		}
		if preSubmission_validationError != nil { // exit
			self.address_inputView.setValidationError(preSubmission_validationError!)
			//
			self.set(resolvingIndicatorIsVisible: false) // hide
			self.view.setNeedsLayout() // for validation err
			// BUT we're also going to just save it so that the validation error here is displayed to the user.
			
			return (didError: true, savableValue: nil) // didError
		}
		//
		// TODO: verify that this is a legit server somehow here before writing value
		//
		return (didError: false, savableValue: value) // didError = false
	}
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		self.address_inputView.isEnabled = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.address_inputView.isEnabled = true
	}
	override func _tryToSubmitForm()
	{
		assert(false) // no such thing - the 'About' button target is overridden
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		//
		let spacingBetweenFieldsets: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView + 16
		//
		let label_x = self.new__label_x
		let input_x = self.new__input_x
//		let edgeFlushInput_x = input_x + UICommonComponents.FormInputCells.imagePadding_x // re-compensate to arrive at value that causes element to actually be visually aligned with inputs and design metrics
		let textField_w = self.new__textField_w // already has customInsets subtracted
//		let edgeFlushInput_w = textField_w - 2*UICommonComponents.FormInputCells.imagePadding_x // re-compensate to arrive at value that causes element to actually be visually aligned with inputs and design metrics
		let fullWidth_label_w = self.new__fieldLabel_w // already has customInsets subtracted
		//
		do {
			self.changePasswordButton.sizeToFit()
			self.changePasswordButton.frame = CGRect(
				x: input_x,
				y: top_yOffset,
				width: self.changePasswordButton.frame.size.width + 2*10 + 2*UICommonComponents.FormInputCells.imagePadding_x,
				height: 26 + 2*UICommonComponents.FormInputCells.imagePadding_y
			).integral
		}
		//
		do {
			self.appTimeoutAfterS_label!.frame = CGRect(
				x: label_x,
				y: self.changePasswordButton.frame.origin.y + self.changePasswordButton.frame.size.height + spacingBetweenFieldsets,
				width: fullWidth_label_w,
				height: self.appTimeoutAfterS_label!.frame.size.height
			).integral
			self.appTimeoutAfterS_inputView!.frame = CGRect(
				x: label_x, // not input_x
				y: self.appTimeoutAfterS_label!.frame.origin.y + self.appTimeoutAfterS_label!.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: fullWidth_label_w, // not input_x
				height: SettingsAppTimeoutAfterSecondsSliderInputView.h
			).integral
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.frame = CGRect(
				x: label_x,
				y: self.appTimeoutAfterS_inputView!.frame.origin.y + self.appTimeoutAfterS_inputView!.frame.size.height + UICommonComponents.FormFieldAccessoryMessageLabel.marginAboveLabelBelowTextInputView,
				width: fullWidth_label_w,
				height: 0
			)
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.sizeToFit()
		}
		do {
			let previousSectionBottomView: UIView = self.appTimeoutAfterS_fieldAccessoryMessageLabel!
			self.displayCurrency_label.frame = CGRect(
				x: label_x,
				y: previousSectionBottomView.frame.origin.y + previousSectionBottomView.frame.size.height + spacingBetweenFieldsets,
				width: fullWidth_label_w,
				height: self.displayCurrency_label.frame.size.height
			)
			let fixed_dropdownWidth: CGFloat = 8*16
			self.displayCurrency_inputView.frame = CGRect(
				x: input_x,
				y: self.displayCurrency_label.frame.origin.y + self.displayCurrency_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: min(textField_w, fixed_dropdownWidth), // obvs the latter
				height: self.displayCurrency_inputView.frame.size.height
			)
		}
		//
//		do {
//			let previousSectionBottomView: UIView = self.displayCurrency_inputView!
//			let marginUnderSwitchesFieldsetTitleAboveFirstField: CGFloat = 7
//			self.notifyMeWhen_label.frame = CGRect(
//				x: label_x,
//				y: previousSectionBottomView.frame.origin.y + previousSectionBottomView.frame.size.height + spacingBetweenFieldsets,
//				width: fullWidth_label_w,
//				height: self.notifyMeWhen_label.frame.size.height
//			)
//			let switchesToLayOut: [UICommonComponents.Form.Switches.TitleAndControlField] =
//			[
//				self.fundsComeIn_inputView,
//				self.whenOutgoingTransactionsConfirmed_inputView
//			]
//			for (idx, switchView) in switchesToLayOut.enumerated() {
//				let mostPreviousView = idx == 0 ? self.notifyMeWhen_label : switchesToLayOut[idx - 1]
//				switchView.frame = CGRect(
//					x: edgeFlushInput_x,
//					y: mostPreviousView.frame.origin.y + mostPreviousView.frame.size.height
//						+ (idx == 0 ? marginUnderSwitchesFieldsetTitleAboveFirstField : 0)
//					,
//					width: edgeFlushInput_w,
//					height: switchView.fixedHeight
//				)
//			}
//		}
		//
		// NOTE: IF YOU UNCOMMENT THE ABOVE, MAKE SURE TO UNCOMMENT/SWAP the 'previousSectionBottomView = self.whenOutgoingTransactionsConfirmed_inputView! just below'
		
		
		
		
		//
		do {
			let previousSectionBottomView: UIView = self.displayCurrency_inputView!
//			let previousSectionBottomView: UIView = self.whenOutgoingTransactionsConfirmed_inputView!
			self.address_label.frame = CGRect(
				x: label_x,
				y: previousSectionBottomView.frame.origin.y + previousSectionBottomView.frame.size.height + spacingBetweenFieldsets,
				width: fullWidth_label_w,
				height: self.address_label.frame.size.height
			)
			self.address_inputView.frame = CGRect(
				x: input_x,
				y: self.address_label.frame.origin.y + self.address_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.address_inputView.frame.size.height
			)
		}
		let address_inputView_bottomEdge = self.address_inputView.frame.origin.y + (
			self.address_inputView.validationErrorMessageLabel != nil // if so, do not add address_inputView height redundantly - it's encoded in validationErrorMessageLabel!.frame.origin.y
				? self.address_inputView.validationErrorMessageLabel!.frame.origin.y + self.address_inputView.validationErrorMessageLabel!.frame.size.height
				: self.address_inputView.frame.size.height // or else just use the address_inputView height
		)
		if self.resolving_activityIndicator.isHidden == false {
			self.resolving_activityIndicator.frame = CGRect(
				x: label_x,
				y: address_inputView_bottomEdge + UICommonComponents.GraphicAndLabelActivityIndicatorView.marginAboveActivityIndicatorBelowFormInput,
				width: fullWidth_label_w,
				height: self.resolving_activityIndicator.new_height
			)
		}
		let addressFieldset_bottomEdge = self.resolving_activityIndicator.isHidden ?
				address_inputView_bottomEdge // to get validation msg label layout support
			: self.resolving_activityIndicator.frame.origin.y + self.resolving_activityIndicator.frame.size.height
		//
		do {
			self.deleteButton!.frame = CGRect(
				x: label_x,
				y: addressFieldset_bottomEdge + spacingBetweenFieldsets,
				width: self.deleteButton!.frame.size.width,
				height: self.deleteButton!.frame.size.height
			)
		}
		//
		let bottomMostView = self.deleteButton
		let bottomPadding: CGFloat = 18
		self.scrollableContentSizeDidChange(
			withBottomView: bottomMostView!,
			bottomPadding: bottomPadding
		)
	}
	override func viewDidAppear(_ animated: Bool)
	{
//		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
	}
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		//
		// TODO: This configuration is not the optimal place to do this - change to upon a notification from PasswordController
		do { // config change pw btn text
			self.changePasswordButton.setTitle(
				NSLocalizedString("Change \(PasswordController.shared.passwordType.capitalized_humanReadableString)", comment: ""),
				for: .normal
			)
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.text = String(
				format: NSLocalizedString(
					"Amount of idle time before your %@ is required again",
					comment: ""
				),
				PasswordController.shared.passwordType.humanReadableString
			)
			self.view.setNeedsLayout()
		}
		do {
			self.appTimeoutAfterS_inputView.slider.setValueFromSettings()
		}
		do {
			if PasswordController.shared.hasUserSavedAPassword == false {
				self.changePasswordButton.isEnabled = false // can't change til entered
				// self.serverURLInputLayer.disabled = false // enable - user may want to change URL before they add their first wallet
				self.appTimeoutAfterS_inputView.set(isEnabled: false)
				self.deleteButton.isEnabled = false
			} else if PasswordController.shared.hasUserEnteredValidPasswordYet == false { // has data but not unlocked app - prevent tampering
				// however, user should never be able to see the settings view in this state
				self.changePasswordButton.isEnabled = false // not going to enable this b/c changing the pw before the app objects are in memory would mean they passwordController record would get out of step with the password used to save records to disk
				// self.serverURLInputLayer.disabled = true
				self.appTimeoutAfterS_inputView.set(isEnabled: false)
				self.deleteButton.isEnabled = false
			} else { // has entered PW - unlock
				self.changePasswordButton.isEnabled = true
				// self.serverURLInputLayer.disabled = false
				self.appTimeoutAfterS_inputView.set(isEnabled: true)
				self.deleteButton.isEnabled = true
			}
		}
	}
	//
	// Delegation - Interactions
	func tapped_rightBarButtonItem()
	{
		self.aFormSubmissionButtonWasPressed()
	}
	@objc func tapped_barButtonItem_about()
	{
		let viewController = AboutMyMoneroViewController()
		let navigationController = UINavigationController(rootViewController: viewController)
		navigationController.modalPresentationStyle = .formSheet
		self.navigationController!.present(navigationController, animated: true, completion: nil)
	} 
	//
	@objc func changePasswordButton_tapped()
	{
		PasswordController.shared.initiateChangePassword()
	}
	@objc func deleteButton_tapped()
	{
		let alertController = UIAlertController(
			title: NSLocalizedString("Delete everything?", comment: ""),
			message: NSLocalizedString(
				"Are you sure you want to delete all of your local data?\n\nAny wallets will remain permanently on the Monero blockchain but local data such as contacts will not be recoverable at present.",
				comment: ""
			),
			preferredStyle: .alert
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Delete Everything", comment: ""),
				style: .destructive
				)
			{ (result: UIAlertAction) -> Void in
				PasswordController.shared.initiateDeleteEverything()
			}
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Cancel", comment: ""),
				style: .default
				)
			{ (result: UIAlertAction) -> Void in
			}
		)
		self.navigationController!.present(alertController, animated: true, completion: nil)
	}
	//
	var _timerToSave_addressEditingChanged: Timer?
	@objc func address_inputView__editingChanged()
	{
		self.tearDown_timerToSave_addressEditingChanged()
		//
		self.address_inputView.clearValidationError()
		if self.address_inputView.text == nil || self.address_inputView.text == "" {
			self.set(resolvingIndicatorIsVisible: false) // no need to show 'connecting…'
		} else {
			self.set(resolvingIndicatorIsVisible: true) // show
		}
		self.view.setNeedsLayout() // for validation err
		func _exitAndUnlock(
			withValidationErr err_str: String?
		)
		{
			if err_str != nil {
				self.address_inputView.setValidationError(err_str!)
			}
			self.set(resolvingIndicatorIsVisible: false) // hide
			self.view.setNeedsLayout() // for validation err
		}
		func _havingUnlocked_revertValueToExistingSettingsValue()
		{
			self.address_inputView.text = SettingsController.shared.specificAPIAddressURLAuthority
			// we don't really want this to cause address_inputView__editingChanged() to be called, although it wouldn't be so bad
		}
		//
		self._timerToSave_addressEditingChanged = Timer.scheduledTimer(
			withTimeInterval: 0.6, // wait until they're really done typing (probably want to extend this to 1.75s or risk annoyed users if you add back the alert), b/c we'll cause their wallets to be cleared and logged into the new server if a change happened
			repeats: false,
			block:
			{ [unowned self] (timer) in
				self.tearDown_timerToSave_addressEditingChanged()
				//
				let (didError, savableValue) = self._updateValidationErrorForAddressInputView() // also called on init so we get validation error on load
				if didError {
					return // not proceeding to save
				}
				func _writeValue() -> String? // err_str
				{
					let err_str = SettingsController.shared.set(
						specificAPIAddressURLAuthority: savableValue
					)
					// but note! This does not handle reverting the value if failure occurs
					return err_str
				}
				if savableValue == SettingsController.shared.specificAPIAddressURLAuthority {
					_exitAndUnlock(withValidationErr: nil) // do not clear/re-log-in on wallets if we're, e.g., resetting the password programmatically after the user has canceled deleting all wallets
					return
				}
				let err_str = _writeValue() // this will notify any wallets that they must log out and log back in
				if err_str != nil { // write failed, so revert value
					_havingUnlocked_revertValueToExistingSettingsValue() // importantly, revert the input contents, b/c the write failed
					return
				}
				_exitAndUnlock(withValidationErr: err_str)
			}
		)
	}
	func tearDown_timerToSave_addressEditingChanged()
	{
		if self._timerToSave_addressEditingChanged != nil {
			self._timerToSave_addressEditingChanged!.invalidate()
			self._timerToSave_addressEditingChanged = nil
		}
	}
	//
	// Delegation - Protocols - SettingsAppTimeoutAfterSecondsSliderInteractionsDelegate
	var _timerToSave_durationUpdated: Timer?
	func tearDown_timerToSave_durationUpdated()
	{
		if self._timerToSave_durationUpdated != nil {
			self._timerToSave_durationUpdated!.invalidate()
			self._timerToSave_durationUpdated = nil
		}
	}
	func durationUpdated(_ durationInSeconds_orNeverValue: TimeInterval)
	{
		// debounce to prevent/optimize spam/unnecessary saves
		self.tearDown_timerToSave_durationUpdated()
		self._timerToSave_durationUpdated = Timer.scheduledTimer(
			withTimeInterval: 0.3,
			repeats: false,
			block:
			{ [unowned self] (timer) in
				self.tearDown_timerToSave_durationUpdated()
				let err_str = SettingsController.shared.set(
					appTimeoutAfterS_nilForDefault_orNeverValue: self.appTimeoutAfterS_inputView.slider.valueAsWholeNumberOfSeconds_orNeverValue
				)
				if err_str != nil {
					assert(false, "error while setting app timeout")
				}
			}
		)
	}
}
