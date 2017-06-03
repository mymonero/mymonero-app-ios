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
		case unstyled
		case grey
		case blue
	}
	var pushButtonType: PushButtonType?
	init(pushButtonType: PushButtonType)
	{
		super.init(frame: .zero)
		self.pushButtonType = pushButtonType
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
		var pushButtonType: MMPushButton.PushButtonType!
		switch type
		{
			case .add, .save:
				pushButtonType = .blue
				break
			case .cancel, .edit, .back:
				pushButtonType = .grey
				break
			case .valueDisplayLabel:
				pushButtonType = .unstyled
				break
		}
		let view = MMPushButton(pushButtonType: pushButtonType)
		view.addTarget(target, action: action, for: .touchUpInside)
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
				view.sizeToFit()
				break
			case .save:
				view.setTitle(title_orNilForDefault ?? NSLocalizedString("Save", comment: ""), for: .normal)
				view.sizeToFit()
				break
			case .edit:
				view.setTitle(title_orNilForDefault ?? NSLocalizedString("Edit", comment: ""), for: .normal)
				view.sizeToFit()
				break
			case .valueDisplayLabel:
				break
		}
		self.customView = view
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
