//
//  ScrollableInfo.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
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
	class ScrollableValidatingInfoViewController: UIViewController, UIScrollViewDelegate
	{
		//
		// Properties - Views
		var messageView: UICommonComponents.InlineMessageView?
		var scrollView: UIScrollView!
		//
		// Imperatives - Init
		init()
		{
			super.init(nibName: nil, bundle: nil)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.view.backgroundColor = .contentBackgroundColor
			//
			self.setup_scrollView() // must be before setup_views b/c a subclasser may put self.scrollView.addSubview prior to super.setup_views()
			self.setup_views() // must be before _navigation b/c that may rely on _views
			self.setup_navigation()
			self.startObserving()
		}
		func setup_views()
		{ // override but call on super
			if self.new_wantsInlineMessageViewForValidationMessages() {
				self.setup_messageView()
			}
		}
		func setup_scrollView()
		{
			let view = UIScrollView()
			view.indicatorStyle = .white
			view.delegate = self
			self.view.addSubview(view)
			self.scrollView = view
			self.configure_scrollView_contentInset()
			do {
				self.automaticallyAdjustsScrollViewInsets = false // to fix apparent visual bug of vertical transit on nav push/pop
				if #available(iOS 11.0, *) {
					view.contentInsetAdjustmentBehavior = .never
				}
			}
		}
		func setup_messageView()
		{
			let view = UICommonComponents.InlineMessageView(
				mode: .withCloseButton,
				didHide:
				{ [unowned self] in
					self.view.setNeedsLayout()
				}
			)
			self.messageView = view
			self.view.addSubview(view) // rather than to self.scrollView
		}
		func setup_navigation()
		{ // override but call on super
			if self.overridable_wantsBackButton {
				self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
					type: .back,
					tapped_fn:
					{ [unowned self] in
						self.navigationController?.popViewController(animated: true)
					}
				)
			}
		}
		func startObserving()
		{ // override, but call on super
		}
		//
		// Lifecycle - Deinit
		deinit
		{
			self.tearDown()
		}
		func tearDown()
		{
			self.stopObserving()
		}
		func stopObserving()
		{
		}
		//
		// Runtime - Accessors - Components configuration
		func new_wantsInlineMessageViewForValidationMessages() -> Bool
		{ // overridable
			return true
		}
		var overridable_wantsBackButton: Bool { return false }
		func new_navigationBarTitleColor() -> UIColor?
		{ // overridable
			return nil // for themeController default 
		}
		//
		func new_contentInset() -> UIEdgeInsets // NOTE: this is contentInset for the SCROLLVIEW
		{ // overridable
			return UIEdgeInsetsMake(0, 0, 0, 0)
		}
		var new_subviewLayoutInsets: UIEdgeInsets
		{ // overridable
			return UIEdgeInsetsMake(0, 0, 0, 0)
		}
		//
		// Accessors - Lookups/Derived - Layout metrics
		var new__messageView_left: CGFloat {
			return CGFloat.visual__form_input_margin_x + self.new_subviewLayoutInsets.left // use visual__ instead so we don't get extra img padding
		}
		var new__messageView_right: CGFloat {
			return CGFloat.visual__form_input_margin_x + self.new_subviewLayoutInsets.right
		}
		var yOffsetForViewsBelowValidationMessageView: CGFloat {
			return ceil(
				self.new_subviewLayoutInsets.top + 
				UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView // chosen in order to keep consistency in terms of 'minimum required visual y offset - aka margin_y' for auto-scroll-to-input
			)
		}
		//
		// Runtime - Imperatives - Convenience/Overridable - Validation error
		func setValidationMessage(_ message: String)
		{ // legacy
			self.set(validationMessage: message, wantsXButton: true)
		}
		func set(validationMessage message: String, wantsXButton: Bool)
		{
			if self.new_wantsInlineMessageViewForValidationMessages() == false {
				assert(false, "override \(#function)")
				return
			}
			if let timer = self._validationMessageDismissing_clearAndShowDebounceTimer {
				timer.invalidate() // always prevent an existing 'close' timer from stomping on a more recent 'show'
				self._validationMessageDismissing_clearAndShowDebounceTimer = nil
			}
			let view = self.messageView! // this ! is not necessary according to the var's optionality but there seems to be a compiler bug
			view.set(text: message)
			view.set(mode: wantsXButton ? .withCloseButton : .noCloseButton)
			self.layOut_messageView() // this can be slightly redundant, but it is called here so we lay out before showing (and so contents reflow if wantsXButton changed). maybe rework this so it doesn't require laying out twice and checking visibility. maybe a flag saying "ought to be showing". maybe.
			view.show()
			self.view.setNeedsLayout() // so views (below messageView) get re-laid-out
		}
		var _validationMessageDismissing_clearAndShowDebounceTimer: Timer?
		func clearValidationMessage()
		{
			if self.new_wantsInlineMessageViewForValidationMessages() == false {
				assert(false, "override \(#function)")
				return
			}
			if let timer = self._validationMessageDismissing_clearAndShowDebounceTimer {
				timer.invalidate()
				self._validationMessageDismissing_clearAndShowDebounceTimer = nil // not technically necessary
			}
			self._validationMessageDismissing_clearAndShowDebounceTimer = Timer.scheduledTimer(
				withTimeInterval: 0.2, // just a tiny delay, to prevent the message from being hidden and shown immediately
				repeats: false,
				block:
				{ [weak self] (timer) in
					guard let thisSelf = self else {
						return
					}
					if thisSelf._validationMessageDismissing_clearAndShowDebounceTimer == nil {
						assert(false) // ever expected?
						return
					}
					assert(timer == thisSelf._validationMessageDismissing_clearAndShowDebounceTimer)
					//
					thisSelf.messageView!.clearAndHide() // as you can see, no ! required here. compiler bug?
					// we don't need to call setNeedsLayout() here b/c the messageView callback in self.setup will do so
					//
					thisSelf._validationMessageDismissing_clearAndShowDebounceTimer = nil
				}
			)
		}
		//
		// Imperatives - Configuration - Scroll view
		func configure_scrollView_contentInset()
		{
			self.scrollView.contentInset = self.new_contentInset()
		}
		//
		// Imperatives - Convenience - Navigation bar title color
		func configureNavigationBarTitleColor()
		{
			ThemeController.shared.styleViewController_navigationBarTitleTextAttributes(
				viewController: self,
				titleTextColor: self.new_navigationBarTitleColor()
			)
		}
		//
		// Imperatives - Internal - Layout
		func layOut_messageView()
		{
			assert(self.new_wantsInlineMessageViewForValidationMessages())
			// we'll allow laying out while hidden, here, for text/button reflow before .show(), etc
			assert(self.messageView != nil)
			//
			let left = self.new__messageView_left
			let right = self.new__messageView_right
			let w = self.view.frame.size.width - left - right
			self.messageView!.layOut(
				atX: left,
				y: 8, // was 16
				width: w
			)
		}
		//
		// Imperatives - Overrides - Layout
		override func viewWillLayoutSubviews()
		{
			super.viewWillLayoutSubviews()
			//
			let safeAreaInsets = self.view.polyfilled_safeAreaInsets
			let contentViewFrame = UIEdgeInsetsInsetRect(self.view.bounds, safeAreaInsets)
			//
			var scrollView_top: CGFloat = contentViewFrame.origin.y
			if let messageView = self.messageView, messageView.isHidden == false {
				self.layOut_messageView() // already accounts for safeAreaInsets
				//
				scrollView_top = messageView.frame.origin.y + messageView.frame.size.height
			}
			self.scrollView.frame = CGRect(
				x: contentViewFrame.origin.x,
				y: scrollView_top,
				width: contentViewFrame.size.width,
				height: contentViewFrame.size.height - scrollView_top
			)
		}
		//
		// Delegation - Internal/Convenience - Scroll view
		func scrollableContentSizeDidChange(withBottomView bottomView: UIView, bottomPadding: CGFloat)
		{
			self.scrollView.contentSize = CGSize(
				width: self.scrollView/*not self.view*/.frame.size.width,
				height: bottomView.frame.origin.y + bottomView.frame.size.height + bottomPadding
			)
		}
		//
		// Delegation - View
		var hasAppearedBefore = false
		override func viewDidAppear(_ animated: Bool)
		{
			super.viewDidAppear(animated)
			if self.hasAppearedBefore == false {
				self.hasAppearedBefore = true
			}
		}
		override func viewWillAppear(_ animated: Bool)
		{
			super.viewWillAppear(animated)
			self.configureNavigationBarTitleColor() // for transactions details support plus clearing it for popping vc
		}
		override func viewSafeAreaInsetsDidChange()
		{
			if #available(iOS 11.0, *) {
				super.viewSafeAreaInsetsDidChange()
				//
				// update according to self.view.safeAreaInsets
				self.configure_scrollView_contentInset()
				self.view.setNeedsLayout()
			}
		}
	}
	
}
