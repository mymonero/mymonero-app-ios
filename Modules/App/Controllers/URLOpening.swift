//
//  URLOpening.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/28/17.
//  Copyright (c) 2014-2018, MyMonero.com
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

class URLOpening: DeleteEverythingRegistrant
{
	//
	// Shared
	static let shared = URLOpening()
	//
	// Constants
	enum NotificationNames: String
	{
		case saysTimeToHandleReceivedMoneroURL = "URLOpening.NotificationNames.saysTimeToHandleReceivedMoneroURL"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum NotificationUserInfoKeys: String
	{
		case url = "URLOpening.NotificationUserInfoKeys.url"
		//
		var key: String {
			return self.rawValue
		}
	}
	//
	// Properties
	var requestURLToOpen_pendingFromDisallowedFromOpening: URL?
	
	//
	// Properties - Protocols - DeleteEverythingRegistrant
	var instanceUUID = UUID()
	func identifier() -> String { // satisfy DeleteEverythingRegistrant for isEqual
		return self.instanceUUID.uuidString
	}
	//
	// Lifecycle - Init
	required init()
	{
		self.setup()
	}
	func setup()
	{
		self.startObserving()
	}
	func startObserving()
	{
		NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate_willLockDownAppOn_didEnterBackground), name: AppDelegate.NotificationNames.willLockDownAppOn_didEnterBackground.notificationName, object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(PasswordController_willDeconstructBootedStateAndClearPassword),
			name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared
		)
		PasswordController.shared.addRegistrantForDeleteEverything(self)
	}
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
		NotificationCenter.default.removeObserver(self, name: AppDelegate.NotificationNames.willLockDownAppOn_didEnterBackground.notificationName, object: nil)
		NotificationCenter.default.removeObserver(
			self,
			name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared
		)
		PasswordController.shared.removeRegistrantForDeleteEverything(self)
	}
	//
	// Accessors
	var isAllowedToReceiveURLs: Bool {
		if PasswordController.shared.isUserChangingPassword {
			DDLog.Info("URLOpening", "User is changing pw - ignoring URL")
			return false
		}
		if WalletsListController.shared.records.count == 0 {
			DDLog.Info("URLOpening", "No wallet - ignoring URL")
			return false
		}
		if PasswordController.shared.hasUserEnteredValidPasswordYet == false {
			DDLog.Info("URLOpening", "User hasn't entered valid pw yet - ignoring URL")
			return false
		}
		return true
	}
	//
	// Delegation
	func appReceived(url: URL) -> Bool // false if was not accepted
	{
		guard let scheme = url.scheme else {
			return false
		}
		if scheme != MoneroConstants.currency_requestURIPrefix_sansColon {
			return false
		}
		if self.isAllowedToReceiveURLs == false { // then defer this til we are ready (as gracefully as we can)
			if PasswordController.shared.isUserChangingPassword {
				DDLog.Info("URLOpening", "User is changing pw - not waiting for that to finish since the user probably doesn't want to open the URL in this state anyway")
				return false
			}
			// This is commented because... it'll always be true! Better would be to have a check that says "no wallets saved to disk"
//			if WalletsListController.shared.records.count == 0 {
//				DDLog.Info("URLOpening", "No wallet - not waiting for PW entry to open this URL since that may not be what the user intends")
//				return false
//			}
			let hasAPasswordBeenSaved = PasswordController.shared.hasUserSavedAPassword
			if hasAPasswordBeenSaved == false {
				// app is blank - no wallets have been created, password hasn't been entered…… ignore so as not to cause a superfluous password entry request
				return false
				// NOTE: returning before self.requestURLToOpen_pendingFromDisallowedFromOpening set - at least for now, b/c otherwise _yieldThatTimeToHandleReceivedMoneroURL would never be called unless code further enhanced to avoid call to OnceBootedAndPasswordObtained when hasAPasswordBeenSaved=false
			}
			let hadExistingPendingURL = self.requestURLToOpen_pendingFromDisallowedFromOpening != nil ? true : false
			self.requestURLToOpen_pendingFromDisallowedFromOpening = url // we will clear this either on the app going back into the background (considered a cancellation or failed attempt to unlock), the requestURL is processed after unlock, or
			DDLog.Warn("URLOpening", "Not allowed to perform URL opening ops yet but a password has been saved. Hanging onto requestURLToOpen until app unlocked.")
			if hadExistingPendingURL == false { // so we don't make duplicative requests for pw entry notification
				PasswordController.shared.OnceBootedAndPasswordObtained(
					{ (password, passwordType) in // it might be slightly more rigorous to observe the contact list controller for its next boot to do this but then we have to worry about whether that is waiting for all the information we would end up actually needing… so I'm opting for the somewhat more janky but probably safer option of using a delay to wait for things to load
						DispatchQueue.main.asyncAfter(
							deadline: .now() + 0.3, // which is probably excessive but it's ok and possibly preferred in order to let the user orient first
							execute:
							{
								if self.requestURLToOpen_pendingFromDisallowedFromOpening != nil { // if still have one - aka not cancelled
									self._yieldThatTimeToHandleReceivedMoneroURL(
										url: self.requestURLToOpen_pendingFromDisallowedFromOpening!
									)
								} else {
									DDLog.Warn("URLOpening", "Called back from a pw entry notification but no longer had a self.requestURLToOpen_pendingFromDisallowedFromOpening")
								}
							}
						)
					}
				)
			} else {
				DDLog.Warn("URLOpening", "Already had a URL pending app unlock so not adding another request for PW entry notification.")
			}
		} else {
			self._yieldThatTimeToHandleReceivedMoneroURL(url: url)
		}
		return true
	}
	func _yieldThatTimeToHandleReceivedMoneroURL(
		url: URL
	) {
		self.requestURLToOpen_pendingFromDisallowedFromOpening = nil // jic
		//
		DispatchQueue.main.async
		{
			let userInfo: [String: Any] =
			[
				NotificationUserInfoKeys.url.key: url
			]
			NotificationCenter.default.post(
				name: NotificationNames.saysTimeToHandleReceivedMoneroURL.notificationName,
				object: nil,
				userInfo: userInfo
			)
		}
	}
	//
	// Delegation - Notifications
	@objc func AppDelegate_willLockDownAppOn_didEnterBackground()
	{
		self.requestURLToOpen_pendingFromDisallowedFromOpening = nil // just nil - treat as if user canceled it
	}
	@objc func PasswordController_willDeconstructBootedStateAndClearPassword()
	{
		self.requestURLToOpen_pendingFromDisallowedFromOpening = nil // just in case ? (TODO: is this necessary?)
	}
	//
	// Delegation - Protocol - Delete Everything Registrant
	func passwordController_DeleteEverything() -> String?
	{
		self.requestURLToOpen_pendingFromDisallowedFromOpening = nil // in case user must delete everything instead of unlocking the app
		return nil // no error
	}
}

