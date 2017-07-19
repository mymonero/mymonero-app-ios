//
//  EditFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

extension EditWallet
{
	class SubmissionController
	{
		struct Parameters
		{
			var walletInstance: Wallet
			//
			var walletLabel: String
			var swatchColor: Wallet.SwatchColor
			//
			// Process callbacks
//			var preInputValidation_terminal_validationMessage_fn: (_ localizedString: String) -> Void
//			var passedInputValidation_fn: (Void) -> Void
			var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void // aka error
			//
			var success_fn: (_ instance: Wallet) -> Void
		}
		var parameters: Parameters
		init(parameters: Parameters)
		{
			self.parameters = parameters
		}
		//
		// Imperatives
		func handle()
		{
			let err_str = self.parameters.walletInstance.SetValuesAndSave(
				walletLabel: self.parameters.walletLabel,
				swatchColor: self.parameters.swatchColor
			)
			if err_str != nil {
				self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
				return
			}
			self.parameters.success_fn(self.parameters.walletInstance)
		}
	}
}
