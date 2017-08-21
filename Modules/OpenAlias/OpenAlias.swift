//
//  OpenAlias.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

struct OpenAlias
{
	//
	static let txtRecord_oaPrefix = "oa1"
	//
	//
	static func containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(_ address: String) -> Bool
	{
		if address.range(of: ".") != nil { // assumed to be an OA address as XMR addresses do not have periods, and OA addrs must
			return true
		}
		return false
	}
}
