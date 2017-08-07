//
//  ConnectivityMessageViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/6/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
		let margin = UIEdgeInsetsMake(
			44/*janky way of approximating nav bar offset*/,
			8,
			0,
			8
		)
		let containerView_padding = UIEdgeInsetsMake(2, 0, 2, 0)
		let h: CGFloat = containerView_padding.top + 24 + containerView_padding.bottom
		let viewportWidth = UIScreen.main.bounds.size.width // is now always correct value regardless of statusBarOrientation
		let frame = CGRect(
			x: margin.left,
			y: statusBarFrame.origin.y + statusBarFrame.size.height + margin.top,
			width: viewportWidth - margin.left - margin.right,
			height: h
		)
		self.containerView.frame = frame
		self.label.frame = self.containerView.frame.insetBy(dx: 8, dy: 0)
	}
	//
	// Delegation - Status bar
}
