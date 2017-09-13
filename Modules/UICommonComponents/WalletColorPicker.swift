//
//  WalletColorPicker.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/20/17.
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

extension UICommonComponents
{
	class WalletColorPickerView: UIView
	{
		typealias Color = Wallet.SwatchColor
		// Properties - Static
		static let colors = Color.allOrdered()
		static let colors_count = WalletColorPickerView.colors.count
		// Properties - Init
		var optionViews: [WalletColorPickerOptionView]!
		// Properties - Runtime
		var currentlySelected_idx: Int?
		var currentlySelected_color: Color? {
			if let idx = self.currentlySelected_idx {
				return WalletColorPickerView.colors[idx]
			}
			return nil
		}
		//
		init(optl__currentlySelected_color: Wallet.SwatchColor?)
		{
			super.init(frame: .zero)
			self.setup()
			//
			let currentlySelected_color: Wallet.SwatchColor?
			do {
				if optl__currentlySelected_color != nil {
					currentlySelected_color = optl__currentlySelected_color
				} else {
					let alreadyInUseColors = WalletsListController.shared.givenBooted_swatchesInUse
					var aFreeColor: Wallet.SwatchColor?
					do {
						for (_, color) in WalletColorPickerView.colors.enumerated() {
							if alreadyInUseColors.contains(color) == false {
								aFreeColor = color
								break
							}
						}
					}
					if aFreeColor != nil {
						currentlySelected_color = aFreeColor
					} else {
						currentlySelected_color = WalletColorPickerView.colors.first! // just use the first one as all are already in use
					}
				}
			}
			if currentlySelected_color != nil {
				self.select(color: currentlySelected_color!)
			}
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			do {
				self.optionViews = WalletColorPickerOptionView.new_all_optionViews(
					tapped_fn:
					{ [unowned self] (option) in
						self.tapped(option: option)
					}
				)
				for (_, view) in optionViews.enumerated() {
					self.addSubview(view)
				}
			}
//			self.borderSubviews()
//			self.giveBorder()
		}
		//
		// Accessors - Layout
		var rowHeight: CGFloat
		{
			let bottomPadding = WalletColorPickerOptionView.cellPadding_side_v
			return WalletColorPickerOptionView.cellSize_side_v + bottomPadding
		}
		func returningNumberOfRows_enumerateOptions(
			numberOfOptions: Int,
			inParentWithWidth containerWidth: CGFloat,
			emittingOptionInformation_fn: ((
				_ optionIdx: Int,
				_ optionViewFrame: CGRect
			) -> Void)?
		) -> Int // numberOfRows (would be nice to name return value)
		{
			var rowIdx = 0
			var idxInRow = 0
			let rowHeight = self.rowHeight
			let cellSize_side_h = WalletColorPickerOptionView.cellSize_side_h
			let cellSize_side_v = WalletColorPickerOptionView.cellSize_side_v
			let cellPadding_side_h = WalletColorPickerOptionView.cellPadding_side_h
			let cellPadding_side_v = WalletColorPickerOptionView.cellPadding_side_v
			func new_origin() -> (x: CGFloat, y: CGFloat)
			{
				let x = CGFloat(idxInRow) * (WalletColorPickerOptionView.cellSize_side_h + cellPadding_side_h)
				let y = CGFloat(rowIdx) * rowHeight
				//
				return (x, y)
			}
			for optionIdx in 0..<numberOfOptions {
				var origin = new_origin()
				let option_rightEdgeX = origin.x + cellSize_side_h + cellPadding_side_h
				if option_rightEdgeX > containerWidth {
					rowIdx += 1
					idxInRow = 0 // return to origin on next row
					//
					origin = new_origin() // re-derive origin
				}
				if let fn = emittingOptionInformation_fn {
					let frame = CGRect(
						x: origin.x,
						y: origin.y,
						width: cellSize_side_h,
						height: cellSize_side_v
					)
					fn(optionIdx, frame)
				}				//
				// now tentatively advance to next column on same row (for next iteration calculation of new_origin)
				idxInRow += 1
			}
			//
			return rowIdx + 1 // idx -> whole number
		}
		func numberOfRowsToFit(inParentWithWidth width: CGFloat, numberOfOptions: Int) -> Int
		{
			let numberOfRows = self.returningNumberOfRows_enumerateOptions(
				numberOfOptions: numberOfOptions,
				inParentWithWidth: width,
				emittingOptionInformation_fn: nil
			)
			return numberOfRows
		}
		func numberOfRows(inParentWithWidth width: CGFloat) -> Int
		{
			return numberOfRowsToFit(
				inParentWithWidth: width,
				numberOfOptions: WalletColorPickerView.colors_count
			)
		}
		func heightThatFits(width parentWidth: CGFloat) -> CGFloat
		{
			let numberOfRows = self.numberOfRows(inParentWithWidth: parentWidth)
			let totalHeight = CGFloat(numberOfRows) * self.rowHeight
			//
			return totalHeight
		}
		//
		// Imperatives - State
		func select(color: Wallet.SwatchColor)
		{
			let to_idx = WalletColorPickerView.colors.index(of: color)!
			if let idx = self.currentlySelected_idx {
				if to_idx == idx {
					return // redundant
				}
				let selected_option = self.optionViews[idx]
				selected_option.set(isSelected: false)
			}
			self.currentlySelected_idx = to_idx
			let option = self.optionViews[to_idx]
			option.set(isSelected: true)
		}
		var isEnabled: Bool = true
		func set(isEnabled: Bool)
		{
			self.isEnabled = isEnabled
			optionViews.forEach
			{ (view) in
				view.set(isEnabled: isEnabled)
			}
		}
		//
		// Imperatives - Layout
		override func layoutSubviews()
		{
			super.layoutSubviews()
			
			let numberOfOptions = self.optionViews.count
			let containerWidth = self.frame.size.width
			let _ = self.returningNumberOfRows_enumerateOptions(
				numberOfOptions: numberOfOptions,
				inParentWithWidth: containerWidth,
				emittingOptionInformation_fn:
				{ (optionIdx, optionViewFrame) in
					let optionView = self.optionViews[optionIdx]
					optionView.frame = optionViewFrame
				}
			)
		}
		//
		// Delegation
		func tapped(option: WalletColorPickerOptionView)
		{
			self.select(color: option.color)
		}
	}
	//
	class WalletColorPickerOptionView: UIView
	{
		static func new_all_optionViews(tapped_fn: @escaping ((_ option: WalletColorPickerOptionView) -> Void)) -> [WalletColorPickerOptionView]
		{
			let colors = Wallet.SwatchColor.allOrdered()
			let views = colors.map
			{ (color) -> WalletColorPickerOptionView in
				let view = WalletColorPickerOptionView(color: color)
				view.tapped_fn = tapped_fn
				//
				return view
			}
			//
			return views
		}
		//
		static let backgroundImage = UICommonComponents.HighlightableCells.Variant.normal.stretchableImage
		static let selectedBackgroundImage = UICommonComponents.HighlightableCells.Variant.highlighted.stretchableImage
		static let disabledBackgroundImage = UICommonComponents.HighlightableCells.Variant.disabled.stretchableImage
		//
		static let cellSize_side_h: CGFloat = 88 + 2*UICommonComponents.HighlightableCells.imagePaddingForShadow_h
		static let cellSize_side_v: CGFloat = 88 + 2*UICommonComponents.HighlightableCells.imagePaddingForShadow_v
		static let visual__cellPadding_side_h: CGFloat = 9
		static let visual__cellPadding_side_v: CGFloat = 8
		static let cellPadding_side_h: CGFloat = visual__cellPadding_side_h - 2*UICommonComponents.HighlightableCells.imagePaddingForShadow_h
		static let cellPadding_side_v: CGFloat = visual__cellPadding_side_v - 2*UICommonComponents.HighlightableCells.imagePaddingForShadow_v
		//
		var tapped_fn: ((_ option: WalletColorPickerOptionView) -> Void)!
		//
		let iconView = WalletIconView(sizeClass: .large48)
		static let selectionIndicator_image = UIImage(named: "walletColorPicker_selectionIndicator_stretchable")!.stretchableImage(withLeftCapWidth: 8, topCapHeight: 8)
		static let selectionIndicator_disabled_image = UIImage(named: "walletColorPicker_selectionIndicator_disabled_stretchable")!.stretchableImage(withLeftCapWidth: 8, topCapHeight: 8)
		let selectionIndicatorView = UIImageView(image: selectionIndicator_image)
		//
		var color: Wallet.SwatchColor!
		//
		init(color: Wallet.SwatchColor)
		{
			super.init(frame: .zero)
			self.color = color
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.backgroundColor = .contentBackgroundColor
			self.isOpaque = true
			do {
				let view = self.iconView
				view.configure(withSwatchColor: self.color)
				self.addSubview(view)
			}
			do {
				let view = self.selectionIndicatorView
				self.addSubview(view)
				self.configure_selectionIndicator()
			}
			do {
				let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
				self.addGestureRecognizer(recognizer)
			}
		}
		//
		// Imperatives - State
		var isSelected: Bool = false
		func set(isSelected: Bool)
		{
			self.isSelected = isSelected
			self.configure_selectionIndicator()
		}
		var isBeingTouched: Bool = false
		func set(isBeingTouched: Bool)
		{
			self.isBeingTouched = isBeingTouched
			self.setNeedsDisplay() // to redraw bg
		}
		var isEnabled: Bool = true
		func set(isEnabled: Bool)
		{
			self.isEnabled = isEnabled
			self.setNeedsDisplay() // to redraw bg
			self.configure_selectionIndicator()
		}
		//
		// Imperatives - Configuration
		func configure_selectionIndicator()
		{
			self.selectionIndicatorView.isHidden = isSelected == false
			if self.isSelected {
				if self.isEnabled {
					self.selectionIndicatorView.image = WalletColorPickerOptionView.selectionIndicator_image
				} else {
					self.selectionIndicatorView.image = WalletColorPickerOptionView.selectionIndicator_disabled_image
				}
			}
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			self.iconView.frame = CGRect(
				x: (self.frame.size.width - self.iconView.frame.size.width)/2,
				y: (self.frame.size.height - self.iconView.frame.size.height)/2,
				width: self.iconView.frame.size.width,
				height: self.iconView.frame.size.height
			).integral
			self.selectionIndicatorView.frame = self.bounds.insetBy(
				dx: UICommonComponents.HighlightableCells.imagePaddingForShadow_h,
				dy: UICommonComponents.HighlightableCells.imagePaddingForShadow_v
			).integral
		}
		override func draw(_ rect: CGRect)
		{
			do {
				var image: UIImage!
				if self.isEnabled == false {
					image = WalletColorPickerOptionView.disabledBackgroundImage
				} else {
					if self.isBeingTouched {
						image = WalletColorPickerOptionView.selectedBackgroundImage
					} else {
						image = WalletColorPickerOptionView.backgroundImage
					}
				}
				image.draw(in: rect)
			}
			super.draw(rect)
		}
		//
		// Delegation - Interactions - Gestures
		func tapped()
		{
			if self.isEnabled == true {
				self.tapped_fn(self)
			}
		}
		//
		// Delegation - Interactions - Overrides
		override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
		{
			super.touchesBegan(touches, with: event)
			if self.isEnabled == true {
				self.set(isBeingTouched: true)
			}
		}
		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
		{
			super.touchesEnded(touches, with: event)
			self.set(isBeingTouched: false) // in case we disable while touching, do not filter to isEnabled=true to get back to ground state
		}
		override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
		{
			super.touchesCancelled(touches, with: event)
			self.set(isBeingTouched: false) // in case we disable while touching, do not filter to isEnabled=true to get back to ground state
		}
	}
}
