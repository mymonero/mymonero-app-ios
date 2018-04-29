//
//  FundsRequestDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/12/17.
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
	let sectionView_instanceCell = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
	let sectionView_codeAndLink = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
	let sectionView_message = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
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
		do {
			let sectionView = self.sectionView_instanceCell
			do {
				let view = UICommonComponents.Details.FundsRequestCellFieldView(
					fundsRequest: self.fundsRequest,
					displayMode: .noQRCode
				)
				sectionView.add(fieldView: view)
			}
			self.scrollView.addSubview(sectionView)
		}
		do {
			let sectionView = self.sectionView_codeAndLink
			do {
				let view = QRImageButtonDisplayingFieldView(
					labelVariant: self.fieldLabels_variant,
					title: NSLocalizedString("QR Code", comment: ""),
					tapped_fn:
					{ [unowned self] in
						self.qrImageFieldView_tapped()
					}
				)
				let image = QRCodeImages.new_qrCode_UIImage( // generating a new image here - is this performant enough?
					fromCGImage: self.fundsRequest.qrCode_cgImage,
					withQRSize: .medium
				)
				view.set(image: image)
				sectionView.add(fieldView: view)
			}
			do {
				let view = UICommonComponents.Details.SharableLongStringFieldView(
					labelVariant: self.fieldLabels_variant,
					title: NSLocalizedString("Request Link", comment: ""),
					valueToDisplayIfZero: nil
				)
				view.contentLabel.lineBreakMode = .byCharWrapping // flows better w/o awkward break
				let url = self.fundsRequest.new_URI(inMode: .addressAsAuthority) // clickable
				view.set(text: url.absoluteString, url: url)
				sectionView.add(fieldView: view)
			}
			self.scrollView.addSubview(sectionView)
		}
		do {
			let sectionView = self.sectionView_message
			do {
				let view = UICommonComponents.Details.SharableLongStringFieldView(
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
	// Accessors - Overrides
	override var overridable_wantsBackButton: Bool {
		return true
	}
	override func new_contentInset() -> UIEdgeInsets
	{
		var inset = super.new_contentInset()
		inset.bottom += 14
		
		return inset
	}
	//
	// Accessors - Factories
	var new_requesteeMessagePlaintextString: String
	{
		let hasAmount = self.fundsRequest.amount != nil && self.fundsRequest.amount != ""
		//
		//
		var value = "" // must use \r\n instead of \n for Windows
		if hasAmount == false {
			value += String(
				format: NSLocalizedString(
					"Someone has requested a %@ payment.",
					comment: ""
				),
				MoneroConstants.currency_name
			)
		} else {
			value += String(
				format: NSLocalizedString(
					"Someone has requested a %@ payment of %@ %@.",
					comment: ""
				),
				MoneroConstants.currency_name,
				self.fundsRequest.amount!,
				(self.fundsRequest.amountCurrency ?? MoneroConstants.currency_symbol)
			)
		}
		var numberOfLinesAddedInSection = 0
		do {
			if let message = self.fundsRequest.message, message != "" {
				value += "\r\n" // spacer
				value += "\r\n" // linebreak
				value += String(
					format: NSLocalizedString(
						"Memo: \"%@\"",
						comment: ""
					),
					message
				)
				numberOfLinesAddedInSection += 1
			}
			if let description = self.fundsRequest.description, description != "" {
				value += "\r\n" // spacer
				value += "\r\n" // linebreak
				value += String(
					format: NSLocalizedString(
						"Description: \"%@\"",
						comment: ""
					),
					description
				)
				numberOfLinesAddedInSection += 1
			}
		}
		value += "\r\n" // spacer
		value += "\r\n" // linebreak
		value += "------------"
		value += "\r\n" // linebreak
		value += NSLocalizedString("If you have MyMonero installed, use this link to send the funds: ", comment: "")
		value += self.fundsRequest.new_URI(inMode: .addressAsAuthority).absoluteString // addr as authority b/c we want it to be clickable
		value += "\r\n" // spacer
		value += "\r\n" // linebreak
		value += String(format:
			NSLocalizedString(
				"If you don't have MyMonero installed, download it from %@",
				comment: ""
			),
			Homepage.appDownloadLink_fullURL
		)
		//
		return value
	}
	var new_requesteeMessageNSAttributedString: NSAttributedString
	{
		let value = self.new_requesteeMessagePlaintextString
		let value_NSString = value as NSString
		let attributes: [NSAttributedStringKey : Any] = [:]
		let attributedString = NSMutableAttributedString(string: value, attributes: attributes)
		let linkColor = UIColor.white
		attributedString.addAttributes(
			[
				NSAttributedStringKey.foregroundColor: linkColor
			],
			range: value_NSString.range(of: self.fundsRequest.new_URI(inMode: .addressAsAuthority).absoluteString) // clickable addr
		)
		attributedString.addAttributes(
			[
				NSAttributedStringKey.foregroundColor: linkColor
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
		let subviewLayoutInsets = self.new_subviewLayoutInsets
		let label_x = CGFloat.form_label_margin_x + subviewLayoutInsets.left
		//
		let section_x = subviewLayoutInsets.left
		let section_w = self.scrollView/*not view*/.bounds.size.width - subviewLayoutInsets.left - subviewLayoutInsets.right
		self.sectionView_instanceCell.layOut(
			withContainingWidth: section_w, // since width may have been updated…
			withXOffset: section_x,
			andYOffset: self.yOffsetForViewsBelowValidationMessageView
		)
		self.sectionView_codeAndLink.layOut(
			withContainingWidth: section_w, // since width may have been updated…
			withXOffset: section_x,
			andYOffset: self.sectionView_instanceCell.frame.origin.y + self.sectionView_instanceCell.frame.size.height + UICommonComponents.Details.SectionView.interSectionSpacing
		)
		self.sectionView_message.layOut(
			withContainingWidth: section_w, // since width may have been updated…
			withXOffset: section_x,
			andYOffset: self.sectionView_codeAndLink.frame.origin.y + self.sectionView_codeAndLink.frame.size.height + UICommonComponents.Details.SectionView.interSectionSpacing
		)
		//
		self.deleteButton.frame = CGRect(
			x: label_x,
			y: self.sectionView_message.frame.origin.y + self.sectionView_message.frame.size.height + UICommonComponents.Details.SectionView.interSectionSpacing,
			width: self.deleteButton.frame.size.width,
			height: self.deleteButton.frame.size.height
		)
		//
		self.scrollableContentSizeDidChange(
			withBottomView: self.deleteButton,
			bottomPadding: 12
		) // btm padding in .contentInset
	}
	//
	// Delegation
	@objc func deleteButton_tapped()
	{
		let generator = UINotificationFeedbackGenerator()
		generator.prepare()
		generator.notificationOccurred(.warning)
		//
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
	//
	// Delegation - Notifications - Object
	@objc func wasDeleted()
	{ // was instead of willBe b/c willBe is premature and won't let us see a returned deletion error 
		// but we must perform this method's operations on next tick so as not to prevent delete()'s err_str from being returned before we can perform them
		DispatchQueue.main.async {
			if self.navigationController!.topViewController! != self {
				assert(false)
				return
			}
			self.navigationController!.popViewController(animated: true)
		}
	}
	//
	// Delegation - Interactions
	func qrImageFieldView_tapped()
	{
		let controller = FundsRequestQRDisplayViewController(fundsRequest: self.fundsRequest)
		let navigationController = UINavigationController(rootViewController: controller)
		self.navigationController!.present(navigationController, animated: true, completion: nil)
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
		var cellContentView: FundsRequestsCellContentView!
		//
		// Init
		init(
			fundsRequest: FundsRequest,
			displayMode: FundsRequestsCellContentView.DisplayMode? = .withQRCode
		) {
			do {
				let view = FundsRequestsCellContentView(displayMode: displayMode ?? .withQRCode)
				self.cellContentView = view
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
		) {
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

class QRImageButtonDisplayingFieldView: UICommonComponents.Details.ImageButtonDisplayingFieldView
{
	//
	// Properties
	var qrCodeMatteView: UIImageView!
	//
	// Properties - Overrides
	override var _bottomMostView: UIView {
		return self.qrCodeMatteView // to support proper bottom inset
	}
	//
	override func setup()
	{
		super.setup()
		do {
			let view = UIImageView(
				image: FundsRequestCellQRCodeMatteCells.stretchableImage
			)
			self.qrCodeMatteView = view
			self.insertSubview(view, at: 0) // underneath image
		}
	}
	//
	override func layOut_contentView(content_x: CGFloat, content_w: CGFloat)
	{
		// not going to call on super
		let qrCodeImageSide = QRCodeImages.QRSize.medium.side
		let qrCodeInsetFromMatteView: CGFloat = 3
		let offsetFromImage = CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset) + qrCodeInsetFromMatteView
		let qrCodeMatteViewSide: CGFloat = qrCodeImageSide + 2*offsetFromImage
		self.qrCodeMatteView!.frame = CGRect(
			x: content_x + 1 - CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset), // +1 for visual,
			y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 12 - CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset),
			width: qrCodeMatteViewSide,
			height: qrCodeMatteViewSide
		).integral
		self.contentImageButton.frame = self.qrCodeMatteView!.frame.insetBy(
			dx: offsetFromImage,
			dy: offsetFromImage
		).integral
	}
}
