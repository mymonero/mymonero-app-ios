//
//  UseExisting_MetaInfo_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
import PKHUD

class UseExisting_MetaInfo_ViewController: AddWalletWizardScreen_MetaInfo_BaseViewController
{
	//
	// Types/Constants
	enum LoginWith_Mode
	{
		case mnemonicSeed
		case addrAndPrivKeys
		//
		var titleForModeToggleButtonInModeSelf: String
		{
			switch self {
				case .mnemonicSeed:
					return NSLocalizedString("Address and Private Keys", comment: "")
				case .addrAndPrivKeys:
					return NSLocalizedString("Secret Mnemonic", comment: "")
			}
		}
		var otherMode: LoginWith_Mode
		{
			switch self {
				case .mnemonicSeed:
					return .addrAndPrivKeys
				case .addrAndPrivKeys:
					return .mnemonicSeed
			}
		}
	}
	//
	// Properties - Model/state
	var loginWith_mode: LoginWith_Mode = .mnemonicSeed // initial state
	// Properties - Subviews
	var walletMnemonic_label: UICommonComponents.Form.FieldLabel!
	var walletMnemonic_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
	var walletMnemonic_inputView: UICommonComponents.FormTextViewContainerView!
	//
	var addr_label: UICommonComponents.Form.FieldLabel!
	var addr_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
	var addr_inputView: UICommonComponents.FormTextViewContainerView!
	var viewKey_label: UICommonComponents.Form.FieldLabel!
	var viewKey_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
	var viewKey_inputView: UICommonComponents.FormTextViewContainerView!
	var spendKey_label: UICommonComponents.Form.FieldLabel!
	var spendKey_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
	var spendKey_inputView: UICommonComponents.FormTextViewContainerView!
	//
	var orUse_label: UICommonComponents.FormFieldAccessoryMessageLabel!
	var orUse_button: UICommonComponents.LinkButtonView!
	//
	// Lifecycle - Init
	override func setup()
	{
		super.setup()
		self.configureWith_loginWithMode() // b/c this touches the nav bar btn items
	}
	override func setup_views()
	{
		super.setup_views()
		//
		do { // .mnemonicSeed
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("SECRET MNEMONIC", comment: ""),
					sizeToFit: true
				)
				self.walletMnemonic_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"This secret mnemonic is never sent to the MyMonero server.",
						comment: ""
					)
				)
				view.tooltipDirectionFromOrigin = .down // .right would be nice but there's not enough room
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.walletMnemonic_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: NSLocalizedString("From your existing wallet", comment: "")
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
				view.textView.delegate = self
				self.walletMnemonic_inputView = view
				self.scrollView.addSubview(view)
			}
		}
		do { // .addrAndPrivKeys
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("ADDRESS", comment: ""),
					sizeToFit: true
				)
				self.addr_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"Your wallet's public address",
						comment: ""
					)
				)
				view.tooltipDirectionFromOrigin = .right
				view.willPresentTipView_fn =
					{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.addr_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: nil
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
				view.textView.delegate = self
				self.addr_inputView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("VIEW KEY", comment: ""),
					sizeToFit: true
				)
				self.viewKey_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"This private view key and the wallet address are the only things sent to the MyMonero server.",
						comment: ""
					)
				)
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.viewKey_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: nil
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
				view.textView.delegate = self
				self.viewKey_inputView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("SPEND KEY", comment: ""),
					sizeToFit: true
				)
				self.spendKey_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"This private spend key is never sent to the MyMonero server.",
						comment: ""
					)
				)
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.spendKey_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormTextViewContainerView(
					placeholder: nil
				)
				view.textView.autocorrectionType = .no
				view.textView.autocapitalizationType = .none
				view.textView.spellCheckingType = .no
				view.textView.returnKeyType = .next
				view.textView.delegate = self
				self.spendKey_inputView = view
				self.scrollView.addSubview(view)
			}
		}
		do {
			let view = UICommonComponents.FormFieldAccessoryMessageLabel(
				text: NSLocalizedString("Or, use ", comment: "")
			)
			self.orUse_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: "") // title will be set in configureWith_loginWithMode()
			view.addTarget(self, action: #selector(orUse_button_tapped), for: .touchUpInside)
			self.orUse_button = view
			self.scrollView.addSubview(view)
		}
		//
