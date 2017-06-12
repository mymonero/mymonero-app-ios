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
	static let cellHeight: CGFloat = 100
	//
	let cellContentView = WalletCellContentView()
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
		let capSize = 5 // TODO: factor/centralize with PushButtons' capSize
		self.backgroundView = UIImageView(image: UIImage(named: "highlightableCellBG_utility")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize))
		self.selectedBackgroundView = UIImageView(image: UIImage(named: "highlightableCellBG_utility_highlighted")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize))
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
		self.object = nil
	}
	//
	// Imperatives - Configuration
	var object: Wallet?
	func configure(withObject object: Wallet)
	{
		assert(self.object == nil)
		self.object = object
		self.cellContentView.configure(withObject: object)
	}
	//
	// Overrides - Imperatives - Layout
	override func layoutSubviews()
	{
		super.layoutSubviews()
		let frame = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(0, 16, 16, 16))
		self.contentView.frame = frame
		self.backgroundView!.frame = frame
		self.selectedBackgroundView!.frame = frame
		self.cellContentView.frame = self.contentView.bounds
		self.accessoryChevronView.frame = CGRect(
			x: frame.size.width - self.accessoryChevronView.frame.size.width - 16,
			y: frame.origin.y + (frame.size.height - self.accessoryChevronView.frame.size.height)/2,
			width: self.accessoryChevronView.frame.size.width,
			height: self.accessoryChevronView.frame.size.height
		).integral
	}
}
