//
//  SettingsFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
		return false // doesn't exist
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
	
	func _updateValidationErrorForAddressInputView() -> ( // TODO: migrate this to be async?
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
		func newValidationMessage_invalidFormat() -> String {
			return String(
				format: NSLocalizedString("Please enter a valid URL authority, e.g. %@.", comment: ""),
				HostedMoneroAPIClient.mymonero_apiAddress_authority
			)
		}
		if value != nil {
			if value!.contains(".") == false {
				preSubmission_validationError = newValidationMessage_invalidFormat()
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
		assert(false) // no such thing
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
		let spacingBetweenFieldsets: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView + 16
		//
		let label_x = CGFloat.form_label_margin_x + formFieldsCustomInsets.left
		let input_x = CGFloat.form_input_margin_x + formFieldsCustomInsets.left
		let textField_w = self.new__textField_w // already has customInsets subtracted
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
		//
		do {
			self.address_label.frame = CGRect(
				x: label_x,
				y: self.appTimeoutAfterS_fieldAccessoryMessageLabel!.frame.origin.y + self.appTimeoutAfterS_fieldAccessoryMessageLabel!.frame.size.height + spacingBetweenFieldsets,
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
	func tapped_barButtonItem_about()
	{
		let viewController = AboutMyMoneroViewController()
		let navigationController = UINavigationController(rootViewController: viewController)
		navigationController.modalPresentationStyle = .formSheet
		self.navigationController!.present(navigationController, animated: true, completion: nil)
	}
	//
	func changePasswordButton_tapped()
	{
		PasswordController.shared.initiateChangePassword()
	}
	func deleteButton_tapped()
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
	func address_inputView__editingChanged()
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
		//
		self._timerToSave_addressEditingChanged = Timer.scheduledTimer(
			withTimeInterval: 0.5, // wait until they're really done typing
			repeats: false,
			block:
			{ [unowned self] (timer) in
				self.tearDown_timerToSave_addressEditingChanged()
				let (didError, savableValue) = self._updateValidationErrorForAddressInputView() // also called on init so we get validation error on load
				if didError {
					return // not proceeding to save
				}
				//
				let err_str = SettingsController.shared.set(
					specificAPIAddressURLAuthority: savableValue
				)
				if err_str != nil {
					self.address_inputView.setValidationError(err_str!)
				}
				self.set(resolvingIndicatorIsVisible: false) // hide
				self.view.setNeedsLayout() // for validation err

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
