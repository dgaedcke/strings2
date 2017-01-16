//
//  AppDelegate.swift
//  Strings2
//
//  Created by Dewey Gaedcke on 12/27/16.
//  Copyright © 2016 Dewey Gaedcke. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	let locationManager = CLLocationManager()
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		
		locationManager.delegate = self
		locationManager.requestAlwaysAuthorization()
		return true
	}

//	func applicationWillResignActive(_ application: UIApplication) {
//		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//	}
//
//	func applicationDidEnterBackground(_ application: UIApplication) {
//		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
//		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//	}
//
//	func applicationWillEnterForeground(_ application: UIApplication) {
//		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
//	}
//
//	func applicationDidBecomeActive(_ application: UIApplication) {
//		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//	}
//
//	func applicationWillTerminate(_ application: UIApplication) {
//		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//	}


}

extension AppDelegate: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		if region is CLCircularRegion {
			handleEvent(forRegion: region)
			
		} else if region is CLBeaconRegion {
			
		}
	}
 
	func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		if region is CLCircularRegion {
			handleEvent(forRegion: region)
		}
	}
	
	func handleEvent(forRegion region: CLRegion!) {
		
		if UIApplication.shared.applicationState == .active {	// alert if application is active
			guard let message = note(fromRegionIdentifier: region.identifier) else { return }
			window?.rootViewController?.showAlert(withTitle: nil, message: message)
		
		} else { // Otherwise local notification
			
			// original (deprecated) approach
			let notification = UILocalNotification()
			notification.alertBody = note(fromRegionIdentifier: region.identifier)
			notification.soundName = Constants.Sounds.Default
			UIApplication.shared.presentLocalNotificationNow(notification)
			
			// new untested approach
//			let c = UNMutableNotificationContent()
//			c.title = "GeoFence"
//			c.body = note(fromRegionIdentifier: region.identifier) ?? "missing"
//			c.sound = UNNotificationSound(named: Constants.Sounds.Default)
//			// Deliver the notification in five seconds.
//			let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
//			let notification = UNNotificationRequest.init(identifier: "local", content: c, trigger: trigger)
//			UNUserNotificationCenter.current().add(notification)
		}
	}
	
	func note(fromRegionIdentifier identifier: String) -> String? {
		let savedItems = UserDefaults.standard.array(forKey: Constants.Keys.savedItems) as? [NSData]
		let geotifications = savedItems?.map { NSKeyedUnarchiver.unarchiveObject(with: $0 as Data) as? GeoFenceLocation }
		let index = geotifications?.index { $0?.identifier == identifier }
		return index != nil ? geotifications?[index!]?.note : nil
	}
	
	
}
