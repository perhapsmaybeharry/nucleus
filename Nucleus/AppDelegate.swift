//
//  AppDelegate.swift
//  menubarlists
//
//  Created by Harry Wang on 10/3/16.
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa

let menuBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
let popover = NSPopover()
var monitorLeftClick: EventMonitor?, monitorPrefLeftClick: EventMonitor?
var dropdown = NSMenu()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	func applicationDidFinishLaunching(notification: NSNotification) {
		if let button = menuBarItem.button {
			button.image = NSImage(named: "atom")
			button.action = #selector(togglePopover(_:))
		}
		popover.contentViewController = PopoverController(nibName: "PopoverController", bundle: nil)
		
		monitorLeftClick = EventMonitor(mask: .LeftMouseDownMask) { [unowned self] event in
			if popover.shown && prefPopover.shown == false {
				self.closePopover(event)
			}
		}

		// prevents log from getting too big, log is truncated on restart of app
		truncateActivityLog()
		
	}
	
	func showPopover(sender: AnyObject?) {
		if let button = menuBarItem.button {
			popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
		}
		monitorLeftClick?.start("main")
	}
	
	func closePopover(sender: AnyObject?) {
		prefPopover.performClose(sender)
		monitorLeftClick?.stop("preferences")
		popover.performClose(sender)
		if !popover.shown {monitorLeftClick?.stop("main")}
	}
	
	func togglePopover(sender: AnyObject?) {
		if popover.shown {
			closePopover(sender)
		} else {
			showPopover(sender)
		}
	}
	
	func truncateActivityLog() {
		do {
			try String().writeToFile(defaultpath.stringByAppendingString("/activity.txt"), atomically: true, encoding: NSUTF8StringEncoding)
		} catch let err as NSError{
			debug("For some reason, the activity file could not be truncated.")
			debug("Error is as follows: \(err.localizedDescription)")
		}
	}
}
