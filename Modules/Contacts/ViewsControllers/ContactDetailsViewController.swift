//
//  ContactDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
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

class ContactDetailsViewController: UICommonComponents.Details.ViewController
{
	//
	// Constants/Types
	let fieldLabels_variant = UICommonComponents.Details.FieldLabel.Variant.middling
	//
	// Properties
	var contact: Contact // strong
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
	// Accessors - Overrides
	override func new_contentInset() -> UIEdgeInsets
	{
		var inset = super.new_contentInset()
		inset.bottom += UICommonComponents.ActionButton.wholeButtonsContainerHeight
		
		return inset
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
		let subviewLayoutInsets = self.new_subviewLayoutInsets
		//
		let section_x = subviewLayoutInsets.left
		let section_w = self.scrollView/*not view*/.bounds.size.width - subviewLayoutInsets.left - subviewLayoutInsets.right
		//
		self.sectionView.layOut(
			withContainingWidth: section_w, // since width may have been updated…
			withXOffset: section_x,
			andYOffset: self.yOffsetForViewsBelowValidationMessageView
		)
		self.scrollableContentSizeDidChange(
			withBottomView: self.sectionView,
			bottomPadding: 0
		) // btm padding (for action btns) in .contentInset
		//
		// non-scrolling:
		let buttons_y = self.view.bounds.size.height - UICommonComponents.ActionButton.wholeButtonsContainerHeight_withoutTopMargin
		self.send_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
		self.request_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
	}
	//
	// Delegation
	@objc func tapped_rightBarButtonItem()
	{
		let viewController = EditContactFormViewController(withContact: self.contact)
		let presenting_viewController = UINavigationController(rootViewController: viewController)
		presenting_viewController.modalPresentationStyle = .formSheet
		self.navigationController!.present(presenting_viewController, animated: true, completion: nil)
	}
	//
	@objc func willBeDeleted()
	{
		if self.navigationController!.topViewController! != self {
			assert(false)
			return
		}
		self.navigationController!.popViewController(animated: true)
	}
	@objc func infoUpdated()
	{
		self.set_navigationTitle()
		self.configureSectionsWithObject()
	}
	//
	// Delegation - Interactions - Action buttons
	@objc func send_tapped()
	{
		WalletAppContactActionsCoordinator.Trigger_sendFunds(toContact: self.contact)
	}
	@objc func request_tapped()
	{
		WalletAppContactActionsCoordinator.Trigger_requestFunds(fromContact: self.contact)
	}
}
