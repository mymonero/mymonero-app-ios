//
//  ActivityIndicators.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/1/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
		init()
		{
			let frame = CGRect(x: 0, y: 0, width: GraphicActivityIndicatorView.width, height: max(GraphicActivityIndicatorPartBulbView.height_off, GraphicActivityIndicatorPartBulbView.height_on))
			super.init(frame: frame)
			do {
				for _ in 0..<GraphicActivityIndicatorView.numberOf_bulbViews {
					let bulbView = GraphicActivityIndicatorPartBulbView()
					bulbViews.append(bulbView)
					self.addSubview(bulbView)
				}
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
			if self.isAnimating {
				assert(false)
				return
			}
			self.isAnimating = true
			self._animateNextLoop()
		}
		var isAnimatingALoop = false
		func _animateNextLoop()
		{
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
					{ (finished) in
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
			if self.isAnimating == false {
				return
			}
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
		static let color_on = UIColor(rgb: 0x494749)
		static let color_off = UIColor(rgb: 0x383638)
		//
		init()
		{
			super.init(image: GraphicActivityIndicatorPartBulbView.image__decoration)
			do {
				let layer = self.layer
				layer.shadowColor = UIColor(red: 22.0/255.0, green: 20.0/255.0, blue: 22.0/255.0, alpha: 155.0/255.0).cgColor
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
				color: GraphicActivityIndicatorPartBulbView.color_on
			)
		}
		func configureAs_off()
		{
			self.configure(
				withY: GraphicActivityIndicatorPartBulbView.y_off,
				height: GraphicActivityIndicatorPartBulbView.height_off,
				color: GraphicActivityIndicatorPartBulbView.color_off
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
		var activityIndicator = GraphicActivityIndicatorView()
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
				DDLog.Warn("UICommonComponents.ActivityIndicators", ".show() called but isHidden=false; bailing.")
				return
			}
			self.isHidden = false
			self.activityIndicator.startAnimating()
		}
		func hide()
		{
			if self.isHidden == true {
				// common
//				DDLog.Warn("UICommonComponents.ActivityIndicators", ".hide() called but isHidden=true; bailing.")
				return
			}
			self.isHidden = true
			self.activityIndicator.stopAnimating()
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
				y: 0,
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
			self.accessoryLabel.textAlignment = .right
			self.addSubview(accessoryLabel)
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
			self.accessoryLabel.frame = CGRect(
				x: 0,
				y: self.label.frame.origin.y,
				width: self.frame.size.width,
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
