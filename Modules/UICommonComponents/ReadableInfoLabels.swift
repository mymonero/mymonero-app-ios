//
//  InlineMessages.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/25/17.
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
//
extension UICommonComponents
{
	class ReadableInfoHeaderLabel: UILabel
	{
		//
		// Properties
		
		//
		// Lifecycle - Init
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
			self.font = UIFont.middlingSemiboldSansSerif
			self.textColor = UIColor(rgb: 0xF8F7F8)
			self.numberOfLines = 0
		}
		//
		// Accessors

		//
		// Imperatives

	}
	class ReadableInfoDescriptionLabel: UILabel
	{
		//
		// Properties
		
		//
		// Lifecycle - Init
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
			self.numberOfLines = 0
		}
		//
		// Accessors
		
		//
		// Imperatives
		func set(text: String)
		{
			let paragraphStyle = NSMutableParagraphStyle()
			do {
				paragraphStyle.lineSpacing = 4
			}
			let attributedString = NSAttributedString(
				string: text,
				attributes:
				[
                    NSAttributedStringKey.foregroundColor: UIColor(rgb: 0x8D8B8D),
					NSAttributedStringKey.font: UIFont.middlingRegularSansSerif,
					NSAttributedStringKey.paragraphStyle: paragraphStyle
				]
			)
			self.attributedText = attributedString
		}
	}
}
