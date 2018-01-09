//
//  SwitchControl.swift
//  MyMonero
//
//  Created by John Woods on 06/09/2017.
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
//
//UIColor extension for MyMonero colors
extension UIColor {
	// TODO: put these into (or, if specific to this file, derive these from) ThemeController
	class func myMoneroKnobBlue() -> UIColor {
		return UIColor(red: 77/255.0, green: 199/255.0, blue: 251/255.0, alpha: 1)
	}
	class func myMoneroKnobGray() -> UIColor {
		return UIColor(red: 51/255.0, green: 54/255.0, blue: 56/255.0, alpha: 1)
	}
	class func myMoneroKnobShadow() -> UIColor {
		return UIColor(red: 145/255.0, green: 150/255.0, blue: 170/255.0, alpha: 1)
	}
	class func myMoneroBackgroundGray() -> UIColor {
		return UIColor(red: 29/255.0, green: 27/255.0, blue: 29/255.0, alpha: 1)
	}
}
extension UICommonComponents.Form
{
	struct Switches {}
}
extension UICommonComponents.Form.Switches
{
	class TitleAndControlField: UIView
	{
		//
		// Metrics
		var fixedHeight: CGFloat {
			return 40
		}
		//
		// Properties
		var touchInterceptingFieldBackgroundView: UIView!
		var titleLabel: UICommonComponents.FormFieldAccessoryMessageLabel!
		var switchControl: UICommonComponents.Form.Switches.Control!
		var separatorView: UICommonComponents.Details.FieldSeparatorView!
		//
		// Lifecycle - Init
		init(frame: CGRect, title: String)
		{
			super.init(frame: frame)
			self.setup(title: title)
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup(title: String)
		{
			do {
				let view = UIView(frame: .zero)
				self.touchInterceptingFieldBackgroundView = view
				self.addSubview(view)
				do {
					let recognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundView_tapped))
					view.addGestureRecognizer(recognizer)
				}
			}
			do {
				let view = UICommonComponents.FormFieldAccessoryMessageLabel(
					text: title,
					displayMode: .normal
				)
				view.isUserInteractionEnabled = false // so as not to intercept touches
				self.titleLabel = view
				self.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.Switches.Control(frame: .zero) // initial frame
				self.switchControl = view
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
		// Overrides - Layout
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			self.touchInterceptingFieldBackgroundView.frame = self.bounds
			//
			let minimumSwitchSectionWidth: CGFloat = 80
			let switchControl_width: CGFloat = 30 // TODO: place this declaration into the control itself as a derived property - so it can scale with the UI
			let switchControl_height: CGFloat = 10 // TODO: place this declaration into the control itself as a derived property - so it can scale with the UI
			//
			self.titleLabel.frame = CGRect(
				x: CGFloat.form_label_margin_x - CGFloat.form_input_margin_x, // b/c self is already positioned by the consumer at the properly inset input_x
				y: 14,
				width: self.bounds.size.width - minimumSwitchSectionWidth,
				height: UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
			).integral
			self.switchControl.frame = CGRect(
				x: self.bounds.size.width - switchControl_width - 8/*design insets.right*/ + 1/*for visual alignment*/,
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
			self.switchControl.toggle()
		}
	}
	class Control: UIControl
	{
		fileprivate(set) var isOn = false
		var switchFeedbackGenerator:UISelectionFeedbackGenerator? = nil
		var backgroundLayer: CALayer!
		var knobLayer: CALayer!
		
		//configurable parameters
		var shadowIntensity: CGFloat { didSet { self.knobLayer?.shadowOffset = CGSize(width: 0, height: 1.5 * self.shadowIntensity); self.knobLayer?.shadowRadius = 0.6 * (self.shadowIntensity * 2) }}
		var knobOffBorderColor: UIColor? { didSet { self.knobLayer?.borderColor = self.knobOffBorderColor?.cgColor }}
		var knobOffFillColor: UIColor? { didSet { self.knobLayer?.backgroundColor = self.knobOffFillColor?.cgColor }}
		var railOffBorderColor: UIColor? { didSet { self.backgroundLayer?.borderColor = self.railOffBorderColor?.cgColor }}
		var railOffFillColor: UIColor? { didSet { self.backgroundLayer?.backgroundColor = self.railOffFillColor?.cgColor }}
		var knobDiameter: CGFloat { didSet { self.knobLayer?.frame = self.getKnobOffRect(); self.knobLayer?.cornerRadius = self.knobDiameter / 2 }}
		var cornerRadius: CGFloat { didSet { self.backgroundLayer?.self.cornerRadius = self.cornerRadius }}
		var knobCornerRadius: CGFloat { didSet { self.knobLayer?.cornerRadius = self.knobCornerRadius }}
		var knobShadowColor: UIColor? { didSet { self.knobLayer?.shadowColor = self.knobShadowColor?.cgColor }}
		var railOffInteractionBorderColor: UIColor?
		var knobOffInteractionBorderColor: UIColor?
		var railOnFillColor: UIColor?
		var railOnBorderColor: UIColor?
		var knobOnBorderColor: UIColor?
		var knobOnFillColor: UIColor?
		var railInset: CGFloat
		//end configurable parameters
		
