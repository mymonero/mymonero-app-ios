//
//  PersistedObjectListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright (c) 2014-2019, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
import Foundation
import RNCryptor
//
class PersistedObjectListController: DeleteEverythingRegistrant, ChangePasswordRegistrant
{
	// constants
	enum Notifications_Boot: String
	{ // the raw values of Notification name enums must be globally unique, i.e. semantically specific
		case did = "PersistedObjectListController_Notifications_Boot_Did"
		case failed = "PersistedObjectListController_Notifications_Boot_Failed"
		//
		var notificationName: NSNotification.Name { return NSNotification.Name(self.rawValue) }
	}
	enum Notifications_List: String
	{
		case updated = "PersistedObjectListController_Notifications_List_Updated"
		//
		var notificationName: NSNotification.Name { return NSNotification.Name(self.rawValue) }
	}
	//
	// Properties - Initializing inputs and constants
	var listedObjectType: PersistableObject.Type!
	var instanceUUID = UUID()
	func identifier() -> String { // satisfy DeleteEverythingRegistrant for isEqual
		return self.instanceUUID.uuidString
	}
	var passwordController = PasswordController.shared
	//
	var records = [PersistableObject]()
	// Properties - Runtime
	var hasBooted = false // can be set from true back to false
	var __blocksWaitingForBootToExecute: [() -> Void]?
	//
	//
	// Lifecycle - Init
	//
	init(listedObjectType type: PersistableObject.Type)
	{
		self.listedObjectType = type
		self.setup()
	}
	func setup()
	{
		self.setup_startObserving()
		self.setup_tryToBoot()
	}
	func setup_startObserving()
	{
		self.startObserving_passwordController()
	}
	func setup_tryToBoot()
	{
		self.overridable_deferBootUntil
		{ [weak self] (err) in
			guard let thisSelf = self else {
				return
			}
			if err != nil {
				fatalError(err!) // necessary?
			}
			thisSelf.setup_fetchAndReconstituteExistingRecords()
		}
	}
	func overridable_deferBootUntil(_ fn: @escaping (_ err: String?) -> Void)
	{
		fn(nil) // make sure to call this
	}
	func startObserving_passwordController()
	{
		self.passwordController.addRegistrantForDeleteEverything(self)
		self.passwordController.addRegistrantForChangePassword(self)
		//
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(PasswordController_willDeconstructBootedStateAndClearPassword),
			name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(PasswordController_didDeconstructBootedStateAndClearPassword),
			name: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared
		)
	}
	func setup_fetchAndReconstituteExistingRecords()
	{
		records = [PersistableObject]() // zeroing
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
		self.passwordController.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
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
			let (load__err_str, documentsData) = DocumentPersister.shared.DocumentsData(
				withIds: ids!,
				inCollectionNamed: self.listedObjectType.collectionName()
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
			for (_, encrypted_base64Encoded_documentData) in documentsData!.enumerated() {
				let encrypted_binary_documentData = Data(
					base64Encoded: encrypted_base64Encoded_documentData
				)! // must base64-decode data for portability
				var plaintext_documentData: Data
				do {
					plaintext_documentData = try RNCryptor.decrypt(
						data: encrypted_binary_documentData,
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
				var listedObjectInstance: PersistableObject?
				do {
					listedObjectInstance = try self.listedObjectType.init(withPlaintextDictRepresentation: plaintext_documentJSON)
				} catch let e {
					self._setup_didFailToBoot(withErrStr: e.localizedDescription)
					return
				}
				self.records.append(listedObjectInstance!)
				self.overridable_booting_didReconstitute(listedObjectInstance: listedObjectInstance!)
			}
			self._setup_didBoot()
		}
	}
	func _setup_didBoot()
	{
//		DDLog.Done("Lists", "\(self) booted.")
		self.overridable_finalizeAndSortRecords() // finalize on every boot - so that overriders can opt to do CRUD even with 0 extant records
		self.hasBooted = true // all done!
		self._callAndFlushAllBlocksWaitingForBootToExecute() // after hasBooted=true
		DispatchQueue.main.async
		{ [weak self] in // on next tick to avoid instantiator missing this
			guard let thisSelf = self else {
				return
			}
			NotificationCenter.default.post(name: Notifications_Boot.did.notificationName, object: self)
			thisSelf._listUpdated_records() // notify every boot, after did-boot notification

		}
	}
	func _setup_didFailToBoot(withErrStr err_str: String)
	{
		DDLog.Error("Lists", "\(self) failed to boot with err: \(err_str)")
		DispatchQueue.main.async
		{ [unowned self] in // on next tick to avoid instantiator missing this
			NotificationCenter.default.post(
				name: Notifications_Boot.failed.notificationName,
				object: self,
				userInfo: nil
			)
		}
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.tearDown()
	}
	func tearDown()
	{ // overridable but call on super obvs
		self.stopObserving()
	}
	func stopObserving()
	{ // overridable but call on super obvs
		self._stopObserving_passwordController()
	}
	func _stopObserving_passwordController()
	{
		self.passwordController.removeRegistrantForDeleteEverything(self)
		self.passwordController.removeRegistrantForChangePassword(self)
		//
		NotificationCenter.default.removeObserver(
			self,
			name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared
		)
		NotificationCenter.default.removeObserver(
			self,
			name: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared
		)
	}
	//
	// Accessors - Overridable
	func overridable_shouldSortOnEveryRecordAdditionAtRuntime() -> Bool
	{
		return false // default
	}
	var overridable_wantsRecordsAppendedNotPrepended: Bool {
		return false // default
	}
	//
	// Runtime - Accessors - Private - Lookups - Documents & instances
	func _new_idsOfPersistedRecords() -> (err_str: String?, ids: [DocumentPersister.DocumentId]?)
	{
		return DocumentPersister.shared.IdsOfAllDocuments(inCollectionNamed: self.listedObjectType.collectionName())
	}
	//
	// Imperatives - Overridable
	func overridable_finalizeAndSortRecords() {}
	//
	// Imperatives - Deferring execution
	// NOTE: onceBooted() exists because waiting for a password to be entered by the user must be asynchronous
	func onceBooted(
		_ fn: @escaping (() -> Void)
	) {
		if self.hasBooted == true {
			fn()
			return
		}
		if self.__blocksWaitingForBootToExecute == nil {
			self.__blocksWaitingForBootToExecute = []
		}
		self.__blocksWaitingForBootToExecute!.append(fn)
	}
	func _callAndFlushAllBlocksWaitingForBootToExecute()
	{
		if self.__blocksWaitingForBootToExecute == nil {
			return
		}
		let blocks = self.__blocksWaitingForBootToExecute!
		self.__blocksWaitingForBootToExecute = nil
		for (_, block) in blocks.enumerated() {
			block()
		}
	}
	//
	// Imperatives - Delete
	func givenBooted_delete(listedObject object: PersistableObject) -> String?
	{
		assert(self.hasBooted)
		if self.hasBooted == false {
			return "Code fault"
		}
		let err_str = object.delete()
		if err_str == nil { // remove / release
			self._removeFromList(object)
		}
		return err_str
	}
	func givenBooted_delete_noListUpdatedNotify(listedObject object: PersistableObject) -> String?
	{
		assert(self.hasBooted)
		if self.hasBooted == false {
			return "Code fault"
		}
		let err_str = object.delete()
		if err_str == nil { // remove / release
			self._removeFromList_noListUpdatedNotify(object)
		}
		return err_str
	}
	func _removeFromList(_ object: PersistableObject)
	{
		self._removeFromList_noListUpdatedNotify(object)
		self._listUpdated_records(updatedRecord: object)
	}
	func _removeFromList_noListUpdatedNotify(_ object: PersistableObject)
	{
		// self.stopObserving(record: record) // if observation added later…
		let index = self.records.index(where: { (record) -> Bool in
			record._id == object._id
		})!
		self.records.remove(at: index)
	}
	//
	// Delegation
	func overridable_booting_didReconstitute(listedObjectInstance: PersistableObject) {} // somewhat intentionally ignores errors and values which would be returned asynchronously, e.g. by way of a callback/block
	func _atRuntime__record_wasSuccessfullySetUp(_ listedObject: PersistableObject)
	{
		self._atRuntime__record_wasSuccessfullySetUp_noSortNoListUpdated(listedObject)
		if self.overridable_shouldSortOnEveryRecordAdditionAtRuntime() == true { // this is no longer actually used by anything
			self.overridable_finalizeAndSortRecords()
		}
		self.__dispatchAsync_listUpdated_records(updatedRecord: listedObject)
		// ^-- so control can be passed back before all observers of notification handle their work - which is done synchronously
	}
	func _atRuntime__record_wasSuccessfullySetUp_noSortNoListUpdated(
		_ listedObject: PersistableObject
	) {
		if self.overridable_wantsRecordsAppendedNotPrepended {
			self.records.append(listedObject)
		} else {
			self.records.insert(listedObject, at: 0) // so we add it to the top
		}
//		self.overridable_startObserving(record: recordInstance) // TODO if necessary - but shouldn't be at the moment - if implemented, be sure to add corresponding stopObserving in _removeFromList_noListUpdatedNotify
	}
	//
	func _listUpdated_records(
		updatedRecord record: PersistableObject? = nil // no one's actually looking for this in Notifications_List.updated userInfo at present
	) {
		NotificationCenter.default.post(name: Notifications_List.updated.notificationName, object: self, userInfo: nil)
	}
	func __dispatchAsync_listUpdated_records(updatedRecord record: PersistableObject? = nil)
	{
		DispatchQueue.main.async
		{ [weak self] in
			guard let thisSelf = self else {
				return
			}
			thisSelf._listUpdated_records(updatedRecord: record)
		}
	}
	//
	// Protocol - DeleteEverythingRegistrant
	func passwordController_DeleteEverything() -> String?
	{
		let (err_str, _) = DocumentPersister.shared.RemoveAllDocuments(inCollectionNamed: self.listedObjectType.collectionName())
		if err_str != nil {
			DDLog.Error("Lists", "Error while deleting everything: \(err_str!.debugDescription)")
		} else {
			DDLog.Deleting("Lists", "Deleted all \(self.listedObjectType.collectionName()).")
		}
		return err_str
	}
	//
	// Delegation - ChangePasswordRegistrant
	func passwordController_ChangePassword() -> String?
	{ // err
		if self.hasBooted != true {
			DDLog.Warn("Lists", "\(self) asked to change password but not yet booted.")
			return "Asked to change password but not yet booted" // critical: not ready to get this
		}
		// change all record passwords by re-saving
		for (_, record) in self.records.enumerated() {
			if record.didFailToInitialize_flag != true && record.didFailToBoot_flag != true {
				let err_str = record.saveToDisk()
				if err_str != nil { // err_str is logged
					return err_str
				}
			} else {
				DDLog.Error("Lists", "This record failed to boot. Not messing with its saved data")
				assert(false) // not considering this a runtime error.. app can deal with it.. plus we don't want to abort a save just for this - if we did, change pw revert would not work anyway
			}
		}
		return nil // success
	}
	//
	// Delegation - Notifications - Password Controller
	@objc func PasswordController_willDeconstructBootedStateAndClearPassword()
	{
		self.records = [] // flash
		self.hasBooted = false
		// now we'll wait for the "did" event ---v before emiting anything like list updated, etc
	}
	@objc func PasswordController_didDeconstructBootedStateAndClearPassword()
	{
		self.__dispatchAsync_listUpdated_records() // manually emit so that the UI updates to empty list after the pw entry screen is shown
		self.setup_tryToBoot() // this will re-request the pw and lead to loading records & booting self
	}
}
