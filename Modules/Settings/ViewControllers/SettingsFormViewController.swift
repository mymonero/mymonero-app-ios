//
//  SettingsFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class SettingsFormViewController: UICommonComponents.FormViewController
{
	//
	// Static - Shared
	static let shared = SettingsFormViewController()
	//
	// Properties - Views
	var changePasswordButton = UICommonComponents.PushButton(pushButtonType: .utility)
	//
	var address_label: UICommonComponents.Form.FieldLabel!
	var address_inputView: UICommonComponents.FormInputField!
	var resolving_activityIndicator: UICommonComponents.ResolvingActivityIndicatorView!
	//
	var appTimeoutAfterS_label: UICommonComponents.Form.FieldLabel!
	var appTimeoutAfterS_inputView: UICommonComponents.FormTextViewContainerView! // TODO
	var appTimeoutAfterS_fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel!
	//
	var deleteButton_separatorView: UICommonComponents.Details.FieldSeparatorView!
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
			self.view.addSubview(view)
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
			let view = UICommonComponents.FormTextViewContainerView(
				placeholder: "TODO"
			)
			self.appTimeoutAfterS_inputView = view
			
			let initialValue = SettingsController.shared.appTimeoutAfterS_nilForDefault_orNeverValue ?? SettingsController.shared.default_appTimeoutAfterS
			view.textView.text = "\(initialValue)"
			
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
			let view = UICommonComponents.Details.FieldSeparatorView(mode: .contentBackgroundAccent)
			self.deleteButton_separatorView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_destructive, title: "DELETE EVERYTHING")
			view.addTarget(self, action: #selector(deleteButton_tapped), for: .touchUpInside)
			self.deleteButton = view
			self.scrollView.addSubview(view)
		}
		//
//		do {
//			let view = UICommonComponents.Form.FieldLabel(
//				title: NSLocalizedString("CUSTOM API ADDRESS", comment: "")
//			)
//			self.address_label = view
//			self.scrollView.addSubview(view)
//		}
//		do {
//			let view = UICommonComponents.FormInputField(
//				placeholder: String(
//					format: NSLocalizedString(
//						"e.g. %@",
//						comment: ""
//					),
//					"\(HostedMoneroAPIClient.apiAddress_scheme)://\(HostedMoneroAPIClient.shared.mymonero_apiAddress_authority)"
//				)
//			)
//			view.autocorrectionType = .no
//			view.autocapitalizationType = .none
//			view.spellCheckingType = .no
//			view.returnKeyType = .next
//			view.delegate = self
//			if let value = SettingsController.shared.specificAPIAddressURLAuthority {
//				view.text = value
//			}
//			self.address_inputView = view
//			self.scrollView.addSubview(view)
//		}
//		do {
//			let view = UICommonComponents.ResolvingActivityIndicatorView()
//			view.isHidden = true
//			self.resolving_activityIndicator = view
//			self.scrollView.addSubview(view)
//		}
//		self.scrollView.borderSubviews()
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
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		if self.formSubmissionController != nil {
			return false
		}
		return true
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
	var sanitizedInputValue__address: String {
		return (self.address_inputView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
	var formSubmissionController: ContactFormSubmissionController?
	override func _tryToSubmitForm()
	{
		assert(self.sanitizedInputValue__address != "")
//		let parameters = SettingsFormSubmissionController.Parameters(
//			address: self.sanitizedInputValue__address,
//			//
//			preInputValidation_terminal_validationMessage_fn:
//			{ [unowned self] (localizedString) in
//				self.setValidationMessage(localizedString)
//				self.formSubmissionController = nil // must free as this is a terminal callback
//				self.set_isFormSubmittable_needsUpdate()
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
//				self.set_isFormSubmittable_needsUpdate()
//				self.reEnableForm() // b/c we disabled it
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
//				self.set_isFormSubmittable_needsUpdate()
//				self.reEnableForm() // b/c we disabled it
//				self._didSave(instance: contactInstance)
//			}
//		)
//		let controller = SettingsFormSubmissionController(parameters: parameters)
//		self.formSubmissionController = controller
//		do {
//			self.set_isFormSubmittable_needsUpdate() // update submittability only after setting formSubmissionController
//		}
//		controller.handle()
	}
	//
	// Delegation - Form submission success
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
		do {
			self.changePasswordButton.sizeToFit()
			self.changePasswordButton.frame = CGRect(
				x: input_x,
				y: top_yOffset,
				width: self.changePasswordButton.frame.size.width + 2*10 + 2*UICommonComponents.FormInputCells.imagePadding_x,
				height: 26 + 2*UICommonComponents.FormInputCells.imagePadding_y
			).integral
		}
//		do {
//			self.address_label.frame = CGRect(
//				x: label_x,
//				y: top_yOffset,
//				width: fullWidth_label_w,
//				height: self.address_label.frame.size.height
//				).integral
//			self.address_inputView.frame = CGRect(
//				x: input_x,
//				y: self.address_label.frame.origin.y + self.address_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
//				width: textField_w,
//				height: self.address_inputView.frame.size.height
//				).integral
//		}
//		if self.resolving_activityIndicator.isHidden == false {
//			self.resolving_activityIndicator.frame = CGRect(
//				x: label_x,
//				y: self.address_inputView.frame.origin.y + self.address_inputView.frame.size.height + UICommonComponents.GraphicAndLabelActivityIndicatorView.marginAboveActivityIndicatorBelowFormInput,
//				width: fullWidth_label_w,
//				height: self.resolving_activityIndicator.new_height
//				).integral
//		}
		let addressFieldset_bottomEdge = self.changePasswordButton.frame.origin.y + self.changePasswordButton.frame.size.height // <- TEMPORARY
		// self.resolving_activityIndicator.isHidden ?
		// self.address_inputView.frame.origin.y + self.address_inputView.frame.size.height
		//  : self.resolving_activityIndicator.frame.origin.y + self.resolving_activityIndicator.frame.size.height
		
		self.appTimeoutAfterS_label!.frame = CGRect(
			x: label_x,
			y: addressFieldset_bottomEdge + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView + 16,
			width: fullWidth_label_w,
			height: self.appTimeoutAfterS_label!.frame.size.height
			).integral
		self.appTimeoutAfterS_inputView!.frame = CGRect(
			x: input_x,
			y: self.appTimeoutAfterS_label!.frame.origin.y + self.appTimeoutAfterS_label!.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
			width: textField_w,
			height: self.appTimeoutAfterS_inputView!.frame.size.height
		).integral
		if self.appTimeoutAfterS_fieldAccessoryMessageLabel != nil {
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.frame = CGRect(
				x: label_x,
				y: self.appTimeoutAfterS_inputView!.frame.origin.y + self.appTimeoutAfterS_inputView!.frame.size.height + UICommonComponents.FormFieldAccessoryMessageLabel.marginAboveLabelBelowTextInputView,
				width: fullWidth_label_w,
				height: 0
			).integral
			self.appTimeoutAfterS_fieldAccessoryMessageLabel!.sizeToFit()
		}
		do {
			assert(self.appTimeoutAfterS_fieldAccessoryMessageLabel != nil)
			let justPreviousView = self.appTimeoutAfterS_fieldAccessoryMessageLabel!
			self.deleteButton_separatorView!.frame = CGRect(
				x: input_x,
				y: justPreviousView.frame.origin.y + justPreviousView.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
				width: self.scrollView.frame.size.width - 2 * CGFloat.form_input_margin_x,
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
					"Amount of time before your %@ is required again",
					comment: ""
				),
				PasswordController.shared.passwordType.humanReadableString
			)
			self.view.setNeedsLayout()
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
}