		let knobDelta:CGFloat = 6
		
		//init methods
		required public init(coder aDecoder: NSCoder) {
			self.knobDiameter = 12
			self.cornerRadius = 10
			self.knobCornerRadius = 6
			self.railInset = 0
			self.shadowIntensity = 1
			//
			super.init(coder: aDecoder)!
			self.setup()
		}
		override public init(frame: CGRect) {
			self.knobDiameter = 12
			self.cornerRadius = 10
			self.knobCornerRadius = 6
			self.railInset = 0
			self.shadowIntensity = 1
			//
			super.init(frame: frame)
			self.setup()
		}
		//post-super-init setup
		fileprivate func setup() {
			self.clipsToBounds = false
			self.railOffBorderColor = UIColor.myMoneroBackgroundGray()
			self.railOffFillColor = UIColor.myMoneroBackgroundGray()
			self.railOnBorderColor = UIColor.myMoneroBackgroundGray()
			self.railOnFillColor = UIColor.myMoneroBackgroundGray()
			self.railOffInteractionBorderColor = UIColor.myMoneroBackgroundGray()
			
			self.knobShadowColor = UIColor.black
			self.knobOffInteractionBorderColor = UIColor.myMoneroBackgroundGray()
			self.knobOffBorderColor = UIColor.myMoneroKnobGray()
			self.knobOffFillColor = UIColor.myMoneroKnobGray()
			self.knobOnBorderColor = UIColor.myMoneroKnobBlue()
			self.knobOnFillColor = UIColor.myMoneroKnobBlue()
			
			self.knobLayer = CALayer()
			self.knobLayer.frame = self.getKnobOffRect()
			self.knobLayer.cornerRadius = self.knobCornerRadius
			self.knobLayer.backgroundColor = self.knobOffFillColor?.cgColor
			self.knobLayer.borderWidth = 1
			self.knobLayer.shadowOffset = CGSize(width: 0, height: 1.5 * self.shadowIntensity)
			self.knobLayer.shadowRadius = 0.6 * (self.shadowIntensity * 2)
			self.knobLayer.shadowColor = self.knobShadowColor?.cgColor
			self.knobLayer.shadowOpacity = 1
			self.knobLayer.borderColor = self.knobOffBorderColor?.cgColor
			
			self.backgroundLayer = CALayer()
			self.backgroundLayer.cornerRadius = self.cornerRadius
			self.backgroundLayer.borderWidth = 1
			self.backgroundLayer.borderColor = self.railOffBorderColor?.cgColor
			self.backgroundLayer.backgroundColor = self.railOffFillColor?.cgColor
			self.layer.addSublayer(self.backgroundLayer)
			self.layer.addSublayer(self.knobLayer)
		}
		//factory methods for creation of CAAnimation and CAAnimationGrp objects
		fileprivate func makeCABasicAnimation(withKeyPath:String, timingFunction:CAMediaTimingFunction, fromValue:Any, toValue:Any, fillMode:String, duration:CFTimeInterval, isRemovedOnCompletion:Bool) -> CABasicAnimation {
			let returnAnimation = CABasicAnimation(keyPath: withKeyPath)
			returnAnimation.timingFunction = timingFunction
			returnAnimation.fromValue = fromValue
			returnAnimation.toValue = toValue
			returnAnimation.fillMode = fillMode
			returnAnimation.duration = duration
			returnAnimation.isRemovedOnCompletion = isRemovedOnCompletion
			return returnAnimation
		}
		fileprivate func makeCAAnimationGrp(duration:CFTimeInterval, fillMode:String, isRemovedOnCompletion:Bool, animations:[CAAnimation]) -> CAAnimationGroup {
			let returnAnimationGrp = CAAnimationGroup()
			returnAnimationGrp.duration = duration
			returnAnimationGrp.fillMode = fillMode
			returnAnimationGrp.isRemovedOnCompletion = isRemovedOnCompletion
			returnAnimationGrp.animations = animations
			return returnAnimationGrp
		}
		
