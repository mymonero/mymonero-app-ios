//
//  PersistedObjectListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
import RNCryptor
//
class PersistedObjectListController: DeleteEverythingRegistrant
{
	// constants
	enum Notifications_Boot: String
	{ // the raw values of Notification name enums must be globally unique, i.e. semantically specific
		case Did = "PersistedObjectListController_Notifications_Boot_Did"
		case Failed = "PersistedObjectListController_Notifications_Boot_Failed"
	}
	enum Notifications_List: String
	{
		case Updated = "PersistedObjectListController_Notifications_List_Updated"
	}
	enum Notifications_userInfoKeys: String
	{
		case err_str = "err_str"
	}
	//
	// inputs
	var listedObjectType: ListedObject.Type!
	var documentCollectionName: DocumentPersister.CollectionName!
	var passwordController = PasswordController.shared
	//
	var records = [ListedObject]()
	// runtime
	var hasBooted = false
	//
	//
	// Lifecycle - Setup
	//
	init(listedObjectType type: ListedObject.Type)
	{
		self.listedObjectType = type
		self.documentCollectionName = "\(type)" as DocumentPersister.CollectionName
		self.setup()
	}
	func setup()
	{
		self.setup_startObserving()
		self.setup_fetchAndReconstituteExistingRecords()
	}
	func setup_startObserving()
	{
		self.startObserving_passwordController()
	}
	func startObserving_passwordController()
	{
		self.passwordController.AddRegistrantForDeleteEverything(self)
		//
//		const controller = self.context.passwordController
//			{ // EventName_ChangedPassword
//				if (self._passwordController_EventName_ChangedPassword_listenerFn !== null && typeof self._passwordController_EventName_ChangedPassword_listenerFn !== 'undefined') {
//					throw "self._passwordController_EventName_ChangedPassword_listenerFn not nil in " + self.constructor.name
//				}
//				self._passwordController_EventName_ChangedPassword_listenerFn = function()
//					{
//						self._passwordController_EventName_ChangedPassword()
//				}
//				controller.on(
//					controller.EventName_ChangedPassword(),
//					self._passwordController_EventName_ChangedPassword_listenerFn
//				)
//		}
//		{ // EventName_willDeconstructBootedStateAndClearPassword
//			if (self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn !== null && typeof self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn !== 'undefined') {
//				throw "self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn not nil in " + self.constructor.name
//			}
//			self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn = function()
//				{
//					self._passwordController_EventName_willDeconstructBootedStateAndClearPassword()
//			}
//			controller.on(
//				controller.EventName_willDeconstructBootedStateAndClearPassword(),
//				self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn
//			)
//		}
//			{ // EventName_didDeconstructBootedStateAndClearPassword
//				if (self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn !== null && typeof self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn !== 'undefined') {
//					throw "self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn not nil in " + self.constructor.name
//				}
//				self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn = function()
//					{
//						self._passwordController_EventName_didDeconstructBootedStateAndClearPassword()
//				}
//				controller.on(
//					controller.EventName_didDeconstructBootedStateAndClearPassword(),
//					self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn
//				)
//		}
	}
	func setup_fetchAndReconstituteExistingRecords()
	{
		records = [ListedObject]() // zeroing
		//
		let (err_str, ids) = self._new_idsOfPersistedRecords()
		if let err_str = err_str {
			self._setup_didFailToBoot(withErrStr: err_str)
			return
		}
		if ids!.count == 0 { // we must check before requesting password so pw entry not enforced when not necessary
			self._setup_didBoot()
			return
		}
		self.passwordController.OncePasswordObtained( // this will 'block' until we have access to the pw
			{ (obtainedPasswordString, passwordType) in
				__proceedTo_loadAndBootAllExtantRecords(withPassword: obtainedPasswordString)
			}
		)
		func __proceedTo_loadAndBootAllExtantRecords(withPassword password: String)
		{ // now we actually want to load the ids again after we have the password - or we'll have stale ids on having deleted all data in the app and subsequently adding a record!
			let (err_str, ids) = self._new_idsOfPersistedRecords()
			if let err_str = err_str {
				self._setup_didFailToBoot(withErrStr: err_str)
				return
			}
			if ids!.count == 0 { // we must check before requesting password so pw entry not enforced when not necessary
				self._setup_didBoot()
				return
			}
			let (load__err_str, documentsData) = DocumentPersister.shared().DocumentsData(
				withIds: ids!,
				inCollectionNamed: self.documentCollectionName
			)
			if load__err_str != nil {
				self._setup_didFailToBoot(withErrStr: load__err_str!)
				return
			}
			if documentsData!.count == 0 { // just in case
				self._setup_didBoot()
				return
			}
			if let load__err_str = load__err_str {
				self._setup_didFailToBoot(withErrStr: load__err_str)
				return
			}
			for (_, encrypted_documentData) in documentsData!.enumerated() {
				var plaintext_documentData: Data
				do {
					plaintext_documentData = try RNCryptor.decrypt(
						data: encrypted_documentData,
						withPassword: password
					)
				} catch let e {
					self._setup_didFailToBoot(withErrStr: e.localizedDescription)
					return
				}
				var plaintext_documentJSON: [String: Any]
				do {
					plaintext_documentJSON = try JSONSerialization.jsonObject(with: plaintext_documentData) as! [String: Any]
				} catch let e {
					self._setup_didFailToBoot(withErrStr: e.localizedDescription)
					return
				}
				var listedObjectInstance: ListedObject?
				do {
					listedObjectInstance = try self.listedObjectType.init(withPlaintextDictRepresentation: plaintext_documentJSON)
				} catch let e {
					self._setup_didFailToBoot(withErrStr: e.localizedDescription)
					return
				}
				self.records.append(listedObjectInstance!)
				self.overridable_booting_didReconstitute(listedObjectInstance: listedObjectInstance!)
			}
			self.overridable_sortRecords()
			self._setup_didBoot()
			self._listUpdated_records() // post notification after booting, i.e. at runtime
		}
	}
	func _setup_didBoot()
	{
		NSLog("✅ \(self) booted.")
		self.hasBooted = true // all done!
		DispatchQueue.main.async { // on next tick to avoid instantiator missing this
			NotificationCenter.default.post(name: Notification.Name(Notifications_Boot.Did.rawValue), object: self)
		}
	}
	func _setup_didFailToBoot(withErrStr err_str: String)
	{
		NSLog("❌ \(self) failed to boot with err: \(err_str)")
		DispatchQueue.main.async { // on next tick to avoid instantiator missing this
			let userInfo: [String: Any] =
			[
				Notifications_userInfoKeys.err_str.rawValue: err_str
			]
			NotificationCenter.default.post(
				name: Notification.Name(Notifications_Boot.Failed.rawValue),
				object: self,
				userInfo: userInfo
			)
		}
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		self._stopObserving_passwordController()
	}
	func _stopObserving_passwordController()
	{
//		const controller = self.context.passwordController
//			{ // EventName_ChangedPassword
//				if (typeof self._passwordController_EventName_ChangedPassword_listenerFn === 'undefined' || self._passwordController_EventName_ChangedPassword_listenerFn === null) {
//					throw "self._passwordController_EventName_ChangedPassword_listenerFn undefined"
//				}
//				controller.removeListener(
//					controller.EventName_ChangedPassword(),
//					self._passwordController_EventName_ChangedPassword_listenerFn
//				)
//				self._passwordController_EventName_ChangedPassword_listenerFn = null
//		}
//		{ // EventName_willDeconstructBootedStateAndClearPassword
//			if (typeof self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn === 'undefined' || self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn === null) {
//				throw "self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn undefined"
//			}
//			controller.removeListener(
//				controller.EventName_willDeconstructBootedStateAndClearPassword(),
//				self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn
//			)
//			self._passwordController_EventName_willDeconstructBootedStateAndClearPassword_listenerFn = null
//		}
//			{ // EventName_didDeconstructBootedStateAndClearPassword
//				if (typeof self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn === 'undefined' || self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn === null) {
//					throw "self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn undefined"
//				}
//				controller.removeListener(
//					controller.EventName_didDeconstructBootedStateAndClearPassword(),
//					self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn
//				)
//				self._passwordController_EventName_didDeconstructBootedStateAndClearPassword_listenerFn = null
//		}
	}
	//
	// Accessors - Overridable
	func overridable_shouldSortOnEveryRecordAdditionAtRuntime() -> Bool
	{
		return false // default
	}
	//
	// Runtime - Accessors - Private - Lookups - Documents & instances
	func _new_idsOfPersistedRecords() -> (err_str: String?, ids: [DocumentPersister.DocumentId]?)
	{
		return DocumentPersister.shared().IdsOfAllDocuments(inCollectionNamed: self.documentCollectionName)
	}
	//
	//
	// Imperatives - Overridable
	func overridable_sortRecords() {}

	//
	// Internal - Imperatives - Queue entry
	func _dispatchAsync_listUpdated_records()
	{
		DispatchQueue.main.async {
			self._listUpdated_records()
		}
	}
	//
	// Delegation
	func overridable_booting_didReconstitute(listedObjectInstance: ListedObject) {} // somewhat intentionally ignores errors and values which would be returned asynchronously, e.g. by way of a callback/block
	func _atRuntime__record_wasSuccessfullySetUp(_ listedObject: ListedObject)
	{
		self.records.insert(listedObject, at: 0) // so we add it to the top
//		self.overridable_startObserving_record(recordInstance) // TODO
		//
		if self.overridable_shouldSortOnEveryRecordAdditionAtRuntime() == true {
			self.overridable_sortRecords()
		}
		self._dispatchAsync_listUpdated_records()
		// ^-- so control can be passed back before all observers of notification handle their work - which is done synchronously
	}
	func _listUpdated_records()
	{
		NotificationCenter.default.post(
			name: NSNotification.Name(Notifications_List.Updated.rawValue),
			object: self
		)
	}
}
