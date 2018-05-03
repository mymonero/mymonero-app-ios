//
//  QRPickingActionButtons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 4/28/18.
//  Copyright © 2014-2018 MyMonero. All rights reserved.
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
//
extension UICommonComponents
{
	class QRPickingActionButtons: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate // not a view
	{
		//
		// Properties - Interface - Settable after init
		var willDecodePickedImage_fn: (() -> Void)?
		var didPick_fn: ((_ requestURIString: String) -> Void)?
		var didEndQRScanWithErrStr_fn: ((_ localizedValidationMessage: String) -> Void)?
		var havingPickedImage_shouldAllowPicking_fn: (() -> Bool)?
		//
		// Properties - Internal
		// - Init - Weak vars (preventing retain cycle)
		weak var containingViewController: UIViewController!
		weak var superview: UIView!
		// - Setup - Views
		var useCamera_actionButtonView: UICommonComponents.ActionButton!
		var chooseFile_actionButtonView: UICommonComponents.ActionButton!
		// - Runtime - Controllers
		var presented_imagePickerController: UIImagePickerController?
		var presented_cameraViewController: QRCodeScanningCameraViewController?
		//
		// Accessors - Runtime
		var frame: CGRect {
			return self.useCamera_actionButtonView.frame // just picking one of them
		}
		//
		// Imperatives - Setup
		init(
			containingViewController: UIViewController,
			attachingToView superview: UIView
		) {
			self.containingViewController = containingViewController
			self.superview = superview
			super.init()
			self.setup()
		}
		func setup()
		{
			do {
				let iconImage = UIImage(named: "actionButton_iconImage__useCamera")!
				let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true, iconImage: iconImage)
				view.addTarget(self, action: #selector(useCamera_tapped), for: .touchUpInside)
				view.setTitle(NSLocalizedString("Use Camera", comment: ""), for: .normal)
				view.titleEdgeInsets = UICommonComponents.ActionButton.new_titleEdgeInsets_withIcon
				self.useCamera_actionButtonView = view
				self.superview.addSubview(view) // not self.scrollView
			}
			do {
				let iconImage = UIImage(named: "actionButton_iconImage__chooseFile")!
				let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: false, iconImage: iconImage)
				view.addTarget(self, action: #selector(chooseFile_tapped), for: .touchUpInside)
				view.setTitle(NSLocalizedString("Choose file", comment: ""), for: .normal)
				view.titleEdgeInsets = UICommonComponents.ActionButton.new_titleEdgeInsets_withIcon
				self.chooseFile_actionButtonView = view
				self.superview.addSubview(view) // not self.scrollView
			}
		}
		//
		// Imperatives - Teardown
		deinit
		{
			self.teardownAnyPickers()
		}
		func teardownAnyPickers()
		{
			self._tearDownAnyImagePickerController(animated: false)
			self._tearDownAnyQRScanningCameraViewController(animated: false)
		}
		func _tearDownAnyImagePickerController(animated: Bool)
		{
			if let viewController = self.presented_imagePickerController {
				if self.containingViewController.navigationController?.presentedViewController == viewController {
					viewController.dismiss(animated: animated, completion: nil)
				} else {
					DDLog.Warn("SendFundsTab", "Asked to teardown image picker while it was non-nil but not presented.")
				}
				self.presented_imagePickerController = nil
			}
		}
		func _tearDownAnyQRScanningCameraViewController(animated: Bool)
		{
			if let viewController = self.presented_cameraViewController {
				let actualPresentedViewController = viewController.navigationController!
				if self.containingViewController.navigationController?.presentedViewController == actualPresentedViewController {
					actualPresentedViewController.dismiss(animated: animated, completion: nil)
				} else {
					DDLog.Warn("SendFundsTab", "Asked to teardown QR scanning camera vc while it was non-nil but not presented.")
				}
				self.presented_cameraViewController = nil
			}
		}
		//
		// Imperatives - Interactivity
		func set(isEnabled: Bool)
		{
			self.useCamera_actionButtonView.isEnabled = isEnabled
			self.chooseFile_actionButtonView.isEnabled = isEnabled
		}
		//
		// Imperatives - Layout
		func givenSuperview_layOut(atY buttons_y: CGFloat, withMarginH margin_h: CGFloat)
		{
			self.useCamera_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
			self.chooseFile_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
		}
		//
		// Delegation - Picking
		func __shared_didPick(requestURIStringForAutofill requestURIString: String)
		{
			self.didPick_fn?(requestURIString)
		}
		//
		// Delegation - Interactions
		@objc func useCamera_tapped()
		{
			let viewController = QRCodeScanningCameraViewController()
			if let error = viewController.didFatalErrorOnInit {
				let alertController = UIAlertController(
					title: error.localizedDescription,
					message: error.userInfo["NSLocalizedRecoverySuggestion"] as? String ?? NSLocalizedString("Please ensure MyMonero can access your device camera via iOS Settings > Privacy.", comment: ""),
					preferredStyle: .alert
				)
				alertController.addAction(
					UIAlertAction(
						title: NSLocalizedString("OK", comment: ""),
						style: .default
					) { (result: UIAlertAction) -> Void in
					}
				)
				self.containingViewController.navigationController!.present(alertController, animated: true, completion: nil)
				//
				return // effectively discarding viewController
			}
			viewController.didCancel_fn =
				{ [unowned self] in
					self._tearDownAnyQRScanningCameraViewController(animated: true)
			}
			var hasOnceUsedScannedString = false // prevent redundant submits
			viewController.didLocateQRCodeMessageString_fn =
				{ [unowned self] (scannedMessageString) in
					if hasOnceUsedScannedString == false {
						hasOnceUsedScannedString = true
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) // delay here merely for visual effect
						{ [unowned self] in
							self._tearDownAnyQRScanningCameraViewController(animated: true)
							self.__shared_didPick(requestURIStringForAutofill: scannedMessageString) // possibly wait til completion?
						}
					}
			}
			self.presented_cameraViewController = viewController
			let navigationController = UINavigationController(rootViewController: viewController)
			self.containingViewController.navigationController!.present(
				navigationController,
				animated: true,
				completion: nil
			)
		}
		@objc func chooseFile_tapped()
		{
			guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else {
				let alertController = UIAlertController(
					title: NSLocalizedString("Saved Photos Album not available", comment: ""),
					message: NSLocalizedString(
						"Please ensure you have allowed MyMonero to access your Photos.",
						comment: ""
					),
					preferredStyle: .alert
				)
				alertController.addAction(
					UIAlertAction(
						title: NSLocalizedString("OK", comment: ""),
						style: .default
					) { (result: UIAlertAction) -> Void in
					}
				)
				self.containingViewController.navigationController!.present(alertController, animated: true, completion: nil)
				return
			}
			let pickerController = UIImagePickerController()
			pickerController.view.backgroundColor = .contentBackgroundColor // prevent weird flashing on transitions
			pickerController.navigationBar.tintColor = UIColor.systemStandard_navigationBar_tintColor // make it look at least slightly passable… would be nice if font size of btns could be reduced (next to such a small nav title font)… TODO: pimp out nav bar btns, including 'back', ala PushButton
			pickerController.allowsEditing = false
			pickerController.delegate = self
			pickerController.modalPresentationStyle = .formSheet
			self.presented_imagePickerController = pickerController
			self.containingViewController.navigationController!.present(pickerController, animated: true, completion: nil)
		}
		//
		// Delegation - UIImagePickerControllerDelegate
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
		{
			let picked_originalImage = info[UIImagePickerControllerOriginalImage] as! UIImage
			self._didPick(possibleQRCodeImage: picked_originalImage)
			self._tearDownAnyImagePickerController(animated: true)
		}
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
		{
			self._tearDownAnyImagePickerController(animated: true)
		}
		//
		// Delegation - QR code and URL picking
		func _didPick(possibleQRCodeImage image: UIImage)
		{
			if let fn = self.havingPickedImage_shouldAllowPicking_fn {
				if fn() == false {
					// TODO: add notify fn here if necessary
					return
				}
			}
			self.willDecodePickedImage_fn?()
			//
			// now decode qr …
			let ciImage = CIImage(cgImage: image.cgImage!)
			var options: [String: Any] = [:]
			do {
				options[CIDetectorAccuracy] = CIDetectorAccuracyHigh
				do {
					let properties = ciImage.properties
					let raw_orientation = properties[kCGImagePropertyOrientation as String]
					let final_orientation = raw_orientation ?? 1 /* "If not present, a value of 1 is assumed." */
					//
					options[CIDetectorImageOrientation] = final_orientation
				}
			}
			let context = CIContext()
			let detector = CIDetector(
				ofType: CIDetectorTypeQRCode,
				context: context,
				options: options
			)!
			let features = detector.features(in: ciImage, options: options)
			if features.count == 0 {
				self.didEndQRScanWithErrStr_fn?(
					NSLocalizedString("Unable to find QR code data in image", comment: "")
				)
				return
			}
			if features.count > 2 {
				self.didEndQRScanWithErrStr_fn?(
					NSLocalizedString("Unexpectedly found multiple QR features in image. This may be a bug.", comment: "")
				)
			}
			let feature = features.first! as! CIQRCodeFeature
			let messageString = feature.messageString
			if messageString == nil || messageString == "" {
				self.didEndQRScanWithErrStr_fn?(
					NSLocalizedString("Unable to find message string in image's QR code.", comment: "")
				)
				return
			}
			self.__shared_didPick(requestURIStringForAutofill: messageString!)
		}
	}
}
