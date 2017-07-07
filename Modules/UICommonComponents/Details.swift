//
//  Details.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
			//
			// Lifecycle - Init
			override func setup_views()
			{
				super.setup_views()
				self.view.backgroundColor = UIColor.contentBackgroundColor
			}
			override func setup_scrollView()
			{
				super.setup_scrollView()
				do {
					self.scrollView.indicatorStyle = .white
				}
			}
		}
		//
		// Sections
		class SectionView: UIView
		{
			//
			// Constants/Types
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
			func sizeToFitAndLayOutSubviews(
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
				self.containerView.sizeToFitAndLayOutSubviews(
					withContainingWidth: sectionContentsContainingWidth,
					andYOffset: contentContainerView_yOffset
				)
				//
				self.frame = CGRect(
					x: xOffset,
					y: yOffset,
					width: containingWidth,
					height: self.containerView.frame.origin.y + self.containerView.frame.size.height
				)
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
				self.layer.borderColor = UIColor(rgb: 0x494749).cgColor
				self.layer.borderWidth = 1/UIScreen.main.scale
				self.layer.cornerRadius = 5
			}
			//
			// Imperatives
			var fieldViews: [FieldView] = []
			var fieldSeparatorViews: [FieldSeparatorView] = []
			func add(fieldView: FieldView)
			{
				if fieldViews.count > 0 {
					let separatorView = FieldSeparatorView()
					fieldSeparatorViews.append(separatorView)
					self.addSubview(separatorView)
				}
				fieldViews.append(fieldView)
				self.addSubview(fieldView)
			}
			//
			func sizeToFitAndLayOutSubviews(
				withContainingWidth containingWidth: CGFloat,
				andYOffset yOffset: CGFloat
			)
			{
				let self_width = containingWidth - 2*UICommonComponents.Details.SectionContentContainerView.x
				let frame_withoutHeight = CGRect(
					x: UICommonComponents.Details.SectionContentContainerView.x,
					y: yOffset,
					width: self_width,
					height: 0
				)
				let numberOfFields = fieldViews.count
				if numberOfFields == 0 {
					self.frame = frame_withoutHeight
					return
				}
				var currentField_yOffset: CGFloat = 0
				for (idx, fieldView) in fieldViews.enumerated() {
					let contentInsets = fieldView.contentInsets
					fieldView.sizeToFitAndLayOutSubviews(
						withContainingWidth: self_width - contentInsets.left - contentInsets.right,
						withXOffset: contentInsets.left,
						andYOffset: currentField_yOffset + contentInsets.top
					)
					currentField_yOffset = fieldView.frame.origin.y + fieldView.frame.size.height + contentInsets.bottom
					//
					if idx < numberOfFields - 1 { // any but the last field
						let separatorView = self.fieldSeparatorViews[idx] // we expect there to be done
						separatorView.frame = CGRect(
							x: contentInsets.left,
							y: currentField_yOffset,
							width: self_width - contentInsets.left, // no right offset - flush with edge
							height: FieldSeparatorView.h
						)
						currentField_yOffset = separatorView.frame.origin.y + separatorView.frame.size.height // update - but do not add .bottom inset (twice) since (a) we just added .bottom, and (b) next field has .top
					}
				}
				var frame_withHeight = frame_withoutHeight
				do { // finalize
					let last_fieldView = fieldViews.last!
					frame_withHeight.size.height = last_fieldView.frame.origin.y + last_fieldView.frame.size.height + last_fieldView.contentInsets.bottom
				}
				self.frame = frame_withHeight
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
			var value: Any?
			//
			// Init
			init()
			{
				self.value = nil
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
			func sizeToFitAndLayOutSubviews(
				withContainingWidth containingWidth: CGFloat,
				withXOffset xOffset: CGFloat,
				andYOffset yOffset: CGFloat
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
			init()
			{
				super.init(frame: .zero)
				self.backgroundColor = UIColor(rgb: 0x494749)
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
		}
		//
		class CopyableLongStringFieldView: FieldView
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
			var copyButton: CopyButton!
			var contentLabel: UILabel! // TODO a class?
			//
			var valueToDisplayIfZero: String?
			//
			override var value: Any? {
				willSet
				{
					var use_valueToDisplayIfZero = false
					//
					var displayValue: String?
					if newValue != nil {
						if let stringValue = newValue as? String {
							if stringValue != "" {
								displayValue = stringValue
								//
								self.copyButton.set(text: stringValue)
								self.copyButton.isEnabled = true
							} else {
								use_valueToDisplayIfZero = true
							}
						} else {
							use_valueToDisplayIfZero = true
						}
					} else {
						use_valueToDisplayIfZero = true
					}
					if use_valueToDisplayIfZero {
						displayValue = self.valueToDisplayIfZero
						self.copyButton.isEnabled = false
					}
					self.contentLabel.text = displayValue
				}
			}
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
					self.titleLabel = view
					self.addSubview(view)
				}
				do {
					let view = CopyButton()
					self.copyButton = view
					self.addSubview(view)
				}
				do {
					let view = UILabel()
					self.contentLabel = view
					// TODO? configure here? or in subclass?
					view.numberOfLines = 0
					view.font = .middlingRegularMonospace
					view.textColor = UIColor(rgb: 0x9E9C9E)
					self.addSubview(view)
				}
			}
			//
			// Imperatives - Layout - Overrides
			override func sizeToFitAndLayOutSubviews(
				withContainingWidth containingWidth: CGFloat,
				withXOffset xOffset: CGFloat,
				andYOffset yOffset: CGFloat
			)
			{
				let content_x: CGFloat = 0 // self will have xOffset so content can be at 0
				let content_rightMargin: CGFloat = 36
				let content_w = containingWidth - content_x - content_rightMargin - self.copyButton.frame.size.width
				self.titleLabel.frame = CGRect(
					x: content_x,
					y: 0,
					width: content_w,
					height: self.titleLabel.frame.size.height // it already has a fixed height
				)
				self.copyButton.frame = CGRect(
					x: containingWidth - self.copyButton.frame.size.width,
					y: self.titleLabel.frame.origin.y - (CopyButton.h - self.titleLabel.frame.size.height)/2, // proper y alignment since CopyButton.h is increased for usability
					width: CopyButton.w,
					height: CopyButton.h 
				).integral
				self.contentLabel.frame = CGRect(
					x: content_x,
					y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 12,
					width: content_w,
					height: 0
				)
				self.contentLabel.sizeToFit() // to get height
				//
				let bottomPadding: CGFloat = 0
				self.frame = CGRect(
					x: xOffset,
					y: yOffset,
					width: containingWidth,
					height: self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + bottomPadding
				)
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
