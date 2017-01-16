//
//  AppViewController.swift
//  Strings2
//
//  Created by Dewey Gaedcke on 12/27/16.
//  Copyright © 2016 Dewey Gaedcke. All rights reserved.
//

import UIKit
// import EasyTipView
import FirebaseAnalytics

private let adHeight:CGFloat = 50.0

class AppViewController: UIViewController
{
	var viewsWithHelp:[UIView] = []
	
	var currentHelpViewIndex = 0
	var adContainerView: UIView?
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		//		print("called super viewDidLoad from \(self.description)")
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		showHelpOnFirstAppearanceIfNeeded()
	}
	

}

//extension AppViewController: UITextFieldDelegate {
//	func textFieldChanged(textField: UITextField) {
//	}
//	
//	func configureTextView(notesTextView:UITextField) {
//		notesTextView.layer.cornerRadius = 8.0
//		notesTextView.layer.borderColor = UIColor(white: 0.75, alpha: 0.5).CGColor
//		notesTextView.layer.borderWidth = 1.2
//	}
//}

extension AppViewController
{	// log to Firebase Analytics
	
	func logUserEvent(name:String, params:[String:String] = [:]) {
		var newParams:[String:NSObject] = params as [String : NSObject]
		newParams["screenName"] = self.classForCoder.description().components(separatedBy: ".").last! as NSObject
		FIRAnalytics.logEvent(withName: name, parameters: newParams)
	}
}



