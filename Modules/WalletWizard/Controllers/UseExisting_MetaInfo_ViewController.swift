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
	// Lifecycle - Init
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
}
