//
//  WalletIcons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
