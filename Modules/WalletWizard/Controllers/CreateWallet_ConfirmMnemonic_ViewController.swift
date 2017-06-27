//
//  CreateWallet_ConfirmMnemonic_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class CreateWallet_ConfirmMnemonic_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Properties
	let headerLabel = UICommonComponents.ReadableInfoHeaderLabel()
	let descriptionLabel = UICommonComponents.ReadableInfoDescriptionLabel()
	//
	// Lifecycle - Init
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("New Wallet", comment: "")
		// must implement 'back' btn ourselves
		self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .back,
			tapped_fn:
			{ [unowned self] in
				self.navigationController?.popViewController(animated: true)
			}
		)
	}
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = self.headerLabel
			view.text = NSLocalizedString("Verify your mnemonic", comment: "")
			view.textAlignment = .center
			self.view.addSubview(view)
		}
		do {
			let view = self.descriptionLabel
			view.set(text: NSLocalizedString("Choose each word in the correct order.", comment: ""))
			view.textAlignment = .center
			self.view.addSubview(view)
		}
		//		do {
		//			let view = self.copyButton
		//			view.set(text: self.wizardWalletMnemonicString)
		//			self.view.addSubview(view)
		//		}
//		do {
//			let view = self.mnemonicTextDisplayView
//			view.set(text: self.wizardWalletMnemonicString)
//			self.view.addSubview(view)
//		}
	}
	//
	// Accessors - Overrides
	override func new_titleForNavigationBarButtonItem__next() -> String
	{
		return NSLocalizedString("Confirm", comment: "")
	}
	override func new_isFormSubmittable() -> Bool
	{
		// TODO: check if mnemonic matches
		return true
	}
	//
	// Imperatives - Overrides
	override func _tryToSubmitForm()
	{
		// TODO?
		self.wizardController.proceedToNextStep()
	}
	//
	// Delegation - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let topMargin: CGFloat = 41
		let headers_x: CGFloat = 4 // would normally use content_x, but that's too large to fit content on small screens
		let headers_w = self.view.frame.size.width - 2*headers_x
		self.headerLabel.frame = CGRect(x: 0, y: 0, width: headers_w, height: 0)
		self.descriptionLabel.frame = CGRect(x: 0, y: 0, width: headers_w, height: 0)
		self.headerLabel.sizeToFit() // to get height
		self.descriptionLabel.sizeToFit() // to get height
		self.headerLabel.frame = CGRect(
			x: headers_x,
			y: topMargin,
			width: headers_w,
			height: self.headerLabel.frame.size.height
		).integral
		self.descriptionLabel.frame = CGRect(
			x: headers_x,
			y: self.headerLabel.frame.origin.y + self.headerLabel.frame.size.height + 4,
			width: headers_w,
			height: self.descriptionLabel.frame.size.height
		).integral
		//
		let margin_h: CGFloat = 16
		let content_x = margin_h
		let content_w = self.view.frame.size.width - 2*content_x
//		self.mnemonicTextDisplayView.layOut(
//			atX: content_x,
//			y: self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 44,
//			width: content_w
//		)
		//		self.copyButton.frame = CGRect(
		//			x: self.mnemonicTextDisplayView.frame.origin.x + self.mnemonicTextDisplayView.frame.size.width - self.copyButton.frame.size.width,
		//			y: self.mnemonicTextDisplayView.frame.origin.y - self.copyButton.frame.size.height,
		//			width: self.copyButton.frame.size.width,
		//			height: self.copyButton.frame.size.height
		//		)
		//
		//
//		self.formContentSizeDidChange(withBottomView: self.mnemonicTextDisplayView, bottomPadding: 18)
	}
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{ // must maintain correct state if popped
		self.wizardController.patchToDifferentWizardTaskMode_withoutPushingScreen(
			patchTo_wizardTaskMode: self.wizardController.current_wizardTaskMode,
			atIndex: self.wizardController.current_wizardTaskMode_stepIdx - 1
		)
	}
}
