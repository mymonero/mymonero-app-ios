//
//  EmojiPickerButtonView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/1/17.
//  Copyright (c) 2014-2018, MyMonero.com
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
		var willPresentPopover_fn: (() -> Void)?
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
		@objc func tapped()
		{
			assert(self.popover == nil)
			// the popover should be guaranteed not to be showing here… 
			if let fn = self.willPresentPopover_fn {
				fn()
			}
			let popover = EmojiPickerPopoverView()
			self.popover = popover
			popover.didDismissHandler =
			{ [weak self] in
				guard let thisSelf = self else {
					return // already torn down
				}
				if (thisSelf.popover == nil) {
					return // already cleared - this is probably redundantly occurring on a rotation
				}
				assert(thisSelf.popover == popover)
				thisSelf.popover = nil
			}
			popover.selectedEmojiCharacter_fn =
			{ [weak self] (emojiCharacter) in
				guard let thisSelf = self else {
					return // already torn down?
				}
				assert(thisSelf.popover != nil)
				assert(thisSelf.popover == popover)
				thisSelf.configure(withEmojiCharacter: emojiCharacter)
				DispatchQueue.main.async { // next tick… does this help to avoid any dealloc racing? i didn't think it would…
					assert(thisSelf.popover != nil)
					assert(thisSelf.popover == popover)
					thisSelf.popover!.dismiss()
				}
			}
			let initial_emojiCharacter = self.titleLabel!.text! as Emoji.EmojiCharacter
			popover.show(fromView: self, selecting_emojiCharacter: initial_emojiCharacter)
		}
		//
		// Delegation - Notifications
		@objc func willDeconstructBootedStateAndClearPassword()
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
