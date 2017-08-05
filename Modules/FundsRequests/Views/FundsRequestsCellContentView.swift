//
//  FundsRequestsCellContentView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
	let iconView = UICommonComponents.WalletIconView(sizeClass: .large43)
	let qrCodeMatteView = UIImageView(image: FundsRequestCellQRCodeMatteCells.stretchableImage)
	let qrCodeImageView = UIImageView()
	//
	let amountLabel = UILabel()
	let memoLabel = UILabel()
	let senderLabel = UILabel()
	//
	var willBeDisplayedWithRightSideAccessoryChevron = true // configurable after init, else also call self.setNeedsLayout
	//
	// Lifecycle - Init
	init()
	{
		super.init(frame: .zero)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.addSubview(self.iconView)
		self.addSubview(self.qrCodeMatteView)
		self.addSubview(self.qrCodeImageView)
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
		self.qrCodeImageView.image = object.qrCodeImage
		self.amountLabel.text = object.amount != nil ? "\(object.amount!) XMR" : "Any amount"
		self.senderLabel.text = object.from_fullname ?? "N/A"
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
		do {
			let visual__side = 24
			let side = visual__side + 2*FundsRequestCellQRCodeMatteCells.imagePaddingInset
			let visual__x = 36
			let visual__y = 36
			self.qrCodeMatteView.frame = CGRect(
				x: visual__x - FundsRequestCellQRCodeMatteCells.imagePaddingInset,
				y: visual__y - FundsRequestCellQRCodeMatteCells.imagePaddingInset,
				width: side,
				height: side
			)
			//
			let qrCodeInset: CGFloat = 2
			self.qrCodeImageView.frame = self.qrCodeMatteView.frame.insetBy(
				dx: CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset) + qrCodeInset,
				dy: CGFloat(FundsRequestCellQRCodeMatteCells.imagePaddingInset) + qrCodeInset
			)
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
	func _willBeDeleted()
	{
		self.tearDown_object() // stopObserving/release
	}
	func _willBeDeinitialized()
	{
		self.tearDown_object() // stopObserving/release
	}
}
