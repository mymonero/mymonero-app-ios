//
//  ExchangeFunctions.swift
//  MyMonero
//
//  Created by Karl Buys on 2020/10/28.
//  Copyright © 2020 MyMonero. All rights reserved.
//

import Foundation
import Alamofire

class ExchangeFunctions
{
	private let apiUrl = "https://api.mymonero.com:8443/cx/get_info"
	
	public func getInfo() {
		let params = ["in_currency": "XMR", "out_currency": "BTC"]
		Alamofire.request(apiUrl, method: .post).responseJSON {
			response in debugPrint(response)
			// add error handlers
		}
	}
}
