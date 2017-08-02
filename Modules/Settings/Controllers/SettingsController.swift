//
//  SettingsController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class SettingsController: DeleteEverythingRegistrant
{
	enum NotificationNames_Changed: String
	{
		case serverURL = "SettingsController_NotificationNames_Changed_serverURL"
		case appTimeoutAfterS = "SettingsController_NotificationNames_Changed_appTimeoutAfterS"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	//
	// Constants/Types - Persistence
	let collectionName = "Settings"
	enum DictKey: String
	{
		case _id = "_id"
		case serverURL = "serverURL"
		case appTimeoutAfterS = "appTimeoutAfterS"
		//
		var changed_notificationName: NSNotification.Name?
		{
			switch self {
				case .serverURL:
					return NotificationNames_Changed.serverURL.notificationName
				case .appTimeoutAfterS:
					return NotificationNames_Changed.appTimeoutAfterS.notificationName
				case ._id:
					assert(false)
					// _id is not to be updated
					return nil
			}
		}
	}
	let setForbidden_DictKeys: [DictKey] = [ ._id ]
	//
	// Constants - Default values
	let default_appTimeoutAfterS: TimeInterval = 3 * 60 // minutes
	//
	// Properties - Runtime - Transient
	var hasBooted = false
	var instanceUUID = UUID()
	func identifier() -> String { // satisfy DeleteEverythingRegistrant for isEqual
		return self.instanceUUID.uuidString
	}
	//
	// Properties - Runtime - Persisted
	var _id: DocumentPersister.DocumentId?
	var serverURL: String?
	var appTimeoutAfterS: TimeInterval?
	//
	// Lifecycle - Singleton Init
	static let shared = SettingsController()
	private init()
	{
		self.setup()
	}
	func setup()
	{
		PasswordController.shared.addRegistrantForDeleteEverything(self)
		//
		let (err_str, documentJSONs) = DocumentPersister.shared.AllDocuments(inCollectionNamed: self.collectionName)
		if err_str != nil {
			assert(false, "Error: \(err_str!.debugDescription)")
			return
		}
		let documentJSONs_count = documentJSONs!.count
		if documentJSONs_count > 1 {
			assert(false, "Invalid Settings data state - more than one document")
			return
		}
		if documentJSONs_count == 0 {
			self._setup_loadState(_id: nil, serverURL: nil, appTimeoutAfterS: default_appTimeoutAfterS)
			return
		}
		let jsonDict = documentJSONs![0] // TODO: decrypt?
		let _id = jsonDict[DictKey._id.rawValue] as! DocumentPersister.DocumentId
		let serverURL = jsonDict[DictKey.serverURL.rawValue] as? String
		let appTimeoutAfterS = jsonDict[DictKey.appTimeoutAfterS.rawValue] as! TimeInterval
		self._setup_loadState(_id: _id, serverURL: serverURL, appTimeoutAfterS: appTimeoutAfterS)
	}
	func _setup_loadState(
		_id: DocumentPersister.DocumentId?,
		serverURL: String?,
		appTimeoutAfterS: TimeInterval
	)
	{
		self._id = _id
		self.serverURL = serverURL
		self.appTimeoutAfterS = appTimeoutAfterS
		//
		self.hasBooted = true
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		self.stopObserving()
	}
	func stopObserving()
	{
		PasswordController.shared.removeRegistrantForDeleteEverything(self)
	}
	//
	// Imperatives - Setting values
	func set(valuesByDictKey: [DictKey: Any]) -> String? // err_str
	{
		// configure
		for (key, value) in valuesByDictKey {
			if self.setForbidden_DictKeys.contains(key) == true {
				assert(false)
			}
			self._set(value: value, forPropertyWithDictKey: key)
		}
		// save
		let err_str = self.saveToDisk()
		if err_str != nil {
			return err_str
		}
		// notify
		DispatchQueue.main.async
		{
			for (key, _) in valuesByDictKey {
				NotificationCenter.default.post(name: key.changed_notificationName!, object: nil)
			}
		}
		return nil
	}
	private func _set(value: Any?, forPropertyWithDictKey dictKey: DictKey)
	{
		switch dictKey {
			case ._id: // not used - but for exhaustiveness
				assert(false)
				break
			case .appTimeoutAfterS:
				self.appTimeoutAfterS = value as? TimeInterval
				break
			case .serverURL:
				self.serverURL = value as? String
				break
		}
	}
	//
	// Imperatives - Setters - Convenience - Single-property (for form)
	func set(serverURL value: String?) -> String? // err_str
	{
		return self.set(valuesByDictKey: [ DictKey.serverURL: value as Any ])
	}
	func set(appTimeoutAfterS value: TimeInterval?) -> String? // err_str; use nil for 'never', not for resetting to default
	{
		return self.set(valuesByDictKey: [ DictKey.appTimeoutAfterS: value as Any ])
	}
	//
	// Accessors - Persistence
	var shouldInsertNotUpdate: Bool
	{
		return self._id == nil
	}
	func new_dictRepresentation() -> DocumentPersister.DocumentJSON
	{
		var dict: [String: Any] = [:]
		dict[DictKey._id.rawValue] = self._id
		if let value = self.serverURL {
			dict[DictKey.serverURL.rawValue] = value
		}
		if let value = self.appTimeoutAfterS {
			dict[DictKey.appTimeoutAfterS.rawValue] = value
		}
		//
		// Note: Override this method and add data you would like encrypted – but call on super
		return dict as DocumentPersister.DocumentJSON
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
	// For these, we presume consumers/parents/instantiators have only created this wallet if they have gotten the password
	func _saveToDisk_insert() -> String? // -> err_str?
	{
		assert(self._id == nil, "non-nil _id in \(#function)")
		// only generate _id here after checking shouldInsertNotUpdate since that relies on _id
		self._id = DocumentPersister.new_DocumentId() // generating a new UUID
		// Note: not encrypting server URL b/c based on flow of app, it needs to be able to be set before adding a wallet, which is where first pw entry happens.
		//
		return self.__saveToDisk_write()
	}
	func _saveToDisk_update() -> String?
	{
		assert(self._id != nil, "nil _id in \(#function)")
		//
		return self.__saveToDisk_write()
	}
	func __saveToDisk_write() -> String?
	{
		let dict = self.new_dictRepresentation() // plaintext
		do {
			let plaintextData =  try JSONSerialization.data(
				withJSONObject: dict,
				options: []
			)
			let err_str = DocumentPersister.shared.Write(
				documentFileWithData: plaintextData,
				withId: self._id!,
				toCollectionNamed: self.collectionName
			)
			if err_str != nil {
				DDLog.Error("Persistence", "Error while saving new object: \(err_str!)")
			} else {
				DDLog.Done("Persistence", "Saved new \(self).")
			}
			return err_str
		} catch let e {
			return e.localizedDescription
		}
	}
	//
	// Protocol - DeleteEverythingRegistrant
	func passwordController_DeleteEverything() -> String?
	{
		let defaults_valuesByKey: [DictKey: Any] =
		[
			.serverURL: "",
			.appTimeoutAfterS: default_appTimeoutAfterS
		]
		let err_str = self.set(valuesByDictKey: defaults_valuesByKey)
		//
		return err_str
	}
}
