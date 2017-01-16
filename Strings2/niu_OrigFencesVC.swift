//
//  FencesViewController.swift
//  Strings2
//
//  Created by Dewey Gaedcke on 1/2/17.
//  Copyright © 2017 Dewey Gaedcke. All rights reserved.
//
// Goal of this view is to let the user quickly specify both:
//		Centerpoint of the GeoFence
//		Radius of GeoFence
// for a given String that they created/own
// annotations can be used (later) to show the location of various contributors to the string
// although I'm inclined to factor this code out into a manager-singleton
// locationManager:didUpdateLocations


import UIKit
import MapKit
import CoreLocation

private let NIU_CUR_FENCE_NAME = "CURRENT_FENCE"

private enum ViewMode {
	case Navigate	// user is dragging around the map
	case PinchRadius	// user is pinching circle on the map
	case Search			// user is searching by zip or city-name
}


class NIU_FencesViewController: AppViewController {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var mapModeControl: UISegmentedControl!
	@IBOutlet var pinchGestureRecognizer: UIPinchGestureRecognizer!
	@IBOutlet weak var gestureOverlayView: UIView!
	
	private var viewMode:ViewMode = .Navigate {
		didSet {
			switch viewMode {
			case .Navigate:
				pinchGestureRecognizer.isEnabled = false
				gestureOverlayView.isHidden = true
				mapView.isUserInteractionEnabled = true
				mapView.isRotateEnabled = false
				
			case .PinchRadius:
				pinchGestureRecognizer.isEnabled = true
				gestureOverlayView.isHidden = false
				mapView.isUserInteractionEnabled = false
				//				mapView.isZoomEnabled = false
				//				mapView.isScrollEnabled = false
				
				if radiusOverlay == nil && currentFence != nil {
					radiusOverlay = MKCircle(center: currentFence!.coordinate, radius: currentFence!.radius)
				}
			case .Search:
				break
			}
			
		}
	}
	
	// specify whether to show street, hybrid or satelight view
	@IBOutlet weak var mapViewDetailControl: UISegmentedControl!
	
	var fences: [GeoFenceLocation] = []
	let locationManager = CLLocationManager()
	var currentFence:GeoFenceLocation?
	var radiusOverlay:MKCircle?
	
	@IBAction func changeMapMode(_ sender: UISegmentedControl) {
		assert(sender == mapModeControl, "sanity check")
		
		if currentFence == nil {
			// you must specify your centerpoint b4 u can pinch radius
			sender.selectedSegmentIndex = 0
			// FIXME:  add user alert or tooltip here!!
			return
		}
		
		switch sender.selectedSegmentIndex {
		case 0:
			viewMode = .Navigate
		case 1:
			viewMode = .PinchRadius
		default:
			break
		}
		//		print("changeMapMode \(viewMode.hashValue)")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager.delegate = self
		locationManager.requestAlwaysAuthorization()
		
		mapView.showsUserLocation = true
		mapView.isRotateEnabled = false
		
		//		loadAllFences()
		//		print("LocationManager.authorization: \(CLLocationManager.authorizationStatus().rawValue)")
		if CLLocationManager.authorizationStatus() != .denied {
			print("request location running")
			locationManager.requestLocation()
		}
	}
	
	//	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	//		if segue.identifier == "addFence" {
	//			let navigationController = segue.destination as! UINavigationController
	//			let vc = navigationController.viewControllers.first as! AddFenceViewController
	//			vc.delegate = self
	//		}
	//	}
	
	// MARK: Loading and saving functions
	func loadAllFences() {
		fences = []
		guard let savedItems = UserDefaults.standard.array(forKey: Constants.Keys.savedItems) else { return }
		for savedItem in savedItems {
			guard let fence = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? GeoFenceLocation else { continue }
			add(fence: fence)
		}
	}
	
	func saveAllFences() {
		var items: [Data] = []
		for fence in fences {
			let item = NSKeyedArchiver.archivedData(withRootObject: fence)
			items.append(item)
		}
		UserDefaults.standard.set(items, forKey: Constants.Keys.savedItems)
	}
	
	// MARK: Functions that update the model/associated views with fence changes
	func add(fence: GeoFenceLocation) {
		fences.append(fence)
		mapView.addAnnotation(fence)
		addRadiusOverlay(forFence: fence)
		updateFencesCount()
	}
	
	func remove(fence: GeoFenceLocation) {
		if let indexInArray = fences.index(of: fence) {
			fences.remove(at: indexInArray)
		}
		mapView.removeAnnotation(fence)
		removeRadiusOverlay(forFence: fence)
		updateFencesCount()
	}
	
	func updateFencesCount() {
		title = "Fences (\(fences.count))"
		navigationItem.rightBarButtonItem?.isEnabled = (fences.count < 20)
	}
	
	// MARK: Map overlay functions
	func addRadiusOverlay(forFence fence: GeoFenceLocation) {
		mapView?.add(MKCircle(center: fence.coordinate, radius: fence.radius))
	}
	
