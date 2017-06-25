//
//  CreateWallet_Instructions_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class CreateWallet_Instructions_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Constants/Types
	struct TitleAndDescription
	{
		var title: String
		var description: String
	}
	struct LabelDuo
	{
		var titleLabel: UICommonComponents.ReadableInfoHeaderLabel
		var descriptionLabel: UICommonComponents.ReadableInfoDescriptionLabel
	}
	//
	// Properties
	var labelDuos: [LabelDuo] = []
	var horizontalRuleView = UIView()
	var agreeCheckboxButton = UICommonComponents.PushButton(pushButtonType: .utility)
	//
	// Lifecycle - Init
	override func setup_views()
	{
		super.setup_views()
		do {
			let titlesAndDescriptions = self._new_messages_titlesAndDescriptions
			for (_, titleAndDescription) in titlesAndDescriptions.enumerated() {
				let labelDuo = LabelDuo(
					titleLabel: self._new_titleLabel(with: titleAndDescription.title),
					descriptionLabel: self._new_descriptionLabel(with: titleAndDescription.description)
				)
				self.labelDuos.append(labelDuo)
				//
				let titleLabel = labelDuo.titleLabel
				let descriptionLabel = labelDuo.descriptionLabel
				self.view.addSubview(titleLabel)
				self.view.addSubview(descriptionLabel)
			}
		}
		do {
			let view = self.horizontalRuleView
			view.backgroundColor = UIColor(rgb: 0x383638)
			self.view.addSubview(view)
		}
		do {
			let view = self.agreeCheckboxButton
			let checkbox_image = UIImage(named: "terms_checkbox")!
			let checkbox_checked_image = UIImage(named: "terms_checkbox_checked")!
			view.setImage(checkbox_image, for: .normal)
			view.setImage(checkbox_checked_image, for: .selected)
			view.adjustsImageWhenHighlighted = true
			view.contentHorizontalAlignment = .left
			let inset_h: CGFloat = 8
			let inset_v: CGFloat = 8
			view.imageEdgeInsets = UIEdgeInsetsMake(
				inset_v,
				inset_h + UICommonComponents.FormInputCells.imagePadding_x,
				inset_v,
				0
			)
			view.addTarget(self, action: #selector(agreeCheckboxButton_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("GOT IT!", comment: ""), for: .normal)
			view.titleLabel!.font = UIFont.visualSizeIncreased_smallRegularMonospace // instead of just smallRegularMonospace because that appears too small, visually. not exactly sure why.
			view.setTitleColor(UIColor(rgb: 0xF8F7F8), for: .normal)
			view.titleEdgeInsets = UIEdgeInsetsMake(
				inset_v - 1,
				UICommonComponents.FormInputCells.imagePadding_x + checkbox_image.size.width + 2,
				inset_v,
				0
			)
			self.view.addSubview(view)
		}
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		//
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
	//
	// Accessors
	var _new_messages_titlesAndDescriptions: [TitleAndDescription]
	{
		var list: [TitleAndDescription] = []
		list.append(TitleAndDescription(
			title: NSLocalizedString("Creating a wallet", comment: ""),
			description: NSLocalizedString("Each Monero wallet gets a secret word-sequence called a mnemonic.", comment: "")
		))
		list.append(TitleAndDescription(
			title: NSLocalizedString("Write down your mnemonic", comment: ""),
			description: NSLocalizedString("It's the only way to recover access to your wallet, and is never uploaded.", comment: "")
		))
		list.append(TitleAndDescription(
			title: NSLocalizedString("Keep it secure & private", comment: ""),
			description: NSLocalizedString("Anyone with the mnemonic can view and spend the funds in your wallet.", comment: "")
		))
		list.append(TitleAndDescription(
			title: NSLocalizedString("Use pen and paper or back it up", comment: ""),
			description: NSLocalizedString("If you save it to an insecure location, it may be viewable by other apps.", comment: "")
		))
		//
		return list
	}
	func _new_titleLabel(with text: String) -> UICommonComponents.ReadableInfoHeaderLabel
	{
		let label = UICommonComponents.ReadableInfoHeaderLabel()
		label.text = text
		//
		return label
	}
	func _new_descriptionLabel(with text: String) -> UICommonComponents.ReadableInfoDescriptionLabel
	{
		let label = UICommonComponents.ReadableInfoDescriptionLabel()
		label.textAlignment = .left
		label.set(text: text)
		//
		return label
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		guard self.agreeCheckboxButton.isSelected else {
			return false
		}
		return true
	}
	//
	// Imperatives - Overrides
	override func _tryToSubmitForm()
	{
		self.wizardController.createWalletInstanceAndProceedToNextStep()
	}
	//
	// Delegation - Interactions
	func agreeCheckboxButton_tapped()
	{
		self.agreeCheckboxButton.isSelected = !self.agreeCheckboxButton.isSelected
		self.set_isFormSubmittable_needsUpdate()
	}
	//
	// Delegation - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		let topMargin: CGFloat = 40
		let content_w: CGFloat = 240
		let content_x = (self.view.frame.size.width - content_w) / 2
		do {
			let marginBelowDescriptionLabel: CGFloat = 28
			var lastYOffset = topMargin
			for (_, labelDuo) in self.labelDuos.enumerated() {
				labelDuo.titleLabel.frame = CGRect(x: 0, y: 0, width: content_w, height: 0)
				labelDuo.descriptionLabel.frame = CGRect(x: 0, y: 0, width: content_w, height: 0)
				labelDuo.titleLabel.sizeToFit()
				labelDuo.descriptionLabel.sizeToFit()
				labelDuo.titleLabel.frame = CGRect(
					x: content_x,
					y: lastYOffset,
					width: labelDuo.titleLabel.frame.size.width,
					height: labelDuo.titleLabel.frame.size.height
				).integral
				labelDuo.descriptionLabel.frame = CGRect(
					x: content_x,
					y: labelDuo.titleLabel.frame.origin.y + labelDuo.titleLabel.frame.size.height + 4,
					width: labelDuo.descriptionLabel.frame.size.width,
					height: labelDuo.descriptionLabel.frame.size.height
				).integral
				//
				lastYOffset = labelDuo.descriptionLabel.frame.origin.y + labelDuo.descriptionLabel.frame.size.height + marginBelowDescriptionLabel
			}
		}
		let bottomMostLabel = self.labelDuos.last!.descriptionLabel
		do {
			self.horizontalRuleView.frame = CGRect(
				x: content_x,
				y: bottomMostLabel.frame.origin.y + bottomMostLabel.frame.size.height + 24,
				width: content_w,
				height: 1.0/UIScreen.main.scale
			)
		}
		do {
			let width = 96 + 2 * UICommonComponents.FormInputCells.imagePadding_x
			let y: CGFloat = self.horizontalRuleView.frame.origin.y + self.horizontalRuleView.frame.size.height + 24
			let height = 32 + 2 * UICommonComponents.FormInputCells.imagePadding_y
			self.agreeCheckboxButton.frame = CGRect(x: content_x, y: y, width: width, height: height).integral
		}
		self.formContentSizeDidChange(withBottomView: self.agreeCheckboxButton, bottomPadding: 18)
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
