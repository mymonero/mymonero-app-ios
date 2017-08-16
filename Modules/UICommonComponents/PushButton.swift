//
//  PushButton.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
extension UICommonComponents
{
	class PushButton: UIButton
	{
		enum PushButtonType
		{
			case utility
			case action
			case destructive
		}
		var pushButtonType: PushButtonType
		init(pushButtonType: PushButtonType)
		{
			self.pushButtonType = pushButtonType
			super.init(frame: .zero)
			self.setup()
		}
		func setup()
		{
			self.adjustsImageWhenHighlighted = false // looks better when disabled imo -PS
			//
			var image: UIImage!
			let disabledImage = UICommonComponents.PushButtonCells.Variant.disabled.stretchableImage
			var highlightedImage: UIImage!
			var font: UIFont!
			var color: UIColor!
			let disabledColor = UIColor(rgb: 0x6B696B)
			switch self.pushButtonType
			{
			case .utility:
				image = UICommonComponents.PushButtonCells.Variant.utility.stretchableImage
				highlightedImage = UICommonComponents.PushButtonCells.Variant.utility_highlighted.stretchableImage
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0xFCFBFC)
				break
			case .action:
				image = UICommonComponents.PushButtonCells.Variant.action.stretchableImage
				highlightedImage = UICommonComponents.PushButtonCells.Variant.action_highlighted.stretchableImage
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0x161416)
				break
			case .destructive:
				image = UICommonComponents.PushButtonCells.Variant.destructive.stretchableImage
				highlightedImage = UICommonComponents.PushButtonCells.Variant.destructive_highlighted.stretchableImage
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0x161416)
				break
			}
			self.setBackgroundImage(image, for: .normal)
			self.setBackgroundImage(disabledImage, for: .disabled)
			self.setBackgroundImage(highlightedImage, for: .highlighted)
			self.titleLabel!.font = font
			self.setTitleColor(color, for: .normal)
			self.setTitleColor(disabledColor, for: .disabled)
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
	}
	//
	struct PushButtonCells
	{
		// the grey image has shadow around it, and we add extra space for that in the blue and disabled images, having made all images regular
		static let imagePaddingForShadow_h = CGFloat(imagePaddingForShadow_h_Int)
		static let imagePaddingForShadow_v = CGFloat(imagePaddingForShadow_v_Int)
		static let imagePaddingForShadow_h_Int: Int = 1
		static let imagePaddingForShadow_v_Int: Int = 2
		//
		static let cornerRadius: Int = 4
		static let capSize: Int = cornerRadius + imagePaddingForShadow_h_Int
		//
		enum Variant: String
		{
			case disabled = "disabled"
			//
			case utility = "utility"
			case utility_highlighted = "utility_highlighted"
			//
			case action = "action"
			case action_highlighted = "action_highlighted"
			//
			case destructive = "destructive"
			case destructive_highlighted = "destructive_highlighted"
			//
			var suffix: String
			{
				return "_\(self.rawValue)"
			}
			//
			var stretchableImage: UIImage
			{
				let capSize = UICommonComponents.PushButtonCells.capSize
				return UIImage(named: "pushButtonBG\(self.suffix)")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
			}
		}
	}
}
