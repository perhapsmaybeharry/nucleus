//
//  classes.swift
//  Nucleus
//
//  Created by Harry Wang on 12/4/16.
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa

var defaultpath = ("~/Library/Application Support/Nucleus" as NSString).stringByExpandingTildeInPath

///nucleus class. Comprises low-level file interactions which should mostly be left to the interface class.
class nucleus {
	
	///Loads a packet from the specified position.
	func load(position: Int) -> Packet {
		debug("Loading packet from position \(position)")
		let loadPacket = Packet()
		var contents = String()
		do {
			contents = try String(contentsOfFile: defaultpath.stringByAppendingString(String("/\(position)")))
		} catch let err as NSError {
			debug("For some reason, the packet file couldn't be accessed.")
			debug("Error is as follows: \(err.localizedDescription)")
			return loadPacket
		}
		// now split the values with the delimiter "➾✇✂︎🁢෴⎋෴🁢︎✂✇➾" and load it into packet
		debug("Refining string into components")
		let refinedcontents = contents.componentsSeparatedByString("➾✇✂︎🁢෴⎋෴🁢︎✂✇➾")
		debug("\(refinedcontents.count) components identified")
		loadPacket.completed = refinedcontents[0].toBool()!
		loadPacket.contents = refinedcontents[1]
		loadPacket.position = Int(refinedcontents[2])!
		loadPacket.title = refinedcontents[3]
		printPacket(loadPacket)
		return loadPacket
	}
	///Writes the contents of the provided packet to its location.
	func write(whichPacket: Packet) {
		debug("Writing packet of position \(whichPacket.position)")
		printPacket(whichPacket)
		var dataString = String()
		dataString = String(whichPacket.completed).stringByAppendingString("➾✇✂︎🁢෴⎋෴🁢︎✂✇➾").stringByAppendingString(whichPacket.contents).stringByAppendingString("➾✇✂︎🁢෴⎋෴🁢︎✂✇➾").stringByAppendingString(String(whichPacket.position)).stringByAppendingString("➾✇✂︎🁢෴⎋෴🁢︎✂✇➾").stringByAppendingString(String(whichPacket.title))
		do {
			try dataString.writeToFile(defaultpath.stringByAppendingString("/\(String(whichPacket.position))"), atomically: true, encoding: NSUTF8StringEncoding)
		} catch let err as NSError {
			debug("For some reason, the packet file couldn't be written to.")
			debug("Error is as follows: \(err.localizedDescription)")
		}
	}
	///Deletes the specified packet. Renames successive packets (if any) (WIP).
	func delete(whichPacket: Packet) {
		debug("Deleting packet of position \(whichPacket.position)")
		do {
			try NSFileManager().removeItemAtPath(defaultpath.stringByAppendingString("/\(whichPacket.position)"))
		} catch let err as NSError {
			debug("For some reason, the packet file couldn't be removed.")
			debug("Error is as follows: \(err.localizedDescription)")
		}
	}
	// implementation: packet printing
	func printPacket(whichPacket: Packet) {
		debug("Packet in position \(whichPacket.position):\ncompleted:\t\(String(whichPacket.completed))\ncontents:\t\(whichPacket.contents)\nposition:\t\(whichPacket.position)\ntitle:\t\t\(whichPacket.title)")
	}
}

class Packet {
	var contents = String()
	var completed = Bool()
	var position = 0
	// implementation for title
	var title = String()
}

///interface class. Comprises mid-level programmatic functions which act as an interface between the files and GUI. Most of the program logic is done within this class.
class interface {
	
	private var	persistentPacket = Packet()
	
