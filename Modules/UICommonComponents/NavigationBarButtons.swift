//
//  NavigationBarButtons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
extension UICommonComponents
{
	class NavigationBarButtonItem: UIBarButtonItem
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
			var pushButtonType: UICommonComponents.PushButton.PushButtonType!
			switch type
			{
				case .add, .save:
					pushButtonType = .action
					break
				case .cancel, .edit, .back:
					pushButtonType = .utility
					break
				case .valueDisplayLabel: // to be exhaustive
					assert(false)
					break
			}
			let view = UICommonComponents.PushButton(pushButtonType: pushButtonType)
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
}
