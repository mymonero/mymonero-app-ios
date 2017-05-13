//
//  HostedMonero_OpenAliasResolving.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
struct ValidOAResolvedMoneroAddressDescription
{
	let moneroAddress: MoneroAddress
	let openAlias_domain: String
	//
	let payment_id: MoneroPaymentID?
	let tx_description: String?
	let recipient_name: String?
	let dnssec_used_and_secured: Bool
}
//
// TODO: this should be encapsulated within/called by a standardized OpenAliasResolver class
func LookupMoneroAddressInfoFromOpenAliasAddress(
	openAliasAddress: String,
	hostedMoneroAPIClient: HostedMoneroAPIClient, // to get TXT records
	mymoneroCore: MyMoneroCore,
	fn: @escaping (
		_ err_str: String?,
		_ validResolvedDescription: ValidOAResolvedMoneroAddressDescription?
	) -> Void
) -> HostedMoneroAPIClient_RequestHandle?
{
	if IsAddressNotMoneroAddressAndThusProbablyOAAddress(openAliasAddress) == false {
		let err_str = "Asked to resolve non-OpenAlias address"
		fn(err_str, nil) // although technically should be a code fault
		return nil
	}
	let openAlias_domain = openAliasAddress.replacingOccurrences(of: "@", with: ".")
	let requestHandle = hostedMoneroAPIClient.TXTRecords(openAlias_domain: openAlias_domain)
	{ (request__err_str, parsedResult) in
		if let request__err_str = request__err_str {
			let err_str = "Couldn't look up '\(openAlias_domain)'… \(request__err_str)"
			fn(err_str, nil)
			return
		}
		// NSLog("\(openAlias_domain): \(records)")
		guard let parsedResult = parsedResult else {
			let err_str = "Unknown error while parsing OA address lookup."
			fn(err_str, nil)
			return
		}
		let dnssec_used = parsedResult.dnssec_used
		let secured = parsedResult.secured
		let dnssec_fail_reason = parsedResult.dnssec_fail_reason
		let (err_str, optl_validated_descriptions) = ValidatedOARecordsFromTXTRecordsWithOpenAliasPrefix(
			domain: openAlias_domain,
			records: parsedResult.records,
			dnssec_used: dnssec_used,
			secured: secured,
			dnssec_fail_reason: dnssec_fail_reason,
			openAliasPrefix: MoneroConstants.currency_openAliasPrefix
		)
		if let err_str = err_str {
			fn(err_str, nil)
			return
		}
		guard let validated_descriptions = optl_validated_descriptions else {
			fn("No DNS records found during OA address lookup.", nil)
			return
		}
		let sampled_description = validated_descriptions[0] // going to assume we only have one, or that the first one is sufficient
		// console.log("OpenAlias record: ", sampled_oaRecord)
		guard let oaRecord_address = sampled_description.recipient_address else {
			fn("No Monero address found on DNS record during OA address lookup.", nil)
			return
		}
		// now verify address is decodable for currency
		mymoneroCore.DecodeAddress(oaRecord_address)
		{ (err, decodedAddress) in
			if let _ = err {
				NSLog("TODO: extract error string from error") // TODO: this is not done yet cause i don't know the format of the error yet
				let err_str = "Address found on DNS record for OA address was not a valid Monero address." // TODO
				fn(err_str, nil)
				return
			}
			let validResolvedDescription = ValidOAResolvedMoneroAddressDescription(
				moneroAddress: oaRecord_address as MoneroAddress, // now considered valid,
				openAlias_domain: openAlias_domain,
				//
				payment_id: sampled_description.tx_payment_id,
				tx_description: sampled_description.tx_description,
				recipient_name: sampled_description.recipient_name,
				dnssec_used_and_secured: dnssec_used && secured
			)
			//
			fn(
				nil,
				validResolvedDescription
			)
		}
	}
	return requestHandle
}

