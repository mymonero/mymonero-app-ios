//
//  QRCodeScanningCameraViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/28/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
import AVFoundation

class QRCodeScanningCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate
{
	//
	// Constants
	
	//
	// Properties - Set by self to indicate result of init
	var didFatalErrorOnInit: NSError? // if non-nil, discard self instance
	//
	// Properties - Set by consumer
	var didCancel_fn: ((Void) -> Void)?
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
		do {
			self.view.backgroundColor = .black
		}
		let captureDevice = AVCaptureDevice.defaultDevice(
			withMediaType: AVMediaTypeVideo
		)
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
			output.metadataObjectTypes = [ AVMetadataObjectTypeQRCode ]
		}
		do {
			guard let layer = AVCaptureVideoPreviewLayer(session: captureSession) else {
				// TODO: error?
				return
			}
			self.videoPreviewLayer = layer
			layer.videoGravity = AVLayerVideoGravityResizeAspectFill
			self.view.layer.addSublayer(layer)
		}
		do {
			let view = UIView()
			self.qrCodeReticleView = view
			view.layer.borderColor = UIColor.utilityOrConstructiveLinkColor.cgColor
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
		if metadataObj.type != AVMetadataObjectTypeQRCode {
			assert(false)
			return
		}
		do {
			let barCodeObject = self.videoPreviewLayer.transformedMetadataObject(for: metadataObj)
			self.qrCodeReticleView.frame = barCodeObject!.bounds
		}
		if let stringValue = metadataObj.stringValue {
			if let fn = self.didLocateQRCodeMessageString_fn {
				fn(stringValue)
			}
		}
	}
}
