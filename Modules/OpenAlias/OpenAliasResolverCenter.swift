//
//  OpenAliasResolver.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import ReachabilitySwift

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
			isReachable: self.reachability.isReachable,
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
