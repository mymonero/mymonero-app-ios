//
//  WalletsListViewCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WalletsListViewCell: UITableViewCell
{
	static let reuseIdentifier = "WalletsListViewCell"
	static let contentViewHeight: CGFloat = 80
	static let contentView_margin_h: CGFloat = 16
	static let cellSpacing: CGFloat = 12
	static let cellHeight: CGFloat = contentViewHeight + cellSpacing
	//
	let cellContentView = WalletCellContentView(sizeClass: .large48)
	let accessoryChevronView = UIImageView(image: UIImage(named: "list_rightside_chevron")!)
	//
	// Lifecycle - Init
	init()
	{
		super.init(style: .default, reuseIdentifier: WalletsListViewCell.reuseIdentifier)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.setup_views()
	}
	func setup_views()
	{
		self.isOpaque = true // performance
		self.backgroundColor = UIColor.contentBackgroundColor
		//
		self.backgroundView = UIImageView(image: UICommonComponents.HighlightableCells.Variant.normal.stretchableImage)
		self.selectedBackgroundView = UIImageView(image: UICommonComponents.HighlightableCells.Variant.highlighted.stretchableImage)
		//
		self.contentView.addSubview(self.cellContentView)
		//
		do {
			self.contentView.addSubview(self.accessoryChevronView)
		}
	}
	//
	// Lifecycle - Deinit
	deinit
	{
		self.prepareForReuse()
	}
	override func prepareForReuse()
	{
		self.cellContentView.prepareForReuse()
	}
	//
	// Imperatives - Configuration
	func configure(withObject object: Wallet)
	{
		self.cellContentView.configure(withObject: object)
	}
	//
	// Overrides - Imperatives - Layout
	override func layoutSubviews()
	{
		super.layoutSubviews()
		let frame = UIEdgeInsetsInsetRect(
			self.bounds,
			UIEdgeInsetsMake(
				0,
				WalletsListViewCell.contentView_margin_h - UICommonComponents.HighlightableCells.imagePaddingForShadow_h,
				WalletsListViewCell.cellSpacing - 2*UICommonComponents.HighlightableCells.imagePaddingForShadow_v,
				WalletsListViewCell.contentView_margin_h - UICommonComponents.HighlightableCells.imagePaddingForShadow_h
			)
		)
		self.contentView.frame = frame
		self.backgroundView!.frame = frame
		self.selectedBackgroundView!.frame = frame
		self.cellContentView.frame = self.contentView.bounds.insetBy(
			dx: UICommonComponents.HighlightableCells.imagePaddingForShadow_h,
			dy: UICommonComponents.HighlightableCells.imagePaddingForShadow_v
		)
		self.accessoryChevronView.frame = CGRect(
			x: frame.size.width - self.accessoryChevronView.frame.size.width - 16,
			y: frame.origin.y + (frame.size.height - self.accessoryChevronView.frame.size.height)/2,
			width: self.accessoryChevronView.frame.size.width,
			height: self.accessoryChevronView.frame.size.height
		).integral
	}
}
