//
//  OrderDetails.swift
//  MyMonero
//
//  Created by Karl Buys on 2020/10/30.
//  Copyright © 2020 MyMonero. All rights reserved.
//

import UIKit
import SwiftyJSON

class OrderDetails {

	let orderDetails:[String:String] = [
		"order_id": "xmrto-wMYbse",
		"expires_at": "2020-10-30T10:11:58Z",
		"in_address": "",
		"in_currency": "",
		"in_amount": "0.3501",
		"out_currency": "",
		"out_amount": "0.0031293",
		"status": "",
		"in_amount_remaining": "0.3501",
		"out_address": "",
		"provider_name": "xmr.to",
		"provider_url": "https://xmr.to/",
		"provider_order_id": "xmrto-wMYbse"
	]
	
	required init(_ JSON: JSON) {
		for (key, value) in JSON {
			if let value = value.string {
				debugPrint(key)
				debugPrint(value)
			}
		}
	}
}
