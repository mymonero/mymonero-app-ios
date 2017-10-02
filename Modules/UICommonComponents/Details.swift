//
//  Details.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
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
	struct Details
	{
		//
		// Principal View Controller
		class ViewController: ScrollableValidatingInfoViewController
		{
		}
		//
		// Table view variation
		class TableView: UITableView
		{
			override func touchesShouldCancel(in view: UIView) -> Bool
			{
				if view is UIButton { // prevent buttons from preventing self from scrolling, catching user pan
					return true
				}
				return super.touchesShouldCancel(in: view)
			}
		}
		//
		// Sections
		class SectionView: UIView
		{
			//
			// Constants/Types
			static let interSectionSpacing: CGFloat = 22
			//
			// Properties
			var sectionHeaderTitle: String?
			//
			var titleLabel: SectionLabel?
			var containerView = SectionContentContainerView()
			//
			// Init
			init(sectionHeaderTitle: String?)
			{
				self.sectionHeaderTitle = sectionHeaderTitle
				super.init(frame: .zero)
				self.setup()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			func setup()
			{
				if let text = self.sectionHeaderTitle {
					let view = SectionLabel(title: text)
					self.titleLabel = view
					self.addSubview(view)
				}
				self.addSubview(self.containerView)
			}
			//
			// Overrides - Imperatives
			override func layoutSubviews()
			{
				super.layoutSubviews()
				// in this case, not going to use layoutSubviews
			}
			//
			// Imperatives
			func add(fieldView: FieldView)
			{
				self.containerView.add(fieldView: fieldView)
			}
			func layOut(
				withContainingWidth containingWidth: CGFloat,
				withXOffset xOffset: CGFloat,
				andYOffset yOffset: CGFloat
			)
			{
				self.layOutSubviews(
					withContainingWidth: containingWidth,
					withXOffset: xOffset,
					andYOffset: yOffset
				)
				self.frame = CGRect(
					x: xOffset,
					y: yOffset,
					width: containingWidth,
					height: self.containerView.frame.origin.y + self.containerView.frame.size.height
				)
			}
			func layOutSubviews(
				withContainingWidth containingWidth: CGFloat,
				withXOffset xOffset: CGFloat,
				andYOffset yOffset: CGFloat
			)
			{
				var contentContainerView_yOffset: CGFloat = 0
				if let view = self.titleLabel {
					view.frame = CGRect(
						x: SectionLabel.x,
						y: 0,
						width: containingWidth - 2 * SectionLabel.x,
						height: view.frame.size.height
					)
					contentContainerView_yOffset += view.frame.origin.y + view.frame.size.height + SectionLabel.marginBelowLabelAboveSectionContentContainerView
				}
				let sectionContentsContainingWidth = containingWidth - xOffset
				let containerView_frame = self.containerView.sizeAndLayOutFieldViewsForDisplay_andReturnMeasuredSelfFrame(
					withContainingWidth: sectionContentsContainingWidth,
					andYOffset: contentContainerView_yOffset
				)
				self.containerView.frame = containerView_frame
			}
		}
		class SectionLabel: UILabel
		{
			//
			// Properties - Static
			static let x: CGFloat = 32
			static let h: CGFloat = 13
			//
			static let visual_marginBelow: CGFloat = 7
			static let marginBelowLabelAboveSectionContentContainerView: CGFloat = SectionLabel.visual_marginBelow
			//
			// Lifecycle - Init
			init(title: String)
			{
				let frame = CGRect(
					x: SectionLabel.x,
					y: 0,
					width: 0,
					height: SectionLabel.h
				)
				super.init(frame: frame)
				self.text = title
				self.setup()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			func setup()
			{
				self.font = UIFont.smallRegularMonospace
				self.textColor = UIColor(rgb: 0x9E9C9E)
				self.numberOfLines = 1
			}
		}
		class SectionContentContainerView: UIView
		{
			//
			// Constants
			static let x: CGFloat = 16
			//
			// Properties
			
			//
			// Init
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
				self.layer.borderColor = UICommonComponents.Details.FieldSeparatorView.Mode.contentBackgroundAccent.color.cgColor
				self.layer.borderWidth = UICommonComponents.Details.FieldSeparatorView.h
				self.layer.cornerRadius = 5
			}
			//
			// Imperatives
			var fieldViews: [FieldView] = []
			var fieldSeparatorViews: [FieldSeparatorView] = []
			func add(fieldView: FieldView)
			{
				if self.fieldViews.count > 0 {
					let separatorView = FieldSeparatorView(mode: .detailsSectionFieldDelimiter)
					fieldSeparatorViews.append(separatorView)
					self.addSubview(separatorView)
				}
				self.fieldViews.append(fieldView)
				self.addSubview(fieldView)
			}
			func removeAllFieldViews()
			{
				if self.fieldViews.count > 0 {
					for (_, fieldView) in self.fieldViews.enumerated() {
						fieldView.removeFromSuperview()
					}
					self.fieldViews = []
				}
				if self.fieldSeparatorViews.count > 0 {
					for (_, fieldSeparatorView) in self.fieldSeparatorViews.enumerated() {
						fieldSeparatorView.removeFromSuperview()
					}
					self.fieldSeparatorViews = []
				}
			}
			func set(fieldViews to_fieldViews: [FieldView])
			{
				self.removeAllFieldViews()
				for (_, fieldView) in to_fieldViews.enumerated() {
					self.add(fieldView: fieldView)
				}
			}
			//
			// - Layout
			func sizeAndLayOutFieldViewsForDisplay_andReturnMeasuredSelfFrame(
				withContainingWidth containingWidth: CGFloat,
				andYOffset yOffset: CGFloat
			) -> CGRect
			{
				let selfFrame = self.sizeAndLayOutGivenFieldViews_andReturnMeasuredSelfFrame(
					withContainingWidth: containingWidth,
					andYOffset: yOffset,
					givenSpecificFieldViews: self.fieldViews,
					alsoLayOutSharedSeparatorViewsForDisplay: true // because layOut() is for immediate display
				)
				return selfFrame
			}
			func sizeAndLayOutGivenFieldViews_andReturnMeasuredSelfFrame(
				withContainingWidth containingWidth: CGFloat,
				andYOffset yOffset: CGFloat,
				givenSpecificFieldViews specific_fieldViews: [FieldView],
				alsoLayOutSharedSeparatorViewsForDisplay: Bool // pass false if you actually only want to use this to measure the fieldViews
			) -> CGRect
			{
				let self_width = containingWidth - 2*UICommonComponents.Details.SectionContentContainerView.x
				let frame_withoutHeight = CGRect(
					x: UICommonComponents.Details.SectionContentContainerView.x,
					y: yOffset,
					width: self_width,
					height: 0
				)
				let numberOfFields = specific_fieldViews.count
				if numberOfFields == 0 {
					return frame_withoutHeight
				}
				var currentField_yOffset: CGFloat = 0
				for (idx, fieldView) in specific_fieldViews.enumerated() {
					let isNotYetAtEnd = idx < numberOfFields - 1
					if fieldView.isHidden == true {
						if isNotYetAtEnd {
							if alsoLayOutSharedSeparatorViewsForDisplay {
								let separatorView = self.fieldSeparatorViews[idx] // we expect there to be one
								separatorView.isHidden = true
							}
						}
						continue // skip
					}
					//
					// fieldViews are actually sized here - it might be nicer if we could just measure them instead
					fieldView.layOut(
						withContainerWidth: self_width,
						withXOffset: 0,
						andYOffset: currentField_yOffset
					)
					currentField_yOffset = fieldView.frame.origin.y + fieldView.frame.size.height
					//
					if isNotYetAtEnd { // any but the last field
						// updating currentField_yOffset - not adding .bottom inset (twice) since (a) we just added .bottom, and (b) next field has .top
						let h = FieldSeparatorView.h
						let topMargin: CGFloat = 0 // just calling these out
						let bottomMargin: CGFloat = 0
						if alsoLayOutSharedSeparatorViewsForDisplay { // should be true if we actually intend to display the fieldViews right here rather than just measure them
							let separatorView = self.fieldSeparatorViews[idx] // we expect there to be one
							separatorView.isHidden = false // just in case it was hidden
							let contentInsets = fieldView.contentInsets
							separatorView.frame = CGRect(
								x: contentInsets.left,
								y: currentField_yOffset + topMargin,
								width: self_width - contentInsets.left, // no right offset - flush with edge
								height: FieldSeparatorView.h
							)
							currentField_yOffset = separatorView.frame.origin.y + separatorView.frame.size.height + bottomMargin // update - but do not add .bottom inset (twice) since (a) we just added .bottom, and (b) next field has .top
						} else { // just use the fixed height
							currentField_yOffset += topMargin + h + bottomMargin
						}
					}
				}
				var frame_withHeight = frame_withoutHeight
				do { // finalize
					let last_fieldView = specific_fieldViews.last!
					frame_withHeight.size.height = last_fieldView.frame.origin.y + last_fieldView.frame.size.height
				}
				return frame_withHeight
			}
		}
		//
		// Field & field separator views
		class FieldView: UIView
		{
			//
			// Constants
			var contentInsets: UIEdgeInsets { // override
				return UIEdgeInsetsMake(0, 0, 0, 0)
			}
			//
			// Properties
			//
			// Init
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
			}
			//
			func layOut(
				withContainerWidth containerWidth: CGFloat, // containER width does not account for contentOffsets
				withXOffset xOffset: CGFloat, // again, without contentOffset.left
				andYOffset yOffset: CGFloat // also w/o contentOffset.top
			)
			{
				assert(false, "Override and implement this")
			}
		}
		class FieldSeparatorView: UIView
		{
			//
			static let h: CGFloat = 1/UIScreen.main.scale
			//
			enum Mode
			{
				case detailsSectionFieldDelimiter
				case contiguousCellContainer
				case contentBackgroundAccent
				var color: UIColor {
					switch self {
						case .detailsSectionFieldDelimiter:
							return UIColor(rgb: 0x494749)
						case .contiguousCellContainer:
							return UIColor(rgb: 0x413e40)
						case .contentBackgroundAccent:
							return UIColor(rgb: 0x494749) // was 383638 but 494749 looks better
					}
				}
			}
			//
			var mode: Mode
			//
			init(mode: Mode)
			{
				self.mode = mode
				let frame = CGRect(x: 0, y: 0, width: 0, height: FieldSeparatorView.h)
				super.init(frame: frame)
				self.backgroundColor = mode.color
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
		}
		//
		class CopyableLongStringFieldView: UtilityActionableLongStringFieldView
		{
			override class func valueButtonClass() -> SmallUtilityValueButton.Type {
				return SmallUtilityCopyValueButton.self
			}
			override func set(
				text: String?,
				ifNonNil_overridingTextAndZeroValue_attributedDisplayText: NSAttributedString?
			)
			{
				super.set(
					text: text,
					ifNonNil_overridingTextAndZeroValue_attributedDisplayText: ifNonNil_overridingTextAndZeroValue_attributedDisplayText
				)
				self.copyButton.set(text: text) // even if nil
			}
			//
			// Accessors
			var copyButton: SmallUtilityCopyValueButton {
				return self.valueButton as! SmallUtilityCopyValueButton
			}
		}
		class SharableLongStringFieldView: UtilityActionableLongStringFieldView
		{
			//
			// Properties
			var urlToShare: URL?
			//
			override class func valueButtonClass() -> SmallUtilityValueButton.Type {
				return SmallUtilityShareValueButton.self
			}
			func set(text: String?, url: URL?)
			{
				self.urlToShare = url // may be nil
				self.set(
					text: text,
					ifNonNil_overridingTextAndZeroValue_attributedDisplayText: nil
				)
			}
			override func set(
				text: String?,
				ifNonNil_overridingTextAndZeroValue_attributedDisplayText: NSAttributedString?
			)
			{
				super.set(
					text: text,
					ifNonNil_overridingTextAndZeroValue_attributedDisplayText: ifNonNil_overridingTextAndZeroValue_attributedDisplayText
				)
				if let url = self.urlToShare {
					self.shareButton.setButtonValue(url: url)
					self.shareButton.setButtonValue(text: nil) // to clear
				} else {
					self.shareButton.setButtonValue(text: text) // even if nil
					self.shareButton.setButtonValue(url: nil) // to clear
				}
			}
			//
			// Accessors
			var shareButton: SmallUtilityShareValueButton {
				return self.valueButton as! SmallUtilityShareValueButton
			}
		}
		class UtilityActionableLongStringFieldView: FieldView
		{
			//
			// Class - Overridable
			class func valueButtonClass() -> SmallUtilityValueButton.Type {
				return SmallUtilityCopyValueButton.self
			}
			//
			// Constants
			override var contentInsets: UIEdgeInsets {
				return UIEdgeInsetsMake(17, 16, 17, 16)
			}
			//
			// Properties
			var labelVariant: FieldLabel.Variant
			var fieldTitle: String
			//
			var titleLabel: FieldLabel!
			var valueButton: SmallUtilityValueButton!
			var contentLabel: UILabel! // TODO a class?
			//
			var valueToDisplayIfZero: String?
			//
			// Init
			init(
				labelVariant: FieldLabel.Variant,
				title: String,
				valueToDisplayIfZero: String?
			)
			{
				self.labelVariant = labelVariant
				self.fieldTitle = title
				self.valueToDisplayIfZero = valueToDisplayIfZero
				super.init()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			override func setup()
			{
				super.setup()
				do {
					let view = FieldLabel(variant: self.labelVariant, title: self.fieldTitle)
					view.isUserInteractionEnabled = false // do not receive/obscure touches
					self.titleLabel = view
					self.addSubview(view)
				}
				do {
					let valueButtonClass = type(of: self).valueButtonClass()
					let view = valueButtonClass.init()
					self.valueButton = view
					self.addSubview(view)
				}
				do {
					let view = UILabel()
					view.isUserInteractionEnabled = false
					self.contentLabel = view
					// TODO? configure here? or in subclass?
					view.numberOfLines = 0
					view.font = .middlingRegularMonospace
					view.textColor = UIColor(rgb: 0x9E9C9E)
					self.addSubview(view)
				}
			}
			//
			// Imperatives - Values
			func set(text: String?)
			{
				self.set(
					text: text,
					ifNonNil_overridingTextAndZeroValue_attributedDisplayText: nil
				)
			}
			func set( // Overridable, but call on super
				text: String?,
				ifNonNil_overridingTextAndZeroValue_attributedDisplayText: NSAttributedString?
			)
			{
				var displayValue: String
				do { // this block is not (yet) aware of ifNonNil_overridingTextAndZeroValue_attributedDisplayText
					if let text = text, text != "" {
						displayValue = text
					} else {
						displayValue = self.valueToDisplayIfZero ?? ""
					}
				}
				if let attributedDisplayText = ifNonNil_overridingTextAndZeroValue_attributedDisplayText {
					self.contentLabel.attributedText = attributedDisplayText
				} else {
					self.contentLabel.text = displayValue
				}
				// NOTE: subclassers: override this method and put your (self.valueButton as! …).set(…: …) call heres
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
				let content_rightMargin: CGFloat = 36 + contentInsets.right
				let content_w = containerWidth - content_x - content_rightMargin - SmallUtilityCopyValueButton.visual_w()
				self.titleLabel.frame = CGRect(
					x: content_x,
					y: contentInsets.top,
					width: content_w,
					height: self.titleLabel.frame.size.height // it already has a fixed height
				)
				self.valueButton.frame = CGRect(
					x: containerWidth - contentInsets.right - self.valueButton.frame.size.width + SmallUtilityCopyValueButton.usabilityPadding_h,
					y: self.titleLabel.frame.origin.y - (SmallUtilityCopyValueButton.h - self.titleLabel.frame.size.height)/2, // proper y alignment since SmallUtilityCopyValueButton.h is increased for usability
					width: SmallUtilityCopyValueButton.w(),
					height: SmallUtilityCopyValueButton.h 
				).integral
				self.layOut_contentLabel(content_x: content_x, content_w: content_w)
				//
				let bottomPadding: CGFloat = contentInsets.bottom
				self.frame = CGRect(
					x: xOffset,
					y: yOffset,
					width: containerWidth,
					height: self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + bottomPadding
				)
			}
			func layOut_contentLabel(content_x: CGFloat, content_w: CGFloat)
			{
				self.contentLabel.frame = CGRect(
					x: content_x,
					y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 12,
					width: content_w,
					height: 0
				)
				self.contentLabel.sizeToFit() // to get height
			}
		}
		//
		class ShortStringFieldContentView: UIView
		{
			//
			// Properties
			var labelVariant: FieldLabel.Variant
			var fieldTitle: String
			//
			var titleLabel: FieldLabel!
			var contentLabel: UILabel! // TODO a class?
			//
			var valueToDisplayIfZero: String?
			//
			// Init
			init(
				labelVariant: FieldLabel.Variant,
				title: String,
				valueToDisplayIfZero: String?
			)
			{
				self.labelVariant = labelVariant
				self.fieldTitle = title
				self.valueToDisplayIfZero = valueToDisplayIfZero
				super.init(frame: .zero)
				self.setup()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			func setup()
			{
				do {
					let view = FieldLabel(variant: self.labelVariant, title: self.fieldTitle)
					view.isUserInteractionEnabled = false // do not receive/obscure touches
					self.titleLabel = view
					self.addSubview(view)
				}
				do {
					let view = UILabel()
					view.isUserInteractionEnabled = false
					self.contentLabel = view
					view.numberOfLines = 1
					view.textAlignment = .right
					view.lineBreakMode = .byTruncatingTail
					view.font = .middlingRegularMonospace
					self.addSubview(view)
				}
			}
			//
			// Imperatives - Values
			func set(text: String?)
			{
				self.set(text: text, color: nil)
			}
			func set(text: String?, color: UIColor?)
			{
				var displayValue: String
				do { // this block is not (yet) aware of ifNonNil_overridingTextAndZeroValue_attributedDisplayText
					if let text = text, text != "" {
						displayValue = text
					} else {
						displayValue = self.valueToDisplayIfZero ?? ""
					}
				}
				if color != nil {
					self.contentLabel.textColor = color
				} else {
					self.contentLabel.textColor = UIColor(rgb: 0x9E9C9E)
				}
				self.contentLabel.text = displayValue
			}
			//
			// Imperatives - Layout
			func layOut(
				withContainerWidth containerWidth: CGFloat,
				contentInsets: UIEdgeInsets
			)
			{
				let content_x: CGFloat = contentInsets.left
				let content_rightMargin: CGFloat = contentInsets.right
				let content_w = containerWidth - content_x - content_rightMargin
				self.titleLabel.frame = CGRect(
					x: content_x,
					y: contentInsets.top + 1,
					width: content_w,
					height: self.titleLabel.frame.size.height // it already has a fixed height
				)
				self.layOut_contentLabel(content_x: content_x, y: contentInsets.top, content_w: content_w)
				//
				self.frame = CGRect(
					x: 0,
					y: 0,
					width: containerWidth,
					height: self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + contentInsets.bottom
				)
			}
			func layOut_contentLabel(
				content_x: CGFloat,
				y: CGFloat,
				content_w: CGFloat
			)
			{
				let margin_x: CGFloat = 63 // may be improved by being obtained from a sized titleLabel
				self.contentLabel.frame = CGRect(
					x: content_x + margin_x,
					y: y,
					width: content_w - margin_x,
					height: 15
				)
			}
		}
		class ShortStringFieldView: FieldView
		{
			//
			// Constants
			override var contentInsets: UIEdgeInsets {
				return UIEdgeInsetsMake(15, 16, 15, 16)
			}
			//
			// Properties
			var contentView: ShortStringFieldContentView
			//
			// Init
			init(
				labelVariant: FieldLabel.Variant,
				title: String,
				valueToDisplayIfZero: String?
			)
			{
				self.contentView = ShortStringFieldContentView(
					labelVariant: labelVariant,
					title: title,
					valueToDisplayIfZero: valueToDisplayIfZero
				)
				super.init()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			override func setup()
			{
				super.setup()
				do {
					let view = self.contentView
					self.addSubview(view)
				}
			}
			//
			// Imperatives - Values
			func set(text: String?)
			{
				self.contentView.set(text: text)
			}
			func set(text: String?, color: UIColor?)
			{
				self.contentView.set(text: text, color: color)
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
				self.contentView.layOut(
					withContainerWidth: containerWidth,
					contentInsets: contentInsets
				) // this will set its bounds
				//
				self.frame = CGRect(
					x: xOffset,
					y: yOffset,
					width: self.contentView.frame.size.width,
					height: self.contentView.frame.size.height
				)

			}
		}
		class ImageButtonDisplayingFieldView: FieldView
		{
			//
			// Constants
			override var contentInsets: UIEdgeInsets {
				return UIEdgeInsetsMake(17, 16, 17, 16)
			}
			//
			// Properties
			var labelVariant: FieldLabel.Variant
			var fieldTitle: String
			//
			var titleLabel: FieldLabel!
			var valueButton: SmallUtilityShareValueButton!
			var contentImageButton: UIButton!
			fileprivate var tapped_fn: (() -> ())?
			//
			var _bottomMostView: UIView { // overridable
				return self.contentImageButton
			}
			//
			// Init
			init(
				labelVariant: FieldLabel.Variant,
				title: String,
				tapped_fn: (() -> Void)?
			)
			{
				self.labelVariant = labelVariant
				self.fieldTitle = title
				self.tapped_fn = tapped_fn
				super.init()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			override func setup()
			{
				super.setup()
				do {
					let view = FieldLabel(variant: self.labelVariant, title: self.fieldTitle)
					view.isUserInteractionEnabled = false // do not receive/obscure touches
					self.titleLabel = view
					self.addSubview(view)
				}
				do {
					let view = SmallUtilityShareValueButton()
					self.valueButton = view
					self.addSubview(view)
				}
				do {
					let view = UIButton()
					if self.tapped_fn != nil {
						view.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
						view.adjustsImageWhenHighlighted = true // to show touches .. expose via config as funds request details view relies on this
					} else {
						view.isUserInteractionEnabled = false // so as not to intercept taps/scrolls/etc
					}
					self.contentImageButton = view
					// TODO? configure here? or in subclass?
					self.addSubview(view)
				}
			}
			//
			// Imperatives - Values
			func set(image: UIImage?)
			{
				self.contentImageButton.setImage(image, for: .normal)
				self.valueButton.setButtonValue(image: image)
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
				let content_rightMargin: CGFloat = 36 + contentInsets.right
				let content_w = containerWidth - content_x - content_rightMargin - SmallUtilityCopyValueButton.visual_w()
				self.titleLabel.frame = CGRect(
					x: content_x,
					y: contentInsets.top,
					width: content_w,
					height: self.titleLabel.frame.size.height // it already has a fixed height
				)
				self.valueButton.frame = CGRect(
					x: containerWidth - contentInsets.right - self.valueButton.frame.size.width + SmallUtilityShareValueButton.usabilityPadding_h,
					y: self.titleLabel.frame.origin.y - (SmallUtilityShareValueButton.h - self.titleLabel.frame.size.height)/2, // proper y alignment since SmallUtilityCopyValueButton.h is increased for usability
					width: SmallUtilityShareValueButton.w(),
					height: SmallUtilityShareValueButton.h
				).integral
				self.layOut_contentView(content_x: content_x, content_w: content_w)
				//
				let bottomPadding: CGFloat = contentInsets.bottom
				let bottomMostView = self._bottomMostView
				self.frame = CGRect(
					x: xOffset,
					y: yOffset,
					width: containerWidth,
					height: bottomMostView.frame.origin.y + bottomMostView.frame.size.height + bottomPadding
				)
			}
			func layOut_contentView(content_x: CGFloat, content_w: CGFloat)
			{
				self.contentImageButton.frame = CGRect(
					x: content_x + 1, // +1 for visual
					y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 12,
					width: 80,
					height: 80 // TODO: enable override
				)
			}
			//
			// Delegation - Interactions
			func buttonTapped()
			{
				if let fn = self.tapped_fn {
                    fn()
				}
			}
		}
		//
		class FieldLabel: UILabel
		{
			enum Variant
			{
				case middling
				case small
			}
			//
			// Properties - Static
			static let fixedHeight: CGFloat = 13
			//
			static let visual_marginBelow: CGFloat = 7
			static let marginBelowLabelAboveTextInputView: CGFloat = Form.FieldLabel.visual_marginBelow - FormInputCells.imagePadding_y
			static let marginBelowLabelAbovePushButton: CGFloat = Form.FieldLabel.visual_marginBelow - PushButtonCells.imagePaddingForShadow_v
			//
			static let visual_marginAboveLabelForUnderneathField: CGFloat = 16
			static let marginAboveLabelForUnderneathField_textInputView: CGFloat = Form.FieldLabel.visual_marginAboveLabelForUnderneathField - FormInputCells.imagePadding_y
			//
			// Properties
			var variant: Variant
			//
			// Lifecycle - Init
			init(variant: Variant, title: String)
			{
				self.variant = variant
				let frame = CGRect(
					x: CGFloat(0),
					y: CGFloat(0),
					width: CGFloat(0),
					height: Details.FieldLabel.fixedHeight
				)
				super.init(frame: frame)
				self.text = title
				self.setup()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			func setup()
			{
				self.font = self.variant == .small ? UIFont.smallSemiboldSansSerif : UIFont.middlingSemiboldSansSerif
				self.textColor = UIColor(rgb: 0xDFDEDF)
				self.numberOfLines = 1
			}
		}
	}
}
