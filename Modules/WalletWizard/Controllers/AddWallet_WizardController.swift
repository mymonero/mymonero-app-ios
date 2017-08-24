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
	// Properties - Settable by consumer
	var willDismiss_fn: ((Void) -> Void)?
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
		let viewController = viewController_Type.init(wizardController: self)
		//
		return viewController
	}
	var isAtEndOf_current_wizardTaskMode: Bool
	{
		let classes = self.current_wizardTaskMode!.stepsScreenViewControllerClasses
		if self.current_wizardTaskMode_stepIdx! >= classes.count {
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
			self.wizard_navigationController.modalPresentationStyle = .formSheet
			WindowController.presentModalsInViewController!.present(self.wizard_navigationController, animated: true, completion: nil)
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
		if let fn = self.willDismiss_fn {
			fn()
		}
		self.wizard_navigationController.dismiss(animated: true)
		{ [weak self] in
			guard let _ = self else {
				return
			}
		}
	}
	//
	// Runtime - Imperatives - Steps - Convenience - Advancing steps - Create wallet
	var walletCreation_metaInfo_walletLabel: String?
	var walletCreation_metaInfo_color: Wallet.SwatchColor?
	//
	var walletCreation_walletInstance: Wallet? // strong reference for ownership
	func setMetaInfoAndProceedToNextStep(
		walletLabel: String,
		color: Wallet.SwatchColor
	)
	{
		self.walletCreation_metaInfo_walletLabel = walletLabel
		self.walletCreation_metaInfo_color = color
		self.proceedToNextStep()
	}
	private func __generateWallet(_ fn: @escaping ((Void) -> Void))
	{
		WalletsListController.shared.CreateNewWallet_NoBootNoListAdd
		{ [unowned self] (err_str, walletInstance) in
			if err_str != nil {
				assert(false)
				let alertController = UIAlertController(
					title: NSLocalizedString("Error", comment: ""),
					message: NSLocalizedString(
						"An error occurred while creating your wallet. Please try again or contact us for support.",
						comment: ""
					),
					preferredStyle: .alert
				)
				alertController.addAction(
					UIAlertAction(
						title: NSLocalizedString("OK", comment: ""),
						style: .default
					)
					{ (result: UIAlertAction) -> Void in
					}
				)
				self.wizard_navigationController.present(alertController, animated: true, completion: nil)
				return
			}
			self.walletCreation_walletInstance = walletInstance
			fn()
		}
	}
	func createWalletInstanceAndProceedToNextStep()
	{
		self.__generateWallet
		{ [unowned self] in
			self.proceedToNextStep()
		}
	}
	func regenerateWalletAndPopToInformOfMnemonicScreen()
	{
		// TODO: maybe assert that this is being called from the correct screen
		self.__generateWallet
		{ [unowned self] in
			self.wizard_navigationController.popViewController(animated: true)
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
