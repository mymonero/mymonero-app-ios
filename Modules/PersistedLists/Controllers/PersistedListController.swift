//
//  PersistedListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
import RealmSwift
//
class PersistedListController
{
	// inputs
	var listedObjectType: PersistedListedObject.Type
	// initial
	var realm: Realm! // cache of default realm
	var results: Results<PersistedListedObject>!
	var results_notificationsToken: NotificationToken!
	// runtime
	//
	// Lifecycle - Setup
	init(listedObjectType type: PersistedListedObject.Type)
	{
		self.listedObjectType = type
		self.setup()
	}
	func setup()
	{
		self.realm = self.listedObjectType.realm()
		self.results = self.realm.objects(self.listedObjectType)
		self.results_notificationsToken = self.results?.addNotificationBlock(
			{ (changes: RealmCollectionChange) in
				NSLog("\(self) received changes: \(changes)")
				// .insertions
				// .deletions
				// .modifications
			}
		)
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		self.results_notificationsToken.stop()
		self.results_notificationsToken = nil
	}
	//
	// Accessors
	//
	// Imperatives
	func InsertOne(
		withInstanceDescription instanceDescription: PersistedListedObjectDescription,
		_ failed: @escaping (Error?) -> Void
	)
	{
		if Thread.isMainThread { // realm was created on main thread
			DispatchQueue.main.async
			{
				self.InsertOne(withInstanceDescription: instanceDescription, failed)
			}
			return
		}
		let item = self.listedObjectType.init()
		item.setup(withDescription: instanceDescription)
		do {
			try realm.write {
				realm.add(item)
			}
		} catch let(e) {
			failed(e)
		}
	}

	//
	// Delegation
}
