//
//  CreateWallet_InformOfMnemonic_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class MnemonicTextDisplayView: UIView
{
	//
	// Properties
	let label = UILabel()
	let image = UIImage(named: "mnemonicTextDisplayView_bg_stretchable")!.stretchableImage(
		withLeftCapWidth: 6,
		topCapHeight: 6
	)
	//
	// Lifecycle - Init
	init()
	{
		super.init(frame: .zero)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		do {
			self.backgroundColor = .clear
		}
		do {
			let view = self.label
			view.numberOfLines = 0
			self.addSubview(view)
		}
	}
	//
	// Imperatives - Overrides
	override func draw(_ rect: CGRect)
	{
		self.image.draw(in: rect)
		super.draw(rect)
	}
	//
	// Imperatives
	func layOut(atX x: CGFloat, y: CGFloat, width: CGFloat)
	{
		let padding_h: CGFloat = 24
		let padding_y: CGFloat = 36
		self.label.frame = CGRect(x: 0, y: 0, width: width - 2*padding_h, height: 0)
		self.label.sizeToFit()
		self.label.frame = CGRect(x: padding_h, y: padding_y, width: self.label.frame.size.width, height: self.label.frame.size.height)
		//
		self.frame = CGRect(x: x, y: y, width: width, height: self.label.frame.size.height + 2*padding_y)
	}
	//
	// Imperatives
	func set(text: String)
	{
		let paragraphStyle = NSMutableParagraphStyle()
		do {
			paragraphStyle.lineSpacing = 7
		}
		let attributedString = NSAttributedString(
			string: text,
			attributes:
			[
				NSForegroundColorAttributeName: UIColor(rgb: 0x9E9C9E),
				NSFontAttributeName: UIFont.middlingBoldMonospace, // have to make this bold even though design says regular because regular is too light, oddly
				NSParagraphStyleAttributeName: paragraphStyle
			]
		)
		self.label.attributedText = attributedString
	}
}

class CreateWallet_InformOfMnemonic_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Properties
	let headerLabel = UICommonComponents.ReadableInfoHeaderLabel()
	let descriptionLabel = UICommonComponents.ReadableInfoDescriptionLabel()
	let mnemonicTextDisplayView = MnemonicTextDisplayView()
	let messageView = UICommonComponents.InlineMessageView(mode: .noCloseButton)
	//
	// Lifecycle - Init
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = "New Wallet"
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
			view.text = NSLocalizedString("Write down your mnemonic", comment: "")
			view.textAlignment = .center
			self.view.addSubview(view)
		}
		do {
			let view = self.descriptionLabel
			view.set(text: NSLocalizedString("You'll confirm this sequence on the next screen.", comment: ""))
			view.textAlignment = .center
			self.view.addSubview(view)
		}
		do {
			let view = self.mnemonicTextDisplayView
			view.set(text: self.wizardWalletMnemonicString)
			self.view.addSubview(view)
		}
		do {
			let view = self.messageView
			view.set(text: NSLocalizedString("NOTE: This is the only way to access your wallet if you switch devices, use another Monero wallet app, or lose your data.", comment: ""))
			view.show()
			self.view.addSubview(view)
		}
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		return true
	}
	//
	// Accessors
	var wizardWalletMnemonicString: MoneroSeedAsMnemonic {
		let walletInstance = self.wizardController.walletCreation_walletInstance!
		//
		return walletInstance.generatedOnInit_walletDescription!.mnemonic
	}
	//
	// Imperatives - Overrides
	override func _tryToSubmitForm()
	{
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
		self.mnemonicTextDisplayView.layOut(
			atX: content_x,
			y: self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 44,
			width: content_w
		)
		//
		self.messageView.layOut(atX: content_x, y: self.mnemonicTextDisplayView.frame.origin.y + self.mnemonicTextDisplayView.frame.size.height + 24, width: content_w)
		//
		self.formContentSizeDidChange(withBottomView: self.mnemonicTextDisplayView, bottomPadding: 18)
	}
	//
	// Delegation - Views
	var hasAppearedOnce = false
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		//
		if self.hasAppearedOnce == false {
			self.hasAppearedOnce = true
		} else { // to also handle reconfig, i.e. on a 'back' cause we may have a new wallet instance generated by successors' "Start over"
			self.mnemonicTextDisplayView.set(text: self.wizardWalletMnemonicString)
			self.view.setNeedsLayout()
		}
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
