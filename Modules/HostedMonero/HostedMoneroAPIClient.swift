//
//  HostedMoneroAPIClient.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

typealias HostedMoneroAPIClient_RequestHandle = String // TODO

struct ParsedResult_TXTRecords
{
	let records: [String]
	let dnssec_used: Bool
	let secured: Bool
	let dnssec_fail_reason: String?
}

class HostedMoneroAPIClient
{
	func TXTRecords(
		openAlias_domain: String,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: ParsedResult_TXTRecords?
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle
	{
		let err_str = ""
		let records = [String]()
		let result = ParsedResult_TXTRecords(
			records: records,
			dnssec_used: false,
			secured: false,
			dnssec_fail_reason: nil
		)
		fn(err_str, result)
		return ""
	}
}
