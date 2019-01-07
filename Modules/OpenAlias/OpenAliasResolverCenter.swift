//
//  OpenAliasResolver.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
//  Copyright (c) 2014-2019, MyMonero.com
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
import Reachability

class OpenAliasResolver
{
	//
	// Constants and Types
	enum NotificationNames: String
	{
		case resolvedOpenAliasAddress = "OpenAliasResolver_NotificationNames_resolvedOpenAliasAddress"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum NotificationUserInfoKeys: String
	{
		case response = "OpenAliasResolver_NotificationUserInfoKeys_response"
	}
	//
	struct OpenAliasResolverResponse
	{
		var moneroReady_address: MoneroAddress?
		var returned__payment_id: MoneroPaymentID? // may be nil on a success
		var tx_description: String?
		var openAlias_domain: String?
		var recipient_name: String?
		//
		var dnssec_validationRequired: Bool
		var dnssec_status: DNSLookup_DNSSECStatus?
	}
	//
	// Properties - Static
	static let shared = OpenAliasResolver()
	//
	// Properties - Instance
	var reachability = Reachability()!
	//
	// Imperatives - Lifecycle
	private init()
	{
		self.setup()
	}
	func setup()
	{
		do {
			try self.reachability.startNotifier()
		} catch let e {
			assert(false, "Unable to start notification with error \(e)")
		}
	}
	//
	// Imperatives - Runtime
	@discardableResult
	func resolveOpenAliasAddress(
		openAliasAddress: String,
		validationRequired: Bool = false,
		forCurrency currency: OpenAliasDNSLookups.OpenAliasAddressCurrency, // TODO: possibly return all which are found
		_ fn: @escaping (
			_ err_str: String?,
			_ addressWhichWasPassedIn: String?,
			_ response: OpenAliasResolverResponse?
		) -> Void
	) -> DNSLookupHandle?
	{
		let lookupHandle = OpenAliasDNSLookups.moneroAddressInfo(
			fromOpenAliasAddress: openAliasAddress,
			forCurrency: currency,
			isReachable: self.reachability.connection != .none,
			fn:
			{ (err_str, validResolvedAddressDescription) in
				if err_str != nil {
					fn(err_str, openAliasAddress, nil)
					return
				}
				let response = OpenAliasResolverResponse(
					moneroReady_address: validResolvedAddressDescription!.recipient_address,
					returned__payment_id: validResolvedAddressDescription!.payment_id,
					tx_description: validResolvedAddressDescription!.tx_description,
					openAlias_domain: openAliasAddress,
					recipient_name: validResolvedAddressDescription!.recipient_name,
					dnssec_validationRequired: validationRequired,
					dnssec_status: validResolvedAddressDescription!.dnssec_status
				)
				DispatchQueue.main.async
				{
					let userInfo: [String: Any] = [ NotificationUserInfoKeys.response.rawValue: response ]
					NotificationCenter.default.post(
						name: NotificationNames.resolvedOpenAliasAddress.notificationName,
						object: nil,
						userInfo: userInfo
					)
				}
				fn(nil, openAliasAddress, response)
			}
		)
		return lookupHandle
	}
}
