//
//  FundsRequestDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
import PKHUD

class FundsRequestDetailsViewController: UICommonComponents.Details.ViewController
{
	//
	// Constants/Types
	let fieldLabels_variant = UICommonComponents.Details.FieldLabel.Variant.middling
	//
	// Properties
	var fundsRequest: FundsRequest
	//
	var sectionView_instanceCell = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
	var sectionView_link = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
	var sectionView_message = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
	var deleteButton: UICommonComponents.LinkButtonView!
	//
	//
	// Imperatives - Init
	init(fundsRequest: FundsRequest)
	{
		self.fundsRequest = fundsRequest
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
		self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 14, 0)
		do {
			let sectionView = self.sectionView_instanceCell
			do {
				let view = UICommonComponents.Details.FundsRequestCellFieldView(fundsRequest: self.fundsRequest)
				sectionView.add(fieldView: view)
			}
			self.scrollView.addSubview(sectionView)
		}
		do {
			let sectionView = self.sectionView_link
			do {
				let view = UICommonComponents.Details.CopyableLongStringFieldView(
					labelVariant: self.fieldLabels_variant,
					title: NSLocalizedString("Request Link", comment: ""),
					valueToDisplayIfZero: nil
				)
				view.contentLabel.lineBreakMode = .byCharWrapping // flows better w/o awkward break
				view.set(text: self.fundsRequest.new_URI.absoluteString)
				sectionView.add(fieldView: view)
			}
			self.scrollView.addSubview(sectionView)
		}
		do {
			let sectionView = self.sectionView_message
			do {
				let view = UICommonComponents.Details.CopyableLongStringFieldView(
					labelVariant: self.fieldLabels_variant,
					title: NSLocalizedString("Message for Requestee", comment: ""),
					valueToDisplayIfZero: nil
				)
				view.set(
					text: self.new_requesteeMessagePlaintextString,
					ifNonNil_overridingTextAndZeroValue_attributedDisplayText: self.new_requesteeMessageNSAttributedString
				)
				sectionView.add(fieldView: view)
			}
			self.scrollView.addSubview(sectionView)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_destructive, title: "DELETE REQUEST")
			view.addTarget(self, action: #selector(deleteButton_tapped), for: .touchUpInside)
			self.deleteButton = view
			self.scrollView.addSubview(view)
		}
		//		self.view.borderSubviews()
		self.view.setNeedsLayout()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.set_navigationTitle() // also to be called on contact info updated
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem),
			title_orNilForDefault: NSLocalizedString("Download", comment: "")
		)
	}
	override var overridable_wantsBackButton: Bool {
		return true
	}
	//
	override func startObserving()
	{
		super.startObserving()
		NotificationCenter.default.addObserver(self, selector: #selector(wasDeleted), name: PersistableObject.NotificationNames.wasDeleted.notificationName, object: self.fundsRequest)
	}
	override func stopObserving()
	{
		super.stopObserving()
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.wasDeleted.notificationName, object: self.fundsRequest)
	}
	//
	// Accessors - Factories
	var new_requesteeMessagePlaintextString: String
	{
		var value = "" // must use \r\n instead of \n for Windows
		value += "Someone wants some Monero."
		value += "\r\n------------"
		var numberOfLinesAddedAfterJustPreviousSeparator = 0
		do {
			if let amount = self.fundsRequest.amount, amount != "" {
				value += "\r\n\(amount) XMR"
				numberOfLinesAddedAfterJustPreviousSeparator += 1
			}
			if let message = self.fundsRequest.message, message != "" {
				value += "\r\n\(message)"
				numberOfLinesAddedAfterJustPreviousSeparator += 1
			}
			if let description = self.fundsRequest.description, description != "" {
				value += "\r\n\(description)"
				numberOfLinesAddedAfterJustPreviousSeparator += 1
			}
		}
		value += "\r\n" // spacer
		if numberOfLinesAddedAfterJustPreviousSeparator > 0 {
			value += "\r\n------------"
		}
		value += "\r\nIf you have MyMonero installed, use this link to send the funds: \(self.fundsRequest.new_URI.absoluteString)"
		value += "\r\n" // spacer
		value += "\r\nIf you don't have MyMonero installed, download it from \(Homepage.appDownloadLink_fullURL)"
		//
		return value
	}
	var new_requesteeMessageNSAttributedString: NSAttributedString
	{
		let value = self.new_requesteeMessagePlaintextString
		let value_NSString = value as NSString
		let attributes: [String: Any] = [:]
		let attributedString = NSMutableAttributedString(string: value, attributes: attributes)
		let linkColor = UIColor.white
		attributedString.addAttributes(
			[
				NSForegroundColorAttributeName: linkColor
			],
			range: value_NSString.range(of: self.fundsRequest.new_URI.absoluteString)
		)
		attributedString.addAttributes(
			[
				NSForegroundColorAttributeName: linkColor
			],
			range: value_NSString.range(of: Homepage.appDownloadLink_fullURL)
		)
		//
		return attributedString
	}
	//
	// Imperatives
	func set_navigationTitle()
	{
		self.navigationItem.title = NSLocalizedString("Monero Request", comment: "")
	}
	//
	// Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		self.sectionView_instanceCell.layOut(
			withContainingWidth: self.view.bounds.size.width, // since width may have been updated…
			withXOffset: 0,
			andYOffset: self.yOffsetForViewsBelowValidationMessageView
		)
		//
		self.sectionView_link.layOut(
			withContainingWidth: self.view.bounds.size.width, // since width may have been updated…
			withXOffset: 0,
			andYOffset: self.sectionView_instanceCell.frame.origin.y + self.sectionView_instanceCell.frame.size.height + UICommonComponents.Details.SectionView.interSectionSpacing
		)
		//
		self.sectionView_message.layOut(
			withContainingWidth: self.view.bounds.size.width, // since width may have been updated…
			withXOffset: 0,
			andYOffset: self.sectionView_link.frame.origin.y + self.sectionView_link.frame.size.height + UICommonComponents.Details.SectionView.interSectionSpacing
		)
		//
		self.deleteButton.frame = CGRect(
			x: CGFloat.form_label_margin_x,
			y: self.sectionView_message.frame.origin.y + self.sectionView_message.frame.size.height + UICommonComponents.Details.SectionView.interSectionSpacing,
			width: self.deleteButton.frame.size.width,
			height: self.deleteButton.frame.size.height
		)
		//
		self.scrollableContentSizeDidChange(withBottomView: self.deleteButton, bottomPadding: 12) // btm padding in .contentInset
	}
	//
	// Delegation
	func deleteButton_tapped()
	{
		let alertController = UIAlertController(
			title: NSLocalizedString("Delete this request?", comment: ""),
			message: NSLocalizedString(
				"Delete this request? This cannot be undone.",
				comment: ""
			),
			preferredStyle: .alert
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Delete", comment: ""),
				style: .destructive
				)
			{ (result: UIAlertAction) -> Void in
				let err_str = FundsRequestsListController.shared.givenBooted_delete(listedObject: self.fundsRequest)
				if err_str != nil {
					self.setValidationMessage(err_str!)
					return
				}
				// wait for wasDeleted()
			}
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Cancel", comment: ""),
				style: .default
				)
			{ (result: UIAlertAction) -> Void in
			}
		)
		self.navigationController!.present(alertController, animated: true, completion: nil)
	}
	func tapped_rightBarButtonItem()
	{
		UIImageWriteToSavedPhotosAlbum(self.fundsRequest.qrCodeImage, self, #selector(_savedToPhotosAlbum(image:error:context:)), nil)
	}
	func _savedToPhotosAlbum(image: UIImage?, error: Error?, context: Any?)
	{
		if error != nil {
			let alertController = UIAlertController(
				title: NSLocalizedString("Error saving QR Code", comment: ""),
				message: NSLocalizedString("Please ensure MyMonero can access Photos via iOS Settings > Privacy.", comment: ""),
				// error!.localizedDescription doesn't appear to be a good match to display here
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
			self.navigationController!.present(alertController, animated: true, completion: nil)
			return
		}
		HUD.flash(
			.label(
				NSLocalizedString("Saved to Camera Roll album.", comment: "")
			),
			delay: 1
		)
	}
	//
	// Delegation - Notifications - Object
	func wasDeleted()
	{ // was instead of willBe b/c willBe is premature and won't let us see a returned deletion error 
		if self.navigationController!.topViewController! != self {
			assert(false)
			return
		}
		self.navigationController!.popViewController(animated: true)
	}
}
//
//
extension UICommonComponents.Details
{
	class FundsRequestCellFieldView: UICommonComponents.Details.FieldView
	{
		//
		// Constants - Overrides
		override var contentInsets: UIEdgeInsets {
			return UIEdgeInsetsMake(0, 0, 0, 0)
		}
		//
		// Constants
		static let cellHeight: CGFloat = 80
		//
		// Properties
		let cellContentView = FundsRequestsCellContentView()
		//
		// Init
		init(fundsRequest: FundsRequest)
		{
			do {
				let view = self.cellContentView
				view.willBeDisplayedWithRightSideAccessoryChevron = false // so we get proper right margin
				view.configure(withObject: fundsRequest)
			}
			super.init()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			super.setup()
			self.addSubview(self.cellContentView)
		}
		//
		// Imperatives - Layout - Overrides
		override func layOut(
			withContainerWidth containerWidth: CGFloat,
			withXOffset xOffset: CGFloat,
			andYOffset yOffset: CGFloat
			)
		{
			let contentInsets = self.contentInsets
			let content_x: CGFloat = contentInsets.left
			let content_rightMargin: CGFloat = contentInsets.right
			let content_w = containerWidth - content_x - content_rightMargin
			//
			self.cellContentView.frame = CGRect(
				x: content_x,
				y: contentInsets.top,
				width: content_w,
				height: FundsRequestCellFieldView.cellHeight
			)
			//
			self.frame = CGRect(
				x: xOffset,
				y: yOffset,
				width: containerWidth,
				height: FundsRequestCellFieldView.cellHeight
			)
		}
	}
}
