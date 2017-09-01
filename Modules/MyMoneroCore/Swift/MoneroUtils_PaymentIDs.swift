//
//  MoneroUtils_PaymentIDs.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/31/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
//
struct MoneroUtils
{
	struct PaymentIDs
	{
		static func isAValidOrNotA(paymentId: String?) -> Bool
		{
			if let paymentId = paymentId, paymentId != "" {
				let pattern = "^[0-9a-fA-F]{64}$"
				if paymentId.characters.count != 64 || paymentId.range(of: pattern, options: .regularExpression) == nil { // not a valid 64 char pid
					return false // then not valid
				}
			}
			return true // then either no pid or is a valid one
		}
	}
}
