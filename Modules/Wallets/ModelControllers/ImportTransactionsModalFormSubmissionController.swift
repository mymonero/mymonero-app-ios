//
//  ImportTransactionsModalFormSubmissionController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/20/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

extension ImportTransactionsModal
{
	class SubmissionController
	{
		struct Parameters
		{
			let fromWallet: Wallet
			let infoRequestParsingResult: HostedMoneroAPIClient_Parsing.ParsedResult_ImportRequestInfoAndStatus
			//
			var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void // aka error
			var success_fn: () -> Void
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
//			if err_str != nil {
//				self.parameters.preSuccess_terminal_validationMessage_fn(err_str!)
//				return
//			}
			self.parameters.success_fn()
		}

	}
}
