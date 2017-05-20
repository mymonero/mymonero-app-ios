//
//  ListedObject.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import RealmSwift
//
struct ObjectDescription
{
}
typealias PersistedListedObjectDescription = ObjectDescription
//
class PersistedListedObject: Object
{
	static func realm() -> Realm
	{
		let default_fileURL = Realm.Configuration().fileURL!
		let fileURL = default_fileURL.deletingLastPathComponent().appendingPathComponent("\(self)s.realm")
		let config = Realm.Configuration(
			fileURL: fileURL
		)
		let realm = try! Realm(configuration: config)
		return realm
	}
	//
	dynamic var id = 0
	override class func primaryKey() -> String? {
		return "id"
	}
	//
	// Standing in for an initializer - because init override seems to have an issue given new RLM type names
	func setup(withDescription: PersistedListedObjectDescription)
	{ // override and implement this with your custom PersistedListedObjectDescription
		fatalError("setup(withDescription:) has not been implemented")
	}

//	override static func primaryKey() -> String?
//	{
//		return "id"
//	}
}
