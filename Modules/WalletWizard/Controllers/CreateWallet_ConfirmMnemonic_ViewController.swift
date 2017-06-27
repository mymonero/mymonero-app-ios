//
//  CreateWallet_ConfirmMnemonic_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
struct CreateWallet_ConfirmMnemonic {}
//
class CreateWallet_ConfirmMnemonic_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Properties
	var messageView: UICommonComponents.InlineMessageView!
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
			let view = UICommonComponents.InlineMessageView(
				mode: .withCloseButton,
				didHide:
				{ [unowned self] in
					self.view.setNeedsLayout()
				}
			)
			self.messageView = view
			self.view.addSubview(view)
		}
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
	// Accessors - Layout
	var margin_h: CGFloat { return 16 }
	var content_x: CGFloat { return self.margin_h }
	var content_w: CGFloat { return (self.view.frame.size.width - 2*content_x) }
	var topPadding: CGFloat { return 41 }
	var marginAboveValidationMessageView: CGFloat { return 13 }
	var minimumMarginBelowValidationMessageView: CGFloat { return self.marginAboveValidationMessageView }
	var yOffsetForViewsBelowValidationMessageView: CGFloat
	{
		if self.messageView.isHidden {
			return self.topPadding
		}
		return max(
			self.topPadding,
			(self.marginAboveValidationMessageView + self.messageView.frame.size.height + self.minimumMarginBelowValidationMessageView)
		)
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
	// Imperatives - Overrides - Validation
	override func setValidationMessage(_ message: String)
	{
		let view = self.messageView! // this ! is not necessary according to the var's optionality but there seems to be a compiler bug
		view.set(text: message)
		self.layOut_messageView() // this can be slightly redundant, but it is called here so we lay out before showing. maybe rework this so it doesn't require laying out twice and checking visibility. maybe a flag saying "ought to be showing". maybe.
		view.show()
		self.view.setNeedsLayout() // so views (below messageView) get re-laid-out
	}
	override func clearValidationMessage()
	{
		self.messageView.clearAndHide() // as you can see, no ! required here. compiler bug?
		// we don't need to call setNeedsLayout() here b/c the messageView callback in self.setup will do so
	}
	//
	// Imperatives - Overrides - Submission
	override func _tryToSubmitForm()
	{
		// TODO
//		self.wizardController.proceedToNextStep()
	}
	//
	// Imperatives - Layout
	func layOut_messageView()
	{
		let x = CGFloat.visual__form_input_margin_x // use visual__ instead so we don't get extra img padding
		let y: CGFloat = 13
		let w = self.content_w
		self.messageView.layOut(atX: x, y: y, width: w)
	}
	//
	// Delegation - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let content_x = self.margin_h
		let content_w = self.content_w
		//
		if self.messageView.shouldPerformLayOut { // i.e. is visible
			self.layOut_messageView()
		}
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		let headers_x: CGFloat = 4 // would normally use content_x, but that's too large to fit content on small screens
		let headers_w = self.view.frame.size.width - 2*headers_x
		self.headerLabel.frame = CGRect(x: 0, y: 0, width: headers_w, height: 0)
		self.descriptionLabel.frame = CGRect(x: 0, y: 0, width: headers_w, height: 0)
		self.headerLabel.sizeToFit() // to get height
		self.descriptionLabel.sizeToFit() // to get height
		self.headerLabel.frame = CGRect(
			x: headers_x,
			y: top_yOffset,
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
//
extension CreateWallet_ConfirmMnemonic
{
	class MnemonicTextDisplayView: UIView
	{
		//
		// Properties
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
			let padding_h: CGFloat = 22 //24 // b/c 24 doesn't give enough h room to break well
			let padding_y: CGFloat = 36
			//
//			self.frame = CGRect(x: x, y: y, width: width, height: self.label.frame.size.height + 2*padding_y)
		}
		//
		// Imperatives - State
		
	}
}
