//
//  ScrollableInfo.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents
{
	class ScrollableValidatingInfoViewController: UIViewController, UIScrollViewDelegate
	{
		//
		// Properties - Cached
		var scrollView: UIScrollView!
		var messageView: UICommonComponents.InlineMessageView?
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
			view.delegate = self
			self.view.addSubview(view)
			self.scrollView = view
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
			self.scrollView.addSubview(view)
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
		// Runtime - Accessors - Form components configuration
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
		// Accessors - Lookups/Derived - Layout metrics
		var inlineMessageValidationView_topMargin: CGFloat {
			return 16
		}
		var inlineMessageValidationView_bottomMargin: CGFloat {
			return UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView // just for visual consistency
		}
		var yOffsetForViewsBelowValidationMessageView: CGFloat
		{
			assert(self.new_wantsInlineMessageViewForValidationMessages() == true)
			if self.messageView!.isHidden {
				return UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView // to keep consistency in terms of 'minimum required visual y offset - aka margin_y' for auto-scroll-to-input
			}
			let y = self.inlineMessageValidationView_topMargin + self.messageView!.frame.size.height + self.inlineMessageValidationView_bottomMargin
			//
			return ceil(y) // b/c having it be .5 doesn't mix well with consumers' usage of .integral
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
			let view = self.messageView! // this ! is not necessary according to the var's optionality but there seems to be a compiler bug
			view.set(text: message)
			view.set(mode: wantsXButton ? .withCloseButton : .noCloseButton)
			self.layOut_messageView() // this can be slightly redundant, but it is called here so we lay out before showing (and so contents reflow if wantsXButton changed). maybe rework this so it doesn't require laying out twice and checking visibility. maybe a flag saying "ought to be showing". maybe.
			view.show()
			self.view.setNeedsLayout() // so views (below messageView) get re-laid-out
		}
		func clearValidationMessage()
		{
			if self.new_wantsInlineMessageViewForValidationMessages() == false {
				assert(false, "override \(#function)")
				return
			}
			self.messageView!.clearAndHide() // as you can see, no ! required here. compiler bug?
			// we don't need to call setNeedsLayout() here b/c the messageView callback in self.setup will do so
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
			assert(self.new_wantsInlineMessageViewForValidationMessages() == true)
			let x = CGFloat.visual__form_input_margin_x // use visual__ instead so we don't get extra img padding
			let w = self.view.frame.size.width - 2 * x
			self.messageView!.layOut(atX: x, y: self.inlineMessageValidationView_topMargin, width: w)
		}
		//
		// Imperatives - Overrides - Layout
		override func viewWillLayoutSubviews()
		{
			super.viewWillLayoutSubviews()
			//
			self.scrollView.frame = self.view.bounds
		}
		//
		// Delegation - View
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
			if self.new_wantsInlineMessageViewForValidationMessages() {
				if self.messageView!.shouldPerformLayOut { // i.e. is visible
					self.layOut_messageView()
				}
			}
		}
		//
		// Delegation - Internal/Convenience - Scroll view
		func scrollableContentSizeDidChange(withBottomView bottomView: UIView, bottomPadding: CGFloat)
		{
			self.scrollView.contentSize = CGSize(
				width: self.view.frame.size.width,
				height: bottomView.frame.origin.y + bottomView.frame.size.height + bottomPadding
			)
		}		//
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
	}
	
}
