//
//  EmojiPickerButtonView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/1/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

struct EmojiUI
{
	class EmojiPickerButtonView: UICommonComponents.PushButton
	{
		//
		// Constants
		static let visual__w: CGFloat = 58
		static let visual__h: CGFloat = 31
		static let w = EmojiPickerButtonView.visual__w + 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_h
		static let h = EmojiPickerButtonView.visual__h + 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
		//
		static let visual__arrowRightPadding: CGFloat = 8
		//
		// Properties
		var willPresentPopover_fn: ((Void) -> Void)?
		//
		// Lifecycle - Init
		init()
		{
			super.init(pushButtonType: .utility)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			super.setup()
			//
			let image = UIImage(named: "popoverDisclosureArrow")!
			self.setImage(image, for: .normal)
			self.imageEdgeInsets = UIEdgeInsetsMake(
				1,
				EmojiPickerButtonView.w - (UICommonComponents.PushButtonCells.imagePaddingForShadow_h + image.size.width + EmojiPickerButtonView.visual__arrowRightPadding),
				0,
				EmojiPickerButtonView.visual__arrowRightPadding + UICommonComponents.PushButtonCells.imagePaddingForShadow_h
			)
			//
			self.contentHorizontalAlignment = .left
			self.titleEdgeInsets = UIEdgeInsetsMake(0, 1, 0, 0)
			//
			self.frame = CGRect(
				x: 0, y: 0,
				width: EmojiPickerButtonView.w,
				height: EmojiPickerButtonView.h
			)
			//
			// Start observing:
			self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
			// For delete everything, idle, lock-down, etc
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(willDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(UIApplicationWillChangeStatusBarFrame),
				name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame,
				object: nil
			)
		}
		//
		// Lifecycle - Deinit
		deinit
		{
			self.teardown()
		}
		func teardown()
		{
			if let popover = self.popover {
				popover.dismiss()
			}
			self.popover = nil
			self.stopObserving()
		}
		func stopObserving()
		{
			NotificationCenter.default.removeObserver(
				self,
				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			NotificationCenter.default.removeObserver(
				self,
				name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame,
				object: nil
			)
		}
		//
		// Accessors
		var selected_emojiCharacter: Emoji.EmojiCharacter {
			return self.titleLabel!.text! as Emoji.EmojiCharacter
		}
		//
		// Imperatives - Config
		func configure(withEmojiCharacter emojiCharacter: Emoji.EmojiCharacter)
		{
			self.setTitle(emojiCharacter, for: .normal)
		}
		//
		// Delegation - Interactions
		var popover: EmojiPickerPopoverView?
		func tapped()
		{
			assert(self.popover == nil)
			// the popover should be guaranteed not to be showing here… 
			if let fn = self.willPresentPopover_fn {
				fn()
			}
			let popover = EmojiPickerPopoverView(
				dismissHandler:
				{ [weak self] in
					guard let thisSelf = self else {
						return // already torn down
					}
					thisSelf.popover = nil
				}
			)
			self.popover = popover
			popover.selectedEmojiCharacter_fn =
			{ [unowned self] (emojiCharacter) in
				self.configure(withEmojiCharacter: emojiCharacter)
				self.popover!.dismiss()
			}
			let initial_emojiCharacter = self.titleLabel!.text! as Emoji.EmojiCharacter
			popover.show(fromView: self, selecting_emojiCharacter: initial_emojiCharacter)
		}
		//
		// Delegation - Notifications
		func willDeconstructBootedStateAndClearPassword()
		{ // just in case 
			if let popover = self.popover {
				popover.dismiss()
			}
		}
		
		@objc fileprivate func UIApplicationWillChangeStatusBarFrame()
		{
			if let popover = self.popover {
				popover.dismiss() // or else it'll be off center (alternative is just move it but that's more work)
			}
		}
	}
}
