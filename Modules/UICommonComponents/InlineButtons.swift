//
//  InlineButtons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/3/18.
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
//
extension UICommonComponents
{
	class InlineButton: UIButton
	{
		static let fixedHeight: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 40 : 42
		// TODO: style
		
		
		enum InlineButtonType
		{
			case utility
		}
		var inlineButtonType: InlineButtonType
		init(inlineButtonType: InlineButtonType)
		{
			self.inlineButtonType = inlineButtonType
			super.init(frame: .zero)
			self.setup()
		}
		func setup()
		{
			let font: UIFont = UIFont.shouldStepDownLargerFontSizes ? .middlingSemiboldSansSerif : .largeSemiboldSansSerif
			var color: UIColor!
			var backgroundColor: UIColor!
			var cornerRadius: CGFloat!
			let disabledColor = UIColor(rgb: 0x6B696B)
			switch self.inlineButtonType
			{
				case .utility:
					color = UIColor(rgb: 0xFCFBFC)
					backgroundColor = UIColor(rgb: 0x383638)
					cornerRadius = InlineButton.fixedHeight/2
					break
			}
			self.layer.cornerRadius = cornerRadius
			self.backgroundColor = backgroundColor
			self.titleLabel!.font = font
			self.setTitleColor(color, for: .normal)
			self.setTitleColor(disabledColor, for: .disabled)
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
	}
}
