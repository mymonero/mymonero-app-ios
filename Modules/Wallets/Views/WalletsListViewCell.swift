//
//  WalletsListViewCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
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
