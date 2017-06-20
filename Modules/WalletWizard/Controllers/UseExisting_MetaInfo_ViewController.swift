//
//  UseExisting_MetaInfo_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class UseExisting_MetaInfo_ViewController: AddWalletWizardScreen_MetaInfo_BaseViewController
{
	//
	// Types/Constants
	enum LoginWith_Mode
	{
		case mnemonicSeed
		case addrAndPrivKeys
	}
	//
	// Properties - Model/state
	var loginWith_mode: LoginWith_Mode!
	// Properties - Subviews
	var walletMnemonic_label: UICommonComponents.FormLabel!
	var walletMnemonic_inputView: UICommonComponents.FormTextViewContainerView!
	//
	// Lifecycle - Init
	override func setup_views()
	{
		super.setup_views()
		// initial state (could be placed in .setup)
		self.loginWith_mode = .mnemonicSeed
		//
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("SECRET MNEMONIC", comment: ""),
				sizeToFit: true
			)
			self.walletMnemonic_label = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormTextViewContainerView(
				placeholder: NSLocalizedString("From your existing wallet", comment: "")
			)
			view.textView.autocorrectionType = .no
			view.textView.autocapitalizationType = .none
			view.textView.spellCheckingType = .no
			view.textView.returnKeyType = .next
//			view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
//			view.delegate = self
			self.walletMnemonic_inputView = view
			self.view.addSubview(view)
		}
		do {
			
		}
		self._setup_form_walletMnemonicField()
		self._setup_form_walletAddrAndKeysFields()
		self._setup_form_toggleLoginModeLayer()
		//
		self._setup_form_walletNameField()
		self._setup_form_walletSwatchField()
	}
	
	func _setup_form_walletMnemonicField()
	{
		
	}
	func _setup_form_walletAddrAndKeysFields()
	{
	}
	func _setup_form_toggleLoginModeLayer()
	{
	}
	//
	func _setup_form_walletNameField()
	{
	}
	func _setup_form_walletSwatchField()
	{
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = "Log Into Your Wallet"
		if self.wizardController.current_wizardTaskMode == .firstTime_useExisting { // only if it is, add cancel btn
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				target: self,
				action: #selector(tapped_barButtonItem_cancel)
			)
		}
	}
	//
	// Delegation - Interactions
	func tapped_barButtonItem_cancel()
	{
		self.wizardController._fromScreen_userPickedCancel()
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
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		//
		if self.loginWith_mode == .mnemonicSeed { // really only care about the first 'appear' of self anyway
			self.walletMnemonic_inputView.becomeFirstResponder()
		} else {
			// not going to worry about it
		}
	}
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let topPadding: CGFloat = 20
		let textField_x: CGFloat = CGFloat.form_input_margin_x
		let labels_x: CGFloat  = CGFloat.form_label_margin_x
		let textField_w: CGFloat = self.view.frame.size.width - 2 * textField_x
		do {
			self.walletMnemonic_label.frame = CGRect(
				x: labels_x,
				y: topPadding,
				width: textField_w,
				height: self.walletMnemonic_label.frame.size.height
			).integral
			self.walletMnemonic_inputView.frame = CGRect(
				x: textField_x,
				y: self.walletMnemonic_label.frame.origin.y + self.walletMnemonic_label.frame.size.height + 8,
				width: textField_w,
				height: self.walletMnemonic_inputView.frame.size.height
			).integral
		}
//		do {
//			self.fieldAccessoryMessageLabel.frame = CGRect(
//				x: labels_x,
//				y: self.password_inputView.frame.origin.y + self.password_inputView.frame.size.height + 7,
//				width: textField_w,
//				height: 0
//				).integral
//			self.fieldAccessoryMessageLabel.sizeToFit()
//		}
//		let bottomPadding = topPadding
//		self.contentSize = CGSize(
//			width: self.frame.size.width,
//			height: self.confirmPassword_inputView.frame.origin.y + self.confirmPassword_inputView.frame.size.height + bottomPadding
//		)
	}
}
