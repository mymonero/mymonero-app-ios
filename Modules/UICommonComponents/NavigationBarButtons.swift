//
//  Forms.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class MMPushButton: UIButton
{
	enum PushButtonType
	{
		case grey
		case blue
	}
	var pushButtonType: PushButtonType
	init(pushButtonType: PushButtonType)
	{
		self.pushButtonType = pushButtonType
		super.init(frame: .zero)
		self.setup()
	}
	func setup()
	{
		var image: UIImage!
		var disabledImage: UIImage!
		var font: UIFont!
		var color: UIColor!
		var disabledColor: UIColor!
		switch self.pushButtonType
		{
			case .grey:
				image = UIImage(named: "navigationBarBtnBG_grey")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
				disabledImage = UIImage(named: "navigationBarBtnBG_disabled")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0xFCFBFC)
				disabledColor = UIColor(rgb: 0x6B696B)
				break
			case .blue:
				image = UIImage(named: "navigationBarBtnBG_blue")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
				disabledImage = UIImage(named: "navigationBarBtnBG_disabled")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0x161416)
				disabledColor = UIColor(rgb: 0x6B696B)
				break
		}
		self.setBackgroundImage(image, for: .normal)
		self.setBackgroundImage(disabledImage, for: .disabled)
		self.titleLabel!.font = font
		self.setTitleColor(color, for: .normal)
		self.setTitleColor(disabledColor, for: .disabled)
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}

class MMNavigationBarButtonItem: UIBarButtonItem
{
	enum ButtonItemType
	{
		case back
		case add
		case cancel
		case save
		case edit
		case valueDisplayLabel
	}
	convenience init(type: ButtonItemType, target: Any, action: Selector)
	{
		self.init(type: type, target: target, action: action, title_orNilForDefault: nil)
	}
	init(type: ButtonItemType, target: Any, action: Selector, title_orNilForDefault: String?)
	{
		super.init()
		//
		if type == .valueDisplayLabel {
			let view = UILabel()
			view.text = title_orNilForDefault
			view.font = UIFont.smallRegularMonospace
			view.textColor = UIColor(rgb: 0x9E9C9E)
			view.sizeToFit()
			self.customView = view
			return
		}
		var pushButtonType: MMPushButton.PushButtonType!
		switch type
		{
			case .add, .save:
				pushButtonType = .blue
				break
			case .cancel, .edit, .back:
				pushButtonType = .grey
				break
			case .valueDisplayLabel: // to be exhaustive
				assert(false)
				break
		}
		let view = MMPushButton(pushButtonType: pushButtonType)
		view.addTarget(target, action: action, for: .touchUpInside)
		var sizeToFitAndAddPadding = false
		switch type
		{
			case .back:
				view.setImage(UIImage(named: "backButtonIcon"), for: .normal)
				break
			case .add:
				view.setImage(UIImage(named: "addButtonIcon"), for: .normal)
				break
			case .cancel:
				view.setTitle(title_orNilForDefault ?? NSLocalizedString("Cancel", comment: ""), for: .normal)
				sizeToFitAndAddPadding = true
				break
			case .save:
				view.setTitle(title_orNilForDefault ?? NSLocalizedString("Save", comment: ""), for: .normal)
				sizeToFitAndAddPadding = true
				break
			case .edit:
				view.setTitle(title_orNilForDefault ?? NSLocalizedString("Edit", comment: ""), for: .normal)
				sizeToFitAndAddPadding = true
			break
			case .valueDisplayLabel: // to be exhaustive
				assert(false)
				break
		}
		var frame: CGRect!
		if sizeToFitAndAddPadding {
			view.sizeToFit()
			//
			let padding_x: CGFloat = 8
			frame = view.frame // after sizeToFit()
			frame.size.width += padding_x * 2
		} else {
			frame = view.frame
		}
		frame.size.height = 26 // 26, not 24, because the grey image has shadow around it, and we add extra space for that in the blue and disabled images
		view.frame = frame
		self.customView = view
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
