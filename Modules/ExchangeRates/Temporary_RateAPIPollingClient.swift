//
//  Temporary_RateAPIPollingClient.swift
//  MyMonero
//
//  Created by Paul Shapiro on 10/21/17.
//  Copyright © 2014-2017 MyMonero. All rights reserved.
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
import Alamofire

struct Temporary_RateAPIPolling {}
extension Temporary_RateAPIPolling
{
	class Client
	{
		//
		// Common - Types
		typealias RequestHandle = Alamofire.DataRequest
		//
		// Interface - Shared Instance
		static let shared = Temporary_RateAPIPolling.Client()
		//
		// Internal - Properties
		var manager: SessionManager!
		var timer: Timer!
		//
		// Internal - Accessors / Derived properties
		let domain = "cryptocompare.com"
		let subdomain = "min-api"
		var authority: String {
			return self.subdomain + "." + self.domain
		}
		let _path_plusArgs_sansCurrenciesCSV = "/data/price?fsym=XMR&tsyms="
		var path: String {
			var string = ""
			string += self._path_plusArgs_sansCurrenciesCSV
			var currenciesCSV: String
			do {
				let allCurrencies = ExchangeRates.Currency.lazy_allCurrencies
				// strip .XMR
				let filtered_currencies = allCurrencies.filter({ (currency) -> Bool in
					return currency != .XMR
				})
				let filtered_currencySymbols = filtered_currencies.map({ (currency) -> ExchangeRates.CurrencySymbol in return currency.symbol })
				currenciesCSV = filtered_currencySymbols.joined(separator: ",")
			}
			string += currenciesCSV
			return string
		}
		
		
		//
		// Interface - Init
		required init()
		{
			self.setup()
		}
		//
		// Internal - Init
		func setup()
		{
			self.setup_manager()
			//
			self._performPollRequest() // the intial poll request…
			//
			self.timer = Timer(
				timeInterval: 60 * 3/*mins*/,
				target: self,
				selector: #selector(timer_fired),
				userInfo: nil,
				repeats: true
			)
			//
			// TODO: trigger request on certain events per notes
		}
		func setup_manager()
		{
			self.manager = SessionManager(
				configuration: URLSessionConfiguration.default,
				serverTrustPolicyManager: ServerTrustPolicyManager(
					policies: [String: ServerTrustPolicy]()
				)
			)
		}
		//
		// Internal - Imperatives - Request
		var _current_request: RequestHandle?
		var _dateOfLastSuccessResponse: Date?
		func _performPollRequest()
		{
			do {
				if self._current_request != nil {
					DDLog.Warn("Temporary_RateAPIPollingClient", "asked to \(#function) but _current_request already exists")
					return
				}
				if let date = self._dateOfLastSuccessResponse {
					let now = Date()
					let timeIntervalSince_dateOfLastSuccessResponse = now.timeIntervalSince(date)
					if timeIntervalSince_dateOfLastSuccessResponse < 30 {
						DDLog.Warn("Temporary_RateAPIPollingClient", "asked to \(#function) but timeIntervalSince_dateOfLastSuccessResponse = \(timeIntervalSince_dateOfLastSuccessResponse)")
						return // don't refresh - anti-spam / rate-limit avoidance
					}
				}
			}
			self._current_request = self._request
			{ [weak self] (err_str, response_data, response_jsonDict) in
				guard let thisSelf = self else {
					return
				}
				thisSelf._current_request = nil // free/clear
				if err_str != nil {
					DDLog.Error("Temporary_RateAPIPollingClient", "\(err_str!)")
					return
				}
				do {
					thisSelf._dateOfLastSuccessResponse = Date()
				}
				do {
					var wasAnyRateChanged = false
					let rateDoublesByCurrencySymbolStrings = response_jsonDict as! [String: Double]
					for (_, pair) in rateDoublesByCurrencySymbolStrings.enumerated() {
						let currencySymbol = pair.key as ExchangeRates.CurrencySymbol // no validation
						let currency = ExchangeRates.CurrencySymbol.currency(fromSymbol: currencySymbol)! // we'll just assume it's valid or we'll see a crash in development
						let rateDouble: Double = pair.value
						let wasSetValueDifferent = ExchangeRates.Controller.shared.set(
							XMRToCurrencyRate: rateDouble,
							forCurrency: currency,
							isPartOfBatch: true // defer notification til end
						)
						if wasSetValueDifferent {
							wasAnyRateChanged = true
						}
					}
					if wasAnyRateChanged {
						ExchangeRates.Controller.shared.ifBatched_notifyOf_set_XMRToCurrencyRate() // finally, notify
					} else {
						DDLog.Warn("Temporary_RateAPIPolling", "No different rate values received in rates matrix")
					}
				}
			}
		}
		func _teardownAny_request()
		{
			if self._current_request != nil {
				self._current_request?.cancel()
				self._current_request = nil
			}
		}
		//
		// Internal - Runtime - Imperatives - Requests - Shared
		@discardableResult
		fileprivate func _request(
			_ fn: @escaping (
				_ err_str: String?,
				_ response_data: Data?,
				_ response_jsonDict: [String: Any]?
			) -> Void
		) -> RequestHandle?
		{
			let headers: HTTPHeaders =
			[
				"Accept": "application/json",
				"Content-Type": "application/json",
			]
			let url = "https://\(self.authority)\(self.path)"
			let final_parameters = [String: Any]()
			let requestHandle = self.manager.request(
				url,
				method: .get,
				parameters: final_parameters,
				encoding: JSONEncoding.default,
				headers: headers
			).validate(
				statusCode: 200..<300
			).validate(
				contentType: ["application/json"]
			).responseJSON
			{ response in
				let _ = response.response?.statusCode ?? -1
				switch response.result
				{
					case .failure(let error):
						print(error)
						//
						let alert = UIAlertController(
							title: NSLocalizedString("Error retrieving currency rates", comment: ""),
							message: error.localizedDescription,
							preferredStyle: .alert
						)
						alert.addAction(
							UIAlertAction(
								title: NSLocalizedString("OK", comment: ""),
								style: .cancel,
								handler: nil
							)
						)
						WindowController.rootViewController!.present(alert, animated: true, completion: nil)
						//
						fn(error.localizedDescription, nil, nil) // localized description ok here?
						return
					case .success:
//						DDLog.Done("Temporary_RateAPIPollingClient", "\(url) \(statusCode)")
						break
				}
				guard let result_value = response.result.value else {
					fn("Unable to find data in response from ExchangeRate API server.", nil, nil)
					return
				}
				guard let JSON = result_value as? [String: Any] else {
					fn("Unable to find JSON in response from ExchangeRate API server.", nil, nil)
					return
				}
				fn(nil, response.data, JSON)
			}
			//
			return requestHandle
		}
		//
		// Internal - Delegation - Timer
		@objc func timer_fired()
		{
			self._performPollRequest()
		}
		//
		// Interface - Delgation
		func ApplicationDidBecomeActive()
		{ // hacky/patchy way (instead of a notification) to just tell self to kick off a poll
			self._performPollRequest()
		}
	}
}
