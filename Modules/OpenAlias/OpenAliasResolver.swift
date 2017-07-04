//
//  OpenAliasResolver.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

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
		var dnssec_used_and_secured: Bool
	}
	//
	// Properties - Static
	static let shared = OpenAliasResolver()
	//
	// Properties - Instance
	//
	// Imperatives - Lifecycle
	private init() {}
	//
	// Imperatives - Runtime
	func resolveOpenAliasAddress(
		openAliasAddress: String,
		_ fn: @escaping (
			_ err_str: String?,
			_ addressWhichWasPassedIn: String?,
			_ response: OpenAliasResolverResponse?
		) -> Void
	) -> HostedMoneroAPIClient.RequestHandle?
	{
		let requestHandle = HostedMoneroAPIClient.lookupMoneroAddressInfoFromOpenAliasAddress(
			openAliasAddress: openAliasAddress,
			hostedMoneroAPIClient: HostedMoneroAPIClient.shared,
			mymoneroCore: MyMoneroCore.shared
		)
		{ (err_str, validResolvedDescription) in
			if err_str != nil {
				fn(
					err_str,
					openAliasAddress,
					nil
				)
				return
			}
			let response = OpenAliasResolverResponse(
				moneroReady_address: validResolvedDescription!.moneroAddress,
				returned__payment_id: validResolvedDescription!.payment_id,
				tx_description: validResolvedDescription!.tx_description,
				openAlias_domain: validResolvedDescription!.openAlias_domain,
				recipient_name: validResolvedDescription!.recipient_name,
				dnssec_used_and_secured: validResolvedDescription!.dnssec_used_and_secured
			)
			DispatchQueue.main.async
			{
				let userInfo: [String: Any] =
				[
					NotificationUserInfoKeys.response.rawValue: response
				]
				NotificationCenter.default.post(
					name: NotificationNames.resolvedOpenAliasAddress.notificationName,
					object: nil,
					userInfo: userInfo
				)
			}
			fn(nil, openAliasAddress, response)
		}
		return requestHandle
	}
}
