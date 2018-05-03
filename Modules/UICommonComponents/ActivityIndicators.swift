//
//  ActivityIndicators.swift
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

extension UICommonComponents
{
	class GraphicActivityIndicatorView: UIView
	{
		//
		// Constants
		static let numberOf_bulbViews = 3
		static let widthOfAllBulbViews = CGFloat(numberOf_bulbViews) * GraphicActivityIndicatorPartBulbView.width
		static let widthOfInterItemSpacingBtwnAllBulbViews = (CGFloat(numberOf_bulbViews-1)) * GraphicActivityIndicatorPartBulbView.interBulbSpacing
		static let width = widthOfAllBulbViews + widthOfInterItemSpacingBtwnAllBulbViews
		//
		// Properties
		var bulbViews: [GraphicActivityIndicatorPartBulbView] = []
		var delayBetweenLoops_scheduledTimer: Timer?
		//
		// Lifecycle
		init(appearance: GraphicActivityIndicatorPartBulbView.Appearance)
		{
			let frame = CGRect(x: 0, y: 0, width: GraphicActivityIndicatorView.width, height: max(GraphicActivityIndicatorPartBulbView.height_off, GraphicActivityIndicatorPartBulbView.height_on))
			super.init(frame: frame)
			//
			for _ in 0..<GraphicActivityIndicatorView.numberOf_bulbViews {
				let bulbView = GraphicActivityIndicatorPartBulbView(appearance: appearance)
				bulbViews.append(bulbView)
				self.addSubview(bulbView)
			}
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		deinit
		{
			if self.isAnimating { // jic but may not be necessary
				self.stopAnimating()
			}
		}
		//
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			for (idx, bulbView) in bulbViews.enumerated() {
				bulbView.frame = CGRect(
					x: CGFloat(idx) * (GraphicActivityIndicatorPartBulbView.width + GraphicActivityIndicatorPartBulbView.interBulbSpacing),
					y: bulbView.frame.origin.y,
					width: bulbView.frame.size.width,
					height: bulbView.frame.size.height
				)
			}
		}
		//
		// Imperatives
		var isAnimating = false
		func startAnimating()
		{
			assert(Thread.isMainThread)
			if self.isAnimating {
				// TODO: assert that has animations or timer
				assert(false)
			}
			self.isAnimating = true
			self._animateNextLoop()
		}
		var isAnimatingALoop = false
		func _animateNextLoop()
		{
			assert(Thread.isMainThread)
			if self.isAnimating == false {
				return // terminate; may have been called after a cancel
			}
			if self.isAnimatingALoop {
				assert(false)
				return // terminate; may have been called after a cancel
			}
			self.isAnimatingALoop = true
			let durationOfAnimationTo_on = 0.15
			let durationOfAnimationTo_off = 0.3
			let delayBetweenLoops: TimeInterval = 0.05
			
			// TODO: rework this to make it resilient to restarting if necessary
			
			for (idx, bulbView) in bulbViews.enumerated() {
//				bulbView.layer.removeAllAnimations() // in case
				//
				let bulbAnimationDelay: TimeInterval = TimeInterval(idx) * (durationOfAnimationTo_on + 0.05)
				UIView.animate(
					withDuration: durationOfAnimationTo_on,
					delay: bulbAnimationDelay,
					options: [.curveEaseInOut],
					animations:
					{
						bulbView.configureAs_on()
					},
					completion:
					{ [unowned self] (finished) in
						if finished {
							UIView.animate(
								withDuration: durationOfAnimationTo_off,
								delay: 0,
								options: [.curveEaseInOut],
								animations:
								{
									bulbView.configureAs_off()
								},
								completion:
								{ [unowned self] (finished) in
									if finished {
										if idx == GraphicActivityIndicatorView.numberOf_bulbViews - 1 {
											let scheduledTimer = Timer.scheduledTimer(
												withTimeInterval: delayBetweenLoops,
												repeats: false,
												block:
												{ [unowned self] (timer) in
													self.delayBetweenLoops_scheduledTimer = nil
													self.isAnimatingALoop = false
													self._animateNextLoop()
												}
											)
											self.delayBetweenLoops_scheduledTimer = scheduledTimer
										}
									}
								}
							)
						}
					}
				)
			}
		}
		func stopAnimating()
		{
			assert(Thread.isMainThread)
			if self.isAnimating == false {
				// TODO: assert that has NO animations and NO timer
				return
			}
			// TODO: assert that has animations or timer
			if let timer = self.delayBetweenLoops_scheduledTimer {
				timer.invalidate()
				self.delayBetweenLoops_scheduledTimer = nil // important to prevent crashes on deinit
			}
			for (_, bulbView) in bulbViews.enumerated() {
				bulbView.layer.removeAllAnimations()
				bulbView.configureAs_off()
			}
			self.isAnimating = false
			self.isAnimatingALoop = false
		}
	}
	class GraphicActivityIndicatorPartBulbView: UIImageView
	{
		//
		// Constants
		static let image__decoration = UIImage(named: "graphicActivityIndicator_decoration")!.stretchableImage(withLeftCapWidth: 1, topCapHeight: 1)
		//
		static let width: CGFloat = 3
		static let interBulbSpacing: CGFloat = 2
		//
		static let height_off: CGFloat = 8
		static let height_on: CGFloat = 8
		//
		static let y_off: CGFloat = 3
		static let y_on: CGFloat = 0
		//
		static let color_on__normalBackground = UIColor(rgb: 0x494749)
		static let color_off__normalBackground = UIColor(rgb: 0x383638)
		static let color_on__accentBackground = UIColor(rgb: 0x7C7A7C)
		static let color_off__accentBackground = UIColor(rgb: 0x5A585A)
		enum Appearance
		{
			case onNormalBackground
			case onAccentBackground
			//
			var color_on: UIColor {
				switch self {
					case .onNormalBackground:
						return color_on__normalBackground
					case .onAccentBackground:
						return color_on__accentBackground
				}
			}
			var color_off: UIColor {
				switch self {
					case .onNormalBackground:
						return color_off__normalBackground
					case .onAccentBackground:
						return color_off__accentBackground
				}
			}
			var shadowColor: UIColor {
				switch self {
					case .onNormalBackground:
						return UIColor(red: 22.0/255.0, green: 20.0/255.0, blue: 22.0/255.0, alpha: 155.0/255.0)
					case .onAccentBackground:
						return UIColor(red: 33.0/255.0, green: 30.0/255.0, blue: 33.0/255.0, alpha: 135.0/255.0)
				}
			}
		}
		//
		// Properties
		var appearance: Appearance!
		//
		init(appearance: Appearance)
		{
			self.appearance = appearance
			super.init(image: GraphicActivityIndicatorPartBulbView.image__decoration)
			do {
				let layer = self.layer
				layer.shadowColor = self.appearance.shadowColor.cgColor
				layer.shadowOpacity = 1
				layer.shadowOffset = CGSize(width: 0, height: 1)
				layer.shadowRadius = 1
				//
				layer.cornerRadius = 1
			}
			self.configureAs_off() // initial config; will set frame
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		//
		// Imperatives - Animation - Configuration
		func configureAs_on()
		{
			self.configure(
				withY: GraphicActivityIndicatorPartBulbView.y_on,
				height: GraphicActivityIndicatorPartBulbView.height_on,
				color: self.appearance.color_on
			)
		}
		func configureAs_off()
		{
			self.configure(
				withY: GraphicActivityIndicatorPartBulbView.y_off,
				height: GraphicActivityIndicatorPartBulbView.height_off,
				color: self.appearance.color_off
			)
		}
		func configure(withY y: CGFloat, height: CGFloat, color: UIColor)
		{
			let frame = CGRect(x: self.frame.origin.x, y: y, width: GraphicActivityIndicatorPartBulbView.width, height: height)
			self.frame = frame
			self.backgroundColor = color
		}
	}
	class GraphicAndLabelActivityIndicatorView: UIView
	{
		//
		// Constants
		static let spaceBetweenGraphicAndLabel: CGFloat = 7
		//
		static let marginAboveActivityIndicatorBelowFormInput: CGFloat = 6
		//
		// Properties
		var activityIndicator = GraphicActivityIndicatorView(appearance: .onNormalBackground)
		var label = Form.FieldLabel(title: "", sizeToFit: false)
		//
		// Lifecycle
		init()
		{
			super.init(frame: .zero)
			self.setup()
//			self.giveBorder()
//			self.borderSubviews()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.addSubview(activityIndicator)
			self.addSubview(label)
		}
		//
		// Accessors - Layout
		var new_height: CGFloat {
			var height = self.new_height_withoutVSpacing
			height += 12 // for v spacing
			//
			return height
		}
		var new_height_withoutVSpacing: CGFloat {
			// validate too-early call
			assert(self.label.frame != .zero)
			assert(self.activityIndicator.frame != .zero)
			//
			return max(
				self.label.frame.origin.y + self.label.frame.size.height,
				self.activityIndicator.frame.origin.y + self.activityIndicator.frame.size.height
			)
		}
		//
		// Imperatives
		func set(labelText: String)
		{
			self.label.text = labelText
			self.label.sizeToFit()
			self.setNeedsLayout()
		}
		//
		func show()
		{
			if self.isHidden == false {
//				DDLog.Warn("UICommonComponents.ActivityIndicators", ".show() called but isHidden=false; bailing.")
				return
			}
			self.isHidden = false
			if !self.activityIndicator.isAnimating {
				self.activityIndicator.startAnimating()
			}
		}
		func hide()
		{
			if self.isHidden == true {
				// common
//				DDLog.Warn("UICommonComponents.ActivityIndicators", ".hide() called but isHidden=true; bailing.")
				return
			}
			self.isHidden = true
			if self.activityIndicator.isAnimating {
				self.activityIndicator.stopAnimating()
			}
		}
		//
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			self.activityIndicator.frame = CGRect(
				x: 0,
				y: 0,
				width: self.activityIndicator.frame.size.width,
				height: self.activityIndicator.frame.size.height
			)
			self.label.frame = CGRect(
				x: self.activityIndicator.frame.origin.x + self.activityIndicator.frame.size.width + GraphicAndLabelActivityIndicatorView.spaceBetweenGraphicAndLabel,
				y: -2, // because it's larger now
				width: self.label.frame.size.width,
				height: self.label.frame.size.height
			)
		}
	}
	class GraphicAndTwoUpLabelsActivityIndicatorView: GraphicAndLabelActivityIndicatorView
	{
		var accessoryLabel = Form.FieldLabel(title: "", sizeToFit: false)
		override func setup()
		{
			super.setup()
			//
			let view = self.accessoryLabel
			view.textAlignment = .right
			view.font = UIFont.smallLightMonospace // lighter than bold
			view.adjustsFontSizeToFitWidth = true // for smaller screens
			view.minimumScaleFactor = 0.4
			self.addSubview(view)
		}
		//
		// Imperatives
		func set(accessoryLabelText text: String)
		{
			self.accessoryLabel.text = text
			// no need for re-layout here b/c accessoryLabel isn't sized to fit... (yet?)
		}
		//
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			let left = self.label.frame.origin.x + self.label.frame.size.width
			self.accessoryLabel.frame = CGRect(
				x: left,
				y: self.label.frame.origin.y,
				width: self.frame.size.width - left,
				height: self.accessoryLabel.frame.size.height
			)
		}
	}
	//
	class ResolvingActivityIndicatorView: GraphicAndLabelActivityIndicatorView
	{
		override init()
		{
			super.init()
			self.set(labelText: NSLocalizedString("RESOLVING…", comment: ""))
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}
