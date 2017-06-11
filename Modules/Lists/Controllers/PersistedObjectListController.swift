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
	var listedObjectType: PersistableObject.Type!
	var documentCollectionName: DocumentPersister.CollectionName!
	var passwordController = PasswordController.shared
	//
	var records = [PersistableObject]()
	// runtime
	var hasBooted = false // can be set from true back to false
	var __blocksWaitingForBootToExecute: [(Void) -> Void]?
	//
	//
	// Lifecycle - Setup
	//
	init(listedObjectType type: PersistableObject.Type)
	{
		self.listedObjectType = type
		self.documentCollectionName = "\(type)" as DocumentPersister.CollectionName
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
		self.setup_fetchAndReconstituteExistingRecords()
	}
	func startObserving_passwordController()
	{
		self.passwordController.addRegistrantForDeleteEverything(self)
		//
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(PasswordController_changedPassword),
			name: PasswordController.NotificationNames.changedPassword.notificationName,
			object: PasswordController.shared
		)
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
			self.overridable_sortRecords()
			self._setup_didBoot()
			self._listUpdated_records() // post notification after booting, i.e. at runtime
		}
	}
	func _setup_didBoot()
	{
		DDLog.Done("Lists", "\(self) booted.")
		self.hasBooted = true // all done!
		self._callAndFlushAllBlocksWaitingForBootToExecute() // after hasBooted=true
		DispatchQueue.main.async { // on next tick to avoid instantiator missing this
			NotificationCenter.default.post(name: Notification.Name(Notifications_Boot.Did.rawValue), object: self)
		}
	}
	func _setup_didFailToBoot(withErrStr err_str: String)
	{
		DDLog.Error("Lists", "\(self) failed to boot with err: \(err_str)")
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
		self.tearDown()
	}
	func tearDown()
	{
		self._stopObserving_passwordController()
	}
	func _stopObserving_passwordController()
	{
		NotificationCenter.default.removeObserver(
			self,
			name: PasswordController.NotificationNames.changedPassword.notificationName,
			object: PasswordController.shared
		)
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
	//
	// Runtime - Accessors - Private - Lookups - Documents & instances
	func _new_idsOfPersistedRecords() -> (err_str: String?, ids: [DocumentPersister.DocumentId]?)
	{
		return DocumentPersister.shared.IdsOfAllDocuments(inCollectionNamed: self.documentCollectionName)
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
	// Imperatives - Deferring execution
	// NOTE: onceBooted() exists because waiting for a password to be entered by the user must be asynchronous
	func onceBooted(
		_ fn: @escaping ((Void) -> Void)
	)
	{
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
	// Delegation
	func overridable_booting_didReconstitute(listedObjectInstance: PersistableObject) {} // somewhat intentionally ignores errors and values which would be returned asynchronously, e.g. by way of a callback/block
	func _atRuntime__record_wasSuccessfullySetUp(_ listedObject: PersistableObject)
	{
		self.records.insert(listedObject, at: 0) // so we add it to the top
//		self.overridable_startObserving_record(recordInstance) // TODO if necessary - but shouldn't be at the moment - if implemented, be sure to add corresponding stopObserving where necessary
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
	//
	// Protocol - DeleteEverythingRegistrant
	func passwordController_DeleteEverything() -> String?
	{
		let (err_str, _) = DocumentPersister.shared.RemoveAllDocuments(inCollectionNamed: self.documentCollectionName)
		if err_str != nil {
			DDLog.Error("Lists", "Error while deleting everything: \(err_str!.debugDescription)")
		} else {
			DDLog.Deleting("Lists", "Deleted all \(self.documentCollectionName).")
		}
		return err_str
	}
	//
	// Delegation - Notifications - Password Controller
	@objc
	func PasswordController_changedPassword()
	{
		if self.hasBooted != true {
			DDLog.Warn("Lists", "\(self) asked to change password but not yet booted.")
			return // critical: not ready to get this
		}
		// change all record passwords by re-saving
		for (_, record) in self.records.enumerated() {
			if record.didFailToInitialize_flag != true && record.didFailToBoot_flag != true {
				let err_str = record.saveToDisk()
				if err_str != nil {
					// err_str is logged
					// TODO: is there any sensible strategy to handle failures here?
					assert(false)
				}
			} else {
				DDLog.Error("Lists", "This record failed to boot. Not messing with its saved data")
				assert(false)
			}
		}
	}
	@objc
	func PasswordController_willDeconstructBootedStateAndClearPassword()
	{
		self.records = [] // flash
		self.hasBooted = false
		// now we'll wait for the "did" event ---v before emiting anything like list updated, etc
	}
	@objc
	func PasswordController_didDeconstructBootedStateAndClearPassword()
	{
		self._dispatchAsync_listUpdated_records() // manually emit so that the UI updates to empty list after the pw entry screen is shown
		self.setup_tryToBoot() // this will re-request the pw and lead to loading records & booting self
	}
}
