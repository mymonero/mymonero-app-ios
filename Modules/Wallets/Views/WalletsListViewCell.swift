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
	static let cellHeight: CGFloat = 95 // TODO
	//
	let cellContentView = WalletCellContentView()
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
	}
}
