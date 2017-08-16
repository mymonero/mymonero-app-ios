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
			case send
			case edit
			case valueDisplayLabel
		}
		var tapped_fn: ((Void) -> Void)?
		convenience init(type: ButtonItemType, target: Any?, action: Selector?)
		{
			self.init(type: type, target: target, action: action, title_orNilForDefault: nil)
		}
		convenience init(type: ButtonItemType, tapped_fn: @escaping (Void) -> Void)
		{
			self.init(type: type, tapped_fn: tapped_fn, title_orNilForDefault: nil)
		}
		init(type: ButtonItemType, tapped_fn: @escaping (Void) -> Void, title_orNilForDefault: String?)
		{
			super.init()
			self.tapped_fn = tapped_fn
			self._shared_initializeWith(type: type, target: self, action: #selector(_forFn_tapped), title_orNilForDefault: title_orNilForDefault)
		}
		init(type: ButtonItemType, target: Any?, action: Selector?, title_orNilForDefault: String?)
		{
			super.init()
			self._shared_initializeWith(type: type, target: target, action: action, title_orNilForDefault: title_orNilForDefault)
		}
		func _shared_initializeWith(type: ButtonItemType, target: Any?, action: Selector?, title_orNilForDefault: String?)
		{
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
				case .add, .save, .send:
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
			if target != nil && action != nil {
				view.addTarget(target!, action: action!, for: .touchUpInside)
			}
			var sizeToFitAndAddPadding = false
			var or_useWidth_notIncludingImagePadding: CGFloat?
			let imagePaddingForShadow_h = UICommonComponents.PushButtonCells.imagePaddingForShadow_h
			let imagePaddingForShadow_v = UICommonComponents.PushButtonCells.imagePaddingForShadow_v
			switch type
			{
				case .back:
					view.setImage(UIImage(named: "backButtonIcon"), for: .normal)
					or_useWidth_notIncludingImagePadding = 26
					view.imageEdgeInsets = UIEdgeInsetsMake(0, -imagePaddingForShadow_h, 0, imagePaddingForShadow_h)
					break
				case .add:
					view.setImage(UIImage(named: "addButtonIcon_10"), for: .normal)
					or_useWidth_notIncludingImagePadding = 26
					view.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
					break
				case .cancel:
					view.setTitle(title_orNilForDefault ?? NSLocalizedString("Cancel", comment: ""), for: .normal)
					sizeToFitAndAddPadding = true
					break
				case .save:
					view.setTitle(title_orNilForDefault ?? NSLocalizedString("Save", comment: ""), for: .normal)
					sizeToFitAndAddPadding = true
					break
				case .send:
					view.setTitle(title_orNilForDefault ?? NSLocalizedString("Send", comment: ""), for: .normal)
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
				frame.size.width += 2*padding_x + 2*imagePaddingForShadow_h
			} else {
				frame = view.frame
				if let width = or_useWidth_notIncludingImagePadding {
					frame.size.width = width + 2*imagePaddingForShadow_h
				}
			}
			frame.size.height = 24 + 2*imagePaddingForShadow_v
			view.frame = frame
			self.customView = view
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		//
		@objc func _forFn_tapped()
		{
			self.tapped_fn!()
		}
	}
}
