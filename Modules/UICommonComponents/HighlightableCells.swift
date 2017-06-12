//
//  HighlightableCells.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents
{
	struct HighlightableCells
	{
		static let capSize: Int = 5
		static let imagePaddingForShadow_h: CGFloat = 1 // the grey image has shadow around it, and we add extra space for that in the blue and disabled images to make all images regular
		static let imagePaddingForShadow_v: CGFloat = 2

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
				return self.rawValue
			}
			//
			var image: UIImage
			{
				let capSize = UICommonComponents.HighlightableCells.capSize
				return UIImage(named: "highlightableCellBG_\(self.suffix)")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
			}
		}
	}
}
