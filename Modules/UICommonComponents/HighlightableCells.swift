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
		// the grey image has shadow around it
		static let imagePaddingForShadow_h = CGFloat(imagePaddingForShadow_h_Int)
		static let imagePaddingForShadow_v = CGFloat(imagePaddingForShadow_v_Int)
		static let imagePaddingForShadow_h_Int: Int = 1
		static let imagePaddingForShadow_v_Int: Int = 2
		//
		static let cornerRadius: Int = 5
		static let capSize: Int = cornerRadius + imagePaddingForShadow_h_Int
		//
		enum Variant: String
		{
			case normal = ""
			case highlighted = "_highlighted"
			case disabled = "_disabled"
			//
			var suffix: String
			{
				return self.rawValue
			}
			//
			var stretchableImage: UIImage
			{
				let capSize = UICommonComponents.HighlightableCells.capSize
				return UIImage(
					named: "highlightableCellBG\(self.suffix)"
				)!.stretchableImage(
					withLeftCapWidth: capSize,
					topCapHeight: capSize
				)
			}
		}
	}
}
