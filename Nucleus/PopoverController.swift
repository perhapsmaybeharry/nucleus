//
//  PopoverController.swift
//  menubarlists
//
//  Created by Harry Wang on 10/3/16.
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa
import EventKit

let prefPopover = NSPopover()

class PopoverController: NSViewController {
	
	override func viewDidAppear() {
		debug("Checking for Nucleus database at \(defaultpath)")
		if NSFileManager().fileExistsAtPath(defaultpath) == false {
			print("Nucleus database could not be found! Attempting to recreate.")
			do {
				try NSFileManager().createDirectoryAtPath(defaultpath, withIntermediateDirectories: true, attributes: nil)
				print("Nucleus database created successfully.")
			} catch {
				print("Nucleus database failed to be created. Please check your permissions.")
			}
		}
		debug("Nucleus database present at \(defaultpath)")
		debug("Checking for activity log")
		if NSFileManager().fileExistsAtPath(defaultpath.stringByAppendingString("/activity.txt")) == false {
			debug("Activity log does not exist at \(defaultpath), creating")
			NSFileManager().createFileAtPath(defaultpath.stringByAppendingString("/activity.txt"), contents: nil, attributes: nil)
		}
		debug("Activity log exists at \(defaultpath.stringByAppendingString("/activity.txt"))")
		debug("Checking for configuration file")
		if NSFileManager().fileExistsAtPath(defaultpath.stringByAppendingString("/config")) == false {
			do {
				debug("Configuration file does not exist, creating with default settings")
				try String("30,true").writeToFile(defaultpath.stringByAppendingString("/config"), atomically: false, encoding: NSUTF8StringEncoding)
			} catch let err as NSError {
				debug("Configuration file failed to be created. Please check your permissions.")
				debug("Error is as follows: \(err.localizedDescription)")
			}
		}
		debug("Configuration file present at \(defaultpath.stringByAppendingString("/config"))")		
		debug("View was loaded into view")
		
		client.printzero(content, title: header)
		client.makefancy(content)
		
		// switch delete to quit
		// http://stackoverflow.com/questions/36622263/programatically-changing-button-text-and-actions-when-a-modifier-key-is-pressed
		NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.AnyEventMask) { event in
			if event.modifierFlags.contains(.AlternateKeyMask) {
				debug("Option key pressed, switching \"Delete\" to \"Quit\" and \"Save\" to \"Options\"")
				self.deletequit.title = "Quit"
				self.savepref.title = "Options"
			} else if event.modifierFlags.contains(.AlternateKeyMask) == false {
				// uncommenting this will spam logs
				/*debug("Option key released, switching \"Quit\" to \"Delete\"")*/
				self.deletequit.title = "Delete"
				self.savepref.title = "Save"
			}
			return event
		}
		
		// setup preferences popover
		prefPopover.contentViewController = PrefPopover(nibName: "PrefPopover", bundle: nil)
		
		// setup preferences leftclick watcher
		monitorPrefLeftClick = EventMonitor(mask: .LeftMouseDownMask) { [unowned self] event in
			if prefPopover.shown {
				self.closePrefPopover(event)
			}
		}
		
		currentPosition.integerValue = client.position()+1
		maxPosition.integerValue = client.getMaxPosition()
		
		if currentPosition.integerValue == 1 {descendbutton.enabled = false}
		else {descendbutton.enabled = true}
		
	}
	
	override func viewDidDisappear() {
		client.sync(content.string!, title: header.stringValue)
		client.save()
		debug("View was unloaded from view")
	}
	
	let client = interface()
	
	@IBAction func ascend(sender: NSButton) {
		client.sync(content.string!, title: header.stringValue)
		client.save()
		client.ascend(content, title: header)
		client.makefancy(content)
		client.displaycompletedstatus(checkbox)
		currentPosition.integerValue=client.position()+1
		maxPosition.integerValue = client.getMaxPosition()
		if currentPosition.integerValue == 1 {descendbutton.enabled = false}
		else {descendbutton.enabled = true}
	}
	
	@IBAction func descend(sender: NSButton) {
		client.sync(content.string!, title: header.stringValue)
		client.save()
		client.descend(content, title: header)
		client.makefancy(content)
		client.displaycompletedstatus(checkbox)
		currentPosition.integerValue=client.position()+1
		if currentPosition.integerValue == 1 {descendbutton.enabled = false}
		else {descendbutton.enabled = true}
	}
	
	@IBOutlet var descendbutton: NSButton!
	
	@IBAction func delete(sender: NSButton) {
		if deletequit.title == "Delete" {
			client.delete(content, title: header)
			client.displaycompletedstatus(checkbox)
			currentPosition.integerValue=client.position()+1
			maxPosition.integerValue = client.getMaxPosition()
			if maxPosition.integerValue < currentPosition.integerValue {
				maxPosition.integerValue+=1
			}
			if currentPosition.integerValue == 1 {descendbutton.enabled = false}
			else {descendbutton.enabled = true}
		}
		else if deletequit.title == "Quit" {
			debug("Nucleus is quitting")
			client.save()
			popover.performClose(sender)
			monitorLeftClick?.stop("main popover")
			
			debug("Nucleus has quit")
			NSApplication.sharedApplication().terminate(self)
		}
	}
	
	@IBAction func completed(sender: NSButton) {
		if checkbox.state == NSOnState {
			client.complete(true)
		}
		else if checkbox.state == NSOffState {
			client.complete(false)
		}
	}
	
	@IBAction func save(sender: NSButton) {
		if savepref.title == "Save" {
			if prefPopover.shown {
				closePrefPopover(sender)
			}
			client.sync(content.string!, title: header.stringValue)
			client.save()
		}
		else if savepref.title == "Options" {
			client.sync(content.string!, title: header.stringValue)
			client.save()
			if prefPopover.shown {
				closePrefPopover(sender)
			}
			else {showPrefPopover(sender)}
		}
	}
	
	@IBOutlet var content: NSTextView!
	@IBOutlet var checkbox: NSButton!
	
	@IBOutlet var deletequit: NSButton!
	@IBOutlet var savepref: NSButton!
	
	
	// implementation: position counter
	@IBOutlet var currentPosition: NSTextFieldCell!
	@IBOutlet var maxPosition: NSTextField!
	
	// implementation: title field
	@IBOutlet var header: NSTextField!
	
	//implementation: preferences popover
	func showPrefPopover(sender: AnyObject?) {
		if let button = savepref {
			prefPopover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
		}
		monitorPrefLeftClick?.start("preferences popover")
	}
	func closePrefPopover(sender: AnyObject?) {
		prefPopover.performClose(sender)
		monitorPrefLeftClick?.stop("preferences popover")
		client.makefancy(content)
	}
	func togglePrefPopover(sender: AnyObject?) {
		if prefPopover.shown {
			closePrefPopover(sender)
		} else {
			showPrefPopover(sender)
		}
	}
	
}
