//
//  DNSLookups.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import dnssd

class DNSLookups
{
	//
	// Interface - Shared - Instance
	static let shared = DNSLookups()
	//
	// Interface - TXT records
	@discardableResult
	func TXTRecords(
		forDomain domain: String,
		_ fn: @escaping (
			_ err_str: String?,
			_ recordRows: [TXTRecordRow]?
		) -> Void
	) -> BlockOperation
	{
		let operation = BlockOperation
		{ [unowned self] in
			let (err_str, recordRows) = self._blocking_TXTRecords(
				forDomain: domain
			)
			DispatchQueue.main.async { // so as not to execute fn contents on operationQueue
				fn(err_str, recordRows)
			}
		}
		self.operationQueue.addOperation(operation)
		//
		return operation
	}
	struct TXTRecordRow
	{
		var recordText: String
		//
		var DNSSEC_isFlagSet_statusAvailable: Bool
		var DNSSEC_isFlagSet_validateOptional: Bool
		var DNSSEC_isFlagSet_secure: Bool
		var DNSSEC_isFlagSet_insecure: Bool
		var DNSSEC_isFlagSet_bogus: Bool // "If the response cannot be verified to be secure due to expired signatures, missing signatures etc., then the results are considered to be bogus."
		var DNSSEC_isFlagSet_indeterminate: Bool // "There is no valid trust anchor that can be used to determine whether a response is secure or not."
	}
	//
	// Internal - Properties
	fileprivate let operationQueue = OperationQueue()
	//
	// Internal - Shared - Accessors
	fileprivate static func isSet(
		flag: Int/*actual type of flag so casting not necessary*/,
		onFlags flags: DNSServiceFlags
	) -> Bool
	{
		return Int(flags) & flag > 0
	}
	//
	// Internal - TXTRecords
	fileprivate typealias __TXTRecords_DNSLookupRecordRowHandler = (
		_ err_str: String?,
		_ hasMoreComing: Bool,
		_ recordRow: TXTRecordRow?
	) -> Void
	fileprivate func _blocking_TXTRecords(forDomain domainName: String) -> (
		err_str: String?,
		recordRows: [TXTRecordRow]?
	)
	{
		
		let callback: DNSServiceQueryRecordReply =
		{ (sdRef, flags, interfaceIndex, errorCode, fullname, rrtype, rrclass, rdlen, rdata, ttl, context) in
			//
			// dereference completionHandler from pointer since we can't directly capture it in a C callback
			let pointerTo_completionHandler = context?.assumingMemoryBound(
				to: __TXTRecords_DNSLookupRecordRowHandler.self
			)
			let lookupHandler = pointerTo_completionHandler!.pointee
			//
			let hasMoreComing = DNSLookups.isSet(flag: kDNSServiceFlagsMoreComing, onFlags: flags)
			//
			let errorType_Int = Int(errorCode)
			if errorType_Int != kDNSServiceErr_NoError {
				var err_str: String?
				switch errorType_Int {
					case kDNSServiceErr_NoSuchRecord:
						err_str = NSLocalizedString("No DNS record found", comment: "")
					
					case kDNSServiceErr_NoSuchName:
						err_str = NSLocalizedString("No DNS name found", comment: "")
						assert(false) // never seen in testing yet
					
					case kDNSServiceErr_NoError:
						assert(false, "Code fault")
					
					default:
						err_str = String(
							format: NSLocalizedString("Unrecognized DNS lookup error. Code %d", comment: ""),
							errorType_Int
						)
						assert(false) // since we've not encountered this yet and will need to handle it
				}
				assert(hasMoreComing == false)
				lookupHandler(err_str!, false, nil)
				return
			}
			//
			guard let txtPtr = rdata?.assumingMemoryBound(to: UInt8.self) else {
				assert(false)
				//				completionHandler(nil) // this was in the original example code
				// should this be returned as an error?
				return
			}
			// advancing pointer by 1 to skip bad character at beginning of record
			let recordText = String(cString: txtPtr.advanced(by: 1))
			if recordText == "" {
				assert(hasMoreComing == false) // just b/c this is what we have seen so far
				// TODO: why does this appear sometimes?
				return
			}
			let recordRow = TXTRecordRow(
				recordText: recordText,
				//
				DNSSEC_isFlagSet_statusAvailable: DNSLookups.isSet(flag: kDNSServiceFlagsValidate, onFlags: flags),
				DNSSEC_isFlagSet_validateOptional: DNSLookups.isSet(flag: kDNSServiceFlagsValidateOptional, onFlags: flags),
				DNSSEC_isFlagSet_secure: DNSLookups.isSet(flag: kDNSServiceFlagsSecure, onFlags: flags),
				DNSSEC_isFlagSet_insecure: DNSLookups.isSet(flag: kDNSServiceFlagsInsecure, onFlags: flags),
				DNSSEC_isFlagSet_bogus: DNSLookups.isSet(flag: kDNSServiceFlagsBogus, onFlags: flags),
				DNSSEC_isFlagSet_indeterminate: DNSLookups.isSet(flag: kDNSServiceFlagsIndeterminate, onFlags: flags)
			)
			lookupHandler(nil, hasMoreComing, recordRow)
		}
		//
		let serviceRef: UnsafeMutablePointer<DNSServiceRef?> = UnsafeMutablePointer.allocate(
			capacity: MemoryLayout<DNSServiceRef>.size // original code's comment: "MemoryLayout<T>.size can give us the necessary size of the struct to allocate"
		) //  A pointer to an uninitialized DNSServiceRef. If the call succeeds then it initializes the DNSServiceRef, returns kDNSServiceErr_NoError and the query operation will run indefinitely until the client terminates it by passing this DNSServiceRef to DNSServiceRefDeallocate()
		//
		// passing completionHandler as the context object to the callback so that there's a way to pass the record result back to the caller
		//
		var serviceFlags: DNSServiceFlags = 0
		serviceFlags |= DNSServiceFlags(kDNSServiceFlagsValidate)
		serviceFlags |= DNSServiceFlags(kDNSServiceFlagsReturnIntermediates) // must set this in order to receive errors, including validation problems (must handle invalid and non-existent domains)
		//
		var recordRows: [TXTRecordRow] = []
		var received__err_str: String?
		// v-- lookup handler needs to be mutable to be used as inout param
		var mutable_lookupResultReceiptHandler: __TXTRecords_DNSLookupRecordRowHandler =
		{ (err_str, hasMoreComing, recordRow) in
			if err_str != nil {
				DDLog.Error("OpenAlias.DNSLookups", "Has errored")
				assert(hasMoreComing == false)
				assert(received__err_str == nil) // in case the callback is called multiple times…… maybe we should just bail immediately to ignore successive err_strs instead of throwing via the assert
				received__err_str = err_str!
				return
			}
			recordRows.append(recordRow!)
		}
		do {
			let errorType = DNSServiceQueryRecord(
				serviceRef,
				serviceFlags,
				0,
				domainName,
				UInt16(kDNSServiceType_TXT),
				UInt16(kDNSServiceClass_IN),
				callback,
				&mutable_lookupResultReceiptHandler
			)
			let errorType_Int = Int(errorType)
			if errorType_Int != kDNSServiceErr_NoError {
				DDLog.Error("OpenAlias.DNSLookups", "had error")
				if errorType_Int == kDNSServiceErr_NoSuchName {
					DDLog.Info("OpenAlias.DNSLookups", "no name!")
				}
				DDLog.Info("OpenAlias.DNSLookups", "queryRecord: errorType: \(errorType)")
				assert(false) // for dev visibility - verify case
			}
		}
		let serviceRef_pointee = serviceRef.pointee
		do {
			let errorType = DNSServiceProcessResult(serviceRef_pointee) // "Read a reply from the daemon, calling the appropriate application callback. This call will block until the daemon's response is received"
			let errorType_Int = Int(errorType)
			if errorType_Int != kDNSServiceErr_NoError {
				DDLog.Error("OpenAlias.DNSLookups", "had error")
				if errorType_Int == kDNSServiceErr_NoSuchName {
					DDLog.Info("OpenAlias.DNSLookups", "no name!")
				}
				DDLog.Info("OpenAlias.DNSLookups", "processResult: errorType: \(errorType)")
				assert(false) // for dev visibility - verify case
			}
		}
		DNSServiceRefDeallocate(serviceRef_pointee)
		//
		return (received__err_str, recordRows)
	}
}
