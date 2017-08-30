//
//  OpenAliasResolverRequestMaker.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
// TODO: This class could stand to be improved / fleshed out a little
//
class OpenAliasResolverRequestMaker
{ // Subclass this in application code for cancellation/teardown handling 
	//
	// Properties
	var resolve_lookupHandle: DNSLookupHandle?
	//
	// Lifecycle - Deinit
	deinit
	{
		self.cancelAnyRequestFor_oaResolution() // just in case
	}
	//
	// Imperatives
	func cancelAnyRequestFor_oaResolution()
	{
		if let handle = self .resolve_lookupHandle {
			handle.cancel()
			self.resolve_lookupHandle = nil
		}
	}
}
