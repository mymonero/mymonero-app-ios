//
//  IconAndMessage.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/22/17.
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
	class DetectedIconAndMessageView: UICommonComponents.IconAndMessageView
	{
		init()
		{
			super.init(
				imageName: "detectedCheckmark",
				message: NSLocalizedString("Detected", comment: "")
			)
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	class IconAndMessageView: UIView
	{
		//
		// Constants
		static let h: CGFloat = 11
		//
		// Properties
		var imageView: UIImageView
		let label = UILabel()
		//
		// Init
		init(imageName: String, message: String)
		{
			self.imageView = UIImageView(image: UIImage(named: imageName))
			self.label.text = message
			let frame = CGRect(x: 0, y: 0, width: 0, height: type(of: self).h)
			super.init(frame: frame)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.addSubview(self.imageView)
			do {
				let view = self.label
				view.textColor = UIColor(rgb: 0x8D8B8D)
				view.font = UIFont.smallRegularMonospace
				self.addSubview(view)
			}
		}
		override func layoutSubviews()
		{
			super.layoutSubviews()
			self.imageView.frame = CGRect(x: 0, y: 3, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height)
			do {
				let x = self.imageView.frame.origin.x + self.imageView.frame.size.width + 7
				let y: CGFloat = 0
				self.label.frame = CGRect(
					x: x,
					y: y,
					width: self.frame.size.width - x,
					height: self.frame.size.height - y
				)
			}
		}
	}
}
