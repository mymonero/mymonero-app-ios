//
//  WalletIcons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/12/17.
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
	class WalletIconView: UIImageView
	{
		enum SizeClass
		{
			case large48
			case large43
			case medium32
		}
		init(sizeClass: SizeClass)
		{
			super.init(frame: .zero)
			do {
				let size: CGSize
				switch sizeClass
				{
					case .large48:
						size = CGSize(width: 48, height: 48)
						break
					case .large43:
						size = CGSize(width: 43, height: 43)
						break
					case .medium32:
						size = CGSize(width: 32, height: 32)
						break
					
				}
				var frame = self.frame
				frame.size = size
				self.frame = frame
			}
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		//
		func configure(withSwatchColor swatchColor: Wallet.SwatchColor)
		{
			let hexColorString = swatchColor.colorHexString()
			let hexColorString_sansPound = (hexColorString as NSString).substring(from: 1) // strip "#" sign
			let imageFilename = "wallet-\(hexColorString_sansPound)"
			let image = UIImage(named: imageFilename)!
			self.image = image
		}
	}
}
