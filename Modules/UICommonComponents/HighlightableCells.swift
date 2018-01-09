//
//  HighlightableCells.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/12/17.
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

extension UICommonComponents
{
	struct HighlightableCells
	{
		// the grey image has shadow around it and so needs padding
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
			var suffix: String {
				return self.rawValue
			}
			var stretchableImage: UIImage { // todo: lazily cache these at this accessor? would otherwise have made them static
				let capSize = UICommonComponents.HighlightableCells.capSize
				return UIImage(
					named: "highlightableCellBG\(self.suffix)"
				)!.stretchableImage(
					withLeftCapWidth: capSize,
					topCapHeight: capSize
				)
			}
			var contentBackgroundColor: UIColor {
				switch self {
					case .normal:
						return UIColor(rgb: 0x383638)
					case .highlighted:
						return UIColor(rgb: 0x3F3E3F)
					case .disabled:
						return UIColor(rgb: 0x373637)
				}
			}
			var visualEquivalentSemiOpaque_contentBackgroundColor: UIColor {
				switch self {
					case .normal:
						return UIColor(red: 80/255, green: 74/255, blue: 80/255, alpha: 0.55)
					case .highlighted:
						return UIColor(rgb: 0x3F3E3F) // TODO
					case .disabled:
						return UIColor(rgb: 0x373637)
				}
			}
		}
	}
	struct GroupedHighlightableCells
	{
		// the grey image has shadow around it and so needs padding
		static let imagePaddingForShadow_h = CGFloat(imagePaddingForShadow_h_Int)
		static let imagePaddingForShadow_h_Int: Int = 1
		//
		static let imagePaddingForShadow_v_shadow = CGFloat(imagePaddingForShadow_v_shadow_Int)
		static let imagePaddingForShadow_v_sheer = CGFloat(imagePaddingForShadow_v_sheer_Int)
		static let imagePaddingForShadow_v_shadow_Int: Int = 2
		static let imagePaddingForShadow_v_sheer_Int: Int = 0
		//
		static let cornerRadius: Int = HighlightableCells.cornerRadius
		static let capSize: Int = cornerRadius + imagePaddingForShadow_h_Int
		//
		enum Variant: String
		{	
			// TODO: decompose these into CellState and CellPosition
			case normal_top = "_normal_top"
			case normal_middle = "_normal_middle"
			case normal_bottom = "_normal_bottom"
			case normal_standalone = "_normal_standalone"
			//
			case highlighted_top = "_highlighted_top"
			case highlighted_middle = "_highlighted_middle"
			case highlighted_bottom = "_highlighted_bottom"
			case highlighted_standalone = "_highlighted_standalone"
			//
			case disabled_top = "_disabled_top"
			case disabled_middle = "_disabled_middle"
			case disabled_bottom = "_disabled_bottom"
			case disabled_standalone = "_disabled_standalone"
			//
			static func new(withState state: CellState, position: CellPosition) -> Variant
			{
				switch state
				{
					case .normal:
						switch position {
							case .top:
								return .normal_top
							case .middle:
								return .normal_middle
							case .bottom:
								return .normal_bottom
							case .standalone:
								return .normal_standalone
						}
					case .highlighted:
						switch position {
						case .top:
							return .highlighted_top
						case .middle:
							return .highlighted_middle
						case .bottom:
							return .highlighted_bottom
						case .standalone:
							return .highlighted_standalone
					}
					case .disabled:
						switch position {
						case .top:
							return .disabled_top
						case .middle:
							return .disabled_middle
						case .bottom:
							return .disabled_bottom
						case .standalone:
							return .disabled_standalone
					}
				}
			}
			//
			var suffix: String
			{
				return self.rawValue
			}
			//
			var imagePaddingForShadow: UIEdgeInsets {
				let isTop = self == .normal_top || self == .highlighted_top || self == .disabled_top
//				let isMiddle = self == .normal_middle || self == .highlighted_middle || self == .disabled_middle
				let isBottom = self == .normal_bottom || self == .highlighted_bottom || self == .disabled_bottom
				let isStandalone = self == .normal_standalone || self == .highlighted_standalone || self == .disabled_standalone
				return UIEdgeInsets(
					top: isTop || isStandalone ? imagePaddingForShadow_v_shadow : imagePaddingForShadow_v_sheer,
					left: imagePaddingForShadow_h,
					bottom: isBottom || isStandalone ? imagePaddingForShadow_v_shadow : imagePaddingForShadow_v_sheer,
					right: imagePaddingForShadow_h
				)
			}
			var stretchableImage: UIImage
			{ // todo: lazily cache these at this accessor? would otherwise have made them static
				let capSize = UICommonComponents.GroupedHighlightableCells.capSize
				return UIImage(
					named: "groupedHighlightableCellBG\(self.suffix)"
				)!.stretchableImage(
					withLeftCapWidth: capSize,
					topCapHeight: capSize
				)
			}
		}
	}
}
