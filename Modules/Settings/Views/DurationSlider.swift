//
//  DurationSlider.swift
//  MyMonero
//
//  Created by John Woods on 07/05/2017.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

protocol DurationSliderDelegate:class {
    func durationUpdated(_ durationInSeconds:Int)
}

class DurationSlider: UISlider
{
    let durationLabel: UILabel = UILabel()
    let minLabel: UILabel = UILabel()
    let maxLabel: UILabel = UILabel()
    let minLabelText: String = "5s"
    let maxLabelText: String = "Never"

    var step: Float = 5
    var dateComponents = DateComponents()
    let formatter = DateComponentsFormatter()
    
    //delegate
    weak var delegate:DurationSliderDelegate?

    init() {
        super.init(frame: .zero)
		do {
			self.formatter.unitsStyle = .abbreviated
			self.formatter.allowedUnits = [.second, .minute]
		}
		self.setup_views()
    }
    
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
	func setup_views() {
		do {
			self.minimumValue = 5
			self.maximumValue = 1500
			self.value = 5
			self.tintColor = UIColor.orange
			//
			self.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
		}
        
		do {
			let view = self.durationLabel
			view.frame = CGRect(x: 0, y: -25, width: 0, height: 25) // must set y and h for sizeToFit() and layoutSubviews()
			view.textAlignment = NSTextAlignment.center
			self.addSubview(view)
			self.configureValueLabel(animateTransitions: true)
            
            let leftView = self.minLabel
            leftView.text = self.minLabelText
            leftView.font = UIFont.systemFont(ofSize: 10)
            self.addSubview(leftView)
            
            let rightView = self.maxLabel
            rightView.text = self.maxLabelText
            rightView.font = UIFont.systemFont(ofSize: 10)
            self.addSubview(rightView)
		}
	}
	
	func configureValueLabel(animateTransitions: Bool) {
        if (self.value == 1500) {
            self.durationLabel.text = NSLocalizedString("Never", comment: "")
		} else {
			self.durationLabel.text = self.formatter.string(from: self.dateComponents)
		}
        self.layout_valueLabel()
    }
    
    override func layoutSubviews() {
		super.layoutSubviews()
		//
		self.layout_valueLabel()
        self.layout_minMaxLabel()
	}
    
    func layout_minMaxLabel() {
        self.minLabel.frame = CGRect(x: -20, y: 0, width: 50, height: self.bounds.height)
        self.maxLabel.frame = CGRect(x: self.bounds.size.width+10, y: 0, width: 50, height: self.bounds.height)
    }
    
	func layout_valueLabel() {
		let trackRect = self.trackRect(forBounds: self.bounds)
		let thumbRect = self.thumbRect(forBounds: self.bounds, trackRect: trackRect, value: self.value)
		let knob_centerX = thumbRect.origin.x + thumbRect.size.width/2
		
		self.durationLabel.sizeToFit()
        
        self.durationLabel.frame = CGRect(
			x: knob_centerX - self.durationLabel.frame.width/2,
			y: self.durationLabel.frame.origin.y,
			width: self.durationLabel.frame.size.width,
			height: self.durationLabel.frame.size.height
		).integral
    }
    
    func sliderValueChanged() {
		do { // update local state
			switch (self.value) { // determine stepping category
				case 1..<120:
					self.step = 5
				default:
					self.step = 60
			}
			//
			// round value to step
			self.value = round(self.value / step) * step
			//
			// update formatter for UI config
			self.dateComponents.second = Int(self.value)
		}
		do { // update UI given new state
			self.configureValueLabel(
				animateTransitions: true // b/c from user interaction
			)
		}
		do { // emit/yield
			var wholeNumberOfSeconds: Int
			switch self.value {
				case 1500:
					wholeNumberOfSeconds = -1
				default:
					wholeNumberOfSeconds = (Int)(round(self.value / step) * step)
			}
			self.delegate?.durationUpdated(wholeNumberOfSeconds)
		}
    }
}