		//layout subViews
		override func layoutSubviews() {
			super.layoutSubviews()
			self.backgroundLayer.frame = CGRect(x: 0 + self.railInset, y: 0 + self.railInset, width: self.frame.width - self.railInset*2.0, height: self.frame.height - self.railInset*2.0)
			(self.isOn ? (self.knobLayer.frame = self.getKnobOnRect()) : (self.knobLayer.frame = self.getKnobOffRect()))
		}
		fileprivate func getKnobOffRect() -> CGRect {
			return CGRect(x: (self.frame.height - self.knobDiameter)/2.0, y: (self.frame.height - self.knobDiameter)/2.0, width: self.knobDiameter, height: self.knobDiameter)
		}
		fileprivate func getKnobOffInteractionRect() -> CGRect {
			return CGRect(x: (self.frame.height - self.knobDiameter)/2.0, y: (self.frame.height - self.knobDiameter)/2.0, width: self.knobDiameter + self.knobDelta, height: self.knobDiameter)
		}
		fileprivate func getKnobOnRect() -> CGRect {
			return CGRect(x: self.frame.width - self.knobDiameter - ((self.frame.height - self.knobDiameter)/2.0), y: (self.frame.height - self.knobDiameter)/2.0, width: self.knobDiameter, height: self.knobDiameter)
		}
		fileprivate func getKnobOffPos() -> CGPoint {
			return CGPoint(x: self.frame.height/2.0, y: self.frame.height/2.0)
		}
		fileprivate func getKnobOffInteractionPos() -> CGPoint {
			return CGPoint(x: self.frame.height/2.0 + self.knobDelta - 3, y: self.frame.height/2.0)
		}
		fileprivate func getKnobOnPos() -> CGPoint {
			return CGPoint(x: self.frame.width - self.frame.height/2.0, y: self.frame.height/2.0)
		}
		fileprivate func getKnobOnInteractionPos() -> CGPoint {
			return CGPoint(x: (self.frame.width - self.frame.height/2.0) - self.knobDelta + 3, y: self.frame.height/2.0)
		}
		
		func prepareFeedbackGenerator()
		{
			self.switchFeedbackGenerator = UISelectionFeedbackGenerator()
			self.switchFeedbackGenerator?.prepare()
		}
		func teardownFeedbackGenerator()
		{
			self.switchFeedbackGenerator = nil
		}
		
