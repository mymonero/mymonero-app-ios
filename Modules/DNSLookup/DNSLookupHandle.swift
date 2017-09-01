//
//  DNSLookupHandle.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class DNSLookupHandle: NSObject, DNSLookupEventDelegate
{
	//
	// Class - Overrides for NSObject conformance
	override func isEqual(_ object: Any?) -> Bool {
		return false // for now
	}
	//
	// Class - Constants / Types
	enum LookupType
	{
		case TXT
	}
	//
	// Instance - Properties - Initial
	var domain: String
	var fn: ( // to be called on lookup completion
		_ lookupHandle: DNSLookupHandle
	) -> Void
	//
	// Instance - Properties - Runtime
	var lookup: DNSLookup!
	//
	// Instance - Properties - Final - Access these when your `fn` is called
	var err_str: String?
	var recordsStrings: [String]?
	var dnssecStatus: DNSLookup_DNSSECStatus?
	//
	// Instance - Lifecycle - Init
	init(
		lookupType: LookupType = .TXT,
		validationRequired: Bool = false,
		forDomain domain: String,
		fn: @escaping (
			_ lookupHandle: DNSLookupHandle
		) -> Void
	)
	{
		assert(lookupType == .TXT)
		self.domain = domain
		self.fn = fn
		//
		super.init()
		//
		let isValidationOptional = !validationRequired
		let lookup = DNSLookup.init(
			address: domain,
			isValidationOptional: isValidationOptional
		)
		lookup.delegate = self
		self.lookup = lookup
		//
		let didStart = self.lookup.start()
		if didStart == false {
			DDLog.Warn("DNSLookup/DNSLookupHandle", "Could not start DNSLookup instance.");
			return;
		}

	}
	//
	// Lifecycle - Deinit
	deinit
	{
		DDLog.TearingDown("DNSLookup", "Tearing down a \(type(of: self))")
		//
		self.stop() // if necessary
	}
	func stop()
	{
		self.teardown_dnsLookup()
	}
	func cancel()
	{
		self.stop()
	}
	func teardown_dnsLookup()
	{
		self.lookup = nil; // free / release
	}
	//
	// Delegation - Internal - Final states
	// … either:
	func _didReceiveTXTLookup(
		recordsStrings: [String],
		dnssecStatus: DNSLookup_DNSSECStatus
	)
	{
		self.recordsStrings = recordsStrings
		self.dnssecStatus = dnssecStatus
		//
		self.__didGetFinalState()
	}
	// … or:
	func _didErrorOnTXTLookup(
		error: NSError
	)
	{
		var err_str: String?
		do { // to derive…
			let domain = error.domain
			if error.domain != NetService.errorDomain {
				assert(false, "Unexpected error domain from DNSLookup \(domain)");
				err_str = NSLocalizedString("Unexpected error domain from DNS lookup", comment: "")
			} else {
				let errorCode: NSInteger = error.code
				switch errorCode {
					case kDNSServiceErr_Timeout:
						DDLog.Warn("DNSLookup", "Timed out.")
						break
					case kDNSServiceErr_NoSuchRecord:
						err_str = NSLocalizedString("No such DNS record found", comment: "")
						break
					case kDNSServiceErr_NoSuchName:
						err_str = NSLocalizedString("No such DNS name found", comment: "")
						assert(false) // never seen in testing yet, so just for dev visibility…
						break
					case kDNSServiceErr_NoError:
						assert(false, "Code fault")
						break
					default:
						err_str = String(
							format: NSLocalizedString("Unrecognized DNS lookup error. Code %d", comment: ""),
							errorCode
						)
						assert(false, "Unhandled error code case")
						break;
				}
			}
		}
		DDLog.Error("DNSLookup", "_didErrorOnTXTLookup error: \(error), err_str: \(err_str.debugDescription)")
		self.err_str = err_str
		self.__didGetFinalState()
	}
	//
	func __didGetFinalState()
	{
		DispatchQueue.main.async
		{
			self.fn(self)
		}
	}
	//
	// Delegation - Protocols - DNSLookupEventDelegate
	func dnssdServiceWillResolve(
		_ lookup: DNSLookup
	)
	{
	}
	func dnssdServiceFailedToResolveWithError(
		_ lookup: DNSLookup
	)
	{
		// handled in …DidStop with .error nil check
	}
	func dnssdServiceDidStop(
		_ lookup: DNSLookup
	)
	{
		// first, take copies of all final values before freeing DNSLookup instance
		let error = lookup.error
		let recordsStrings = lookup.recordsStrings
		let dnssecStatus = lookup.dnssecStatus
		do {
			self.teardown_dnsLookup()
		}
		if error != nil {
			self._didErrorOnTXTLookup(
				error: error! as NSError
			)
			return
		}
		self._didReceiveTXTLookup(
			recordsStrings: recordsStrings as! [String],
			dnssecStatus: dnssecStatus
		)
	}
}
