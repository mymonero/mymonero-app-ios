//
//  CreateWallet_MetaInfo_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class CreateWallet_MetaInfo_ViewController: AddWalletWizardScreen_MetaInfo_BaseViewController
{
	//
	// Lifecycle - Init
	override func setup_views()
	{
		super.setup_views()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("New Wallet", comment: "")
		if self.wizardController.current_wizardTaskMode == .firstTime_useExisting { // only if it is, add cancel btn
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				target: self,
				action: #selector(tapped_barButtonItem_cancel)
			)
		} else { // must implement 'back' btn ourselves
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .back,
				tapped_fn:
				{ [unowned self] in
					self.navigationController?.popViewController(animated: true)
				}
			)
		}
	}
	
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		assert(false, "Unexpected")
		return nil
	}
	override func new_wantsInlineMessageViewForValidationMessages() -> Bool { return false }
	override func new_isFormSubmittable() -> Bool
	{
//		if self.isSubmitting == true {
//			return false
//		}
		guard let walletLabel = self.walletLabel, walletLabel != "" else {
			return false
		}
		return true
	}
	//
	// Runtime - Imperatives - Overrides
	override func _tryToSubmitForm()
	{
		// Note: going to assume no validation errors here, but maybe check if name is already in use
		//
		let walletLabel = self.walletLabel!
		let color = self.walletColorPicker_inputView.currentlySelected_color!
		self.wizardController.setMetaInfoAndProceedToNextStep(
			walletLabel: walletLabel,
			color: color
		)
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
		let topPadding: CGFloat = 13
		//
		self.layOut_walletLabelAndSwatchFields(atYOffset: 0)
		self.formContentSizeDidChange(withBottomView: self.walletColorPicker_inputView, bottomPadding: topPadding)
	}
	override func viewDidAppear(_ animated: Bool)
	{
		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
		if isFirstAppearance {
			DispatchQueue.main.async
			{ [unowned self] in
				self.walletLabel_inputView.becomeFirstResponder()
			}
		}
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
	//
	// Delegation - Interactions
	func tapped_barButtonItem_cancel()
	{
		self.wizardController._fromScreen_userPickedCancel()
	}
}
