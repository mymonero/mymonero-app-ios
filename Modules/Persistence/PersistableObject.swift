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
	var _id: String?
	var insertedAt_date: Date?
	func collectionName() -> String
	{
		assert(false, "You must override PersistableObject/collectionName")
		return ""
	}
	func dictRepresentation() -> DocumentPersister.DocumentJSON
	{
		var dict: [String: Any] = [:]
		dict["_id"] = self._id
		if self.insertedAt_date != nil {
			dict["insertedAt_date"] = self.insertedAt_date!.timeIntervalSince1970
		}
		//
		// Note: Override this method and add data you would like encrypted – but call on super 
		return dict as DocumentPersister.DocumentJSON
	}
	//
	init()
	{ // placed here for inserts
	}
	required init?(withDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	{
		self._id = dictRepresentation["_id"] as? String
		if let json__insertedAt_date = dictRepresentation["insertedAt_date"] {
			guard let insertedAt_date_timeInterval = json__insertedAt_date as? TimeInterval else {
				assert(false, "json__insertedAt_date not a TimeInterval")
				return nil
			}
			self.insertedAt_date = Date(timeIntervalSince1970: insertedAt_date_timeInterval)
		}
	}
	//
	// Accessors - Persistence state
	var shouldInsertNotUpdate: Bool
	{
		return self._id == nil
	}
	//
	// Imperatives - Saving
	func saveToDisk() -> String? // -> err_str?
	{
		if self.shouldInsertNotUpdate == true {
			return self._saveToDisk_insert()
		}
		return self._saveToDisk_update()
	}
	func _saveToDisk_insert() -> String? // -> err_str?
	{
		assert(self._id == nil, "non-nil _id in \(#function)")
		// only generate _id here after checking shouldInsertNotUpdate since that relies on _id
		self._id = DocumentPersister.new_DocumentId() // generating a new UUID
		// and since we know this is an insertion, let's any other initial centralizable data
		self.insertedAt_date = Date()
		// and now that those values have been placed, we can generate the dictRepresentation
		let jsonDict = self.dictRepresentation()
		let (err_str, _/*insertedDocumentJSON*/) = DocumentPersister.shared().Insert(
			document: jsonDict,
			intoCollectionNamed: self.collectionName()
		)
		return err_str
	}
	func _saveToDisk_update() -> String?
	{
		assert(self._id != nil, "nil _id in \(#function)")
		let jsonDict = self.dictRepresentation()
		let (err_str, _/*updatedDocumentJSON*/) = DocumentPersister.shared().UpdateDocument(
			withId: self._id!,
			inCollectionNamed: self.collectionName(),
			withDocument: jsonDict
		)
		return err_str
	}
}
