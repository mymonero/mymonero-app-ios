//
//  HostedMonero_OpenAliasResolving.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
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
//
struct OpenAliasDNSLookups
{
	//
	// Types
	struct ResolvedAddressDescription
	{
		let recipient_address: String
		let recipient_name: String?
		let payment_id: MoneroPaymentID?
		let tx_description: String?
	}
	struct ValidResolvedAddressDescription
	{
		let recipient_address: MoneroAddress
		let recipient_name: String?
		let payment_id: MoneroPaymentID?
		let tx_description: String?
		//
		var dnssec_status: DNSLookup_DNSSECStatus?
	}
	//
	// Interface
	static func moneroAddressInfo(
		fromOpenAliasAddress openAliasAddress: String,
		forCurrency currency: OpenAliasAddressCurrency,
		isReachable: Bool,
		fn: @escaping (
			_ err_str: String?,
			_ validResolvedAddressDescription: ValidResolvedAddressDescription?
		) -> Void
	) -> DNSLookupHandle? // can be canceled
	{
		if OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(openAliasAddress) == false {
			let err_str = NSLocalizedString("Not an OpenAlias address", comment: "")
			assert(false, "code fault") // not expecting this
			fn(err_str, nil)
			return nil
		}
		if isReachable == false {
			let err_str = String(
				format: NSLocalizedString("Couldn't look up %@… No Internet Connection Found", comment: ""),
				openAliasAddress				
			)
			fn(err_str, nil)
			return nil
		}
		let emailNormalized_address = openAliasAddress.replacingOccurrences(of: "@", with: ".") // per OA spec
		
		
		
		//
		// TODO: look this up in settings
		let validationRequired = false
		
		
		
		
		let lookupHandle = DNSLookupHandle(
			lookupType: .TXT,
			validationRequired: validationRequired,
			forDomain: emailNormalized_address,
			fn:
			{ (lookupHandle) in
				let err_str = lookupHandle.err_str
				let recordsStrings = lookupHandle.recordsStrings
				let dnssecStatus = lookupHandle.dnssecStatus
				
				if err_str != nil {
					let returnable__err_str = String(
						format: NSLocalizedString("Couldn't look up %@… %@", comment: ""),
						openAliasAddress,
						err_str!
					)
					fn(returnable__err_str, nil)
					return
				}
				if recordsStrings!.count == 0 {
					fn(NSLocalizedString("No DNS records found during OA address lookup.", comment: ""), nil)
					return
				}
				var addressDescriptions: [ResolvedAddressDescription] = []
				for (_, recordText) in recordsStrings!.enumerated() {
					let (err_str, parsedDescription) = self.new_parsedDescription(
						fromTXTRecordString: recordText,
						forCurrency: currency
					)
					if err_str != nil {
						fn(err_str!, nil)
						return // bail
					}
					if parsedDescription == nil {
						continue // no OA info on recordRow - at least not for the requested currency - TODO? update this to return all available currencies?
					}
					addressDescriptions.append(parsedDescription!)
				}
				//
				// if DNSSEC validation required, treat as OA lookup error if status bad. otherwise, just pass dnssec status back to consumer so they can reflect it on the UI
				if validationRequired {
					guard let dnssecStatus = lookupHandle.dnssecStatus else {
						fn(NSLocalizedString("DNSSEC status not available.", comment: ""), nil)
						return // bail
					}
					switch dnssecStatus {
						case DNSLookup_DNSSECStatus_secure:
							// nothing to do - validation successful
							DDLog.Done("OpenAlias", "DNSSEC validation successful")
							break
						case DNSLookup_DNSSECStatus_unrecognized:
							assert(false)
							let err_str = NSLocalizedString("DNSSEC validation failed: Unrecognized error.", comment: "")
							fn(err_str, nil)
							return
						case DNSLookup_DNSSECStatus_insecure:
							let err_str = NSLocalizedString("DNSSEC validation failed: Chain of trust could not be built from trust anchor to response (\"Insecure\").", comment: "")
							fn(err_str, nil)
							return
						case DNSLookup_DNSSECStatus_bogus:
							let err_str = NSLocalizedString("DNSSEC validation failed: Possible expired or missing signatures (\"Bogus\").", comment: "")
							fn(err_str, nil)
							return
						case DNSLookup_DNSSECStatus_indeterminate:
							let err_str = NSLocalizedString("DNSSEC validation failed: No valid trust anchor that can be used to determine if response secure (\"Indeterminate\").", comment: "")
							fn(err_str, nil)
							return
						case DNSLookup_DNSSECStatus_undetermined:
							// TODO: pretty sure this is a bug…
//							assert(false, "Status should at least be determined by now")
							fn(NSLocalizedString("DNSSEC validation failed: Status not able to be determined", comment: ""), nil)
							return
						default:
							assert(false, "switch ought to have been exhaustive")
							fn(NSLocalizedString("Unknown error", comment: ""), nil)
							return
					}
				} else {
					if lookupHandle.dnssecStatus == nil || lookupHandle.dnssecStatus! == DNSLookup_DNSSECStatus_unrecognized {
						DDLog.Warn("OpenAlias", "DNSSEC status not available")
					}
				}				
				//
				let addressDescriptions_count = addressDescriptions.count
				if addressDescriptions_count == 0 {
					let err_str = String(
						format: NSLocalizedString("No valid OpenAlias records with prefix %@ found for %@", comment: ""),
						currency.txtRecordPrefixTokenForCurrency,
						openAliasAddress
					)
					fn(err_str, nil)
					return
				}
				if addressDescriptions_count > 1 {
					let err_str = String(
						format: NSLocalizedString("Multiple %@ target addresses found for domain %@", comment: ""),
						currency.txtRecordPrefixTokenForCurrency,
						openAliasAddress
					)
					fn(err_str, nil)
					return
				}
				//
				let resolvedAddressDescription = addressDescriptions.first!
//				DDLog.Info("OpenAlias", "resolvedAddressDescription: \(resolvedAddressDescription)")
				//
				// now verify address is decodable for currency
				assert(currency == .monero) // only one supported at the moment
				MyMoneroCore.shared.DecodeAddress(resolvedAddressDescription.recipient_address)
				{ (err_str, decodedAddressComponents) in
					if let _ = err_str {
						fn(NSLocalizedString("Domain's TXT records had OpenAlias prefix but not a valid Monero address.", comment: ""), nil)
						return
					}
					let validResolvedDescription = ValidResolvedAddressDescription(
						recipient_address: resolvedAddressDescription.recipient_address,
						recipient_name: resolvedAddressDescription.recipient_name,
						payment_id: resolvedAddressDescription.payment_id,
						tx_description: resolvedAddressDescription.tx_description,
						//
						dnssec_status: dnssecStatus
					)
					fn(nil, validResolvedDescription)
				}
			}
		)
		return lookupHandle
	}
	
