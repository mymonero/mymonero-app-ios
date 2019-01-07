//
//  SwitchControl.swift
//  MyMonero
//
//  Created by John Woods on 06/09/2017.
//  Copyright (c) 2014-2019, MyMonero.com
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
//
extension UICommonComponents.Form
{
	struct Switches {}
}
extension UICommonComponents.Form.Switches
{
	class TitleAndControlField: UIView, UIGestureRecognizerDelegate
	{
		//
		// Interface - Settable
		var toggled_fn: (() -> Void)?
		func set(
			shouldToggle_fn: ((
				_ to_isSelected: Bool,
				_ async_fn: @escaping ((_ shouldToggle: Bool) -> Void)
			) -> Void)?
		) {
			self.switchControl.shouldToggle_fn = shouldToggle_fn
		}
		//
		// Interface - Accessors
		var fixedHeight: CGFloat {
			return 40
		}
		var isSelected: Bool {
			return self.switchControl!.isSelected
		}
		//
		// Properties
		var touchInterceptingFieldBackgroundView: UIView!
		var titleLabel: FieldTitleLabel!
		var switchControl: UICommonComponents.Form.Switches.Control!
		var separatorView: UICommonComponents.Details.FieldSeparatorView!
		//
		// Lifecycle - Init
		init(frame: CGRect, title: String, isSelected: Bool)
		{
			super.init(frame: frame)
			self.setup(title: title, isSelected: isSelected)
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup(title: String, isSelected: Bool)
		{
			do {
				let view = UIView(frame: .zero)
				self.touchInterceptingFieldBackgroundView = view
				self.addSubview(view)
				//
				let recognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundView_tapped))
				recognizer.delegate = self
				view.addGestureRecognizer(recognizer)
			}
			do {
				let view = FieldTitleLabel(title: title)
				view.isUserInteractionEnabled = false // so as not to intercept touches
				self.titleLabel = view
				self.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.Switches.Control(isSelected: isSelected)
				self.switchControl = view
				view.toggled_fn =
				{ [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.toggled_fn?()
				}
				self.addSubview(view)
			}
			do {
				let view = UICommonComponents.Details.FieldSeparatorView(
					mode: .contentBackgroundAccent_subtle
				)
				view.isUserInteractionEnabled = false // so as not to intercept touches
				self.separatorView = view
				self.addSubview(view)
			}
		}
		//
		// Imperatives - Interface - Interactivity
		func set(isEnabled: Bool)
		{
			self.switchControl.isEnabled = isEnabled
		}
		//
		// Overrides - Layout
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			self.touchInterceptingFieldBackgroundView.frame = self.bounds
			//
			let minimumSwitchSectionWidth: CGFloat = 80
			let switchControl_width: CGFloat = self.switchControl.fixed__size.width
			let switchControl_height: CGFloat = self.switchControl.fixed__size.height
			//
			self.titleLabel.frame = CGRect(
				x: CGFloat.form_label_margin_x - CGFloat.form_input_margin_x, // b/c self is already positioned by the consumer at the properly inset input_x
				y: 10,
				width: self.bounds.size.width - minimumSwitchSectionWidth,
				height: self.titleLabel.frame.size.height // sizes to fit
			).integral
			self.switchControl.frame = CGRect(
				x: self.bounds.size.width - switchControl_width - 4/*design insets.right*/,
				y: (self.bounds.size.height - switchControl_height)/2, // or 17 per design
				width: switchControl_width,
				height: switchControl_height
			).integral
			self.separatorView.frame = CGRect(x: 0, y: self.bounds.size.height - self.separatorView.frame.size.height, width: self.bounds.size.width, height: self.separatorView.frame.size.height)
		}
		//
		// Delegation
		@objc func backgroundView_tapped()
		{
			if self.switchControl.isEnabled { // we must check this
				self.switchControl.sendActions(for: .touchUpInside)
			}
		}
	}
	class FieldTitleLabel: UICommonComponents.Form.FieldLabel
	{
		//
		// Properties - Static
		//
		// Lifecycle - Init
		init(title: String)
		{
			super.init(title: title, sizeToFit: true)
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			self.font = UIFont.middlingRegularMonospace
			self.textColor = UIColor(rgb: 0x8D8B8D)
		}
	}
	class Control: UIButton
	{
		//
		// Interface - Settable after init
		var toggled_fn: (() -> Void)?
		var shouldToggle_fn: ((
			_ to_isSelected: Bool,
			_ async_fn: @escaping ((_ shouldToggle: Bool) -> Void)
		) -> Void)?
		//
		// Internal
		var fixed__size: CGSize!
		enum ToggleMode
		{
			case on
			case off
			//
			var image_name: String {
				switch self {
					case .on:
						return "switch_toggle"
					case .off:
						return "switch_toggle_off"
				}
			}
			var image: UIImage {
				return UIImage(named: self.image_name)!
			}
		}
		//
		// Imperatives - Lifecycle - Init
		convenience init()
		{
			self.init(isSelected: false)
		}
		init(isSelected: Bool)
		{
			super.init(frame: .zero)
			//
			self.isSelected = isSelected
			//
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.adjustsImageWhenDisabled = true
			//
			let image__off = ToggleMode.off.image
			let image__on = ToggleMode.on.image
			self.setImage(image__off, for: .normal)
			self.setImage(image__on, for: .selected)
			//
			self.fixed__size = image__off.size // sample the size
			//
			self.addTarget(self, action: #selector(touched_upInside), for: .touchUpInside)
		}
		//
		func toggle()
		{
			let to_isSelected = !self.isSelected
			func _really_toggle()
			{
				let generator = UISelectionFeedbackGenerator()
				generator.prepare()
				//
					self.isSelected = to_isSelected
				//
				generator.selectionChanged()
				DispatchQueue.main.async { [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.toggled_fn?()
				}
			}
			if let fn = self.shouldToggle_fn {
				fn( // enable consumer to disallow toggle
					to_isSelected,
					{ (shouldToggle) in
						if shouldToggle {
							_really_toggle()
						}
					}
				)
			} else {
				_really_toggle()
			}
		}
		//
		// Delegation - Interactions
		@objc func touched_upInside()
		{
			self.toggle()
		}
	}

}
