//
//  MoneroUtils_PaymentIDs.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/31/17.
//  Copyright (c) 2014-2018, MyMonero.com
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
//
extension MoneroUtils
{
	struct PaymentIDs
	{
		enum Variant: Int
		{
			case long = 64
			case short = 16
			//
			var charLength: Int {
				return self.rawValue
			}
		}
		static func isAValidOrNotA(paymentId: String?) -> Bool
		{
			guard let paymentId = paymentId, paymentId != "" else {
				return true
			}
			if self.isAValid(paymentId: paymentId, ofVariant: .long) {
				return true
			}
			if self.isAValid(paymentId: paymentId, ofVariant: .short) {
				return true
			}
			return false // not a match but not empty/nil either
		}
		static func isAValid(paymentId: String, ofVariant variant: Variant) -> Bool
		{
			let length = variant.charLength
			let pattern = "^[0-9a-fA-F]{\(length)}$"
			if paymentId.count == length && paymentId.range(of: pattern, options: .regularExpression) != nil { // not a valid 64 char pid
				return true // then is valid
			}
			return false
		}
	}
}
