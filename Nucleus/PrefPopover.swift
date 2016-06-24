//
//  PrefPopover.swift
//  Nucleus
//
//  Created by Harry Wang on 17/4/16.
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa

class PrefPopover: NSViewController {
	
	private var optionset = options()
	
	override func viewDidLoad() {
		debug("Preferences popover did load")
		slider.altIncrementValue = 0.1
		debug("Setting up display from file")
		optionset = config().load()
		slider.doubleValue = Double(optionset.fontSize)
		slider.setNeedsDisplay()
		sizereflector.stringValue = slider.stringValue
		if optionset.hideCompleted == true {showcompleted.state = NSOffState}
		else if optionset.hideCompleted == false {showcompleted.state = NSOnState}
		debug("Display has been set up")
	}
	
	@IBOutlet var slider: NSSlider!
	@IBOutlet var sizereflector: NSTextField!
	
	@IBOutlet var showcompleted: NSButton!
	
	@IBAction func completedtoggle(sender: NSButton) {
		if showcompleted.state == NSOnState {optionset.hideCompleted = false}
		else if showcompleted.state == NSOffState {optionset.hideCompleted = true}
		config().write(optionset)
	}
	@IBAction func sliderchanged(sender: NSSlider) {
		optionset.fontSize = CGFloat(Int(slider.doubleValue*10))/10
		sizereflector.stringValue = String(optionset.fontSize)
		config().write(optionset)
	}
}
