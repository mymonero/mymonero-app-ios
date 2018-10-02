//
//  ConnectivityMessageViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/6/17.
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
import UIKit
//
class ConnectivityMessageViewController: UIViewController
{
	//
	// Properties - Views
	let containerView = UIView(frame: .zero)
	let label = UILabel(frame: .zero)
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
		self.startObserving()
	}
	func setup_views()
	{
		do {
			let view = self.view!
			view.autoresizingMask = []
			view.isUserInteractionEnabled = false // do not intercept touches
			view.backgroundColor = .clear // to be clear
		}
		do {
			let view = self.containerView
			view.layer.masksToBounds = true // clip
			view.autoresizingMask = []
			view.layer.cornerRadius = 3
			view.layer.borderWidth = 1/UIScreen.main.scale // single pixel / hairline
			view.layer.borderColor = UIColor(red: 245/255, green: 230/255, blue: 125/255, alpha: 0.30).cgColor
			view.backgroundColor = UIColor(
				red: 49/255,
				green: 47/255,
				blue: 43/255,
				alpha: 1 // NOTE: opaque for readability
			)
			self.view.addSubview(view)
		}
		do {
			let view = self.label
			view.text = NSLocalizedString("No Internet Connection Found", comment: "")
			view.font = UIFont.smallSemiboldSansSerif
			view.textColor = UIColor(rgb: 0xF5E67E)
			self.view.addSubview(view)
		}
	}
	func startObserving()
	{
		self.startObserving_statusBarFrame()
	}
	func startObserving_statusBarFrame()
	{
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(UIApplicationWillChangeStatusBarFrame),
			name: UIApplication.willChangeStatusBarFrameNotification,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(UIApplicationDidChangeStatusBarFrame),
			name: UIApplication.didChangeStatusBarFrameNotification,
			object: nil
		)
	}
	//
	// Lifecycle - Deinit
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
		self.stopObserving_statusBarFrame()
	}
	func stopObserving_statusBarFrame()
	{
		NotificationCenter.default.removeObserver(
			self,
			name: UIApplication.willChangeStatusBarFrameNotification,
			object: nil
		)
		NotificationCenter.default.removeObserver(
			self,
			name: UIApplication.didChangeStatusBarFrameNotification,
			object: nil
		)
	}
	//
	// Imperatives - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		// this luckily gets called even when we do not set a flexibleWidth autoresizingMask… why?
		//
		let statusBarFrame = UIApplication.shared.statusBarFrame
		let margin = UIEdgeInsets.init(
			top: 0,
			left: 8,
			bottom: 0,
			right: 8
		)
		let containerView_padding = UIEdgeInsets.init(top: 2, left: 0, bottom: 2, right: 0)
		let h: CGFloat = containerView_padding.top + 24 + containerView_padding.bottom
		let viewportWidth = UIScreen.main.bounds.size.width // is now (in modern iOS versions) always correct value regardless of statusBarOrientation
		let final_safeAreaInsets = UIEdgeInsets.init( // because i just can't seem to get sampling the safeAreaInsets right in this particular case (b/c we want to keep self above any possible child of the rootViewController), I'm just going to opt to hardcode these values. It's actually probably an improvement anyway.
			top: 44 - 8,
			left: 44 + 8,
			bottom: 0,
			right: 44 + 8
		)
		let frame = CGRect(
			x: margin.left + final_safeAreaInsets.left,
			y: statusBarFrame.origin.y + statusBarFrame.size.height + margin.top + final_safeAreaInsets.top,
			width: viewportWidth - margin.left - margin.right - final_safeAreaInsets.left - final_safeAreaInsets.right,
			height: h
		)
		self.containerView.frame = frame
		self.label.frame = self.containerView.frame.insetBy(dx: 8, dy: 0)
	}
	//
	// Delegation - Notifications
	@objc func UIApplicationWillChangeStatusBarFrame(_ notification: Notification)
	{
		self.view.setNeedsLayout()
	}
	@objc func UIApplicationDidChangeStatusBarFrame(_ notification: Notification)
	{
		self.view.setNeedsLayout()
	}
}