	///Ascends to the next packet. If the next packet doesn't exist, it creates a new packet.
	func ascend(display: NSTextView?, title: NSTextField) {
		debug("Ascending from \(persistentPacket.position)")
		save()
		if persistentPacket.contents == Packet().contents && persistentPacket.title == Packet().title {
			debug("Current packet \(persistentPacket.position) is empty, not ascending")
			return
		}
		persistentPacket.position += 1
		clear(display)
		title.stringValue = String()
		if NSFileManager().fileExistsAtPath(defaultpath.stringByAppendingString(String("/\(persistentPacket.position)"))) == false {
			debug("Already at top packet \(persistentPacket.position), creating new packet")
			persistentPacket.completed = Packet().completed
			persistentPacket.contents = Packet().contents
			persistentPacket.title = Packet().title
			save()
			return
		}
		else {
			while true {
				persistentPacket = nucleus().load(persistentPacket.position)
				if config().load().hideCompleted {
					// hide completed packets
					if persistentPacket.completed == true {debug("Packet is completed, skipping");persistentPacket.position+=1}
					else {debug("Packet is not completed, printing"); break}
				}
				else {
					// don't hide completed packets
					break;
				}
			}
			xlog(display, line: persistentPacket.contents)
			title.stringValue = persistentPacket.title
			debug("Ascended to \(persistentPacket.position)")
		}
	}
	///Descends to the previous packet. If the packet is already at 0, it doesn't allow any further descents.
	func descend(display: NSTextView?, title: NSTextField) {
		debug("Descending from \(persistentPacket.position)")
		title.stringValue = String()
		save()
		if persistentPacket.position == 0 {
			debug("Already at lowest packet \(persistentPacket.position)")
			// cannot be descended any further
			return
		}
		else {
			while true {
				clear(display)
				persistentPacket.position-=1
				persistentPacket = nucleus().load(persistentPacket.position)
				if config().load().hideCompleted {
					// hide completed packets
					if persistentPacket.position == 0 && nucleus().load(0).completed == true {debug("Packet at zero is completed, printing"); break}
					else if persistentPacket.completed == true {debug("Packet is completed, skipping")}
					else {debug("Packet is not completed, printing"); break}
				}
				else {
					// don't hide completed packets
					break;
				}
			}
			xlog(display, line: persistentPacket.contents)
			title.stringValue = persistentPacket.title
			debug("Descended to \(persistentPacket.position)")
		}
	}
	///Marks the current packet as completed.
	func complete(newstate: Bool) {
		persistentPacket.completed = newstate
		save()
		debug("Packet \(persistentPacket.position)'s completed status was set to \(String(newstate))")
	}
	///Saves the current packet.
	func save() {
		nucleus().write(persistentPacket)
		debug("Packet \(persistentPacket.position) saved")
	}
	///Deletes the current packet.
	func delete(display: NSTextView?, title: NSTextField) {
		nucleus().delete(persistentPacket)
		debug("Packet \(persistentPacket.position) deleted")
		// successive renaming
		// logic: check if file > persistentPacket.position+tracker, subtract one from filename, add one to tracker
		var tracker = persistentPacket.position
		while NSFileManager().fileExistsAtPath(defaultpath.stringByAppendingString("/\(tracker+1)")) == true {
			// subtract one from filename
			do {
				try NSFileManager().moveItemAtPath(defaultpath.stringByAppendingString("/\(tracker+1)"), toPath: defaultpath.stringByAppendingString("/\(tracker)"))
				let renamepacket = nucleus().load(tracker)
				renamepacket.position = tracker
				nucleus().write(renamepacket)
				debug("Repositioned packet at position \(tracker+1) to position \(tracker)")
			} catch let err as NSError {
				debug("For some reason, the packet at position \(tracker+1) could not be repositioned to position \(tracker)")
				debug("Error is as follows: \(err.localizedDescription)")
			}
			tracker+=1
		}
		debug("Successive repositioning completed")
		clear(display)
		xlog(display, line: nucleus().load(persistentPacket.position).contents)
		title.stringValue = nucleus().load(persistentPacket.position).title
		
		makefancy(display)
		debug("Display updated")
	}
	///Synchronises packet contents.
	func sync(text: String, title: String) {
		persistentPacket.contents = text
		persistentPacket.title = title
		debug("Packet \(persistentPacket.position) synced")
	}
	///Makes text look fancy.
	func makefancy(display: NSTextView?) {
		debug("Making textfield fancy")
		
		//http://stackoverflow.com/questions/29390851/change-the-color-and-the-font-of-nstextview
		//http://stackoverflow.com/questions/28957940/remove-all-line-breaks-at-the-beginning-of-a-string-in-swift
		//http://stackoverflow.com/questions/24588939/how-to-center-uitextfield-text-in-swift
		
		let font = NSFont.systemFontOfSize(config().load().fontSize, weight: NSFontWeightUltraLight)
		let attributes = NSDictionary(object: font, forKey: NSFontAttributeName)
		let string = NSMutableAttributedString(string: (display?.textStorage?.string)!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
		string.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, string.length))
		display?.alignment = .Center
		display?.textStorage?.setAttributedString(string)
		display?.typingAttributes = attributes as! [String : AnyObject]
		debug("Textfield has been fancified")
	}
	///Checks if it is the first time that the app has been loaded into view, and if yes, prints the first nucleoid.
	func printzero(display: NSTextView?, title: NSTextField) {
		if persistentPacket.position == 0 && persistentPacket.contents == String() && persistentPacket.title == String() {
			xlog(display, line: nucleus().load(0).contents)
			title.stringValue = nucleus().load(0).title
			print("Loaded first packet at position \(persistentPacket.position)")
		}
	}
	func displaycompletedstatus(checkbox: NSButton) {
		if nucleus().load(persistentPacket.position).completed == false {checkbox.state = NSOffState}
		if nucleus().load(persistentPacket.position).completed == true {checkbox.state = NSOnState}
	}
	// implementation: position counter
	func position() -> Int {
		return persistentPacket.position
	}
	func getMaxPosition() -> Int {
		var tracker = 1
		while NSFileManager().fileExistsAtPath(defaultpath.stringByAppendingString("/\(tracker)")) == true {
			// the file exists
			tracker+=1
		}
		return tracker
	}
}

