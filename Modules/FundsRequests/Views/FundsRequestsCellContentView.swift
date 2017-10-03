//
//  FundsRequestsCellContentView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
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

class FundsRequestCellQRCodeMatteCells
{
	static let imagePaddingInset = 3
	static let capThickness = Int(FundsRequestCellQRCodeMatteCells.imagePaddingInset + 3)
	static let stretchableImage = UIImage(named: "qrCodeMatteBG_stretchable")!.stretchableImage(
		withLeftCapWidth: FundsRequestCellQRCodeMatteCells.capThickness,
		topCapHeight: FundsRequestCellQRCodeMatteCells.capThickness
	)
}

class FundsRequestsCellContentView: UIView
{
	//
	// Constants
	enum DisplayMode
	{
		case withQRCode
		case noQRCode
	}
	//
	// Properties
	let displayMode: DisplayMode
	//
	let iconView = UICommonComponents.WalletIconView(sizeClass: .large43)
	var qrCodeMatteView: UIImageView?
	var qrCodeImageView: UIImageView?
	//
	let amountLabel = UILabel()
	let memoLabel = UILabel()
	let senderLabel = UILabel()
	//
	var willBeDisplayedWithRightSideAccessoryChevron = true // configurable after init, else also call self.setNeedsLayout
	//
	// Lifecycle - Init
	init(displayMode: DisplayMode)
	{
		self.displayMode = displayMode
		super.init(frame: .zero)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.addSubview(self.iconView)
		if self.displayMode == .withQRCode {
			self.qrCodeMatteView = UIImageView(image: FundsRequestCellQRCodeMatteCells.stretchableImage)
			self.addSubview(self.qrCodeMatteView!)
			//
			self.qrCodeImageView = UIImageView()
			self.addSubview(self.qrCodeImageView!)
		}
		do {
			let view = self.amountLabel
			view.textColor = UIColor(rgb: 0xFCFBFC)
			view.font = UIFont.middlingSemiboldSansSerif
			view.numberOfLines = 1
			self.addSubview(view)
		}
		do {
			let view = self.memoLabel
			view.textColor = UIColor(rgb: 0x9E9C9E)
			view.font = UIFont.middlingRegularMonospace
			view.numberOfLines = 1
			self.addSubview(view)
		}
		do {
			let view = self.senderLabel
			view.textColor = UIColor(rgb: 0x9E9C9E)
			view.font = UIFont.middlingRegularMonospace
			view.numberOfLines = 1
			view.textAlignment = .right
			view.lineBreakMode = .byTruncatingTail
			self.addSubview(view)
		}
	}
	//
	// Lifecycle - Teardown/Reuse
	deinit
	{
		self.tearDown_object()
	}
	func tearDown_object()
	{
		if self.object != nil {
			self.stopObserving_object()
			self.object = nil
		}
	}
	func prepareForReuse()
	{
		self.tearDown_object()
	}
	func stopObserving_object()
	{
		assert(self.object != nil)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
	}
		//
	// Accessors
	//
	// Imperatives - Configuration
	weak var object: FundsRequest? // prevent self from preventing object from being freed so we still get .willBeDeinitialized
	func configure(withObject object: FundsRequest)
	{
		if self.object != nil {
			self.prepareForReuse() // in case this is not being used in an actual UITableViewCell (which has a prepareForReuse)
		}
		assert(self.object == nil)
		self.object = object
		self._configureUI()
		self.startObserving_object()
	}
	func _configureUI()
	{
		assert(self.object != nil)
		let object = self.object!
		self.iconView.configure(withSwatchColor: object.to_walletSwatchColor)
		if self.displayMode == .withQRCode {
			self.qrCodeImageView!.image = object.cached__qrCode_image_small
		}
		self.amountLabel.text = object.amount != nil ? "\(object.amount!) XMR" : "Any amount"
		self.senderLabel.text = object.from_fullname ?? "" // appears to be better not to show 'N/A' in else case
		self.memoLabel.text = object.message ?? object.description ?? ""
	}
	//
	func startObserving_object()
	{
		assert(self.object != nil)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeinitialized), name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
	}
	//
	// Imperatives - Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.iconView.frame = CGRect(
			x: 16,
			y: 16,
			width: self.iconView.frame.size.width,
			height: self.iconView.frame.size.height
		)
		if self.displayMode == .withQRCode {
			do {
				let visual__side = 24
				let side = visual__side + 2*FundsRequestCellQRCodeMatteCells.imagePaddingInset
				let visual__x = 36
				let visual__y = 36
				self.qrCodeMatteView!.frame = CGRect(
					x: visual__x - FundsRequestCellQRCodeMatteCells.imagePaddingInset,
					y: visual__y - FundsRequestCellQRCodeMatteCells.imagePaddingInset,
					width: side,
					height: side
				)
				//
				let qrCodeInset: CGFloat = 2
				self.qrCodeImageView!.frame = self.qrCodeMatteView!.frame.insetBy(
					dx: CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset) + qrCodeInset,
					dy: CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset) + qrCodeInset
				)
			}
		}
		let labels_x: CGFloat = self.iconView.frame.origin.x + self.iconView.frame.size.width + 20
		let labels_rightMargin: CGFloat = self.willBeDisplayedWithRightSideAccessoryChevron ? 40 : 16
		let labels_width = self.frame.size.width - labels_x - labels_rightMargin
		self.amountLabel.frame = CGRect(
			x: labels_x,
			y: 22,
			width: labels_width,
			height: 16
		).integral
		self.amountLabel.sizeToFit() // to constrain to minimum width
		do {
			let amountLabelAndMargin_portionOf_labels_width = self.amountLabel.frame.size.width + 12
			let senderLabel_x = self.amountLabel.frame.origin.x + amountLabelAndMargin_portionOf_labels_width
			self.senderLabel.frame = CGRect(
				x: senderLabel_x,
				y: 22,
				width: labels_width - amountLabelAndMargin_portionOf_labels_width,
				height: 16
			).integral
		}
		self.memoLabel.frame = CGRect(
			x: labels_x,
			y: self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 1,
			width: labels_width,
			height: 20
		).integral
	}
	//
	// Delegation
	@objc func _willBeDeleted()
	{
		self.tearDown_object() // stopObserving/release
	}
	@objc func _willBeDeinitialized()
	{
		self.tearDown_object() // stopObserving/release
	}
}