	enum OpenAliasAddressCurrency: String
	{
		case monero = "xmr"
		case bitcoin = "btc"
		//
		var txtRecordPrefixTokenForCurrency: String {
			return self.rawValue
		}
	}
	static func hasValid(
		tokenInTXTRecordForCurrency currency: OpenAliasAddressCurrency,
		inRecord record: String
	) -> Bool
	{
		let oaPrefix = OpenAlias.txtRecord_oaPrefix
		let tokenForCurrency = currency.txtRecordPrefixTokenForCurrency
		let range = NSMakeRange(0, oaPrefix.count + 1 + tokenForCurrency.count + 1) // trailing +1 for space - extra validation
		let record_prefixString = (record as NSString).substring(with: range)
		let expected_prefixString = "\(oaPrefix):\(tokenForCurrency) "
		if record_prefixString != expected_prefixString {
			return false
		}
		return true
	}
	fileprivate static func new_parsedDescription(
		fromTXTRecordString recordString: String,
		forCurrency currency: OpenAliasAddressCurrency
	) -> (
		err_str: String?,
		description: ResolvedAddressDescription?
	)
	{
		let hasValidTokenForCurrency = self.hasValid(
			tokenInTXTRecordForCurrency: currency,
			inRecord: recordString
		)
		if hasValidTokenForCurrency == false { // do not treat as an error - probably is another currency like btc or some other TXT record
			return (err_str:nil, description: nil)
		}
		func parsed_paramValueWithName(_ valueName: String) -> String?
		{
			let valueName_length = valueName.count
			let record_NSString = recordString as NSString
			let record_length = record_NSString.length
			let rangeOfValueNameKeyDeclaration = record_NSString.range(of: "\(valueName)=")
			if rangeOfValueNameKeyDeclaration.location == NSNotFound { // Record does not contain param
				DDLog.Warn("OpenAlias", "\(valueName) not found in OA record.")
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
		if recipient_address == nil || recipient_address == "" {
			return (err_str: NSLocalizedString("No recipient_address found", comment: ""), description: nil)
		}
		let recipient_name = parsed_paramValueWithName("recipient_name")
		let tx_payment_id = parsed_paramValueWithName("tx_payment_id")
		let tx_description = parsed_paramValueWithName("tx_description")
		let description = ResolvedAddressDescription(
			recipient_address: recipient_address!,
			recipient_name: recipient_name,
			payment_id: tx_payment_id,
			tx_description: tx_description
		)
		//
		return (err_str: nil, description: description)
	}
}