class EventMonitor {
	private var monitor: AnyObject?
	private let mask: NSEventMask
	private let handler: NSEvent? -> ()

	init(mask: NSEventMask, handler: NSEvent? -> ()) {
		self.mask = mask
		self.handler = handler
	}
	deinit {
		stop("self")
	}
	func start(watching: String) {
		monitor = NSEvent.addGlobalMonitorForEventsMatchingMask(mask, handler: handler)
		debug("Click-out monitor for \(watching) started")
	}
	func stop(watching: String) {
		if monitor != nil {
			NSEvent.removeMonitor(monitor!)
			monitor = nil
		}
		debug("Click-out monitor for \(watching) stopped")
	}
}

class options {
	var fontSize = CGFloat(30.0)
	var hideCompleted = Bool()
}

class config {
	func load() -> options  {
		var components = [String()]
		let returnset = options()
		do {
			components = try String(contentsOfFile: defaultpath.stringByAppendingString("/config")).componentsSeparatedByString(",")
		} catch let err as NSError {
			debug("For some reason, the configuration file couldn't be read.")
			debug("Error is as follows: \(err.localizedDescription)")
			return returnset
		}
		returnset.fontSize = CGFloat(NSNumberFormatter().numberFromString(components[0])!)
		returnset.hideCompleted = components[1].toBool()!
		debug("Loaded configurations")
		debug("fontsize: \(returnset.fontSize)")
		debug("hidecompleted: \(returnset.hideCompleted)")
		return returnset
	}
	func write(optionset: options) {
		debug("Writing configurations")
		debug("fontsize: \(optionset.fontSize)")
		debug("hidecompleted: \(optionset.hideCompleted)")
		do {
			try String(optionset.fontSize).stringByAppendingString(",").stringByAppendingString(String(optionset.hideCompleted)).writeToFile(defaultpath.stringByAppendingString("/config"), atomically: true, encoding: NSUTF8StringEncoding)
		} catch let err as NSError {
			print("Something went wrong writing the configuration file")
			debug("Error is as follows: \(err.localizedDescription)")
		}
	}
}