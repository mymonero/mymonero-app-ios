//
//  CreateWallet_InformOfMnemonic_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
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
struct CreateWallet_InformOfMnemonic {}
//
class CreateWallet_InformOfMnemonic_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Properties
	let headerLabel = UICommonComponents.ReadableInfoHeaderLabel()
	let descriptionLabel = UICommonComponents.ReadableInfoDescriptionLabel()
	let mnemonicTextDisplayView = CreateWallet_InformOfMnemonic.MnemonicTextDisplayView()
	let note_messageView = UICommonComponents.InlineMessageView(mode: .noCloseButton)
	//
	// Lifecycle - Init
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("New Wallet", comment: "")
	}
	override var overridable_wantsBackButton: Bool { return true }
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = self.headerLabel
			view.text = NSLocalizedString("Write down your mnemonic", comment: "")
			view.textAlignment = .center
			self.scrollView.addSubview(view)
		}
		do {
			let view = self.descriptionLabel
			view.set(text: NSLocalizedString("You'll confirm this sequence on the next screen.", comment: ""))
			view.textAlignment = .center
			self.scrollView.addSubview(view)
		}
		do {
			let view = self.mnemonicTextDisplayView
			view.set(text: self.wizardWalletMnemonicString)
			self.scrollView.addSubview(view)
		}
		do {
			let view = self.note_messageView
			view.set(text: NSLocalizedString("NOTE: This is the only way to access your wallet if you switch devices, use another Monero wallet app, or lose your data.", comment: ""))
			view.show()
			self.scrollView.addSubview(view)
		}
	}
	//
	// Accessors - Overrides
	override func new_wantsInlineMessageViewForValidationMessages() -> Bool { return false }
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
		let topMargin: CGFloat = 36
		let headers_x: CGFloat = 4 // would normally use content_x, but that's too large to fit content on small screens
		let headers_w = self.scrollView.frame.size.width - 2*headers_x
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
		let content_w = self.scrollView.frame.size.width - 2*content_x
		self.mnemonicTextDisplayView.layOut(
			atX: content_x,
			y: self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 44,
			width: content_w
		)
		//
		self.note_messageView.layOut(atX: content_x, y: self.mnemonicTextDisplayView.frame.origin.y + self.mnemonicTextDisplayView.frame.size.height + 24, width: content_w)
		//
		self.scrollableContentSizeDidChange(withBottomView: self.mnemonicTextDisplayView, bottomPadding: 18)
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
			return
		}
		// to also handle reconfig, i.e. on a 'back' cause we may have a new wallet instance generated by successors' "Start over"
		let mnemonicString = self.wizardWalletMnemonicString
		self.mnemonicTextDisplayView.set(text: mnemonicString)
		self.view.setNeedsLayout()
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
//
extension CreateWallet_InformOfMnemonic
{
	class MnemonicTextDisplayLabel: UILabel
	{
		//
		// Accessors - Overrides - UIResponder
		override var canBecomeFirstResponder: Bool {
			return true
		}
		//
		// Accessors - Overrides
		override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
		{
			return action == #selector(copy(_:))
		}
		//
		// Imperatives - Overrides - UIResponderStandardEditActions
		override func copy(_ sender: Any?)
		{
			UIPasteboard.general.string = self.text
		}
	}
	//
	class MnemonicTextDisplayView: UIView
	{
		//
		// Properties
		let label = CreateWallet_InformOfMnemonic.MnemonicTextDisplayLabel()
		let image = UIImage(named: "mnemonicDisplayView_bg_stretchable")!.stretchableImage(
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
				view.isUserInteractionEnabled = true
				view.numberOfLines = 0
				self.addSubview(view)
				//
//				let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(did_longPress(_:)))
//				gestureRecognizer.minimumPressDuration = 0.3
//				view.addGestureRecognizer(gestureRecognizer)
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
		// Imperatives - Layout
		func layOut(atX x: CGFloat, y: CGFloat, width: CGFloat)
		{
			let padding_h: CGFloat = 22
			let padding_y: CGFloat = 36
			self.label.frame = CGRect(x: 0, y: 0, width: width - 2*padding_h, height: 0)
			self.label.sizeToFit()
			self.label.frame = CGRect(x: padding_h, y: padding_y, width: self.label.frame.size.width, height: self.label.frame.size.height)
			//
			self.frame = CGRect(x: x, y: y, width: width, height: self.label.frame.size.height + 2*padding_y)
		}
		//
		// Imperatives - State
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
					NSAttributedStringKey.foregroundColor: UIColor(rgb: 0x9E9C9E),
					NSAttributedStringKey.font: UIFont.middlingRegularMonospace,
					NSAttributedStringKey.paragraphStyle: paragraphStyle
				]
			)
			self.label.attributedText = attributedString
		}
		//
		// Delegation - Interactions
/*
		
		NOTE: Copying mnemonic to pasteboard has been explicitly disabled as it can expose secret data 
		
		@objc func did_longPress(_ recognizer: UIGestureRecognizer)
		{
			guard recognizer.state == .began else { // instead of .recognized - so user knows asap that it's long-pressable
				return
			}
			guard let recognizerView = recognizer.view else {
				return
			}
			guard let recognizerSuperView = recognizerView.superview else {
				return
			}
			guard recognizerView.becomeFirstResponder() else {
				return
			}
			let menuController = UIMenuController.shared
			menuController.setTargetRect(recognizerView.frame, in: recognizerSuperView)
			menuController.setMenuVisible(true, animated:true)
		}
*/
	}
}