		override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
			super.touchesBegan(touches, with: event)
			self.prepareFeedbackGenerator()
			if (self.isOn) {
				//animations for CALayer
				let knobBoundsAnimation = self.makeCABasicAnimation(withKeyPath: "bounds", timingFunction: CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275), fromValue: NSValue(cgRect: self.getKnobOffRect()), toValue: NSValue(cgRect: self.getKnobOffInteractionRect()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				let knobPositionAnimation = self.makeCABasicAnimation(withKeyPath: "position", timingFunction: CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275), fromValue: NSValue(cgPoint: self.getKnobOnPos()), toValue: NSValue(cgPoint: self.getKnobOnInteractionPos()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				let knobBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOnBorderColor?.cgColor as Any, toValue: self.knobOnBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				let knobFillColorAnimation = self.makeCABasicAnimation(withKeyPath: "backgroundColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOnFillColor?.cgColor as Any, toValue: self.knobOnFillColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				//Containing Group
				let animKnobGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [knobBoundsAnimation, knobPositionAnimation, knobBorderColorAnimation, knobFillColorAnimation])
				
				//cleansing of animations and addition to layer
				self.knobLayer.removeAllAnimations()
				self.knobLayer.add(animKnobGrp, forKey: "knobAnimation")
			} else {
				let bgBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.55, 0.055, 0.675, 0.19), fromValue: self.railOffBorderColor?.cgColor as Any, toValue: self.railOffInteractionBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				let animGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [bgBorderColorAnimation])
				
				self.backgroundLayer.add(animGrp, forKey: "bgAnimation")
				
				
				let knobBoundsAnimation = self.makeCABasicAnimation(withKeyPath: "bounds", timingFunction: CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275), fromValue: NSValue(cgRect: self.getKnobOffRect()), toValue: NSValue(cgRect: self.getKnobOffInteractionRect()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				let knobPosAnimation = self.makeCABasicAnimation(withKeyPath: "position", timingFunction: CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275), fromValue: NSValue(cgPoint: self.getKnobOffPos()), toValue: NSValue(cgPoint: self.getKnobOffInteractionPos()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				let knobBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.55, 0.055, 0.675, 0.19), fromValue: self.knobOffBorderColor?.cgColor as Any, toValue: self.knobOffInteractionBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
				
				let animKnobGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [knobBoundsAnimation, knobPosAnimation, knobBorderColorAnimation])
				
				self.knobLayer.add(animKnobGrp, forKey: "knobAnimation")
			}
		}
		
		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
			super.touchesEnded(touches, with: event)
			let touchPoint = touches.first?.location(in: self)
			if (self.bounds.contains(touchPoint!)) {
				(self.isOn ? (self.animateFromOnToOff()) : (self.animateFromOffToOn()))
				self.isOn = !self.isOn
				self.sendActions(for: UIControlEvents.valueChanged)
			} else {
				if (self.isOn) {
					let knobBoundsAnimation = self.makeCABasicAnimation(withKeyPath: "bounds", timingFunction: CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275), fromValue: NSValue(cgRect: self.getKnobOffInteractionRect()), toValue: NSValue(cgRect: self.getKnobOffRect()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let knobPosAnimation = self.makeCABasicAnimation(withKeyPath: "position", timingFunction: CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275), fromValue: NSValue(cgPoint: self.getKnobOnInteractionPos()), toValue: NSValue(cgPoint: self.getKnobOnPos()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let knobBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOnBorderColor?.cgColor as Any, toValue: self.knobOnBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let knobFillColorAnimation = self.makeCABasicAnimation(withKeyPath: "backgroundColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOnFillColor?.cgColor as Any, toValue: self.knobOnFillColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let animKnobGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [knobBoundsAnimation, knobPosAnimation, knobBorderColorAnimation, knobFillColorAnimation])
					
					self.knobLayer.removeAllAnimations()
					self.knobLayer.add(animKnobGrp, forKey: "knobAnimation")
				} else {
					
					let bgBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.railOffInteractionBorderColor?.cgColor as Any, toValue: self.railOffBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let animGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [bgBorderColorAnimation])
					
					self.backgroundLayer.removeAllAnimations()
					self.backgroundLayer.add(animGrp, forKey: "bgAnimation")
					
					
					let knobBoundsAnimation = self.makeCABasicAnimation(withKeyPath: "bounds", timingFunction: CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1), fromValue: NSValue(cgRect: self.getKnobOffInteractionRect()), toValue: NSValue(cgRect: self.getKnobOffRect()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let knobPosAnimation = self.makeCABasicAnimation(withKeyPath: "position", timingFunction: CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1), fromValue: NSValue(cgPoint: self.getKnobOffInteractionPos()), toValue: NSValue(cgPoint: self.getKnobOffPos()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let knobBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.55, 0.055, 0.675, 0.19), fromValue: self.knobOffInteractionBorderColor?.cgColor as Any, toValue: self.knobOffBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					let animKnobGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [knobBoundsAnimation, knobPosAnimation, knobBorderColorAnimation])
					
					self.knobLayer.removeAllAnimations()
					self.knobLayer.add(animKnobGrp, forKey: "knobAnimation")
				}
			}
		}
		
		fileprivate func animateFromOnToOff() {
			let bgBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.railOnBorderColor?.cgColor as Any, toValue: self.railOffBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let bgFillColorAnimation = self.makeCABasicAnimation(withKeyPath: "backgroundColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.railOnFillColor?.cgColor as Any, toValue: self.railOffFillColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let animGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [bgBorderColorAnimation, bgFillColorAnimation])
			
			self.backgroundLayer.removeAllAnimations()
			self.backgroundLayer.add(animGrp, forKey: "bgAnimation")
			
			
			let knobBoundsAnimation = self.makeCABasicAnimation(withKeyPath: "bounds", timingFunction: CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1), fromValue: NSValue(cgRect: self.getKnobOffInteractionRect()), toValue: NSValue(cgRect: self.getKnobOffRect()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let knobPosAnimation = self.makeCABasicAnimation(withKeyPath: "position", timingFunction: CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1), fromValue: NSValue(cgPoint: self.getKnobOnInteractionPos()), toValue: NSValue(cgPoint: self.getKnobOffPos()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let knobBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOnBorderColor?.cgColor as Any, toValue: self.knobOffBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let knobFillColorAnimation = self.makeCABasicAnimation(withKeyPath: "backgroundColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOnFillColor?.cgColor as Any, toValue: self.knobOffFillColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let animKnobGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [knobBoundsAnimation, knobPosAnimation, knobBorderColorAnimation, knobFillColorAnimation])
			
			self.knobLayer.removeAllAnimations()
			self.knobLayer.add(animKnobGrp, forKey: "knobAnimation")
			self.switchFeedbackGenerator?.selectionChanged()
			self.teardownFeedbackGenerator()
		}
		
		fileprivate func animateFromOffToOn() {
			let bgBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.railOffInteractionBorderColor?.cgColor as Any, toValue: self.railOnBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let bgFillColorAnimation = self.makeCABasicAnimation(withKeyPath: "backgroundColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.railOffFillColor?.cgColor as Any, toValue: self.railOnFillColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let animBorderGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [bgBorderColorAnimation, bgFillColorAnimation])
			
			self.backgroundLayer.add(animBorderGrp, forKey: "bgOffToOnAnimation")
			
			
			let knobBoundsAnimation = self.makeCABasicAnimation(withKeyPath: "bounds", timingFunction: CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1), fromValue: NSValue(cgRect: self.getKnobOffInteractionRect()), toValue: NSValue(cgRect: self.getKnobOffRect()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let knobPosAnimation = self.makeCABasicAnimation(withKeyPath: "position", timingFunction: CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1), fromValue: NSValue(cgPoint: self.getKnobOffInteractionPos()), toValue: NSValue(cgPoint: self.getKnobOnPos()), fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let knobBorderColorAnimation = self.makeCABasicAnimation(withKeyPath: "borderColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOffInteractionBorderColor?.cgColor as Any, toValue: self.knobOnBorderColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let knobFillColorAnimation = self.makeCABasicAnimation(withKeyPath: "backgroundColor", timingFunction: CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1), fromValue: self.knobOffFillColor?.cgColor as Any, toValue: self.knobOnFillColor?.cgColor as Any, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
			
			let animKnobGrp = self.makeCAAnimationGrp(duration: 0.25, fillMode: kCAFillModeForwards, isRemovedOnCompletion: false, animations: [knobBoundsAnimation, knobPosAnimation, knobBorderColorAnimation, knobFillColorAnimation])
			
			self.knobLayer.removeAllAnimations()
			self.knobLayer.add(animKnobGrp, forKey: "knobAnimation")
			self.switchFeedbackGenerator?.selectionChanged()
			self.teardownFeedbackGenerator()
		}
		
		
		// TODO: Is this code here bugged/incomplete?
		// 1. is setOn() called on init? if not, is it guaranteed that prepareFeedbackGenerator() would have been called for all .enabled=true self? and
		// 2. should .prepareFeedbackGenerator only be called if animated=true? seems like it would cause a bug
		//
		func setOn(_ on: Bool, animated :Bool) {
			self.isOn = on
			if (animated) {
				self.prepareFeedbackGenerator()
				if (on) {
					let bgBorderAnimation = self.makeCABasicAnimation(withKeyPath: "borderWidth", timingFunction: CAMediaTimingFunction(controlPoints: 0.55, 0.055, 0.675, 0.19), fromValue: 1, toValue: self.frame.height / 2, fillMode: kCAFillModeForwards, duration: 0.25, isRemovedOnCompletion: false)
					
					self.backgroundLayer.add(bgBorderAnimation, forKey: "bgAnimation")
					self.animateFromOffToOn()
				} else {
					self.animateFromOnToOff()
				}
			} else {
				if (on) {
					self.backgroundLayer.borderColor = self.railOnBorderColor?.cgColor
					self.knobLayer.position = self.getKnobOnPos()
					self.knobLayer.borderColor = self.knobOnBorderColor?.cgColor
				} else {
					self.backgroundLayer.borderColor = self.railOffFillColor?.cgColor
					self.knobLayer.position = self.getKnobOffPos()
					self.knobLayer.borderColor = self.knobOffBorderColor?.cgColor
				}
			}
		}
		func toggle()
		{
			self.setOn(!(self.isOn), animated: true)
		}
	}

}
