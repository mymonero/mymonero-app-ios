//
//  DNSLookupHandle.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/19/17.
//  Copyright (c) 2014-2017, MyMonero.com
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
