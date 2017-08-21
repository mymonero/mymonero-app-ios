//
//  OpenAliasResolverRequestMaker.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class OpenAliasResolverRequestMaker
{ // Subclass this
	//
	// Properties
	var resolve_requestOperation: Operation?
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
		if let requestHandle = self.resolve_requestOperation {
			requestHandle.cancel()
			self.resolve_requestOperation = nil
		}
	}
}
