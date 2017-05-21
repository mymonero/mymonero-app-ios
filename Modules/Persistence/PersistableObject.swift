//
//  PersistableObject.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
class PersistableObject
{
	var _id: String!
	func dictRepresentation() -> [String: Any]
	{
		var dict: [String: Any] = [:]
		dict["_id"] = self._id
		// Note: Override this method and add data you would like encrypted
		return dict
	}
	func jsonRepresentationData() -> Data
	{
		let json_Data =  try! JSONSerialization.data(
			withJSONObject: self.dictRepresentation(),
			options: []
		)
		//
		return json_Data
	}
	//
	init()
	{
	}
	required init(withDictRepresentation dictRepresentation: [String: Any])
	{
		self._id = dictRepresentation["_id"] as! String
	}
	//
	// Imperatives
	func saveToDisk()
	{
		// TODO:
	}
}
