//		Credits to
//		https://gist.github.com/rickw/cc198001f5f3aa59ae9f
//		
//		With adjustments cleartext() and clear(..) made by
//		Harry Wang

import Foundation
import Cocoa

extension NSTextView {
	func appendText(line: String) {
		let attrDict = [NSFontAttributeName: NSFont.systemFontOfSize(13.0)]
		let astring = NSAttributedString(string: "\(line)\n", attributes: attrDict)
		self.textStorage?.appendAttributedString(astring)
		let loc = self.string?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
		
		let range = NSRange(location: loc!, length: 0)
		self.scrollRangeToVisible(range)
	}
	
	func cleartext() {
		self.textStorage?.mutableString.setString("")
	}
}

func xlog(logView:NSTextView?, line:String) {
	if let view = logView {
		view.appendText(line)
	}
}

func clear(logView: NSTextView?) {
	if let view = logView {
		view.cleartext()
	}
}

func debug(message: AnyObject?) {
	if let printcontents = message {
		print("DEBUG: \(printcontents)")
		do {
			try String(contentsOfFile: defaultpath.stringByAppendingString("/activity.txt")).stringByAppendingString("\(printcontents)\n").writeToFile(defaultpath.stringByAppendingString("/activity.txt"), atomically: false, encoding: NSUTF8StringEncoding)
		}
		catch {
			print("Activity log could not be appended to")
		}
	}
}

// boolean conversion function extension to the string class.
// http://stackoverflow.com/questions/28107051/convert-string-to-bool-in-swift-via-api-or-most-swift-like-approach
extension String {
	func toBool() -> Bool? {
		switch self {
		case "true":
			return true
		case "false":
			return false
		default:
			return nil
		}
	}
}