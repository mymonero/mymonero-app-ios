//
//  MoneroOpenAlias.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
//
struct ParsedOARecipientDescription
{
	var recipient_address: MoneroAddress?
	var recipient_name: String?
	var tx_payment_id: MoneroPaymentID?
	var tx_description: String?
}
//
extension MyMoneroCoreUtils
{
	static func doesStringContainPeriodChar_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(_ address: String) -> Bool // i.e. we already believe it to be an address
	{
		if address.range(of: ".") != nil { // assumed to be an OA address as XMR addresses do not have periods, and OA addrs must
			return true
		}
		return false
	}
	static func doesRecordHaveValidOpenAliasPrefix(_ record: String, _ openAliasPrefix: String) -> Bool
	{
		let range = NSMakeRange(0, 4 + openAliasPrefix.characters.count + 1)
		let record_prefixString = (record as NSString).substring(with: range)
		if (record_prefixString != "oa1:\(openAliasPrefix) ") {
			return false
		}
		return true
	}
	static func new_parsedDescriptionFromOpenAliasRecordWithOpenAliasPrefix(
		record: String,
		openAliasPrefix: String
	) -> (
		err_str: String?,
		description: ParsedOARecipientDescription?
	)
	{
		var parsedDescription = {}
		if MyMoneroCoreUtils.doesRecordHaveValidOpenAliasPrefix(record, openAliasPrefix) == false {
			return (err_str:"Invalid OpenAlias prefix", description: nil)
		}
		func parsed_paramValueWithName(_ valueName: String) -> String?
		{
			let valueName_length = valueName.characters.count
			let record_NSString = record as NSString
			let record_length = record_NSString.length
			let rangeOfValueNameKeyDeclaration = record_NSString.range(of: "\(valueName)=")
			if rangeOfValueNameKeyDeclaration.location == NSNotFound { // Record does not contain param
				DDLog.Warn("MyMoneroCore", "\(valueName) not found in OA record.")
				return nil
			}
			let nextDelimiter_searchRange_location = rangeOfValueNameKeyDeclaration.location + valueName_length + 1
			let nextDelimiter_searchRange = NSMakeRange(nextDelimiter_searchRange_location, record_length - nextDelimiter_searchRange_location)
			let rangeOfNextDelimiter = record_NSString.range(of: ";", options: [], range: nextDelimiter_searchRange)
			let posOfNextDelimiter = rangeOfNextDelimiter.location
			let pos2 = posOfNextDelimiter == NSNotFound ? record_NSString.length : posOfNextDelimiter // cause we may be at end
			let parsedValue_range = NSMakeRange(
				nextDelimiter_searchRange_location,
				pos2 - nextDelimiter_searchRange_location
			)
			let parsedValue = record_NSString.substring(with: parsedValue_range)
			//
			return parsedValue
		}
		let recipient_address = parsed_paramValueWithName("recipient_address")
		let recipient_name = parsed_paramValueWithName("recipient_name")
		let tx_payment_id = parsed_paramValueWithName("tx_payment_id")
		let tx_description = parsed_paramValueWithName("tx_description")
		let description = ParsedOARecipientDescription(
			recipient_address: recipient_address,
			recipient_name: recipient_name,
			tx_payment_id: tx_payment_id,
			tx_description: tx_description
		)
		//
		return (err_str: nil, description: description)
	}
	static func validatedOARecordsFromTXTRecordsWithOpenAliasPrefix(
		domain: String,
		records: [String],
		dnssec_used: Bool,
		secured: Bool,
		dnssec_fail_reason: String?,
		openAliasPrefix: String
	) -> (err_str: String?, validated_descriptions: [ParsedOARecipientDescription]?)
	{
		if dnssec_used == true {
			if secured == true {
				DDLog.Done("MyMoneroCore", "DNSSEC validation successful")
			} else {
				let err_str = "DNSSEC validation failed for \(domain): \(dnssec_fail_reason.debugDescription)"
				return (err_str: err_str, validated_descriptions: nil)
			}
		} else {
			DDLog.Warn("MyMoneroCore", "DNSSEC Not used")
		}
		var oaRecords = [ParsedOARecipientDescription]()
		for (_, record) in records.enumerated() {
			let (err_str, parsed_description) = MyMoneroCoreUtils.new_parsedDescriptionFromOpenAliasRecordWithOpenAliasPrefix(
				record: record,
				openAliasPrefix: openAliasPrefix
			)
			if err_str != nil {
				continue // instead of erroring, i.e. if records contains another (btc) address before the openAliasPrefix (xmr) address we're looking for
			}
			oaRecords.append(parsed_description!)
		}
		let final_oaRecords_count = oaRecords.count
		if (final_oaRecords_count == 0) {
			let err_str = "No valid OpenAlias records with prefix \(openAliasPrefix) found for: \(domain)"
			return (err_str: err_str, validated_descriptions: nil)
		}
		if (final_oaRecords_count != 1) {
			let err_str = "Multiple addresses found for given domain: \(domain)"
			return (err_str: err_str, validated_descriptions: nil)
		}
		//
		return (err_str: nil, validated_descriptions: oaRecords)
	}
}