	func removeRadiusOverlay(forFence fence: GeoFenceLocation) {
		// Find exactly one overlay which has the same coordinates & radius to remove
		guard let overlays = mapView?.overlays else { return }
		for overlay in overlays {
			guard let circleOverlay = overlay as? MKCircle else { continue }
			let coord = circleOverlay.coordinate
			if coord.latitude == fence.coordinate.latitude && coord.longitude == fence.coordinate.longitude && circleOverlay.radius == fence.radius {
				mapView?.remove(circleOverlay)
				break
			}
		}
	}
	
	func updateRadiusOverlay(radius:Double) {
		if radiusOverlay != nil {
			mapView?.remove(radiusOverlay!)
		}
		radiusOverlay = MKCircle(center: currentFence!.coordinate, radius: radius)
		mapView?.add(radiusOverlay!)
	}
	
	func clearMap() {
		mapView.removeAnnotations(mapView.annotations)
		mapView.removeOverlays(mapView.overlays)
	}
	
	@IBAction func zoomToCurrentLocation(sender: AnyObject) {
		mapView.zoomToUserLocation()
	}
	
	
	func region(withFence fence: GeoFenceLocation) -> CLCircularRegion {
		
		let region = CLCircularRegion(center: fence.coordinate, radius: fence.radius, identifier: fence.identifier)
		
		region.notifyOnEntry = (fence.eventType == .onEntry)
		region.notifyOnExit = !region.notifyOnEntry
		return region
	}
	
	func startMonitoring(fence: GeoFenceLocation) {
		
		if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
			showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
			return
		}
		
		if CLLocationManager.authorizationStatus() != .authorizedAlways {
			showAlert(withTitle:"Warning", message: "Your fence is saved but will only be activated once you grant Geotify permission to access the device location.")
		}
		
		let region = self.region(withFence: fence)
		locationManager.startMonitoring(for: region)
	}
	
	func stopMonitoring(fence: GeoFenceLocation) {
		for region in locationManager.monitoredRegions {
			guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == fence.identifier else { continue }
			locationManager.stopMonitoring(for: circularRegion)
		}
	}
}

// MARK: AddFenceViewControllerDelegate
extension NIU_FencesViewController: AddFenceViewControllerDelegate {
	
	func addFenceViewController(controller: AddFenceViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType)
	{
		controller.dismiss(animated: true, completion: nil)
		
		let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
		let fence = GeoFenceLocation(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
		add(fence: fence)
		
		startMonitoring(fence: fence)
		saveAllFences()
	}
	
	@IBAction func mapTypeChanged(sender: AnyObject) {
		
		switch mapViewDetailControl.selectedSegmentIndex {
		case 0:
			mapView.mapType = MKMapType.standard
		case 1:
			mapView.mapType = MKMapType.hybrid
		case 2:
			mapView.mapType = MKMapType.satellite
		default:
			break
		}
	}
	
	
}

// MARK: - Location Manager Delegate
extension NIU_FencesViewController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status != .denied {
			if currentFence == nil {
				manager.requestLocation()
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
		print("Monitoring failed for region with identifier: \(region!.identifier)")
	}
 
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Location Manager failed with the following error: \(error)")
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("locationManager callback with \(locations.count) locations")
		//		if locations.count < 1 {
		//			return
		//		}
		//
		guard let topLoc = locations.first
			else {
				print("no locations in update")
				return
		}
		
		print("topLoc:  \(topLoc)")
		if currentFence == nil && mapView.knowsUserLocation {
			print("currentFence is nil:  \(currentFence)")
			let zoomRadius = Constants.Map.initialZoom
			mapView.zoomToUserLocation(zoom: zoomRadius)
			currentFence = GeoFenceLocation(coordinate: topLoc.coordinate, radius: zoomRadius, identifier: NIU_CUR_FENCE_NAME, note: "", eventType: .onEntry)
		}
	}
}


// MARK: - MapView Delegate
extension NIU_FencesViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		let identifier = "myFence"
		if annotation is GeoFenceLocation {
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
			if annotationView == nil {
				annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
				annotationView?.canShowCallout = true
				let removeButton = UIButton(type: .custom)
				removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
				removeButton.setImage(UIImage(named: "DeleteFence")!, for: .normal)
				annotationView?.leftCalloutAccessoryView = removeButton
			} else {
				annotationView?.annotation = annotation
			}
			return annotationView
		}
		return nil
	}
	
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKCircle {
			let circleRenderer = MKCircleRenderer(overlay: overlay)
			circleRenderer.lineWidth = 1.0
			circleRenderer.strokeColor = .purple
			circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
			return circleRenderer
		}
		return MKOverlayRenderer(overlay: overlay)
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		
		// Delete fence
		let fence = view.annotation as! GeoFenceLocation
		
		stopMonitoring(fence: fence)
		remove(fence: fence)
		saveAllFences()
	}
}
