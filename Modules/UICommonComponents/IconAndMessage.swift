//
//  IconAndMessage.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/22/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
