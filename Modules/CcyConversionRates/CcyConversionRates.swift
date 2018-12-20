//
//  CcyConversionRates.swift
//  MyMonero
//
//  Created by Paul Shapiro on 10/18/17.
//  Copyright © 2014-2018 MyMonero. All rights reserved.
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
import Foundation
//
//
// Namespace
//
struct CcyConversionRates
{
	//
	// Interface - Typealiases
	typealias Rate = Double
	//
	typealias CurrencySymbol = String
	typealias CurrencyUID = String
	//
	// Internal - Properties - Caches
	fileprivate static var _cached_allCurrencies: [Currency]! // do not access directly
	fileprivate static var _cached_allCurrencySymbols: [CurrencySymbol]! // do not access directly
}
//
//
// Currencies
//
extension CcyConversionRates
{
	//
	// Interface - Enums
	enum Currency: MoneroConvertableCurrencySymbol // aka String
	{
		case none = "" // included for completeness / convenience / API
		case XMR = "XMR" // included for completeness / convenience / API
		case USD = "USD"
		case AUD = "AUD"
		case BRL = "BRL"
		case CAD = "CAD"
		case CHF = "CHF"
		case CNY = "CNY"
		case EUR = "EUR"
		case GBP = "GBP"
		case HKD = "HKD"
		case INR = "INR"
		case JPY = "JPY"
		case KRW = "KRW"
		case MXN = "MXN"
		case NOK = "NOK"
		case NZD = "NZD"
		case SEK = "SEK"
		case SGD = "SGD"
		case TRY = "TRY"
		case RUB = "RUB"
		case ZAR = "ZAR"
		//
		var symbol: CurrencySymbol {
			if self == .none {
				fatalError(".none has no symbol")
			}
			return self.rawValue
		}
		var fullTitleDescription: String {
			fatalError("Not implemented")
			// e.g. something like 'Monero (XMR)', 'US dollars (USD)', 'Pound sterling (GBP)', 'Yuan (CNY)', etc…
//			return "TODO"
		}
		var uid: CurrencyUID {
			if self == .none {
				fatalError(".none has no symbol")
			}
			return CurrencyUID(self.rawValue)
		}
		var hasAtomicUnits: Bool {
			return self == .XMR
		}
		var unitsForDisplay: Int {
			if self == .XMR {
				return MoneroConstants.currency_unitPlaces
			}
			return 2
		}
		static var lazy_allCurrencies: [Currency] {
			if CcyConversionRates._cached_allCurrencies == nil {
				CcyConversionRates._cached_allCurrencies =
				[ // TODO: is there really no way to enumerate an enum…? sort of ironic. the following is too fragile
					//
					// intentionally not including .none… it's not a currency
					//
					.XMR, // we want to display XMR in all currency selectors so far - but argument could be made for removing it and inserting it per use-xcase
					.USD,
					.AUD,
					.BRL,
					.CAD,
					.CHF,
					.CNY,
					.EUR,
					.GBP,
					.HKD,
					.INR,
					.JPY,
					.KRW,
					.MXN,
					.NOK,
					.NZD,
					.SEK,
					.SGD,
					.TRY,
					.RUB,
					.ZAR,
				]
			}
			return CcyConversionRates._cached_allCurrencies
		}
		static var lazy_allCurrencySymbols: [CurrencySymbol] {
			if CcyConversionRates._cached_allCurrencySymbols == nil {
				CcyConversionRates._cached_allCurrencySymbols = self.lazy_allCurrencies.map(
					{ (currency) -> CurrencySymbol in
						return currency.symbol
					}
				)
			}
			return CcyConversionRates._cached_allCurrencySymbols
		}
	}
}
//
extension CcyConversionRates.Currency
{
	func nonAtomicCurrency_localized_formattedString( // is nonAtomic-unit'd currency a good enough way to categorize these?
		final_amountDouble: Double,
		decimalSeparator: String = Locale.current.decimalSeparator ?? "."
	) -> String {
		assert(self != .XMR)
		if final_amountDouble == 0 {
			return "0" // not 0.0 / 0,0 / ...
		}
		let naiveLocalizedString = MoneroAmount.shared_localized_twoDecimalPlaceDoubleFormatter().string(for: final_amountDouble)!
		let components = naiveLocalizedString.components(separatedBy: decimalSeparator)
		let components_count = components.count
		assert(components_count > 0, "Unexpected 0 components while formatting nonatomic currency")
		if components_count == 1 { // meaning there's no '.'
			assert(naiveLocalizedString.contains(decimalSeparator) == false)
			return naiveLocalizedString + decimalSeparator + "00"
		}
		assert(components_count == 2)
		let component_1 = components[0]
		let component_2 = components[1]
		let component_2_characters_count = component_2.count
		assert(component_2_characters_count <= self.unitsForDisplay)
		let requiredNumberOfZeroes = self.unitsForDisplay - component_2_characters_count
		var rightSidePaddingZeroes = ""
		if requiredNumberOfZeroes > 0 {
			for _ in 0..<requiredNumberOfZeroes {
				rightSidePaddingZeroes += "0" // TODO: less verbose way to do this?
			}
		}
		return component_1 + decimalSeparator + component_2 + rightSidePaddingZeroes // pad
	}
}
//
extension CcyConversionRates.Currency
{ // Amount conversion
	static func rounded_ccyConversionRateCalculated_moneroAmountDouble(
		fromUserInputAmountDouble userInputAmountDouble: Double,
		fromCurrency selectedCurrency: CcyConversionRates.Currency
	) -> Double? // may return nil if ccyConversion rate unavailable - consumers will try again on 'didUpdateAvailabilityOfRates'
	{
		if selectedCurrency == .none {
			fatalError("Selected currency unexpectedly .none") // TODO: should this be a throw instead?
		}
		let xmrToCurrencyRate = CcyConversionRates.Controller.shared.rateFromXMR_orNilIfNotReady(
			toCurrency: selectedCurrency
		)
		if xmrToCurrencyRate == nil {
			return nil // ccyConversion rate unavailable - consumers will try again on 'didUpdateAvailabilityOfRates'
		}
		// conversion:
		// currencyAmt = xmrAmt * xmrToCurrencyRate;
		// xmrAmt = currencyAmt / xmrToCurrencyRate.
		// I figure it's better to apply the rounding here rather than only at the display level so that what is actually sent corresponds to what the user saw, even if greater ccyConversion precision /could/ be accomplished..
		let raw_ccyConversionRateApplied_amount = userInputAmountDouble * (1 / xmrToCurrencyRate!)
		let roundingMultiplier = Double(10 * 10 * 10 * 10) // 4 rather than, say, 2, b/c it's relatively more unlikely that fiat amts will be over 10-100 xmr - and b/c some currencies require it for xmr value not to be 0 - and 5 places is a bit excessive
		let truncated_amount = Double(round(roundingMultiplier * raw_ccyConversionRateApplied_amount) / roundingMultiplier) // must be truncated for display purposes
		//
		return truncated_amount
	}
	func displayUnitsRounded_amountInCurrency( // Note: __DISPLAY__ units
		fromMoneroAmount moneroAmount: MoneroAmount
	) -> Double? {
		if self == .none {
			fatalError("Selected currency unexpectedly .none") // TODO: should this be a throw instead?
		}
		let moneroAmountDouble = DoubleFromMoneroAmount(moneroAmount: moneroAmount)
		if self == .XMR {
			return moneroAmountDouble // no conversion necessary
		}
		let xmrToCurrencyRate = CcyConversionRates.Controller.shared.rateFromXMR_orNilIfNotReady(
			toCurrency: self
		)
		if xmrToCurrencyRate == nil {
			return nil // ccyConversion rate unavailable - consumers will try again
		}
		let raw_ccyConversionRateApplied_amount = moneroAmountDouble * xmrToCurrencyRate!
		let roundingMultiplier = pow(Double(10), Double(self.unitsForDisplay))
		let truncated_amount = Double(round(roundingMultiplier * raw_ccyConversionRateApplied_amount) / roundingMultiplier)
		//
		return truncated_amount
	}
	static func amountConverted_displayStringComponents(
		from amount: MoneroAmount,
		ccy: CcyConversionRates.Currency,
		chopNPlaces: UInt = 0
	) -> (
		formattedAmount: String,
		final_ccy: CcyConversionRates.Currency
	) {
		var formattedAmount: String
		var final_input_amount: MoneroAmount!
		if chopNPlaces != 0 {
			let power = MoneroAmount("10")!.power(Int(chopNPlaces)) // this *should* be ok for amount, even if it has no decimal places, because those places would be filled with 0s in such a number
			final_input_amount = (amount / power) * power
		} else {
			final_input_amount = amount
		}
		var mutable_ccy = ccy
		if ccy == .XMR {
			formattedAmount = final_input_amount!.localized_formattedString
		} else {
			let convertedAmount = ccy.displayUnitsRounded_amountInCurrency(fromMoneroAmount: final_input_amount!)
			if convertedAmount != nil {
				formattedAmount = MoneroAmount.shared_localized_twoDecimalPlaceDoubleFormatter().string(for: convertedAmount)!
			} else {
				formattedAmount = final_input_amount!.localized_formattedString
				mutable_ccy = .XMR // display XMR until rate is ready? or maybe just show 'LOADING…'?
			}
		}
		return (formattedAmount, mutable_ccy)
	}
}
//
//
// Controller
//
extension CcyConversionRates
{
	class Controller
	{
		//
		// Constants
		enum NotificationNames: String
		{
			case didUpdateAvailabilityOfRates = "CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates"
			//
			var notificationName: NSNotification.Name {
				return NSNotification.Name(self.rawValue)
			}
		}
		//
		// Interface - Singleton
		static let shared = Controller()
		//
		// Internal - Properties
		fileprivate var xmrToCurrencyRatesByCurrencyUID = [CurrencyUID: Rate]()
		//
		// Internal - Init
		init()
		{
			self.setup()
		}
		func setup()
		{
		
		}
		//
		// Interface - Accessors
		func isRateReady( // if you won't need the actual value
			fromXMRToCurrency currency: Currency
		) -> Bool {
			if currency == .none || currency == .XMR {
				fatalError("Invalid 'currency' argument value")
			}
			return self.xmrToCurrencyRatesByCurrencyUID[currency.uid] != nil
		}
		func rateFromXMR_orNilIfNotReady(
			toCurrency currency: Currency
		) -> Rate? {
			if currency == .none || currency == .XMR {
				fatalError("Invalid 'currency' argument value")
			}
			return self.xmrToCurrencyRatesByCurrencyUID[currency.uid] // which may be nil if the rate is not ready yet
		}
		//
		// Interface - Imperatives
		func set(
			XMRToCurrencyRate rate: Rate, // non-nil … ought to only need to be set to nil internally
			forCurrency currency: Currency,
			isPartOfBatch doNotNotify: Bool = false // normally false … but pass true for batch calls and then call ifBatched_notifyOf_set_XMRToCurrencyRate manually (arg is called doNotNotify b/c if part of batch, you only want to do currency-non-specific notify post once instead of N times)
		) -> Bool { // wasSetValueDifferent
			let wasSetValueDifferent = rate != self.xmrToCurrencyRatesByCurrencyUID[currency.uid]
			self.xmrToCurrencyRatesByCurrencyUID[currency.uid] = rate
			if doNotNotify != true {
				self._notifyOf_updateTo_XMRToCurrencyRate() // the default
			}
			return wasSetValueDifferent
		}
		func ifBatched_notifyOf_set_XMRToCurrencyRate()
		{
			DDLog.Info("CcyConversionRates", "Received updates: \(self.xmrToCurrencyRatesByCurrencyUID)")
			self._notifyOf_updateTo_XMRToCurrencyRate()
		}
		//
		func set_xmrToCcyRatesByCcy(
			_ xmrToCcyRatesByCcy: [Currency: Double]
		) {
			var wasAnyRateChanged = false
			for (_, keyAndValue) in xmrToCcyRatesByCcy.enumerated() {
				let wasSetValueDifferent = self.set(
					XMRToCurrencyRate: keyAndValue.value,
					forCurrency: keyAndValue.key,
					isPartOfBatch: true // defer notification til end
				)
				if wasSetValueDifferent {
					wasAnyRateChanged = true
				}
			}
			if wasAnyRateChanged {
				self.ifBatched_notifyOf_set_XMRToCurrencyRate() // finally, notify
			}
		}
		//
		// Internal - Imperatives
		func _notifyOf_updateTo_XMRToCurrencyRate()
		{
			NotificationCenter.default.post(
				name: NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
		}
	}
}
