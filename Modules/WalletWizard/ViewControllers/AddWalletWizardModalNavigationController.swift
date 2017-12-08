//
//  AddWalletWizardModalNavigationController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 9/4/17.
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
import UIKit

class AddWalletWizardModalNavigationController: UINavigationController
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
			{ // TODO:? maybe cache these
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
	//
	// Properties - Settable by consumer
	var willDismiss_fn: (() -> Void)?
	//
	// Lifecycle - Init
	init(taskMode: TaskMode)
	{
		super.init(nibName: nil, bundle: nil)
		//
		self.initial_wizardTaskMode = taskMode
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.modalPresentationStyle = .formSheet
		//
		self._configureRuntimeStateForTaskModeName(taskMode: self.initial_wizardTaskMode, toIdx: 0) // set current_wizardTaskMode
		self.viewControllers = [ self._new_current_wizardTaskMode_stepViewController ]
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
			let presentInViewController = WindowController.presentModalsInViewController!
			presentInViewController.present(self, animated: true, completion: nil)
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
		self.pushViewController(next_viewController, animated: true)
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
		self.pushViewController(next_viewController, animated: true)
	}
	func dismissWizardModal(
		userCanceled: Bool,
		didTaskFinish: Bool
		// ^-- these should of course not both be true at the same time
	)
	{
		assert((!userCanceled || !didTaskFinish) && (userCanceled || didTaskFinish), "Unrecognized args config")
		self._willDismissWizardModal()
		if didTaskFinish {
			assert(userCanceled == false)
			//
			let generator = UINotificationFeedbackGenerator()
			generator.prepare()
			generator.notificationOccurred(.success)
		}
		self.dismiss(animated: true) {}
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
	private func __generateWallet(_ fn: @escaping (() -> Void))
	{
		WalletsListController.shared.CreateNewWallet_NoBootNoListAdd
			{ [unowned self] (err_str, walletInstance) in
				if err_str != nil {
					assert(false)
					let generator = UINotificationFeedbackGenerator()
					generator.prepare()
					generator.notificationOccurred(.warning)
					//
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
					self.present(alertController, animated: true, completion: nil)
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
	{ // TODO: maybe assert that this is being called from the correct screen
		self.__generateWallet
			{ [unowned self] in
				self.popViewController(animated: true)
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
	func _willDismissWizardModal()
	{ // TODO: this needs to get called every time the navigationView dismisses
		if let fn = self.willDismiss_fn {
			fn()
		}
	}
}
