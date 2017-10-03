//
//  UserIdle.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/2/17.
//  Copyright (c) 2014-2017, MyMonero.com
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

class UserIdle: NSObject
{
	//
	// Properties - Static/Shared
	static let shared = UserIdle()
	//
	// Constants
	enum NotificationNames: String
	{
		case userDidComeBackFromIdle = "UserIdle.NotificationNames.userDidComeBackFromIdle"
		case userDidBecomeIdle = "UserIdle.NotificationNames.userDidBecomeIdle"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	//
	// Properties - Initial
	var isUserIdle = false
	fileprivate var _numberOfSecondsSinceLastUserInteraction: TimeInterval = 0.0
	fileprivate var _numberOfRequestsToLockUserIdleAsDisabled: UInt = 0
	fileprivate var _userIdle_intervalTimer: Timer?
	//
	// Lifecycle - Init
	override init()
	{
		super.init()
		self.setup()
	}
	func setup()
	{
		self.startObserving()
		// ^- let's do the above first
		//
		self._initiate_userIdle_intervalTimer()
	}
	func startObserving()
	{
		NotificationCenter.default.addObserver(self, selector: #selector(MMApplication_didSendEvent(_:)), name: MMApplication.NotificationNames.didSendEvent.notificationName, object: nil)
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
		NotificationCenter.default.removeObserver(self, name: MMApplication.NotificationNames.didSendEvent.notificationName, object: nil)
	}
	//
	// Imperatives - Interface
	func temporarilyDisable_userIdle()
	{
		self._numberOfRequestsToLockUserIdleAsDisabled += 1
		if (self._numberOfRequestsToLockUserIdleAsDisabled == 1) { // if we're requesting to disable without it already having been disabled, i.e. was 0, now 1
			DDLog.Info("App.UserIdle", "Temporarily disabling the user idle timer.")
			self.__disable_userIdle()
		} else {
			DDLog.Info("App.UserIdle", "Requested to temporarily disable user idle but already disabled. Incremented lock.")
		}
	}
	func reEnable_userIdle()
	{
		if self._numberOfRequestsToLockUserIdleAsDisabled == 0 {
			DDLog.Info("App.UserIdle", "ReEnable_userIdle, self._numberOfRequestsToLockUserIdleAsDisabled 0")
			return // don't go below 0
		}
		self._numberOfRequestsToLockUserIdleAsDisabled -= 1
		if self._numberOfRequestsToLockUserIdleAsDisabled == 0 {
			DDLog.Info("App.UserIdle", "Re-enabling the user idle timer.")
			self.__reEnable_userIdle()
		} else {
			DDLog.Info("App.UserIdle", "Requested to re-enable user idle but other locks still exist.")
		}
	}
	//
	// Imperatives - Internal
	fileprivate func __disable_userIdle()
	{
		if self._userIdle_intervalTimer == nil {
			assert(false, "__disable_userIdle called but already have nil self.userIdle_intervalTimer")
			return
		}
		self._userIdle_intervalTimer!.invalidate()
		self._userIdle_intervalTimer = nil
	}
	fileprivate func __reEnable_userIdle()
	{
		if self._userIdle_intervalTimer != nil {
			assert(false, "__reEnable_userIdle called but non-nil self.userIdle_intervalTimer")
			return
		}
		self._initiate_userIdle_intervalTimer()
	}
	//
	fileprivate func _initiate_userIdle_intervalTimer()
	{
		assert(self._userIdle_intervalTimer == nil) // necessary?
		//
		DispatchQueue.main.async
		{ [unowned self] in
			self._userIdle_intervalTimer = Timer.scheduledTimer(
				withTimeInterval: TimeInterval(1.0),
				repeats: true
			)
			{ [unowned self] timer in
				self._numberOfSecondsSinceLastUserInteraction += 1.0 // count the second
				//
				let appTimeoutAfterS = SettingsController.shared.appTimeoutAfterS_nilForDefault_orNeverValue ?? 20.0 // use default on no pw entered / no settings info yet
				if appTimeoutAfterS == SettingsController.appTimeoutAfterS_neverValue { // then idle timer is specifically disabled
					return // do nothing
				}
				//
				if self._numberOfSecondsSinceLastUserInteraction >= appTimeoutAfterS {
					if self.isUserIdle == false { // not already idle (else redundant)
						self._userDidBecomeIdle()
					}
				}
			}
		}
	}
	//
	// Delegation - Notifications
	@objc fileprivate func MMApplication_didSendEvent(_ notification: Notification)
	{
		self._idleBreakingActionOccurred()
		// TODO: also detect when app is being controlled w/o touching the screen - e.g. via Simulator keyboard (or perhaps external)…
	}
	//
	// Delegation - Internal
	fileprivate func _idleBreakingActionOccurred()
	{
		let wasUserIdle = self.isUserIdle
		do {
			self._userDidInteract()
		}
		if wasUserIdle { // emit after we have set isUserIdle back to false
			self._userDidComeBackFromIdle()
		}
	}
	fileprivate func _userDidInteract()
	{
		self._numberOfSecondsSinceLastUserInteraction = 0.0 // reset counter
	}
	fileprivate func _userDidComeBackFromIdle()
	{
		do {
			self.isUserIdle = false // in case they were
		}
		DDLog.Info("App.UserIdle", "User came back from having been idle.")
		NotificationCenter.default.post(name: NotificationNames.userDidComeBackFromIdle.notificationName, object: nil, userInfo: nil)
	}
	fileprivate func _userDidBecomeIdle()
	{
		do {
			self.isUserIdle = true
		}
		DDLog.Info("App.UserIdle", "User became idle.")
		NotificationCenter.default.post(name: NotificationNames.userDidBecomeIdle.notificationName, object: nil, userInfo: nil)
	}
}
