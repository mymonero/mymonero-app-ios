//
//  ContactDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class ContactDetailsViewController: UICommonComponents.Details.ViewController
{
	//
	// Constants/Types
	let fieldLabels_variant = UICommonComponents.Details.FieldLabel.Variant.middling
	//
	// Properties
	var contact: Contact
	//
	var sectionView = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
	//
	var address__fieldView: UICommonComponents.Details.CopyableLongStringFieldView!
	var cached_OAResolved_XMR_address__fieldView: UICommonComponents.Details.CopyableLongStringFieldView!
	var paymentID__fieldView: UICommonComponents.Details.CopyableLongStringFieldView!
	//
	var send_actionButtonView: UICommonComponents.ActionButton!
	var request_actionButtonView: UICommonComponents.ActionButton!
	//
	// Imperatives - Init
	init(contact: Contact)
	{
		self.contact = contact
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	//
	// Overrides
	override func setup_views()
	{
		super.setup_views()
		self.scrollView.contentInset = UIEdgeInsetsMake(14, 0, 14, 0)
		do {
			let sectionView = self.sectionView
			do {
				let view = UICommonComponents.Details.CopyableLongStringFieldView(
					labelVariant: self.fieldLabels_variant,
					title: NSLocalizedString("Address", comment: ""),
					valueToDisplayIfZero: NSLocalizedString("N/A", comment: "")
				)
				self.address__fieldView = view
				sectionView.add(fieldView: view)
			}
			do {
				let view = UICommonComponents.Details.CopyableLongStringFieldView(
					labelVariant: self.fieldLabels_variant,
					title: NSLocalizedString("Resolved Address (XMR)", comment: ""),
					valueToDisplayIfZero: NSLocalizedString("N/A", comment: "")
				)
				self.cached_OAResolved_XMR_address__fieldView = view
				sectionView.add(fieldView: view)
			}
			do {
				let view = UICommonComponents.Details.CopyableLongStringFieldView(
					labelVariant: self.fieldLabels_variant,
					title: NSLocalizedString("Payment ID", comment: ""),
					valueToDisplayIfZero: NSLocalizedString("N/A", comment: "")
				)
				self.paymentID__fieldView = view
				sectionView.add(fieldView: view)
			}
			self.scrollView.addSubview(sectionView)
		}
		do {
			do {
				let iconImage = UIImage(named: "actionButton_iconImage__send")!
				let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true, iconImage: iconImage)
				view.addTarget(self, action: #selector(send_tapped), for: .touchUpInside)
				view.setTitle(NSLocalizedString("Send", comment: ""), for: .normal)
				self.send_actionButtonView = view
				self.view.addSubview(view)
			}
			do {
				let iconImage = UIImage(named: "actionButton_iconImage__request")!
				let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: false, iconImage: iconImage)
				view.addTarget(self, action: #selector(request_tapped), for: .touchUpInside)
				view.setTitle(NSLocalizedString("Request", comment: ""), for: .normal)
				self.request_actionButtonView = view
				self.view.addSubview(view)
			}
		}
//		self.view.borderSubviews()
		self.configureSectionsWithObject()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.set_navigationTitle() // also to be called on contact info updated
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .edit,
			target: self,
			action: #selector(tapped_rightBarButtonItem)
		)
	}
	override var overridable_wantsBackButton: Bool {
		return true
	}
	//
	override func startObserving()
	{
		super.startObserving()
		NotificationCenter.default.addObserver(self, selector: #selector(willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.contact)
		NotificationCenter.default.addObserver(self, selector: #selector(infoUpdated), name: Contact.NotificationNames.infoUpdated.notificationName, object: self.contact)
	}
	override func stopObserving()
	{
		super.stopObserving()
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.contact)
		NotificationCenter.default.removeObserver(self, name: Contact.NotificationNames.infoUpdated.notificationName, object: self.contact)
	}
	//
	// Imperatives
	func set_navigationTitle()
	{
		self.navigationItem.title = "\(self.contact.emoji!)   \(self.contact.fullname!)"
	}
	func configureSectionsWithObject()
	{
		self.address__fieldView.set(text: self.contact.address)
		if let value = self.contact.cached_OAResolved_XMR_address {
			self.cached_OAResolved_XMR_address__fieldView.set(text: value)
			self.cached_OAResolved_XMR_address__fieldView.isHidden = false
		} else {
			self.cached_OAResolved_XMR_address__fieldView.isHidden = true
		}
		self.paymentID__fieldView.set(text: self.contact.payment_id)
		//
		self.view.setNeedsLayout()
	}
	//
	// Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		self.sectionView.sizeToFitAndLayOutSubviews(
			withContainingWidth: self.view.bounds.size.width, // since width may have been updated…
			withXOffset: 0,
			andYOffset: 0
		)
		self.scrollableContentSizeDidChange(withBottomView: self.sectionView, bottomPadding: 0) // btm padding in .contentInset
		//
		// non-scrolling:
		let buttons_y = self.view.bounds.size.height - UICommonComponents.ActionButton.wholeButtonsContainerHeight_withoutTopMargin
		self.send_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
		self.request_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
	}
	//
	// Delegation
	func tapped_rightBarButtonItem()
	{
		let viewController = EditContactFormViewController(withContact: self.contact)
		let presenting_viewController = UINavigationController(rootViewController: viewController)
		self.navigationController!.present(presenting_viewController, animated: true, completion: nil)
	}
	//
	func willBeDeleted()
	{
		if self.navigationController!.topViewController! != self {
			assert(false)
			return
		}
		self.navigationController!.popViewController(animated: true)
	}
	func infoUpdated()
	{
		self.set_navigationTitle()
		self.configureSectionsWithObject()
	}
	//
	// Delegation - Interactions - Action buttons
	func send_tapped()
	{
		assert(false, "TODO")
	}
	func request_tapped()
	{
		assert(false, "TODO")
	}
}
