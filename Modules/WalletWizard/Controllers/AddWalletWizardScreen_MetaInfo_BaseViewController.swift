//
//  AddWalletWizardScreen_MetaInfo_BaseViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddWalletWizardScreen_MetaInfo_BaseViewController: AddWalletWizardScreen_BaseViewController
{
	var walletLabel_label: UICommonComponents.FormLabel!
	var walletLabel_inputView: UICommonComponents.FormInputField!
	//
	override func setup_views()
	{
		do { // validation message view
			DDLog.Todo("WalletWizard", "implement validation msg view")
		}
		super.setup_views()
		do { // wallet label field
			do {
				let view = UICommonComponents.FormLabel(
					title: NSLocalizedString("WALLET NAME", comment: ""),
					sizeToFit: true
				)
				self.walletLabel_label = view
				self.view.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("For your reference", comment: "")
				)
				view.isSecureTextEntry = true
				view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				view.delegate = self
				view.returnKeyType = .go
				self.walletLabel_inputView = view
				self.view.addSubview(view)
			}
		}
		do { // wallet color field
			DDLog.Todo("WalletWizard", "implement swatch clr picker")
		}
	}
}
