//
//  MoneroRequestsURIs.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
//
enum FundsRequestURIQueryItemNames: String
{
	case amount = "tx_amount"
	case description = "tx_description"
	case paymentID = "tx_payment_id"
	case message = "tx_message"
}
//
struct ParsedRequest
{
	let address: MoneroAddress
	let amount: String?
	let description: String?
	let paymentID: MoneroPaymentID?
	let message: String?
}
//
extension MyMoneroCoreUtils
{
	static func New_RequestFunds_URL(
		address: MoneroAddress,
		amount: String?,
		description: String?,
		paymentId: MoneroPaymentID?,
		message: String?
	) -> URL
	{
		var urlComponents = URLComponents()
		urlComponents.scheme = MoneroConstants.currency_requestURIPrefix_sansColon
		urlComponents.host = address
		//
		var queryItems = [URLQueryItem]()
		if let amount = amount {
			queryItems.append(URLQueryItem(name: FundsRequestURIQueryItemNames.amount.rawValue, value: amount))
		}
		if let description = description {
			queryItems.append(URLQueryItem(name: FundsRequestURIQueryItemNames.description.rawValue, value: description))
		}
		if let paymentId = paymentId {
			queryItems.append(URLQueryItem(name: FundsRequestURIQueryItemNames.paymentID.rawValue, value: paymentId))
		}
		if let message = message {
			queryItems.append(URLQueryItem(name: FundsRequestURIQueryItemNames.message.rawValue, value: message))
		}
		urlComponents.queryItems = queryItems
		let url = urlComponents.url
		//
		return url! // TODO: is this ! ok?
	}
	//
	static func New_ParsedRequest_FromURIString(
		_ uriString: String
	) -> (
		err_str: String?,
		parsedRequest: ParsedRequest?
	)
	{
		guard let urlComponents = URLComponents(string: uriString) else {
			return (err_str: "Unrecognized URI format", parsedRequest: nil)
		}
		let scheme = urlComponents.scheme
		if scheme != MoneroConstants.currency_requestURIPrefix_sansColon {
			return (err_str: "Request URI has non-Monero protocol", parsedRequest: nil)
		}
		var target_address: MoneroAddress // var, as we have to finalize it
		// if the URL has '://' in it instead of ':', path may be empty, but host will contain the address instead
		if urlComponents.host != nil {
			target_address = urlComponents.host!
		} else if urlComponents.path != "" {
			target_address = urlComponents.path
		} else {
			return (err_str: "Request URI had no target address", parsedRequest: nil)
		}
		var amount: String?
		var description: String?
		var paymentID: MoneroPaymentID?
		var message: String?
		if let queryItems = urlComponents.queryItems { // needs to be parsed it seems
			for (_, queryItem) in queryItems.enumerated() {
				let queryItem_name = queryItem.name
				if let queryItem_value = queryItem.value {
					switch queryItem_name {
						case FundsRequestURIQueryItemNames.amount.rawValue:
							amount = queryItem_value
						case FundsRequestURIQueryItemNames.description.rawValue:
							description = queryItem_value
						case FundsRequestURIQueryItemNames.paymentID.rawValue:
							paymentID = queryItem_value
						case FundsRequestURIQueryItemNames.message.rawValue:
							message = queryItem_value
						default:
							break
					}
				}
			}
		}
		let parsedRequest = ParsedRequest(
			address: target_address,
			amount: amount,
			description: description,
			paymentID: paymentID,
			message: message
		)
		//
		return (err_str: nil, parsedRequest: parsedRequest)
	}
}
