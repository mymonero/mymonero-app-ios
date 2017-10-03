//
//  CreateWallet_MetaInfo_ViewController.swift
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
		if self.wizardController.current_wizardTaskMode == .firstTime_createWallet { // only if it is, add cancel btn
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				target: self,
				action: #selector(tapped_barButtonItem_cancel)
			)
		} else { // we'll get a back button from super per overridable_wantsBackButton
		}
	}
	override var overridable_wantsBackButton: Bool {
		return self.wizardController.current_wizardTaskMode != .firstTime_createWallet
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
		self.layOut_walletLabelAndSwatchFields(
			atYOffset: 0,
			isTopMostInForm: true
		)
		self.scrollableContentSizeDidChange(withBottomView: self.walletColorPicker_inputView, bottomPadding: topPadding)
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
	// Delegation - Interactions
	@objc func tapped_barButtonItem_cancel()
	{
		self.wizardController._fromScreen_userPickedCancel()
	}
}
