//
//  EditFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/19/17.
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
import Foundation

extension EditWallet
{
	class SubmissionController
	{
		struct Parameters
		{
			var walletInstance: Wallet // think it's ok if this is strong since self ought to be torn down by the owner-viewController
			//
			var walletLabel: String
			var swatchColor: Wallet.SwatchColor
			//
			// Process callbacks
//			var preInputValidation_terminal_validationMessage_fn: (_ localizedString: String) -> Void
//			var passedInputValidation_fn: () -> ()
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
