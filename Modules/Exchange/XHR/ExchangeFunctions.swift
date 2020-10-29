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
	
	public func getInfo(completionHandler: NSDictionary) {
		
	}
	
	private func _getInfo() -> NSDictionary {
		let params = ["in_currency": "XMR", "out_currency": "BTC"]
		var JSON: NSDictionary
		Alamofire.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default, completion: returnData)
			.responseJSON {
				response in response
				var success = false
				if let status = response.response?.statusCode {
					switch(status){
					case 201:
						print("example success")
					default:
						print("error with response status: \(status)")
					}
				};
				
				
				
				if let result = response.result.value {
					JSON = result as! NSDictionary
					debugPrint(JSON);
					switch response.result {
						case .success(let value as NSDictionary):
							completion(.success(value))

						case .failure(let error):
							completion(.failure(error))

						default:
							fatalError("received non-dictionary JSON response")
					}
				}
			
			debugPrint("We're here")
			debugPrint(response.result)
			// add error handlers
		}
		return JSON
	}
}
