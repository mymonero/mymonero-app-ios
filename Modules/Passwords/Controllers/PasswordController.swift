//
//  PasswordController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/22/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
protocol DeleteEverythingRegistrant
{
//	func …()
}
//
final class PasswordController
{
	// Types/Constants
	typealias Password = String
	enum PasswordType: String
	{
		case PIN = "PIN" // 6-digit numerical PIN/code
		case password = "password" // free-form, string password
		var lengthOfPIN: Int { return 6 }
		var humanReadableString: String
		{
			return self.rawValue
		}
		var capitalized_humanReadableString: String
		{
			return self.humanReadableString.capitalized
		}
		func new(detectedFromPassword password: Password) -> PasswordType
		{
			let characters = password.characters
			if characters.count == lengthOfPIN { // if is 6 chars…
				let numbers: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
				if Set(characters).isSubset(of: numbers) { // and contains only numbers
					return .PIN
				}
			}
			return .password
		}
	}
	let collectionName = "PasswordMeta"
	let plaintextMessageToSaveForUnlockChallenges = "this is just a string that we'll use for checking whether a given password can unlock an encrypted version of this very message"
	enum DictKeys: String
	{
		case _id = "_id"
		case passwordType = "passwordType"
		case encryptedMessageForUnlockChallenge = "encryptedMessageForUnlockChallenge"
	}
	enum NotificationNames: String
	{
		case setFirstPasswordDuringThisRuntime = "PasswordController_NotificationNames_SetFirstPasswordDuringThisRuntime"
		case changedPassword = "PasswordController_NotificationNames_ChangedPassword"
		//
		case obtainedNewPassword = "PasswordController_Runtime_NotificationNames_ObtainedNewPassword"
		case obtainedCorrectExistingPassword = "PasswordController_Runtime_NotificationNames_ObtainedCorrectExistingPassword"
		//
		case erroredWhileSettingNewPassword = "PasswordController_Runtime_NotificationNames_ErroredWhileSettingNewPassword"
		case erroredWhileGettingExistingPassword = "PasswordController_Runtime_NotificationNames_ErroredWhileGettingExistingPassword"
		case canceledWhileEnteringExistingPassword = "PasswordController_Runtime_NotificationNames_canceledWhileEnteringExistingPassword"
		case canceledWhileEnteringNewPassword = "PasswordController_Runtime_NotificationNames_canceledWhileEnteringNewPassword"
		//
		case canceledWhileChangingPassword = "PasswordController_Runtime_NotificationNames_canceledWhileChangingPassword"
		case errorWhileChangingPassword = "PasswordController_Runtime_NotificationNames_errorWhileChangingPassword"
		//
		// TODO: SingleObserver_getUserToEnterExistingPasswordWithCB
		// TODO: SingleObserver_getUserToEnterNewPasswordAndTypeWithCB
		//
		case willDeconstructBootedStateAndClearPassword = "PasswordController_Runtime_NotificationNames_willDeconstructBootedStateAndClearPassword"
		case didDeconstructBootedStateAndClearPassword = "PasswordController_Runtime_NotificationNames_didDeconstructBootedStateAndClearPassword"
		case havingDeletedEverything_didDeconstructBootedStateAndClearPassword = "PasswordController_Runtime_NotificationNames_havingDeletedEverything_didDeconstructBootedStateAndClearPassword"
	}
	//
	// Properties
	var hasBooted = false
	var _id: DocumentPersister.DocumentId?
	var password: Password?
	var passwordType: PasswordType! // it will default to .password per init
	var hasUserSavedAPassword: Bool!
	var encryptedMessageForUnlockChallenge: String?
	var _initial_waitingForFirstPWEntryDecode_passwordModel_doc: [String: Any]?
	var isAlreadyGettingExistingOrNewPWFromUser: Bool?
	//
	// Lifecycle - Singleton Init
	static let shared = PasswordController()
	private init()
	{
		self.setup()
	}
	func setup()
	{
		self.startObserving_userIdle()
		self.initializeRuntimeAndBoot()
	}
	func startObserving_userIdle()
	{
		// TODO:
//		controller.on(
//			controller.EventName_userDidBecomeIdle(),
//			
//				{
//					if (self.hasUserSavedAPassword !== true) {
//						// nothing to do here because the app is not unlocked and/or has no data which would be locked
//						console.log("💬  User became idle but no password has ever been entered/no saved data should exist.")
//						return
//					} else if (self.HasUserEnteredValidPasswordYet() !== true) {
//						// user has saved data but hasn't unlocked the app yet
//						console.log("💬  User became idle and saved data/pw exists, but user hasn't unlocked app yet.")
//						return
//					}
//					self._didBecomeIdleAfterHavingPreviouslyEnteredPassword()
//			}
//		)
	}
	func initializeRuntimeAndBoot()
	{
		assert(self.hasBooted == false, "\(#function) called while already booted")
		let (err_str, documentJSONs) = DocumentPersister.shared().AllDocuments(
			inCollectionNamed: self.collectionName
		)
		if err_str != nil {
			NSLog("Fatal error while loading \(self.collectionName): \(err_str!)")
			// TODO: throw/crash?
			return
		}
		let documentJSONs_count = documentJSONs!.count
		if documentJSONs_count >= 1 {
			NSLog("Unexpected state while loading \(self.collectionName): more than one saved doc.")
			// TODO: throw/crash?
			return
		}
		func _proceedTo_load(
			hasUserSavedAPassword: Bool,
			documentJSON: DocumentPersister.DocumentJSON
		)
		{
			self.hasUserSavedAPassword = hasUserSavedAPassword
			//
			self._id = documentJSON[DictKeys._id.rawValue] as? DocumentPersister.DocumentId
			self.passwordType = documentJSON[DictKeys.passwordType.rawValue] as? PasswordType ?? .password
			self.encryptedMessageForUnlockChallenge = documentJSON[DictKeys.encryptedMessageForUnlockChallenge.rawValue] as? String
			if self._id != nil { // existing doc
				if self.encryptedMessageForUnlockChallenge == nil || self.encryptedMessageForUnlockChallenge == "" {
					// ^-- but it was saved w/o an encrypted challenge str
					// TODO: not sure how to handle this case. delete all local info? would suck
					let err_str = "Found undefined encrypted msg for unlock challenge in saved password model document"
					NSLog("Error: \(err_str)")
					return
				}
			}
			self._initial_waitingForFirstPWEntryDecode_passwordModel_doc = documentJSON // this will be nil'd after it's been parsed once the user has entered their pw
			//
			self.hasBooted = true
			self._callAndFlushAllBlocksWaitingForBootToExecute()
			NSLog("✅  Booted \(self) and called all waiting blocks. Waiting for unlock.")
		}
		if documentJSONs_count == 0 {
			let fabricated_documentJSON =
			[
				DictKeys.passwordType.rawValue: PasswordType.password // default (at least for now)
			]
			_proceedTo_load(
				hasUserSavedAPassword: false,
				documentJSON: fabricated_documentJSON
			)
			return
		}
		let documentJSON = documentJSONs![0]
		_proceedTo_load(
			hasUserSavedAPassword: true,
			documentJSON: documentJSON
		)
	}
	//
	// Accessors - Runtime - Derived properties
	var hasUserEnteredValidPasswordYet: Bool
	{
		return self.password != nil
	}
	var isUserChangingPassword: Bool
	{
		return self.hasUserEnteredValidPasswordYet == true && self.isAlreadyGettingExistingOrNewPWFromUser == true
	}
	var new_incorrectPasswordValidationErrorMessageString: String
	{
		let humanReadable_passwordType = self.passwordType!.humanReadableString
		//
		return "Incorrect \(humanReadable_passwordType)"
	}
	//
	// Accessors - Deferring execution convenience methods
	func OnceBootedAndPasswordObtained(
		_ fn: @escaping (_ password: Password, _ passwordType: PasswordType) -> Void,
		_ userCanceled_fn: (() -> Void)? = {}
	)
	{
		func callBackHavingObtainedPassword()
		{
			fn(self.password!, self.passwordType)
		}
		func callBackHavingCanceled()
		{
			userCanceled_fn!()
		}
		if self.hasUserEnteredValidPasswordYet == true {
			callBackHavingObtainedPassword()
			return
		}
		// then we have to wait for it
		var hasCalledBack = false
		var token__obtainedNewPassword: Any?
		var token__obtainedCorrectExistingPassword: Any?
		var token__canceledWhileEnteringExistingPassword: Any?
		var token__canceledWhileEnteringNewPassword: Any?
		func ___guardAllCallBacks() -> Bool
		{
			if hasCalledBack == true {
				NSLog("PasswordController/OnceBootedAndPasswordObtained hasCalledBack already true")
				return false // ^- shouldn't happen but just in case…
			}
			hasCalledBack = true
			return true
		}
		func __stopListening()
		{
			NotificationCenter.default.removeObserver(token__obtainedNewPassword!)
			NotificationCenter.default.removeObserver(token__obtainedCorrectExistingPassword!)
			NotificationCenter.default.removeObserver(token__canceledWhileEnteringExistingPassword!)
			NotificationCenter.default.removeObserver(token__canceledWhileEnteringNewPassword!)
			token__obtainedNewPassword = nil
			token__obtainedCorrectExistingPassword = nil
			token__canceledWhileEnteringExistingPassword = nil
			token__canceledWhileEnteringNewPassword = nil
		}
		func _aPasswordWasObtained()
		{
			if (___guardAllCallBacks() != false) {
				__stopListening() // immediately unsubscribe
				callBackHavingObtainedPassword()
			}
		}
		func _obtainingPasswordWasCanceled()
		{
			if (___guardAllCallBacks() != false) {
				__stopListening() // immediately unsubscribe
				callBackHavingCanceled()
			}
		}
		self.onceBooted({ [unowned self] in
			// hang onto tokens so we can unsub
			token__obtainedNewPassword = NotificationCenter.default.addObserver(
				forName: NSNotification.Name(NotificationNames.obtainedNewPassword.rawValue),
				object: self,
				queue: OperationQueue.main,
				using:
				{ (notification) in
					_aPasswordWasObtained()
				}
			)
			token__obtainedCorrectExistingPassword = NotificationCenter.default.addObserver(
				forName: NSNotification.Name(NotificationNames.obtainedCorrectExistingPassword.rawValue),
				object: self,
				queue: OperationQueue.main,
				using:
				{ (notification) in
					_aPasswordWasObtained()
				}
			)
			token__canceledWhileEnteringExistingPassword = NotificationCenter.default.addObserver(
				forName: NSNotification.Name(NotificationNames.canceledWhileEnteringExistingPassword.rawValue),
				object: self,
				queue: OperationQueue.main,
				using:
				{ (notification) in
					_obtainingPasswordWasCanceled()
				}
			)
			token__canceledWhileEnteringNewPassword = NotificationCenter.default.addObserver(
				forName: NSNotification.Name(NotificationNames.canceledWhileEnteringNewPassword.rawValue),
				object: self,
				queue: OperationQueue.main,
				using:
				{ (notification) in
					_obtainingPasswordWasCanceled()
				}
			)
			// now that we're subscribed, initiate the pw request
			self.givenBooted_initiateGetNewOrExistingPasswordFromUserAndEmitIt()
		})
	}
	func givenBooted_initiateGetNewOrExistingPasswordFromUserAndEmitIt()
	{
		NSLog("Has now booted. initiate get new or existing pw")
	}
	var __blocksWaitingForBootToExecute: [(Void) -> Void]?
	// NOTE: onceBooted() exists because even though init()->setup() is synchronous, we need to be able to tear down and reconstruct the passwordController booted state, e.g. on user idle and delete everything
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
	// Imperatives - Delete Everything notification registration
	func AddRegistrantForDeleteEverything(
		_ observer: DeleteEverythingRegistrant
		) -> Void
	{
		NSLog("TODO: AddRegistrantForDeleteEverything")
	}
	//
	// Delegation
}
