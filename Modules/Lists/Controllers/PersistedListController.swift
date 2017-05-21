//
//  PersistedListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
//
class PersistedListController
{
	// inputs
	var listedObjectType: ListedObject.Type!
	var documentCollectionName: DocumentPersister.CollectionName!
	//
	var results = [ListedObject]()
	// runtime
	//
	// Lifecycle - Setup
	init(listedObjectType type: ListedObject.Type)
	{
		self.listedObjectType = type
		self.documentCollectionName = "\(type)" as DocumentPersister.CollectionName
		self.setup()
	}
	func setup()
	{
		let (err_str, ids) = DocumentPersister.shared().IdsOfAllDocuments(inCollectionNamed: self.documentCollectionName)
		NSLog("err_str \(err_str.debugDescription)")
		NSLog("\(self.listedObjectType!) ids \(ids.debugDescription)")
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
	}
	//
	//
	// Accessors
	//
	
	//
	//
	// Imperatives - Loading
	//
	func reloadData()
	{
	}
	//
	//
	// Imperatives - Insertions
	//
	func InsertOne(
		withInitDescription initDescription: ListedObjectInsertDescription,
		_ failed: @escaping (Error?) -> Void
	)
	{
		if Thread.isMainThread { // realm was created on main thread
			DispatchQueue.main.async
			{
				self.InsertOne(withInitDescription: initDescription, failed)
			}
			return
		}
		let item = self.listedObjectType.new(withInsertDescription: initDescription)
		self.results.insert(item, at: 0)
		// TODO: notify that did insert
	}
	//
	// Delegation
}
