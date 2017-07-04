//
//  MoneroPaymentIDs.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
extension MyMoneroCoreUtils
{
	static func isValidPaymentIDOrNoPaymentID(_ paymentId: String?) -> Bool
	{
		if let paymentId = paymentId {
			let pattern = "^[0-9a-fA-F]{64}$"
			if paymentId.characters.count != 64 || paymentId.range(of: pattern, options: .regularExpression) == nil { // not a valid 64 char pid
				return false // then not valid
			}
		}
		return true // then either no pid or is a valid one
	}
}
