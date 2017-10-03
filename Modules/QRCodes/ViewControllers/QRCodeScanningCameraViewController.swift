//
//  QRCodeScanningCameraViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/28/17.
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
import AVFoundation
import AudioToolbox

class QRCodeScanningCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate
{
	//
	// Constants
	
	//
	// Properties - Set by self to indicate result of init
	var didFatalErrorOnInit: NSError? // if non-nil, discard self instance
	//
	// Properties - Settable by instantiator
	var shouldVibrateOnFirstScan = true // possibly have setting to turn this off
	//
	var didCancel_fn: (() -> Void)?
	var didLocateQRCodeMessageString_fn: ((String) -> Void)?
	//
	// Properties - Runtime
	var captureSession: AVCaptureSession!
	var videoPreviewLayer: AVCaptureVideoPreviewLayer!
	var qrCodeReticleView: UIView!
	//
	
	//
	// Lifecycle - Init
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.setup_views()
		self.setup_navigation()
	}
	func setup_views()
	{
		guard let captureDevice = AVCaptureDevice.default(for: .video) else {
			self.didFatalErrorOnInit = NSError(
				domain: "QRCodes",
				code: -1,
				userInfo:
				[
					NSLocalizedDescriptionKey: NSLocalizedString("Unable to get capture device", comment: "")
				]
			)
			return
		}
		do {
			self.view.backgroundColor = .black
		}
		do {
			let input = try AVCaptureDeviceInput(device: captureDevice)
			let session = AVCaptureSession()
			self.captureSession = session
			session.addInput(input)
		} catch let e {
			self.didFatalErrorOnInit = e as NSError
			return
		}
		do {
			let output = AVCaptureMetadataOutput()
			self.captureSession.addOutput(output) // must add first before setting metadataObjectTypes
			output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			output.metadataObjectTypes = [ AVMetadataObject.ObjectType.qr ]
		}
		do {
			let layer = AVCaptureVideoPreviewLayer(session: captureSession) // no longer optional, no need for guard
			self.videoPreviewLayer = layer
			layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
			self.view.layer.addSublayer(layer)
		}
		do {
			let view = UIView()
			self.qrCodeReticleView = view
			view.layer.borderColor = UIColor.green.cgColor // too faint: UIColor.utilityOrConstructiveLinkColor.cgColor
			view.layer.borderWidth = 2
			self.view.addSubview(view)
			self.view.bringSubview(toFront: view)
		}
	}
	func setup_navigation()
	{
		self.navigationItem.title = NSLocalizedString("Scan QR Code", comment: "")
		do {
			let item = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				tapped_fn:
				{ [unowned self] in
					if let fn = self.didCancel_fn {
						fn()
					}
				}
			)
			self.navigationItem.leftBarButtonItem = item
		}
	}
	//
	// Lifecycle - Deinit
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		if self.captureSession != nil && self.captureSession.isRunning {
			self.captureSession.stopRunning()
			self.captureSession = nil // not actually necessary
		}
	}
	//
	// Delegation - Overrides - Views
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		assert(self.videoPreviewLayer != nil)
		self.videoPreviewLayer.frame = view.layer.bounds		
	}
	//
	// Delegation - View lifecycle
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		if self.captureSession != nil && self.captureSession.isRunning == false {
			self.captureSession.startRunning()
		}
		// Needed?
//		ThemeController.shared.styleViewController_navigationBarTitleTextAttributes(
//			viewController: self,
//			titleTextColor: nil // default
//		) // probably not necessary but probably a good idea here to support clearing potential red clr transactions details on popping to self
	}
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		if self.captureSession != nil && self.captureSession.isRunning {
			self.captureSession.stopRunning()
		}
	}
	//
	// Delegation - AVCapture
	var hasAlreadyOutputMetadataObject = false
	func captureOutput(
		_ captureOutput: AVCaptureOutput!,
		didOutputMetadataObjects metadataObjects: [Any]!,
		from connection: AVCaptureConnection!
	)
	{
		if metadataObjects == nil || metadataObjects.count == 0 {
			self.qrCodeReticleView.frame = .zero
			return
		}
		let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
		if metadataObj.type != AVMetadataObject.ObjectType.qr {
			assert(false)
			return
		}
		do {
			let barCodeObject = self.videoPreviewLayer.transformedMetadataObject(for: metadataObj)
			self.qrCodeReticleView.frame = barCodeObject!.bounds
		}
		if self.hasAlreadyOutputMetadataObject == false {
			self.hasAlreadyOutputMetadataObject = true
			//
			if self.shouldVibrateOnFirstScan {
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
			}
		}
		if let stringValue = metadataObj.stringValue {
			if let fn = self.didLocateQRCodeMessageString_fn {
				fn(stringValue)
			}
		}
	}
}
