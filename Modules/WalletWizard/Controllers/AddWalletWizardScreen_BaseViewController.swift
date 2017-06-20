//
//  AddWalletWizardScreen_BaseViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddWalletWizardScreen_BaseViewController: UIViewController, UIScrollViewDelegate
{
	//
	// Properties
	var scrollView: UIScrollView { return self.view as! UIScrollView }
	var wizardController: AddWallet_WizardController
	//
	// Lifecycle - Init
	required init(wizardController: AddWallet_WizardController)
	{
		self.wizardController = wizardController
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
	override func loadView()
	{
		self.view = UIScrollView()
		self.scrollView.delegate = self
	}
	func setup_views()
	{ // override but call on super
		self.view.backgroundColor = UIColor.contentBackgroundColor
		//
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
		self.view.addGestureRecognizer(tapGestureRecognizer)
	}
	func setup_navigation()
	{ // override but call on super
	}
	//
	// Delegation - View lifecycle
	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		if self.isMovingFromParentViewController {
			self._viewControllerIsBeingPoppedFrom()
		}
	}
	func _viewControllerIsBeingPoppedFrom()
	{ // overridable - and is overriden to set state back to what it should be per VC
	}
	//
	// Delegation - Scrollview
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
	{
		self.view.resignCurrentFirstResponder()
	}
	//
	// Delegation - Gesture recognition
	@objc func tapped()
	{
		self.view.resignCurrentFirstResponder()
	}
}
