//
//  HelpOverlay.swift
//  Strings2
//
//  Created by Dewey Gaedcke on 12/27/16.
//  Copyright © 2016 Dewey Gaedcke. All rights reserved.
//

import UIKit
import ExtraKit
import EasyTipView


private let HELP_SHOWN_KEY = "helpShown"
private let HELP_IDENTIFIER_KEY = "helpIdentifier"

private let K_SHOW_ALL_AT_ONCE = true
private var K_EASYTIP_CONFIGURED = false
private let K_OUTOFRANGE_HELP_VIEW_INDEX = 1000

private var globalPrefs = EasyTipView.Preferences()

private func setGlobalPrefs() {
	
	//	let screenSize = UIScreen.mainScreen().bounds
	//	globalPrefs.positioning.maxWidth = CGFloat( (screenSize.width/2) - 26)
	globalPrefs.drawing.backgroundColor = Constants.UI.toolTipBackColor
	
	//	globalPrefs.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
	//	globalPrefs.drawing.foregroundColor = UIColor.whiteColor()
	globalPrefs.drawing.arrowPosition = Constants.Tooltips.Position
	
	EasyTipView.globalPreferences = globalPrefs
	K_EASYTIP_CONFIGURED = true
}

func helpShownDefaults() -> [String: NSNumber] {
	return UserDefaults.standard.object(forKey: HELP_SHOWN_KEY) as? [String: NSNumber] ?? [:]
}

func getHelpShown(key: String?) -> Bool {
	if let key = key {
		return (helpShownDefaults()[key]?.boolValue) ?? false
	}
	return false
}

func setHelpShown(value: Bool, forKey key: String?) {
	if let key = key {
		var defaults = helpShownDefaults()
		defaults[key] = value as NSNumber?
		UserDefaults.standard.set(defaults, forKey: HELP_SHOWN_KEY)
	}
}

func resetAllHelpShown() {
	UserDefaults.standard.set(nil, forKey: HELP_SHOWN_KEY)
}

extension AppViewController: EasyTipViewDelegate {
	
	func easyTipViewDidDismiss(_ tipView : EasyTipView) {
		// called each time user taps one
		// only if K_SHOW_ALL_AT_ONCE == false
		// print("called easyTipViewDidDismiss delegate.  count=\(self.viewsWithHelp.count)")
		guard K_SHOW_ALL_AT_ONCE == false else { return }
		
		self.currentHelpViewIndex += 1
		let vwh = self.viewsWithHelp
		let curHelpViewIdx = self.currentHelpViewIndex
		
		guard curHelpViewIdx < vwh.count else {
			helpShown = true
			self.currentHelpViewIndex = K_OUTOFRANGE_HELP_VIEW_INDEX
			return
		}
		
		let nextViewWithHelp = vwh[curHelpViewIdx]
		EasyTipView.show(forView: nextViewWithHelp, withinSuperview: view, text: nextViewWithHelp.helpIdentifier ?? "", preferences: globalPrefs, delegate: self)
	}
	
	@IBInspectable var helpIdentifier: String? {
		get { return associatedValueForKey(key: HELP_IDENTIFIER_KEY) }
		set { setAssociatedValue(value: newValue as AnyObject?, forKey: HELP_IDENTIFIER_KEY) }
	}
	@IBInspectable var showHelpOnFirstAppearance: Bool {
		get { return associatedValueForKey(key: "showHelpOnFirstAppearance") ?? false }
		set { setAssociatedValue(value: newValue as AnyObject?, forKey: "showHelpOnFirstAppearance") }
	}
	var helpShown: Bool {
		// indicates whether help has been shown for this specific VC
		get { return getHelpShown (key: helpIdentifier) }
		set { setHelpShown(value: newValue, forKey: helpIdentifier) }
	}
	
	
	func showHelpOnFirstAppearanceIfNeeded() {
		// this is entry point called by viewDidAppear
		guard showHelpOnFirstAppearance else { return }
		
		if !K_EASYTIP_CONFIGURED {
			setGlobalPrefs()
		}
		
		if (showHelpOnFirstAppearance && helpShown == false) {
			showHelp()
		} else if showHelpOnFirstAppearance {  // help already shown once
			// add ?mark icon to allow them to toggle it all at once
			hideHelp()
			addToggleHelpIcon()
		}
	}
	
	func addToggleHelpIcon() {
		// icon callback should be "toggleHelp()" below
		//		let icon = ""
		//		view.addSubview(icon)
	}
	
	@IBAction func showHelp(allAtOnce:Bool = K_SHOW_ALL_AT_ONCE) {
		let helpViews = view.helpViews
		if helpViews.count == 0 {
			return
		}
		
		self.viewsWithHelp = helpViews	// store so you can walk this list if K_SHOW_ALL_AT_ONCE is false
		// to show all at once, change K_SHOW_ALL_AT_ONCE above
		if allAtOnce {
			helpViews.forEach {
				EasyTipView.show(forView: $0, withinSuperview: view, text: $0.helpIdentifier?.localized ?? "")
			}
			self.currentHelpViewIndex = K_OUTOFRANGE_HELP_VIEW_INDEX // prevents new ones being shown when you close one
			
		} else {
			self.currentHelpViewIndex = 0
			EasyTipView.show(forView: helpViews[0], withinSuperview: view, text: helpViews[0].helpIdentifier?.localized ?? "", delegate: self)
		}
		helpShown = true
	}
	
	@IBAction func hideHelp() {
		view.subviews.forEach {
			($0 as? EasyTipView)?.removeFromSuperview()
		}
		self.currentHelpViewIndex = K_OUTOFRANGE_HELP_VIEW_INDEX
	}
	
	@IBAction func toggleHelp() {
		
		if view.subviews.find(predicate: {$0 is EasyTipView }) != nil {
			hideHelp()
		} else {
			showHelp(allAtOnce: true)
		}
	}
	
	private func hideOneTimeTips(forView view: UIView) {
		view.subviews.forEach {
			($0 as? EasyTipView)?.removeFromSuperview()
		}
	}
	
	func showTooltipNow(forView view: UIView, withinSuperView superView: UIView, msg:String) {
		hideOneTimeTips(forView: superView)
		EasyTipView.show(forView: view, withinSuperview: superView, text: msg, delegate: self)
	}
}

extension UIView {
	
	@IBInspectable var helpIdentifier: String? {
		get { return associatedValueForKey(key: HELP_IDENTIFIER_KEY) }
		set { setAssociatedValue(value: newValue as AnyObject?, forKey: HELP_IDENTIFIER_KEY) }
	}
	
	var helpViews: [UIView] {
		var views = [UIView]()
		if helpIdentifier != nil {
			views.append(self)
		}
		subviews.forEach {
			views.append(contentsOf: $0.helpViews)
		}
		
		return views
	}
}