//		self.scrollView.borderSubviews()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Log Into Your Wallet", comment: "")
		if self.wizardController.current_wizardTaskMode == .firstTime_useExisting { // only if it is, add cancel btn
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				target: self,
				action: #selector(tapped_barButtonItem_cancel)
			)
		} else { // we'll get a back button from super per overridable_wantsBackButton
		}
	}
	override var overridable_wantsBackButton: Bool {
		return self.wizardController.current_wizardTaskMode != .firstTime_useExisting
	}
	//
	// Accessors - Lookups/derived - Input values
	var mnemonic: String? {
		return self.walletMnemonic_inputView.textView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	var addr: String? {
		return self.addr_inputView.textView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	var viewKey: String? {
		return self.viewKey_inputView.textView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	var spendKey: String? {
		return self.spendKey_inputView.textView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		switch self.loginWith_mode {
			case .mnemonicSeed:
				if inputView == self.walletMnemonic_inputView.textView {
					return self.walletLabel_inputView
				}
				assert(false, "Unexpected")
				break
			case .addrAndPrivKeys:
				if inputView == self.addr_inputView.textView {
					return self.viewKey_inputView.textView
				}
				if inputView == self.viewKey_inputView.textView {
					return self.spendKey_inputView.textView
				}
				if inputView == self.spendKey_inputView.textView {
					return self.walletLabel_inputView
				}
				assert(false, "Unexpected")
				break
			// TODO: consider looping back to origin and keeping return key type of wallet label as .next until form is ready to submit (might be a neat usability thing)
		}
		assert(false, "Unexpected")
		return nil
	}
	override func new_isFormSubmittable() -> Bool
	{
		if self.isSubmitting == true {
			return false
		}
		guard let walletLabel = self.walletLabel, walletLabel != "" else {
			return false
		}
		switch self.loginWith_mode {
			case .mnemonicSeed:
				guard let mnemonic = self.mnemonic, mnemonic != "" else {
					return false
				}
				break
			case .addrAndPrivKeys:
				guard let addr = self.addr, addr != "" else {
					return false
				}
				guard let viewKey = self.viewKey, viewKey != "" else {
					return false
				}
				guard let spendKey = self.spendKey, spendKey != "" else {
					return false
				}
				break
		}
		return true
	}
	//
	// Imperatives
	func toggle_loginWithMode()
	{
		self.clearValidationMessage() // just in case
		//
		self.loginWith_mode = self.loginWith_mode.otherMode // toggle
		self.configureWith_loginWithMode()
		// ^- will trigger scroll to newly focused field
	}
	func configureWith_loginWithMode()
	{
		self.orUse_button.setTitleText(to: self.loginWith_mode.titleForModeToggleButtonInModeSelf)
		//
		switch self.loginWith_mode {
			case .mnemonicSeed:
				self.walletMnemonic_label.isHidden = false
				self.walletMnemonic_tooltipSpawn_buttonView.isHidden = false
				self.walletMnemonic_inputView.textView.text = ""
				self.walletMnemonic_inputView.isHidden = false
				//
				self.addr_label.isHidden = true
				self.addr_tooltipSpawn_buttonView.isHidden = true
				self.addr_inputView.isHidden = true
				self.viewKey_label.isHidden = true
				self.viewKey_tooltipSpawn_buttonView.isHidden = true
				self.viewKey_inputView.isHidden = true
				self.spendKey_label.isHidden = true
				self.spendKey_tooltipSpawn_buttonView.isHidden = true
				self.spendKey_inputView.isHidden = true
				//
				if self.hasAppearedBefore == true { // we don't want to do this before having appeared b/c frame will be false when we try to scroll to the input view on focus
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) // after delay to give things a chance to lay out (for auto scroll calc) and for visual effect
					{ [unowned self] in
						self.walletMnemonic_inputView.textView.becomeFirstResponder()
					}
				}
				break
			case .addrAndPrivKeys:
				self.walletMnemonic_label.isHidden = true
				self.walletMnemonic_tooltipSpawn_buttonView.isHidden = true
				self.walletMnemonic_inputView.isHidden = true
				//
				self.addr_inputView.textView.text = ""
				self.addr_label.isHidden = false
				self.addr_tooltipSpawn_buttonView.isHidden = false
				self.addr_inputView.isHidden = false
				self.addr_inputView.setNeedsDisplay() // necessary so view calls draw(rect:) with correct frame
				self.viewKey_inputView.textView.text = ""
				self.viewKey_label.isHidden = false
				self.viewKey_tooltipSpawn_buttonView.isHidden = false
				self.viewKey_inputView.isHidden = false
				self.viewKey_inputView.setNeedsDisplay() // necessary so view calls draw(rect:) with correct frame
				self.spendKey_inputView.textView.text = ""
				self.spendKey_label.isHidden = false
				self.spendKey_tooltipSpawn_buttonView.isHidden = false
				self.spendKey_inputView.isHidden = false
				self.spendKey_inputView.setNeedsDisplay() // necessary so view calls draw(rect:) with correct frame
				//
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) // after delay to give things a chance to lay out (for auto scroll calc) and for visual effect
				{ [unowned self] in
					self.addr_inputView.textView.becomeFirstResponder()
				}
				break
		}
		do {
			self.set_isFormSubmittable_needsUpdate()
			self.view.setNeedsLayout() // important; to lay out again
		}
	}
	//
	// Delegation - Interactions
	func tapped_barButtonItem_cancel()
	{
		self.wizardController._fromScreen_userPickedCancel()
	}
	@objc func orUse_button_tapped()
	{
		self.toggle_loginWithMode()
	}
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		self.orUse_button.isEnabled = false
		self.walletColorPicker_inputView.set(isEnabled: false)
		self.walletLabel_inputView.isEnabled = false
		self.walletMnemonic_inputView.set(isEnabled: false)
		self.addr_inputView.set(isEnabled: false)
		self.viewKey_inputView.set(isEnabled: false)
		self.spendKey_inputView.set(isEnabled: false)
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.orUse_button.isEnabled = true
		self.walletColorPicker_inputView.set(isEnabled: true)
		self.walletLabel_inputView.isEnabled = true
		self.walletMnemonic_inputView.set(isEnabled: true)
		self.addr_inputView.set(isEnabled: true)
		self.viewKey_inputView.set(isEnabled: true)
		self.spendKey_inputView.set(isEnabled: true)
	}
	var isSubmitting = false
	override func _tryToSubmitForm()
	{
		if self.isSubmitting == true {
			return
		}
		do {
			UserIdle.shared.temporarilyDisable_userIdle()
			ScreenSleep.temporarilyDisable_screenSleep()
			self.set(isFormSubmitting: true) // will update 'Next' btn
			self.disableForm()
			self.clearValidationMessage()
			HUD.show(
				.label(
					NSLocalizedString("Loading…", comment: "")
				),
				onView: self.navigationController!.view/*or self.view*/
			)
			self.navigationItem.leftBarButtonItem!.isEnabled = false
		}
		func ____reEnable_userIdleAndScreenSleepFromSubmissionDisable()
		{ // factored because we would like to call this on successful submission too!
			UserIdle.shared.reEnable_userIdle()
			ScreenSleep.reEnable_screenSleep()
		}
		func ___reEnableFormFromSubmissionDisable()
		{
			____reEnable_userIdleAndScreenSleepFromSubmissionDisable()
			//
			self.navigationItem.leftBarButtonItem!.isEnabled = true
			HUD.hide(animated: true)
			self.set(isFormSubmitting: false) // will update 'Next' btn
			self.reEnableForm()
		}
		func __trampolineFor_failedWithErrStr(_ err_str: String)
		{
			self.scrollView.setContentOffset(.zero, animated: true) // because we want to show the validation err msg
			self.setValidationMessage(err_str)
			___reEnableFormFromSubmissionDisable()
		}
		func __trampolineFor_didAddWallet()
		{
			____reEnable_userIdleAndScreenSleepFromSubmissionDisable() // we must call this manually as we are not re-enabling the form (or it will break user idle!!)
			self.wizardController.proceedToNextStep() // will dismiss
		}
		//
		let walletLabel = self.walletLabel!
		let color = self.walletColorPicker_inputView.currentlySelected_color
		switch self.loginWith_mode
		{
			case .mnemonicSeed:
				let mnemonic = self.mnemonic!
				WalletsListController.shared.OnceBooted_ObtainPW_AddExtantWalletWith_MnemonicString(
					walletLabel: walletLabel,
					swatchColor: color!,
					mnemonicString: mnemonic,
					{ (err_str, walletInstance, wasWalletAlreadyInserted) in
						if err_str != nil {
							__trampolineFor_failedWithErrStr(err_str!)
							return
						}
						if wasWalletAlreadyInserted == true {
							__trampolineFor_failedWithErrStr("That wallet has already been added.")
							return // consider a 'fail'
						}
						// success
						__trampolineFor_didAddWallet()
					},
					userCanceledPasswordEntry_fn:
					{
						___reEnableFormFromSubmissionDisable()
					}
				)
				break
			case .addrAndPrivKeys:
				let addr = self.addr!
				let viewKey = self.viewKey! as MoneroKey
				let spendKey = self.spendKey! as MoneroKey
				let privateKeys = MoneroKeyDuo(view: viewKey, spend: spendKey)
			
				WalletsListController.shared.OnceBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys(
					walletLabel: walletLabel,
					swatchColor: color!,
					address: addr,
					privateKeys: privateKeys,
					{ (err_str, walletInstance, wasWalletAlreadyInserted) in
						if err_str != nil {
							__trampolineFor_failedWithErrStr(err_str!)
							return
						}
						if wasWalletAlreadyInserted == true {
							__trampolineFor_failedWithErrStr("That wallet has already been added.")
							return // consider a 'fail'
						}
						// success
						__trampolineFor_didAddWallet()
					},
					userCanceledPasswordEntry_fn:
					{
						___reEnableFormFromSubmissionDisable()
					}
				)
				break
		}
	}
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{ // this could only get popped from when it's not the first in the nav stack, i.e. not adding first wallet,
		// so we'll need to get back into .pickCreateOrUseExisting
		self.wizardController.patchToDifferentWizardTaskMode_withoutPushingScreen( // to maintain the correct state
			patchTo_wizardTaskMode: .pickCreateOrUseExisting,
			atIndex: 0 // back to 0 from 1
		)
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		let textField_w = self.new__textField_w
		//
		var viewAbove_orUse_label: UIView!
		switch self.loginWith_mode {
			case .mnemonicSeed:
				viewAbove_orUse_label = self.walletMnemonic_inputView
				//
				self.walletMnemonic_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: top_yOffset,
					width: textField_w,
					height: self.walletMnemonic_label.frame.size.height
				).integral
				do {
					let label = self.walletMnemonic_label!
					label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
					var final__label_frame = label.frame
					final__label_frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
					label.frame = final__label_frame // kinda sucks to set this three times in this method. any alternative?
					//
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.walletMnemonic_tooltipSpawn_buttonView.frame = CGRect(
						x: final__label_frame.origin.x + final__label_frame.size.width - 4,
						y: final__label_frame.origin.y - (tooltipSpawn_buttonView_h - final__label_frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.walletMnemonic_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.walletMnemonic_label.frame.origin.y + self.walletMnemonic_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.walletMnemonic_inputView.frame.size.height
				).integral
				break
			case .addrAndPrivKeys:
				viewAbove_orUse_label = self.spendKey_inputView
				//
				self.addr_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: top_yOffset,
					width: textField_w,
					height: self.addr_label.frame.size.height
				).integral
				do {
					let label = self.addr_label!
					label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
					var final__label_frame = label.frame
					final__label_frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
					label.frame = final__label_frame // kinda sucks to set this three times in this method. any alternative?
					//
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.addr_tooltipSpawn_buttonView.frame = CGRect(
						x: final__label_frame.origin.x + final__label_frame.size.width - 4,
						y: final__label_frame.origin.y - (tooltipSpawn_buttonView_h - final__label_frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.addr_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.addr_label.frame.origin.y + self.addr_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.addr_inputView.frame.size.height
				).integral
				//
				self.viewKey_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.addr_inputView.frame.origin.y + self.addr_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
					width: textField_w,
					height: self.viewKey_label.frame.size.height
				).integral
				do {
					let label = self.viewKey_label!
					label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
					var final__label_frame = label.frame
					final__label_frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
					label.frame = final__label_frame // kinda sucks to set this three times in this method. any alternative?
					//
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.viewKey_tooltipSpawn_buttonView.frame = CGRect(
						x: final__label_frame.origin.x + final__label_frame.size.width - 4,
						y: final__label_frame.origin.y - (tooltipSpawn_buttonView_h - final__label_frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.viewKey_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.viewKey_label.frame.origin.y + self.viewKey_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.viewKey_inputView.frame.size.height
				).integral
				//
				self.spendKey_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.viewKey_inputView.frame.origin.y + self.viewKey_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
					width: textField_w,
					height: self.spendKey_label.frame.size.height
					).integral
				do {
					let label = self.spendKey_label!
					label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
					var final__label_frame = label.frame
					final__label_frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
					label.frame = final__label_frame // kinda sucks to set this three times in this method. any alternative?
					//
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.spendKey_tooltipSpawn_buttonView.frame = CGRect(
						x: final__label_frame.origin.x + final__label_frame.size.width - 4,
						y: final__label_frame.origin.y - (tooltipSpawn_buttonView_h - final__label_frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.spendKey_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.spendKey_label.frame.origin.y + self.spendKey_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.spendKey_inputView.frame.size.height
				).integral
				break
		}
		do {
			self.orUse_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: viewAbove_orUse_label.frame.origin.y + viewAbove_orUse_label.frame.size.height - 1, // -1 cause we set height to 24
				width: 46,
				height: 24
			).integral
			self.orUse_button.frame = CGRect(
				x: self.orUse_label.frame.origin.x + self.orUse_label.frame.size.width + 6,
				y: self.orUse_label.frame.origin.y,
				width: 0,
				height: 24
			)
			self.orUse_button.sizeToFit()
		}
		self.layOut_walletLabelAndSwatchFields(
			atYOffset: self.orUse_label.frame.origin.y + self.orUse_label.frame.size.height,
			isTopMostInForm: false
		)
		//
		let bottomPadding = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView // there probably exists something better to reference
		self.scrollableContentSizeDidChange(withBottomView: self.walletColorPicker_inputView, bottomPadding: bottomPadding)
	}
	override func viewDidAppear(_ animated: Bool)
	{
		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
		if isFirstAppearance {
			DispatchQueue.main.async
			{ [unowned self] in
				self.walletMnemonic_inputView.textView.becomeFirstResponder()
			}
		}
	}
	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		self.walletMnemonic_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
		self.addr_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
		self.viewKey_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
		self.spendKey_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
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
}
