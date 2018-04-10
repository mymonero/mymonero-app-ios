//
//  MoneroTypes_Amounts.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
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
import BigInt
//
typealias HumanUnderstandableCurrencyAmountDouble = Double // e.g. -0.5 for -0.5 XMR
// TODO: ^-- improve name? must be a proper term for this
//
struct MoneyAmount
{
	static let _formatter = NumberFormatter()
	static var __hasConfigured_formatter = false
	static func newDouble(withUserInputAmountString string: String) -> Double?
	{
		if __hasConfigured_formatter == false {
			MoneyAmount._formatter.numberStyle = .decimal
			__hasConfigured_formatter = true
		}
		let number = MoneyAmount._formatter.number(from: string)
		if number == nil {
			return nil
		}
		let double = number!.doubleValue
		
		return double
	}
}
//
var _doubleFormatter: NumberFormatter? = nil
func shared_doubleFormatter() -> NumberFormatter
{
	if _doubleFormatter == nil {
		_doubleFormatter = NumberFormatter()
		_doubleFormatter!.minimumFractionDigits = 1
		_doubleFormatter!.maximumFractionDigits = MoneroConstants.currency_unitPlaces + 1
		_doubleFormatter!.roundingMode = .down
		_doubleFormatter!.numberStyle = .decimal
	}
	return _doubleFormatter!
}
//
typealias MoneroAmount = BigInt // in atomic units, i.e. 10^12 per 1 xmr; and must be unsigned!
extension MoneroAmount
{
	var humanReadableString: String {
		return FormattedString(fromMoneroAmount: self)
	}
	var atomicUnitsBigIntString: String {
		return "\(self)"
	}
	//
	var jsRepresentationString:String
	{ // because we need to convert it back for calls like create_transaction 
		return "new mymonero_core_js.JSBigInt(\"\(self)\")"
	}
	//
	static func new(withDouble doubleValue: HumanUnderstandableCurrencyAmountDouble) -> MoneroAmount
	{
		let amountAsFormattedString = shared_doubleFormatter().string(for: doubleValue)!
		//
		return new(withMoneyAmountDoubleString: amountAsFormattedString)
	}
	static func new(withUserInputAmountString string: String) -> MoneroAmount?
	{
		guard let double = MoneyAmount.newDouble(withUserInputAmountString: string) else {
			return nil
		}
		let amount = self.new(withDouble: double)
		//
		return amount
	}
	static func new(withMoneyAmountDoubleString string: String) -> MoneroAmount
	{ // aka monero_utils.parseMoney
		if string == "" {
			return MoneroAmount(0)
		}
		let signed_NSString = string as NSString
		let isNegative = signed_NSString.substring(to: 1) == "-" ? true : false
		var unsignedDouble_NSString: NSString
		if isNegative {
			unsignedDouble_NSString = signed_NSString.substring(from: 1) as NSString
		} else {
			unsignedDouble_NSString = signed_NSString
		}
		let decimalLocation = unsignedDouble_NSString.range(of: ".").location
		if decimalLocation == NSNotFound { // no decimal
			unsignedDouble_NSString = "\(unsignedDouble_NSString).0" as NSString // so that we have single codepath for int and double
		}
		let maxDecimalUnits_stringLength = decimalLocation + MoneroConstants.currency_unitPlaces + 1
		if (unsignedDouble_NSString.length > maxDecimalUnits_stringLength) { // if precision too great
			unsignedDouble_NSString = unsignedDouble_NSString.substring( // chop
				with: NSMakeRange(0, maxDecimalUnits_stringLength)
			) as NSString
		}
		let string_beforeDecimal = unsignedDouble_NSString.substring(with: NSMakeRange(0, decimalLocation))
		let moneroAmount_beforeDecimal = BigUInt(string_beforeDecimal)! * BigUInt(10).power(MoneroConstants.currency_unitPlaces)
		let afterDecimal_location = decimalLocation + 1
		let string_afterDecimal = unsignedDouble_NSString.substring( // chop
			with: NSMakeRange(
				afterDecimal_location,
				unsignedDouble_NSString.length - afterDecimal_location
			)
		)
		let moneroAmount_afterDecimal = BigUInt(string_afterDecimal)! * BigUInt(10).power(
			decimalLocation + MoneroConstants.currency_unitPlaces - unsignedDouble_NSString.length + 1
		)
		let unsigned_moneroAmount = moneroAmount_beforeDecimal + moneroAmount_afterDecimal
		let unsigned_moneroAmount_String = String(unsigned_moneroAmount, radix: 10) // converting to string in order to convert to BigInt in order to negate... better way?
		let signed_moneroAmount = isNegative ? MoneroAmount("-\(unsigned_moneroAmount_String)") : MoneroAmount(unsigned_moneroAmount_String)
		//
		return signed_moneroAmount!
	}
}
//
struct MoneroAmounts
{
	static func trimRight(_ str: String, _ char: Character) -> String
	{
		var retStr = str
		while retStr.last == char {
			retStr.removeLast()
		}
		return retStr
	}
	static func padLeft(_ str: String, _ len: Int, _ char: Character) -> String
	{
		var retStr = str
		while retStr.count < len {
			retStr = String(char) + retStr
		}
		return retStr
	}
}
func FormattedString(fromMoneroAmount moneroAmount: MoneroAmount) -> String
{ // aka monero_utils.formatMoneyFull + monero_utils.formatMoney
	let signed_moneroAmount_NSString = String(moneroAmount, radix: 10) as NSString
	// now first strip off and hang onto any '-' sign
	let symbol = signed_moneroAmount_NSString.substring(to: 1) == "-" ? "-" : ""
	let moneroAmount_NSString = symbol == "-"
		? signed_moneroAmount_NSString.substring(from: 1) as NSString
		: signed_moneroAmount_NSString
	let moneroAmount_NSString_length = moneroAmount_NSString.length
	var final_substring_afterDecimal: NSString!
	if (moneroAmount_NSString_length >= MoneroConstants.currency_unitPlaces) {
		let range = NSMakeRange(
			moneroAmount_NSString_length - MoneroConstants.currency_unitPlaces,
			MoneroConstants.currency_unitPlaces
		)
		final_substring_afterDecimal = moneroAmount_NSString.substring(with: range) as NSString
	} else {
		final_substring_afterDecimal = MoneroAmounts.padLeft(
			moneroAmount_NSString as String,
			MoneroConstants.currency_unitPlaces,
			Character("0")
		) as NSString
	}
	let lengthOf_substring_beforeDecimal = max(moneroAmount_NSString_length - MoneroConstants.currency_unitPlaces, 0)
	let raw_substring_beforeDecimal = moneroAmount_NSString.substring(
		with: NSMakeRange(0, lengthOf_substring_beforeDecimal) // will come out as empty string if nothing before decimal
	)
	let final_substring_beforeDecimal = raw_substring_beforeDecimal != "" ? raw_substring_beforeDecimal : "0"
	let fullyFormatted = "\(symbol)\(final_substring_beforeDecimal).\(final_substring_afterDecimal!)"
	//
	var trimmed_fullyFormatted_NSString = MoneroAmounts.trimRight(fullyFormatted, Character("0")) as NSString
	let rangeOf_lastChar = NSMakeRange(trimmed_fullyFormatted_NSString.length - 1, 1)
	if trimmed_fullyFormatted_NSString.substring(with: rangeOf_lastChar) == "." {
		trimmed_fullyFormatted_NSString = trimmed_fullyFormatted_NSString.substring(to: rangeOf_lastChar.location) as NSString
	}
	//
	return trimmed_fullyFormatted_NSString as String
}
func DoubleFromMoneroAmount(moneroAmount: MoneroAmount) -> HumanUnderstandableCurrencyAmountDouble
{
	return Double(FormattedString(fromMoneroAmount: moneroAmount))!
}
