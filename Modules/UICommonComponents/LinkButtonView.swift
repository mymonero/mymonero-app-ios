//
//  Links.swift
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
	class LinkButtonView: UIButton
	{
		//
		// Constants
		static var h: CGFloat { // a computed property, so that we can override it
			return 24
		}
		//
		enum Mode
		{
			case mono_default
			case mono_destructive
			case sansSerif_default
		}
		//
		// Init
		var mode: Mode!
		init(mode: Mode, title: String)
		{
			let frame = CGRect(
				x: 0,
				y: 0, 
				width: 0,
				height: LinkButtonView.h // increased height for touchability
			)
			super.init(frame: frame)
			self.mode = mode
			self.setTitleText(to: title)
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
		//
		func setTitleText(to title: String)
		{ // use this instead of setTitle
			let color_normal = self.mode == .mono_destructive
				? UIColor.standaloneValidationTextOrDestructiveLinkContentColor
				: UIColor.utilityOrConstructiveLinkColor
			let normal_attributedTitle = NSAttributedString(
				string: title,
				attributes:
				[
                    NSAttributedStringKey.foregroundColor: color_normal,
                    NSAttributedStringKey.font: UIFont.smallRegularMonospace,
                    NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleNone.rawValue
				]
			)
			let selected_attributedTitle = NSAttributedString(
				string: title,
				attributes:
				[
                    NSAttributedStringKey.foregroundColor: color_normal,
					NSAttributedStringKey.font: UIFont.smallRegularMonospace,
					NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue
				]
			)
			let disabled_attributedTitle = NSAttributedString(
				string: title,
				attributes:
				[
                    NSAttributedStringKey.foregroundColor: UIColor.disabledLinkColor,
					NSAttributedStringKey.font: UIFont.smallRegularMonospace,
					NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleNone.rawValue
				]
			)
			self.setAttributedTitle(normal_attributedTitle, for: .normal)
			self.setAttributedTitle(selected_attributedTitle, for: .highlighted)
			self.setAttributedTitle(selected_attributedTitle, for: .selected)
			self.setAttributedTitle(disabled_attributedTitle, for: .disabled)
			//
			// now that we have title and font…
			self.sizeToFit()
			var frame = self.frame
			frame.size.height = LinkButtonView.h
			self.frame = frame
			
		}
	}
}
