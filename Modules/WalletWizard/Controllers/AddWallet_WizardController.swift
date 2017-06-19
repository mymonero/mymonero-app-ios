//
//  AddWallet_WizardController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import UIKit

class AddWallet_WizardController
{
	//
	// Types/Constants
	enum TaskMode
	{
		case firstTime_createWallet
		case firstTime_useExisting
		//
		case pickCreateOrUseExisting // this will patch into one of the following two:
		case afterPick_createWallet
		case afterPick_useExisting
		//
		func stepScreenViewControllerType(forStepIdx stepIdx: Int) -> AddWalletWizardScreen_BaseViewController.Type
		{
			return self.stepsScreenViewControllerClasses[stepIdx]
		}
		var stepsScreenViewControllerClasses: [AddWalletWizardScreen_BaseViewController.Type]
		{
			switch self
			{ // TODO: maybe cache these
				case .firstTime_createWallet:
					return [
						CreateWallet_MetaInfo_ViewController.self,
						CreateWallet_Instructions_ViewController.self,
						CreateWallet_InformOfMnemonic_ViewController.self,
						CreateWallet_ConfirmMnemonic_ViewController.self
					]
				case .firstTime_useExisting:
					return [
						UseExisting_MetaInfo_ViewController.self
					]
				//
				case .pickCreateOrUseExisting:
					return [
						PickCreateOrUseExisting_Landing_ViewController.self
					] // ^--- only one screen, before we patch to the following two:
				case .afterPick_createWallet:
					return [
						PickCreateOrUseExisting_Landing_ViewController.self, // which will not actually be used/hit as we patch 'across' it… provided here so that we can have idx at 1 for screen after Landing, having patched
						CreateWallet_MetaInfo_ViewController.self,
						CreateWallet_Instructions_ViewController.self,
						CreateWallet_InformOfMnemonic_ViewController.self,
						CreateWallet_ConfirmMnemonic_ViewController.self
					]
				case .afterPick_useExisting:
					return [
						PickCreateOrUseExisting_Landing_ViewController.self, // which will not actually be used/hit as we patch 'across' it… provided here so that we can have idx at 1 for screen after Landing, having patched
						UseExisting_MetaInfo_ViewController.self
					]
			}
		}
	}
	//
	// Properties
	var initial_wizardTaskMode: TaskMode!
	var current_wizardTaskMode: TaskMode!
	var current_wizardTaskMode_stepIdx: Int!
	var wizard_navigationController: UINavigationController!
	//
	// Lifecycle - Init
	init(taskMode: TaskMode)
	{
		self.initial_wizardTaskMode = taskMode
		//
		self.setup()
	}
	func setup()
	{ // aka EnterWizardTaskMode_returningNavigationView in the JS app
		self._configureRuntimeStateForTaskModeName(taskMode: self.initial_wizardTaskMode, toIdx: 0) // set current_wizardTaskMode
		//
		let navigationController = UINavigationController(
			rootViewController: self._new_current_wizardTaskMode_stepViewController
		)
		self.wizard_navigationController = navigationController
	}
	//
	// Runtime - Accessors - Factories
	var _new_current_wizardTaskMode_stepViewController: AddWalletWizardScreen_BaseViewController
	{
		let viewController_Type = self.current_wizardTaskMode!.stepScreenViewControllerType(
			forStepIdx: self.current_wizardTaskMode_stepIdx!
		)
		let viewController = viewController_Type.init(
			wizardController: self
			// TODO
		)
//		let options =
//		{
//			wizardController: self,
//			wizardController_initial_wizardTaskModeName		: self.initial_wizardTaskModeName,
//			wizardController_current_wizardTaskModeName		: self.current_wizardTaskModeName,
//			wizardController_current_wizardTaskMode_stepName: self.current_wizardTaskMode_stepName,
//			wizardController_current_wizardTaskMode_stepIdx	: self.current_wizardTaskMode_stepIdx
//		}
		//
		return viewController
	}
	var isAtEndOf_current_wizardTaskMode: Bool
	{
		let classes = self.current_wizardTaskMode!.stepsScreenViewControllerClasses
		if classes.count >= self.current_wizardTaskMode_stepIdx! {
			return true
		}
		return false
	}
	//
	// Runtime - Imperatives - After init, call present()
	func present()
	{
		DispatchQueue.main.async
		{ [unowned self] in
			let rootViewController = UIApplication.shared.delegate?.window??.rootViewController
			// ^- typically it's not great to reach through the delegate like this, but I made the call that it's ok for a number of reasons; open to discussion
			rootViewController!.present(self.wizard_navigationController, animated: true, completion: nil)
		}
	}
	//
	// Runtime - Imperatives - Configuration & control
	func _configureRuntimeStateForTaskModeName(
		taskMode: TaskMode,
		toIdx: Int
	)
	{
		self.current_wizardTaskMode = taskMode
		self.current_wizardTaskMode_stepIdx = toIdx
	}
	//
	func patchToDifferentWizardTaskMode_byPushingScreen(patchTo_wizardTaskMode: TaskMode, atIndex: Int)
	{
		self._configureRuntimeStateForTaskModeName(
			taskMode: patchTo_wizardTaskMode,
			toIdx: atIndex
		)
		if self.isAtEndOf_current_wizardTaskMode == true {
			self.dismissWizardModal(
				userCanceled: false,
				didTaskFinish: true
			)
			return
		}
		// now configure UI / push
		let next_viewController = self._new_current_wizardTaskMode_stepViewController
		self.wizard_navigationController.pushViewController(next_viewController, animated: true)
	}
	func patchToDifferentWizardTaskMode_withoutPushingScreen(
		patchTo_wizardTaskMode: TaskMode,
		atIndex: Int
	)
	{
		self._configureRuntimeStateForTaskModeName(taskMode: patchTo_wizardTaskMode, toIdx: atIndex)
	}
	//
	// Runtime - Imperatives - Steps
	func proceedToNextStep()
	{
		self._configureRuntimeStateForTaskModeName(
			taskMode: self.current_wizardTaskMode,
			toIdx: self.current_wizardTaskMode_stepIdx + 1
		)
		if self.isAtEndOf_current_wizardTaskMode {
			self.dismissWizardModal(
				userCanceled: false,
				didTaskFinish: true
			)
			return
		}
		let next_viewController = self._new_current_wizardTaskMode_stepViewController
		self.wizard_navigationController.pushViewController(next_viewController, animated: true)
	}
	func dismissWizardModal(
		// these should of course not both be true at the same time
		userCanceled: Bool,
		didTaskFinish: Bool
	)
	{
		assert((!userCanceled || !didTaskFinish) && (userCanceled || didTaskFinish), "Unrecognized args config")
		self.wizard_navigationController.dismiss(animated: true)
		{ // [unowned self] in
			// TODO: ? notify instantiator.. perhaps with a block?
			DDLog.Todo("asdfa", "asdf")
		}
	}
	//
	// Runtime - Delegation
	func _fromScreen_userPickedCancel()
	{
		self.dismissWizardModal(
			userCanceled: true,
			didTaskFinish: false
		)
	}
}
